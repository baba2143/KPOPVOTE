package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.ApplyInviteCodeData
import com.kpopvote.collector.data.model.GenerateInviteCodeData
import io.mockk.coEvery
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class InviteRepositoryImplTest {

    private val client: FunctionsClient = mockk(relaxUnitFun = true)
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val repo = InviteRepositoryImpl(client, json)

    @Test
    fun `generateInviteCode returns data on success`() = runTest {
        coEvery {
            client.post(
                ApiPaths.GENERATE_INVITE_CODE,
                "{}",
                GenerateInviteCodeData.serializer(),
                emptyMap(),
            )
        } returns GenerateInviteCodeData(
            inviteCode = "ABC123XY",
            inviteLink = "https://kpopvote-9de2b.web.app/invite/ABC123XY",
        )

        val result = repo.generateInviteCode()

        assertTrue(result.isSuccess)
        assertEquals("ABC123XY", result.getOrNull()?.inviteCode)
    }

    @Test
    fun `applyInviteCode serializes body with inviteCode`() = runTest {
        val bodySlot = slot<String>()
        coEvery {
            client.post(
                ApiPaths.APPLY_INVITE_CODE,
                capture(bodySlot),
                ApplyInviteCodeData.serializer(),
                emptyMap(),
            )
        } returns ApplyInviteCodeData(success = true, inviterDisplayName = "Alice")

        val result = repo.applyInviteCode("ABC123XY")

        assertTrue(result.isSuccess)
        assertEquals("Alice", result.getOrNull()?.inviterDisplayName)
        assertTrue(bodySlot.captured.contains("\"inviteCode\":\"ABC123XY\""))
    }

    @Test
    fun `applyInviteCode maps 400 already used to AlreadyApplied`() = runTest {
        coEvery {
            client.post(ApiPaths.APPLY_INVITE_CODE, any(), ApplyInviteCodeData.serializer(), any())
        } throws AppError.Server(400, "You have already used an invite code")

        val result = repo.applyInviteCode("ABC123XY")

        assertTrue(result.isFailure)
        assertSame(AppError.Invite.AlreadyApplied, result.exceptionOrNull())
    }

    @Test
    fun `applyInviteCode maps 400 own invite to SelfInvite`() = runTest {
        coEvery {
            client.post(ApiPaths.APPLY_INVITE_CODE, any(), ApplyInviteCodeData.serializer(), any())
        } throws AppError.Server(400, "Cannot use your own invite code")

        val result = repo.applyInviteCode("ABC123XY")

        assertTrue(result.isFailure)
        assertSame(AppError.Invite.SelfInvite, result.exceptionOrNull())
    }

    @Test
    fun `applyInviteCode maps 404 invalid code to NotFound`() = runTest {
        coEvery {
            client.post(ApiPaths.APPLY_INVITE_CODE, any(), ApplyInviteCodeData.serializer(), any())
        } throws AppError.Server(404, "Invalid invite code")

        val result = repo.applyInviteCode("XXXXXX")

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.Invite.NotFound)
    }
}
