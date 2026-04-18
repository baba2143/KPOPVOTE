package com.kpopvote.collector.core.common

import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

interface IdTokenProvider {
    suspend fun currentIdToken(forceRefresh: Boolean = false): String?
    fun currentUid(): String?
}

@Singleton
class FirebaseIdTokenProvider @Inject constructor(
    private val firebaseAuth: FirebaseAuth,
) : IdTokenProvider {

    override suspend fun currentIdToken(forceRefresh: Boolean): String? {
        val user = firebaseAuth.currentUser ?: return null
        return runCatching { user.getIdToken(forceRefresh).await().token }.getOrNull()
    }

    override fun currentUid(): String? = firebaseAuth.currentUser?.uid
}
