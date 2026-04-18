package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.appcheck.AppCheckTokenProvider
import com.kpopvote.collector.core.common.toAppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.InAppVote
import com.kpopvote.collector.data.model.VoteExecuteBody
import com.kpopvote.collector.data.model.VoteExecuteResult
import com.kpopvote.collector.data.model.VoteListData
import com.kpopvote.collector.data.model.VoteRanking
import com.kpopvote.collector.data.model.VoteStatus
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class VoteRepositoryImpl @Inject constructor(
    private val client: FunctionsClient,
    private val appCheckTokenProvider: AppCheckTokenProvider,
    private val json: Json,
) : VoteRepository {

    override suspend fun fetchFeaturedVotes(): Result<List<InAppVote>> = runCatching {
        client.get(
            ApiPaths.LIST_IN_APP_VOTES,
            VoteListData.serializer(),
            mapOf("featured" to "true"),
        ).votes
    }.recoverCatching { throw it.toAppError() }

    override suspend fun fetchVotes(status: VoteStatus?): Result<List<InAppVote>> = runCatching {
        val query = status?.let { mapOf("status" to it.wireName()) } ?: emptyMap()
        client.get(ApiPaths.LIST_IN_APP_VOTES, VoteListData.serializer(), query).votes
    }.recoverCatching { throw it.toAppError() }

    override suspend fun fetchVoteDetail(voteId: String): Result<InAppVote> = runCatching {
        client.get(
            ApiPaths.GET_IN_APP_VOTE,
            InAppVote.serializer(),
            mapOf("voteId" to voteId),
        )
    }.recoverCatching { throw it.toAppError() }

    override suspend fun executeVote(
        voteId: String,
        choiceId: String,
        voteCount: Int,
        pointSelection: String,
    ): Result<VoteExecuteResult> = runCatching {
        val body = json.encodeToString(
            VoteExecuteBody.serializer(),
            VoteExecuteBody(voteId, choiceId, voteCount, pointSelection),
        )
        val headers = appCheckTokenProvider.getToken()?.let {
            mapOf("X-Firebase-AppCheck" to it)
        } ?: emptyMap()
        client.post(ApiPaths.EXECUTE_VOTE, body, VoteExecuteResult.serializer(), headers)
    }.recoverCatching { throw VoteErrorMapper.mapExecuteError(it.toAppError()) }

    override suspend fun fetchRanking(voteId: String): Result<VoteRanking> = runCatching {
        client.get(
            ApiPaths.GET_RANKING,
            VoteRanking.serializer(),
            mapOf("voteId" to voteId),
        )
    }.recoverCatching { throw it.toAppError() }
}

private fun VoteStatus.wireName(): String = when (this) {
    VoteStatus.UPCOMING -> "upcoming"
    VoteStatus.ACTIVE -> "active"
    VoteStatus.ENDED -> "ended"
}
