package com.kpopvote.collector.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Request body for Cloud Function `executeVote`. */
@Serializable
data class VoteExecuteBody(
    val voteId: String,
    val choiceId: String,
    val voteCount: Int = 1,
    val pointSelection: String = "auto",
)

/**
 * Response body for `executeVote`. Note the JSON key is `totalPointsDeducted`
 * on the wire (iOS parity) — we surface it as [pointsDeducted] in Kotlin.
 */
@Serializable
data class VoteExecuteResult(
    val voteId: String,
    val choiceId: String,
    val voteCount: Int,
    @SerialName("totalPointsDeducted") val pointsDeducted: Int,
    val userDailyVotes: Int? = null,
    val userDailyRemaining: Int? = null,
)
