package com.kpopvote.collector.ui.votestab.mine

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.CollectionsListData
import com.kpopvote.collector.data.model.PaginationInfo
import com.kpopvote.collector.data.model.VoteCollection
import com.kpopvote.collector.data.repository.CollectionRepository
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
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class MyCollectionsViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var repo: CollectionRepository
    private lateinit var vm: MyCollectionsViewModel

    private fun col(id: String) = VoteCollection(collectionId = id, ownerId = "me", title = id)
    private fun page(
        items: List<VoteCollection>,
        currentPage: Int = 1,
        hasNext: Boolean = false,
    ) = CollectionsListData(items, PaginationInfo(currentPage = currentPage, hasNext = hasNext))

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        repo = mockk(relaxed = true)
    }

    @After
    fun teardown() = Dispatchers.resetMain()

    @Test
    fun `initial load fetches getMyCollections page 1`() = runTest {
        coEvery { repo.getMyCollections(page = 1) } returns
            Result.success(page(listOf(col("m1"))))

        vm = MyCollectionsViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(listOf("m1"), vm.state.value.items.map { it.collectionId })
        coVerify(exactly = 1) { repo.getMyCollections(page = 1) }
    }

    @Test
    fun `refresh resets to page 1 and refetches`() = runTest {
        coEvery { repo.getMyCollections(page = 1) } returns
            Result.success(page(listOf(col("m1"))))

        vm = MyCollectionsViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.refresh()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(1, vm.state.value.currentPage)
        coVerify(exactly = 2) { repo.getMyCollections(page = 1) }
    }

    @Test
    fun `error surfaces as AppError`() = runTest {
        coEvery { repo.getMyCollections(page = 1) } returns Result.failure(AppError.Network)

        vm = MyCollectionsViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        assertTrue(vm.state.value.items.isEmpty())
        assertSame(AppError.Network, vm.state.value.error)
    }
}
