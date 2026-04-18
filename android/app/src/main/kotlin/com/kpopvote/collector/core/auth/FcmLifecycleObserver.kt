package com.kpopvote.collector.core.auth

import com.google.firebase.messaging.FirebaseMessaging
import com.kpopvote.collector.data.repository.FcmTokenRepository
import com.kpopvote.collector.di.ApplicationScope
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Bridges auth state transitions to FCM token registration:
 *  - On `Authenticated` → fetch the current FCM token and POST `/registerFcmToken`
 *  - On `Unauthenticated` → POST `/unregisterFcmToken`
 *
 * iOS parity: `PushNotificationManager.onUserLogin/onUserLogout` in
 * `ios/KPOPVOTE/KPOPVOTE/Services/PushNotificationManager.swift`.
 *
 * [tokenFetcher] is abstracted so unit tests can avoid touching FirebaseMessaging.
 */
@Singleton
class FcmLifecycleObserver @Inject constructor(
    private val authStateHolder: AuthStateHolder,
    private val fcmTokenRepository: FcmTokenRepository,
    @ApplicationScope private val appScope: CoroutineScope,
    private val tokenFetcher: FcmTokenFetcher,
) {
    private var job: Job? = null

    fun start() {
        if (job != null) return
        job = appScope.launch {
            authStateHolder.authState
                .distinctUntilChanged { old, new -> old::class == new::class }
                .collectLatest { state ->
                    when (state) {
                        is AuthState.Authenticated -> registerCurrentToken()
                        AuthState.Unauthenticated -> unregister()
                        AuthState.Loading -> Unit
                    }
                }
        }
    }

    private suspend fun registerCurrentToken() {
        val token = runCatching { tokenFetcher.currentToken() }
            .onFailure { Timber.w(it, "FCM token fetch failed during auth login") }
            .getOrNull() ?: return
        fcmTokenRepository.register(token)
            .onFailure { Timber.w(it, "FCM token register failed after login") }
    }

    private suspend fun unregister() {
        fcmTokenRepository.unregister()
            .onFailure { Timber.w(it, "FCM token unregister failed after logout") }
    }
}

/** Indirection for `FirebaseMessaging.getInstance().token.await()` to enable unit testing. */
fun interface FcmTokenFetcher {
    suspend fun currentToken(): String
}

class DefaultFcmTokenFetcher @Inject constructor(
    private val messaging: FirebaseMessaging,
) : FcmTokenFetcher {
    override suspend fun currentToken(): String = messaging.token.await()
}
