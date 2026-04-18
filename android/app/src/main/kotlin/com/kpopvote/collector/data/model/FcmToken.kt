package com.kpopvote.collector.data.model

import kotlinx.serialization.Serializable

/**
 * Request bodies for Cloud Functions `registerFcmToken` / `unregisterFcmToken`.
 * Mirrors `functions/src/fcm/registerToken.ts` + `unregisterToken.ts`.
 */
@Serializable
data class RegisterFcmTokenBody(
    val token: String,
    val deviceId: String,
    val platform: String = "android",
)

@Serializable
data class UnregisterFcmTokenBody(
    val deviceId: String,
)

@Serializable
data class RegisterFcmTokenData(
    val registered: Boolean = true,
    val deviceId: String,
)
