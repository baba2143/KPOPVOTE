package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError

/**
 * Maps `AppError.Server(400, ...)` messages returned by `executeVote` into the
 * specific [AppError.Vote] subtypes so UI can present localized, context-aware feedback.
 * iOS counterpart: `VoteService.executeVote` 400 branch (VoteService.swift:200-215).
 */
internal object VoteErrorMapper {
    fun mapExecuteError(error: Throwable): Throwable {
        if (error !is AppError.Server) return error
        val message = error.message
        return when {
            error.code != 400 -> error
            message.contains("Already voted", ignoreCase = true) -> AppError.Vote.AlreadyVoted
            message.contains("Insufficient points", ignoreCase = true) -> AppError.Vote.InsufficientPoints
            message.contains("not active", ignoreCase = true) -> AppError.Vote.NotActive
            message.contains("投票上限") || message.contains("投票数制限") ->
                AppError.Vote.DailyLimitReached(message)
            else -> error
        }
    }
}
