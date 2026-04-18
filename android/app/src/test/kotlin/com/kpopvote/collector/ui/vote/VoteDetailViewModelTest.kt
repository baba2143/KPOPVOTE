package com.kpopvote.collector.ui.vote

import androidx.lifecycle.SavedStateHandle
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.InAppVote
import com.kpopvote.collector.data.model.VoteChoice
import com.kpopvote.collector.data.model.VoteExecuteResult
import com.kpopvote.collector.data.model.VoteStatus
import com.kpopvote.collector.data.repository.VoteRepository
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
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
class VoteDetailViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var repo: VoteRepository

    private fun vote(
        id: String = "v1",
        dailyRemaining: Int? = 5,
        choices: List<VoteChoice> = listOf(
            VoteChoice(choiceId = "c1", displayName = "Alpha"),
            VoteChoice(choiceId = "c2", displayName = "Beta"),
        ),
    ) = InAppVote(
        voteId = id,
        title = "Vote $id",
        status = VoteStatus.ACTIVE,
        startAt = "2026-04-01T00:00:00Z",
        endAt = "2026-04-30T00:00:00Z",
        choices = choices,
        userDailyRemaining = dailyRemaining,
    )

    private fun newVm(voteId: String = "v1"): VoteDetailViewModel =
        VoteDetailViewModel(
            savedStateHandle = SavedStateHandle(mapOf(VoteDetailViewModel.ARG_VOTE_ID to voteId)),
            voteRepository = repo,
        )

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        repo = mockk(relaxed = true)
    }

    @After
    fun teardown() = Dispatchers.resetMain()

    @Test
    fun `load success populates vote`() = runTest {
        coEvery { repo.fetchVoteDetail("v1") } returns Result.success(vote())

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals("v1", vm.state.value.vote?.voteId)
        assertFalse(vm.state.value.isLoading)
        assertNull(vm.state.value.error)
    }

    @Test
    fun `selectChoice updates state`() = runTest {
        coEvery { repo.fetchVoteDetail("v1") } returns Result.success(vote())

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.selectChoice("c2")

        assertEquals("c2", vm.state.value.selectedChoiceId)
        assertTrue(vm.state.value.canVote)
    }

    @Test
    fun `incVoteCount caps at userDailyRemaining`() = runTest {
        coEvery { repo.fetchVoteDetail("v1") } returns Result.success(vote(dailyRemaining = 2))

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.incVoteCount()
        vm.incVoteCount()
        vm.incVoteCount() // should be capped at maxVotes=2

        assertEquals(2, vm.state.value.voteCount)
    }

    @Test
    fun `decVoteCount floors at 1`() = runTest {
        coEvery { repo.fetchVoteDetail("v1") } returns Result.success(vote())

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.decVoteCount()
        vm.decVoteCount()

        assertEquals(1, vm.state.value.voteCount)
    }

    @Test
    fun `confirmVote success emits event and refreshes`() = runTest {
        coEvery { repo.fetchVoteDetail("v1") } returns Result.success(vote())
        val executeResult = VoteExecuteResult(
            voteId = "v1",
            choiceId = "c1",
            voteCount = 1,
            pointsDeducted = 1,
            userDailyVotes = 1,
            userDailyRemaining = 4,
        )
        coEvery {
            repo.executeVote(voteId = "v1", choiceId = "c1", voteCount = 1, pointSelection = any())
        } returns Result.success(executeResult)

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.selectChoice("c1")
        vm.confirmVote()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(executeResult, vm.state.value.lastResult)
        assertFalse(vm.state.value.isVoting)
        coVerify(exactly = 2) { repo.fetchVoteDetail("v1") }
    }

    @Test
    fun `confirmVote emits Success event on success`() = runTest {
        coEvery { repo.fetchVoteDetail("v1") } returns Result.success(vote())
        val executeResult = VoteExecuteResult(
            voteId = "v1",
            choiceId = "c1",
            voteCount = 1,
            pointsDeducted = 1,
        )
        coEvery {
            repo.executeVote(voteId = "v1", choiceId = "c1", voteCount = 1, pointSelection = any())
        } returns Result.success(executeResult)

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.selectChoice("c1")
        vm.confirmVote()
        dispatcher.scheduler.advanceUntilIdle()

        val event = vm.events.first()
        assertTrue(event is VoteEvent.Success)
        assertEquals(executeResult, (event as VoteEvent.Success).result)
    }

    @Test
    fun `confirmVote AlreadyVoted surfaces in error`() = runTest {
        coEvery { repo.fetchVoteDetail("v1") } returns Result.success(vote())
        coEvery {
            repo.executeVote(voteId = "v1", choiceId = "c1", voteCount = 1, pointSelection = any())
        } returns Result.failure(AppError.Vote.AlreadyVoted)

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.selectChoice("c1")
        vm.confirmVote()
        dispatcher.scheduler.advanceUntilIdle()

        assertSame(AppError.Vote.AlreadyVoted, vm.state.value.error)
        assertFalse(vm.state.value.isVoting)
    }

    @Test
    fun `confirmVote InsufficientPoints surfaces in error`() = runTest {
        coEvery { repo.fetchVoteDetail("v1") } returns Result.success(vote())
        coEvery {
            repo.executeVote(voteId = "v1", choiceId = "c1", voteCount = 1, pointSelection = any())
        } returns Result.failure(AppError.Vote.InsufficientPoints)

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.selectChoice("c1")
        vm.confirmVote()
        dispatcher.scheduler.advanceUntilIdle()

        assertSame(AppError.Vote.InsufficientPoints, vm.state.value.error)
    }

    @Test
    fun `confirmVote with no selection is no-op`() = runTest {
        coEvery { repo.fetchVoteDetail("v1") } returns Result.success(vote())

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.confirmVote()
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 0) { repo.executeVote(any(), any(), any(), any()) }
    }
}
