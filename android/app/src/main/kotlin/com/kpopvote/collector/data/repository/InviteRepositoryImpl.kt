package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.toAppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.ApplyInviteCodeBody
import com.kpopvote.collector.data.model.ApplyInviteCodeData
import com.kpopvote.collector.data.model.GenerateInviteCodeData
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class InviteRepositoryImpl @Inject constructor(
    private val client: FunctionsClient,
    private val json: Json,
) : InviteRepository {

    override suspend fun generateInviteCode(): Result<GenerateInviteCodeData> = runCatching {
        client.post(
            ApiPaths.GENERATE_INVITE_CODE,
            bodyJson = "{}",
            dataSerializer = GenerateInviteCodeData.serializer(),
        )
    }.recoverCatching { throw it.toAppError() }

    override suspend fun applyInviteCode(code: String): Result<ApplyInviteCodeData> = runCatching {
        val body = json.encodeToString(
            ApplyInviteCodeBody.serializer(),
            ApplyInviteCodeBody(inviteCode = code),
        )
        client.post(
            ApiPaths.APPLY_INVITE_CODE,
            bodyJson = body,
            dataSerializer = ApplyInviteCodeData.serializer(),
        )
    }.recoverCatching { throw InviteErrorMapper.mapApplyError(it.toAppError()) }
}
