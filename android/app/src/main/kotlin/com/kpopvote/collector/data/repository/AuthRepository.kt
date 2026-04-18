package com.kpopvote.collector.data.repository

import android.content.Context
import com.kpopvote.collector.core.auth.AuthState
import kotlinx.coroutines.flow.StateFlow

/**
 * Abstraction over Firebase Auth + Google Credential Manager.
 *
 * Matches the responsibility surface of iOS AuthService
 * (ios/KPOPVOTE/Services/AuthService.swift).
 */
interface AuthRepository {
    val authState: StateFlow<AuthState>

    suspend fun signInWithEmail(email: String, password: String): Result<Unit>

    suspend fun signUpWithEmail(email: String, password: String): Result<Unit>

    /**
     * Starts Credential Manager Google Sign-In flow.
     * Must be called with an Activity context — Credential Manager attaches
     * a bottom sheet to the current Activity.
     */
    suspend fun signInWithGoogle(activityContext: Context): Result<Unit>

    suspend fun signOut()

    /** Current Firebase ID token, optionally refreshed. */
    suspend fun getIdToken(forceRefresh: Boolean = false): String?
}
