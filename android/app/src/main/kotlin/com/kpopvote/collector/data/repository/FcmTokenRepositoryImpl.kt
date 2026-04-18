package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.toAppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.local.DeviceIdDataStore
import com.kpopvote.collector.data.model.RegisterFcmTokenBody
import com.kpopvote.collector.data.model.UnregisterFcmTokenBody
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FcmTokenRepositoryImpl @Inject constructor(
    private val client: FunctionsClient,
    private val deviceIdDataStore: DeviceIdDataStore,
    private val json: Json,
) : FcmTokenRepository {

    override suspend fun register(token: String): Result<Unit> = runCatching {
        val deviceId = deviceIdDataStore.getOrCreate()
        val body = json.encodeToString(
            RegisterFcmTokenBody.serializer(),
            RegisterFcmTokenBody(token = token, deviceId = deviceId, platform = PLATFORM_ANDROID),
        )
        client.postIgnoringData(ApiPaths.REGISTER_FCM_TOKEN, body)
    }.recoverCatching { throw it.toAppError() }

    override suspend fun unregister(): Result<Unit> = runCatching {
        val deviceId = deviceIdDataStore.getOrCreate()
        val body = json.encodeToString(
            UnregisterFcmTokenBody.serializer(),
            UnregisterFcmTokenBody(deviceId = deviceId),
        )
        client.postIgnoringData(ApiPaths.UNREGISTER_FCM_TOKEN, body)
    }.recoverCatching { throw it.toAppError() }

    private companion object {
        const val PLATFORM_ANDROID = "android"
    }
}
