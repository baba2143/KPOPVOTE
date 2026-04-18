package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError

/**
 * Maps `AppError.Server` messages from `applyInviteCode` into specific [AppError.Invite] subtypes.
 * Backend (functions/src/user/inviteFriend.ts) returns:
 *   - 400 "You have already used an invite code" → AlreadyApplied
 *   - 400 "Cannot use your own invite code"       → SelfInvite
 *   - 404 "Invalid invite code"                   → NotFound
 */
internal object InviteErrorMapper {
    fun mapApplyError(error: Throwable): Throwable {
        if (error !is AppError.Server) return error
        val message = error.message
        return when {
            error.code == 400 && message.contains("already used", ignoreCase = true) ->
                AppError.Invite.AlreadyApplied
            error.code == 400 && message.contains("own invite code", ignoreCase = true) ->
                AppError.Invite.SelfInvite
            error.code == 404 && message.contains("Invalid invite code", ignoreCase = true) ->
                AppError.Invite.NotFound(message)
            else -> error
        }
    }
}
