package com.kpopvote.collector.data.repository

import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.FirebaseNetworkException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthInvalidCredentialsException
import com.google.firebase.auth.FirebaseAuthInvalidUserException
import com.google.firebase.auth.FirebaseAuthUserCollisionException
import com.google.firebase.auth.FirebaseAuthWeakPasswordException
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.functions.FirebaseFunctions
import com.kpopvote.collector.BuildConfig
import com.kpopvote.collector.core.auth.AuthState
import com.kpopvote.collector.core.auth.AuthStateHolder
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.common.AuthFailureReason
import com.kpopvote.collector.di.IoDispatcher
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val firebaseAuth: FirebaseAuth,
    private val functions: FirebaseFunctions,
    private val authStateHolder: AuthStateHolder,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher,
) : AuthRepository {

    override val authState: StateFlow<AuthState> = authStateHolder.authState

    override suspend fun signInWithEmail(email: String, password: String): Result<Unit> =
        withContext(ioDispatcher) {
            runCatching {
                firebaseAuth.signInWithEmailAndPassword(email, password).await()
                Unit
            }.recoverCatching { throw it.toAuthError() }
        }

    override suspend fun signUpWithEmail(email: String, password: String): Result<Unit> =
        withContext(ioDispatcher) {
            runCatching {
                firebaseAuth.createUserWithEmailAndPassword(email, password).await()
                // Mirror iOS behavior: call `register` Cloud Function to create Firestore user doc.
                // Failure here is non-fatal for the Auth session but should be surfaced.
                runCatching {
                    functions.getHttpsCallable("register").call(mapOf("email" to email)).await()
                }.onFailure { Timber.w(it, "register Cloud Function failed — Firestore user doc not created") }
                Unit
            }.recoverCatching { throw it.toAuthError() }
        }

    override suspend fun signInWithGoogle(activityContext: Context): Result<Unit> =
        runCatching {
            val webClientId = BuildConfig.GOOGLE_WEB_CLIENT_ID
            require(webClientId.isNotBlank()) {
                "GOOGLE_WEB_CLIENT_ID is not configured. See docs/android/setup-guide.md"
            }

            val googleIdOption = GetGoogleIdOption.Builder()
                .setServerClientId(webClientId)
                .setFilterByAuthorizedAccounts(false)
                .setAutoSelectEnabled(true)
                .build()

            val request = GetCredentialRequest.Builder()
                .addCredentialOption(googleIdOption)
                .build()

            val credentialManager = CredentialManager.create(activityContext)
            val response = credentialManager.getCredential(activityContext, request)

            val credential = response.credential
            require(credential is CustomCredential && credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                "Unexpected credential type: ${credential::class.java.name}"
            }

            val googleIdToken = GoogleIdTokenCredential.createFrom(credential.data).idToken
            val firebaseCredential = GoogleAuthProvider.getCredential(googleIdToken, null)
            firebaseAuth.signInWithCredential(firebaseCredential).await()
            Unit
        }.recoverCatching { throw it.toAuthError() }

    override suspend fun signOut() = withContext(ioDispatcher) {
        firebaseAuth.signOut()
        runCatching {
            CredentialManager.create(firebaseAuth.app.applicationContext)
                .clearCredentialState(androidx.credentials.ClearCredentialStateRequest())
        }.onFailure { Timber.w(it, "clearCredentialState failed — non-fatal") }
    }

    override suspend fun getIdToken(forceRefresh: Boolean): String? = withContext(ioDispatcher) {
        val user = firebaseAuth.currentUser ?: return@withContext null
        runCatching { user.getIdToken(forceRefresh).await().token }.getOrNull()
    }
}

private fun Throwable.toAuthError(): AppError = when (this) {
    is GetCredentialCancellationException ->
        AppError.Auth(AuthFailureReason.GOOGLE_SIGN_IN_CANCELLED)
    is GetCredentialException ->
        AppError.Auth(AuthFailureReason.GOOGLE_SIGN_IN_FAILED)
    is FirebaseAuthInvalidCredentialsException ->
        AppError.Auth(AuthFailureReason.WRONG_CREDENTIALS)
    is FirebaseAuthInvalidUserException ->
        AppError.Auth(AuthFailureReason.USER_NOT_FOUND)
    is FirebaseAuthUserCollisionException ->
        AppError.Auth(AuthFailureReason.EMAIL_ALREADY_IN_USE)
    is FirebaseAuthWeakPasswordException ->
        AppError.Auth(AuthFailureReason.WEAK_PASSWORD)
    is FirebaseNetworkException ->
        AppError.Network
    is AppError -> this
    else -> {
        Timber.w(this, "Unclassified auth error")
        AppError.Auth(AuthFailureReason.UNKNOWN)
    }
}
