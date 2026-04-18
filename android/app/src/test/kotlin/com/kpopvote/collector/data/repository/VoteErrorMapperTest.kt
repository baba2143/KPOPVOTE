package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class VoteErrorMapperTest {

    @Test
    fun `400 Already voted maps to AlreadyVoted`() {
        val mapped = VoteErrorMapper.mapExecuteError(AppError.Server(400, "Already voted today"))
        assertSame(AppError.Vote.AlreadyVoted, mapped)
    }

    @Test
    fun `400 Insufficient points maps to InsufficientPoints`() {
        val mapped = VoteErrorMapper.mapExecuteError(AppError.Server(400, "Insufficient points"))
        assertSame(AppError.Vote.InsufficientPoints, mapped)
    }

    @Test
    fun `400 not active maps to NotActive`() {
        val mapped = VoteErrorMapper.mapExecuteError(AppError.Server(400, "Vote is not active"))
        assertSame(AppError.Vote.NotActive, mapped)
    }

    @Test
    fun `400 投票上限 maps to DailyLimitReached`() {
        val original = AppError.Server(400, "1日あたりの投票上限に達しました")
        val mapped = VoteErrorMapper.mapExecuteError(original)
        assertTrue(mapped is AppError.Vote.DailyLimitReached)
        assertEquals("1日あたりの投票上限に達しました", (mapped as AppError.Vote.DailyLimitReached).message)
    }

    @Test
    fun `non-400 Server error passes through unchanged`() {
        val original = AppError.Server(500, "Internal server error")
        val mapped = VoteErrorMapper.mapExecuteError(original)
        assertSame(original, mapped)
    }

    @Test
    fun `non-matching 400 Server error passes through unchanged`() {
        val original = AppError.Server(400, "Some other validation error")
        val mapped = VoteErrorMapper.mapExecuteError(original)
        assertSame(original, mapped)
    }

    @Test
    fun `non-Server error passes through unchanged`() {
        val original = AppError.Network
        val mapped = VoteErrorMapper.mapExecuteError(original)
        assertSame(AppError.Network, mapped)
    }
}
