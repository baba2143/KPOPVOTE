package com.kpopvote.collector.ui.vote

import androidx.lifecycle.SavedStateHandle
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.RankingEntry
import com.kpopvote.collector.data.model.VoteRanking
import com.kpopvote.collector.data.repository.VoteRepository
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
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class VoteRankingViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var repo: VoteRepository

    private fun ranking(voteId: String = "v1") = VoteRanking(
        voteId = voteId,
        rankings = listOf(
            RankingEntry(rank = 1, choiceId = "c1", displayName = "Alpha", voteCount = 100, percentage = 60.0),
            RankingEntry(rank = 2, choiceId = "c2", displayName = "Beta", voteCount = 67, percentage = 40.0),
        ),
        totalVotes = 167,
    )

    private fun newVm(voteId: String = "v1"): VoteRankingViewModel =
        VoteRankingViewModel(
            savedStateHandle = SavedStateHandle(mapOf(VoteRankingViewModel.ARG_VOTE_ID to voteId)),
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
    fun `initial load populates ranking`() = runTest {
        coEvery { repo.fetchRanking("v1") } returns Result.success(ranking())

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(2, vm.state.value.ranking?.rankings?.size)
        assertEquals(167L, vm.state.value.ranking?.totalVotes)
        assertFalse(vm.state.value.isLoading)
        assertNull(vm.state.value.error)
    }

    @Test
    fun `refresh refetches ranking`() = runTest {
        coEvery { repo.fetchRanking("v1") } returns Result.success(ranking())

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.refresh()
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 2) { repo.fetchRanking("v1") }
    }

    @Test
    fun `error surfaces as AppError and preserves last ranking`() = runTest {
        coEvery { repo.fetchRanking("v1") } returnsMany listOf(
            Result.success(ranking()),
            Result.failure(AppError.Network),
        )

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.refresh()
        dispatcher.scheduler.advanceUntilIdle()

        assertSame(AppError.Network, vm.state.value.error)
        assertEquals(2, vm.state.value.ranking?.rankings?.size)
    }
}
