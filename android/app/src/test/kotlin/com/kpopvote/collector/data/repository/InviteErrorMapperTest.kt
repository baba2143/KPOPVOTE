package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class InviteErrorMapperTest {

    @Test
    fun `400 already used maps to AlreadyApplied`() {
        val mapped = InviteErrorMapper.mapApplyError(
            AppError.Server(400, "You have already used an invite code"),
        )
        assertSame(AppError.Invite.AlreadyApplied, mapped)
    }

    @Test
    fun `400 own invite code maps to SelfInvite`() {
        val mapped = InviteErrorMapper.mapApplyError(
            AppError.Server(400, "Cannot use your own invite code"),
        )
        assertSame(AppError.Invite.SelfInvite, mapped)
    }

    @Test
    fun `404 Invalid invite code maps to NotFound with message`() {
        val original = AppError.Server(404, "Invalid invite code")
        val mapped = InviteErrorMapper.mapApplyError(original)
        assertTrue(mapped is AppError.Invite.NotFound)
        assertEquals("Invalid invite code", (mapped as AppError.Invite.NotFound).message)
    }

    @Test
    fun `unrelated 500 passes through unchanged`() {
        val original = AppError.Server(500, "Internal server error")
        val mapped = InviteErrorMapper.mapApplyError(original)
        assertSame(original, mapped)
    }

    @Test
    fun `non-Server error passes through unchanged`() {
        val mapped = InviteErrorMapper.mapApplyError(AppError.Network)
        assertSame(AppError.Network, mapped)
    }
}
