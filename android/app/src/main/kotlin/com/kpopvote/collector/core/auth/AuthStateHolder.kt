package com.kpopvote.collector.core.auth

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.stateIn
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Observes FirebaseAuth's user state and publishes [AuthState] to the app.
 * Single source of truth for "am I logged in?"
 */
@Singleton
class AuthStateHolder @Inject constructor(
    private val firebaseAuth: FirebaseAuth,
    appScope: CoroutineScope,
) {
    val authState: StateFlow<AuthState> = callbackFlow {
        val listener = FirebaseAuth.AuthStateListener { auth ->
            trySend(auth.currentUser.toAuthState())
        }
        firebaseAuth.addAuthStateListener(listener)
        trySend(firebaseAuth.currentUser.toAuthState())
        awaitClose { firebaseAuth.removeAuthStateListener(listener) }
    }.stateIn(
        scope = appScope,
        started = SharingStarted.Eagerly,
        initialValue = AuthState.Loading,
    )

    val currentUid: String?
        get() = firebaseAuth.currentUser?.uid
}

private fun FirebaseUser?.toAuthState(): AuthState =
    if (this == null) {
        AuthState.Unauthenticated
    } else {
        AuthState.Authenticated(
            uid = uid,
            email = email,
            displayName = displayName,
        )
    }
