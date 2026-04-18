package com.kpopvote.collector.ui.votestab.saved

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
class SavedCollectionsViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var repo: CollectionRepository
    private lateinit var vm: SavedCollectionsViewModel

    private fun col(id: String) = VoteCollection(collectionId = id, ownerId = "u", title = id)
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
    fun `initial load fetches getSavedCollections page 1`() = runTest {
        coEvery { repo.getSavedCollections(page = 1) } returns
            Result.success(page(listOf(col("s1"), col("s2"))))

        vm = SavedCollectionsViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(listOf("s1", "s2"), vm.state.value.items.map { it.collectionId })
        coVerify(exactly = 1) { repo.getSavedCollections(page = 1) }
    }

    @Test
    fun `loadNextPage appends page 2`() = runTest {
        coEvery { repo.getSavedCollections(page = 1) } returns
            Result.success(page(listOf(col("s1")), currentPage = 1, hasNext = true))
        coEvery { repo.getSavedCollections(page = 2) } returns
            Result.success(page(listOf(col("s2")), currentPage = 2, hasNext = false))

        vm = SavedCollectionsViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.loadNextPage()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(listOf("s1", "s2"), vm.state.value.items.map { it.collectionId })
        assertEquals(false, vm.state.value.hasNext)
    }

    @Test
    fun `error surfaces as AppError and leaves items empty`() = runTest {
        coEvery { repo.getSavedCollections(page = 1) } returns Result.failure(AppError.Network)

        vm = SavedCollectionsViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        assertTrue(vm.state.value.items.isEmpty())
        assertSame(AppError.Network, vm.state.value.error)
    }
}
