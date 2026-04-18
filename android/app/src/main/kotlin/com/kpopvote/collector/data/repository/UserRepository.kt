package com.kpopvote.collector.data.repository

import com.kpopvote.collector.data.model.User
import kotlinx.coroutines.flow.Flow

/**
 * Access to the signed-in user's profile. `observeCurrentUser` tracks Firestore
 * in realtime; `updateProfile` invokes the Cloud Functions HTTP endpoint (mirrors
 * iOS `ProfileService.updateProfile`).
 */
interface UserRepository {
    /** Emits null when logged out or when the Firestore doc is missing. */
    fun observeCurrentUser(): Flow<User?>

    suspend fun getCurrentUser(): Result<User?>

    suspend fun updateProfile(
        displayName: String? = null,
        bio: String? = null,
        biasIds: List<String>? = null,
        photoURL: String? = null,
    ): Result<User>
}
