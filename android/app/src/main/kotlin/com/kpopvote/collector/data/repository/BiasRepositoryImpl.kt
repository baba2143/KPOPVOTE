package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.toAppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.BiasData
import com.kpopvote.collector.data.model.BiasSettings
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class BiasRepositoryImpl @Inject constructor(
    private val client: FunctionsClient,
    private val json: Json,
) : BiasRepository {

    override suspend fun getBias(): Result<List<BiasSettings>> = runCatching {
        client.get(ApiPaths.GET_BIAS, BiasData.serializer()).myBias
    }.recoverCatching { throw it.toAppError() }

    override suspend fun setBias(settings: List<BiasSettings>): Result<Unit> = runCatching {
        val body = json.encodeToString(BiasData.serializer(), BiasData(settings))
        client.post(ApiPaths.SET_BIAS, body, BiasData.serializer())
        Unit
    }.recoverCatching { throw it.toAppError() }
}
