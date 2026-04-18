package com.kpopvote.collector.ui.profile.invite

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.ApplyInviteCodeData
import com.kpopvote.collector.data.model.GenerateInviteCodeData
import com.kpopvote.collector.data.repository.InviteRepository
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class InviteCodeViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var repo: InviteRepository

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        repo = mockk()
    }

    @After
    fun teardown() = Dispatchers.resetMain()

    @Test
    fun `init generates own invite code and link`() = runTest {
        coEvery { repo.generateInviteCode() } returns
            Result.success(GenerateInviteCodeData(inviteCode = "ABC123", inviteLink = "https://inv/ABC123"))

        val vm = InviteCodeViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals("ABC123", vm.state.value.ownCode)
        assertEquals("https://inv/ABC123", vm.state.value.ownLink)
        assertFalse(vm.state.value.isGenerating)
        coVerify(exactly = 1) { repo.generateInviteCode() }
    }

    @Test
    fun `generate failure surfaces error without code`() = runTest {
        coEvery { repo.generateInviteCode() } returns Result.failure(AppError.Network)

        val vm = InviteCodeViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        assertNull(vm.state.value.ownCode)
        assertSame(AppError.Network, vm.state.value.error)
    }

    @Test
    fun `onManualCodeChange uppercases and trims`() = runTest {
        coEvery { repo.generateInviteCode() } returns
            Result.success(GenerateInviteCodeData("ABC123", "https://inv/ABC123"))

        val vm = InviteCodeViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.onManualCodeChange("  xyz789 ")
        assertEquals("XYZ789", vm.state.value.manualCode)
    }

    @Test
    fun `applyManualCode success sets message and clears input`() = runTest {
        coEvery { repo.generateInviteCode() } returns
            Result.success(GenerateInviteCodeData("ABC123", "https://inv/ABC123"))
        coEvery { repo.applyInviteCode("ZZZ999") } returns
            Result.success(ApplyInviteCodeData(success = true, inviterDisplayName = "Taro"))

        val vm = InviteCodeViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()
        vm.onManualCodeChange("ZZZ999")

        vm.applyManualCode()
        dispatcher.scheduler.advanceUntilIdle()

        assertTrue(vm.state.value.applySuccessMessage?.contains("Taro") == true)
        assertEquals("", vm.state.value.manualCode)
        coVerify(exactly = 1) { repo.applyInviteCode("ZZZ999") }
    }

    @Test
    fun `applyManualCode failure surfaces Invite error`() = runTest {
        coEvery { repo.generateInviteCode() } returns
            Result.success(GenerateInviteCodeData("ABC123", "https://inv/ABC123"))
        coEvery { repo.applyInviteCode("BADCOD") } returns
            Result.failure(AppError.Invite.AlreadyApplied)

        val vm = InviteCodeViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()
        vm.onManualCodeChange("BADCOD")

        vm.applyManualCode()
        dispatcher.scheduler.advanceUntilIdle()

        assertSame(AppError.Invite.AlreadyApplied, vm.state.value.error)
        assertNull(vm.state.value.applySuccessMessage)
    }

    @Test
    fun `applyManualCode is a no-op for blank input`() = runTest {
        coEvery { repo.generateInviteCode() } returns
            Result.success(GenerateInviteCodeData("ABC123", "https://inv/ABC123"))

        val vm = InviteCodeViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.applyManualCode()
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 0) { repo.applyInviteCode(any()) }
    }
}
