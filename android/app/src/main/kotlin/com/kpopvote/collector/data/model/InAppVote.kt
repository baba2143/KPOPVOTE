package com.kpopvote.collector.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * In-app vote surfaced via Cloud Function `listInAppVotes` / `getInAppVoteDetail`.
 * Mirrors iOS `InAppVote` (Models/InAppVote.swift).
 */
@Serializable
data class InAppVote(
    val voteId: String,
    val title: String,
    val description: String? = null,
    val coverImageUrl: String? = null,
    val status: VoteStatus,
    val startAt: String,
    val endAt: String,
    val choices: List<VoteChoice> = emptyList(),
    val totalVotes: Long = 0,
    val featured: Boolean = false,
    val pointCost: Int = 1,
    val userDailyLimit: Int? = null,
    val userDailyVotes: Int? = null,
    val userDailyRemaining: Int? = null,
    val userPoints: Int? = null,
)

@Serializable
enum class VoteStatus {
    @SerialName("upcoming") UPCOMING,
    @SerialName("active") ACTIVE,
    @SerialName("ended") ENDED,
}

@Serializable
data class VoteChoice(
    val choiceId: String,
    val idolId: String? = null,
    val groupId: String? = null,
    val displayName: String,
    val imageUrl: String? = null,
    val voteCount: Long = 0,
)

/** Envelope data for `listInAppVotes`. */
@Serializable
data class VoteListData(
    val votes: List<InAppVote> = emptyList(),
    val count: Int = 0,
)
