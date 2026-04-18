package com.kpopvote.collector.data.model

import kotlinx.serialization.Serializable

/** Response body for Cloud Function `getRanking`. */
@Serializable
data class VoteRanking(
    val voteId: String,
    val rankings: List<RankingEntry> = emptyList(),
    val totalVotes: Long = 0,
    val updatedAt: String? = null,
)

@Serializable
data class RankingEntry(
    val rank: Int,
    val choiceId: String,
    val displayName: String,
    val imageUrl: String? = null,
    val voteCount: Long = 0,
    val percentage: Double = 0.0,
)
