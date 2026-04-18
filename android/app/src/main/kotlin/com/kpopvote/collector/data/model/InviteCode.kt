package com.kpopvote.collector.data.model

import kotlinx.serialization.Serializable

/** Response body for Cloud Function `generateInviteCode`. */
@Serializable
data class GenerateInviteCodeData(
    val inviteCode: String,
    val inviteLink: String,
)

/** Request body for Cloud Function `applyInviteCode`. */
@Serializable
data class ApplyInviteCodeBody(
    val inviteCode: String,
)

/** Response body for Cloud Function `applyInviteCode`. */
@Serializable
data class ApplyInviteCodeData(
    val success: Boolean,
    val inviterDisplayName: String? = null,
)
