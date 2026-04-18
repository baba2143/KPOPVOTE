package com.kpopvote.collector.data.repository

import com.kpopvote.collector.data.model.InAppVote
import com.kpopvote.collector.data.model.VoteExecuteResult
import com.kpopvote.collector.data.model.VoteRanking
import com.kpopvote.collector.data.model.VoteStatus

/**
 * In-app voting (iOS `VoteService`). All calls go through Cloud Functions HTTP;
 * `executeVote` additionally attaches a Firebase App Check token in the
 * `X-Firebase-AppCheck` header when available.
 */
interface VoteRepository {
    suspend fun fetchFeaturedVotes(): Result<List<InAppVote>>
    suspend fun fetchVotes(status: VoteStatus? = null): Result<List<InAppVote>>
    suspend fun fetchVoteDetail(voteId: String): Result<InAppVote>
    suspend fun executeVote(
        voteId: String,
        choiceId: String,
        voteCount: Int = 1,
        pointSelection: String = "auto",
    ): Result<VoteExecuteResult>
    suspend fun fetchRanking(voteId: String): Result<VoteRanking>
}
