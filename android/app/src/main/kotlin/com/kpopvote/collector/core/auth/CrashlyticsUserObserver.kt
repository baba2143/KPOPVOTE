package com.kpopvote.collector.core.auth

import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.kpopvote.collector.core.analytics.AnalyticsLogger
import com.kpopvote.collector.di.ApplicationScope
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Propagates the current user id to Crashlytics and Analytics so crash reports and
 * events are attributable without touching PII.
 *
 * iOS parity: `CrashlyticsManager.setUser` call in `AuthService.signIn/signOut`.
 */
@Singleton
class CrashlyticsUserObserver @Inject constructor(
    private val authStateHolder: AuthStateHolder,
    private val crashlytics: FirebaseCrashlytics,
    private val analyticsLogger: AnalyticsLogger,
    @ApplicationScope private val appScope: CoroutineScope,
) {
    private var job: Job? = null

    fun start() {
        if (job != null) return
        job = appScope.launch {
            authStateHolder.authState
                .distinctUntilChanged { old, new -> old::class == new::class }
                .collectLatest { state ->
                    when (state) {
                        is AuthState.Authenticated -> {
                            crashlytics.setUserId(state.uid)
                            analyticsLogger.setUserId(state.uid)
                        }
                        AuthState.Unauthenticated -> {
                            crashlytics.setUserId("")
                            analyticsLogger.setUserId(null)
                        }
                        AuthState.Loading -> Unit
                    }
                }
        }
    }
}
