package com.kpopvote.collector.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Mirrors iOS `User.swift`. `uid` is the Firebase Auth UID and Firestore document id.
 *
 * The backend serializes timestamps inconsistently (Firestore Timestamp for realtime,
 * ISO8601 from HTTP) — we keep them as epoch millis here and convert at the boundary.
 */
@Serializable
data class User(
    @SerialName("uid") val id: String,
    val email: String,
    val displayName: String? = null,
    val photoURL: String? = null,
    val bio: String? = null,
    val points: Int = 0,
    val biasIds: List<String> = emptyList(),
    val followingCount: Int = 0,
    val followersCount: Int = 0,
    val postsCount: Int = 0,
    val isPrivate: Boolean = false,
    val isSuspended: Boolean = false,
    // Backend HTTP serializes timestamps inconsistently (Double seconds, ISO8601 string, or
    // Firestore Timestamp object); we skip them here and populate from Firestore snapshots
    // inside UserRepositoryImpl. Sprint 7 (Profile UI) will revisit if needed.
    val createdAtMillis: Long? = null,
    val updatedAtMillis: Long? = null,
) {
    val displayNameSafe: String
        get() = displayName?.takeIf { it.isNotBlank() } ?: "ユーザー"

    val displayNameOrEmail: String
        get() = displayName?.takeIf { it.isNotBlank() }
            ?: email.substringBefore('@').ifBlank { email }

    val formattedPoints: String get() = "${points}pt"

    val isActive: Boolean get() = !isSuspended
}
