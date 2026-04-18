package com.kpopvote.collector.data.repository

/**
 * FCM device-token registration against the backend.
 * Cloud Functions: `registerFcmToken` (POST) / `unregisterFcmToken` (POST).
 *
 * The deviceId is stable per install ([com.kpopvote.collector.data.local.DeviceIdDataStore]);
 * the token itself rotates whenever Firebase refreshes it.
 */
interface FcmTokenRepository {
    suspend fun register(token: String): Result<Unit>
    suspend fun unregister(): Result<Unit>
}
