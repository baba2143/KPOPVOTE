package com.kpopvote.collector.core.auth

/**
 * Global authentication state exposed by [AuthStateHolder].
 * NavGraph observes this to decide whether to show Auth or Main graph.
 */
sealed interface AuthState {
    /** App is still checking persisted credentials. */
    data object Loading : AuthState

    /** No valid session — show Auth graph. */
    data object Unauthenticated : AuthState

    /** Valid Firebase session. */
    data class Authenticated(
        val uid: String,
        val email: String?,
        val displayName: String?,
    ) : AuthState
}
