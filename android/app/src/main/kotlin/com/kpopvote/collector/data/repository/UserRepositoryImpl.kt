package com.kpopvote.collector.data.repository

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.kpopvote.collector.core.auth.AuthState
import com.kpopvote.collector.core.auth.AuthStateHolder
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.common.IdTokenProvider
import com.kpopvote.collector.core.common.toAppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.User
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.tasks.await
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class UserRepositoryImpl @Inject constructor(
    private val firestore: FirebaseFirestore,
    private val client: FunctionsClient,
    private val tokenProvider: IdTokenProvider,
    private val authStateHolder: AuthStateHolder,
    private val json: Json,
) : UserRepository {

    override fun observeCurrentUser(): Flow<User?> =
        authStateHolder.authState
            .map { (it as? AuthState.Authenticated)?.uid }
            .distinctUntilChanged()
            .flatMapLatest { uid ->
                if (uid == null) flowOf(null) else userDocumentFlow(uid)
            }

    private fun userDocumentFlow(uid: String): Flow<User?> = callbackFlow {
        val doc = firestore.collection("users").document(uid)
        val registration: ListenerRegistration = doc.addSnapshotListener { snap, error ->
            if (error != null) {
                Timber.w(error, "users/$uid snapshot error")
                trySend(null)
                return@addSnapshotListener
            }
            if (snap == null || !snap.exists()) {
                trySend(null)
            } else {
                trySend(snap.toUser(uid))
            }
        }
        awaitClose { registration.remove() }
    }

    override suspend fun getCurrentUser(): Result<User?> = runCatching {
        val uid = tokenProvider.currentUid() ?: throw AppError.Unauthorized
        val doc = firestore.collection("users").document(uid).get().await()
        if (doc.exists()) doc.toUser(uid) else null
    }.recoverCatching { throw it.toAppError() }

    override suspend fun updateProfile(
        displayName: String?,
        bio: String?,
        biasIds: List<String>?,
        photoURL: String?,
    ): Result<User> = runCatching {
        val body = buildJsonObject {
            displayName?.let { put("displayName", it) }
            bio?.let { put("bio", it) }
            photoURL?.let { put("photoURL", it) }
            biasIds?.let {
                put("biasIds", JsonArray(it.map { id -> JsonPrimitive(id) }))
            }
        }
        val bodyString = json.encodeToString(JsonObject.serializer(), body)
        client.post(ApiPaths.UPDATE_USER_PROFILE, bodyString, User.serializer())
    }.recoverCatching { throw it.toAppError() }

    private fun DocumentSnapshot.toUser(uid: String): User {
        val email = getString("email").orEmpty()
        val biasIds = (get("biasIds") as? List<*>)?.filterIsInstance<String>().orEmpty()
        return User(
            id = uid,
            email = email,
            displayName = getString("displayName"),
            photoURL = getString("photoURL"),
            bio = getString("bio"),
            points = getLong("points")?.toInt() ?: 0,
            biasIds = biasIds,
            followingCount = getLong("followingCount")?.toInt() ?: 0,
            followersCount = getLong("followersCount")?.toInt() ?: 0,
            postsCount = getLong("postsCount")?.toInt() ?: 0,
            isPrivate = getBoolean("isPrivate") ?: false,
            isSuspended = getBoolean("isSuspended") ?: false,
            createdAtMillis = (get("createdAt") as? Timestamp)?.toMillis(),
            updatedAtMillis = (get("updatedAt") as? Timestamp)?.toMillis(),
        )
    }

    private fun Timestamp.toMillis(): Long = seconds * 1000 + nanoseconds / 1_000_000
}
