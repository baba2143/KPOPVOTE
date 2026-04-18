package com.kpopvote.collector.ui.vote

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.InAppVote
import com.kpopvote.collector.data.model.VoteStatus
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
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class VoteListViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var repo: VoteRepository
    private lateinit var vm: VoteListViewModel

    private fun vote(id: String, status: VoteStatus = VoteStatus.ACTIVE) = InAppVote(
        voteId = id,
        title = "Vote $id",
        status = status,
        startAt = "2026-04-01T00:00:00Z",
        endAt = "2026-04-30T00:00:00Z",
    )

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        repo = mockk(relaxed = true)
    }

    @After
    fun teardown() = Dispatchers.resetMain()

    @Test
    fun `initial load fetches votes with null status`() = runTest {
        coEvery { repo.fetchVotes(null) } returns Result.success(listOf(vote("v1"), vote("v2")))

        vm = VoteListViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(2, vm.state.value.votes.size)
        assertEquals(false, vm.state.value.isLoading)
        assertNull(vm.state.value.error)
        coVerify(exactly = 1) { repo.fetchVotes(null) }
    }

    @Test
    fun `setStatus triggers refetch with new filter`() = runTest {
        coEvery { repo.fetchVotes(null) } returns Result.success(listOf(vote("a")))
        coEvery { repo.fetchVotes(VoteStatus.ACTIVE) } returns Result.success(listOf(vote("b", VoteStatus.ACTIVE)))

        vm = VoteListViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.setStatus(VoteStatus.ACTIVE)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(VoteStatus.ACTIVE, vm.state.value.statusFilter)
        assertEquals(listOf("b"), vm.state.value.votes.map { it.voteId })
        coVerify(exactly = 1) { repo.fetchVotes(VoteStatus.ACTIVE) }
    }

    @Test
    fun `setStatus with same filter does not refetch`() = runTest {
        coEvery { repo.fetchVotes(null) } returns Result.success(emptyList())

        vm = VoteListViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.setStatus(null)
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 1) { repo.fetchVotes(null) }
    }

    @Test
    fun `error surfaces as AppError in state`() = runTest {
        coEvery { repo.fetchVotes(null) } returns Result.failure(AppError.Network)

        vm = VoteListViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        assertTrue(vm.state.value.votes.isEmpty())
        assertSame(AppError.Network, vm.state.value.error)
    }
}
