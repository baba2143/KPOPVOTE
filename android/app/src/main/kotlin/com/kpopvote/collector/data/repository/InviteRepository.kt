package com.kpopvote.collector.data.repository

import com.kpopvote.collector.data.model.ApplyInviteCodeData
import com.kpopvote.collector.data.model.GenerateInviteCodeData

/** Friend-invite operations (Cloud Functions: generateInviteCode, applyInviteCode). */
interface InviteRepository {
    suspend fun generateInviteCode(): Result<GenerateInviteCodeData>
    suspend fun applyInviteCode(code: String): Result<ApplyInviteCodeData>
}
