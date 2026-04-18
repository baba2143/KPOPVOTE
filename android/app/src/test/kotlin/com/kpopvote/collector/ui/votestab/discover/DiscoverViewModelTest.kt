package com.kpopvote.collector.ui.votestab.discover

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.CollectionSortOption
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
class DiscoverViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var repo: CollectionRepository
    private lateinit var vm: DiscoverViewModel

    private fun collection(id: String) = VoteCollection(
        collectionId = id,
        ownerId = "u1",
        title = "C $id",
    )

    private fun page(
        collections: List<VoteCollection>,
        currentPage: Int = 1,
        hasNext: Boolean = false,
    ) = CollectionsListData(
        collections = collections,
        pagination = PaginationInfo(currentPage = currentPage, hasNext = hasNext),
    )

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        repo = mockk(relaxed = true)
    }

    @After
    fun teardown() = Dispatchers.resetMain()

    @Test
    fun `initial load fetches page 1 via getCollections`() = runTest {
        coEvery {
            repo.getCollections(page = 1, sortBy = CollectionSortOption.LATEST, tags = null)
        } returns Result.success(page(listOf(collection("c1"), collection("c2")), hasNext = true))

        vm = DiscoverViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(2, vm.state.value.items.size)
        assertTrue(vm.state.value.hasNext)
        assertEquals(false, vm.state.value.isLoading)
        coVerify(exactly = 1) { repo.getCollections(page = 1, sortBy = CollectionSortOption.LATEST, tags = null) }
    }

    @Test
    fun `debounced search switches to searchCollections endpoint`() = runTest {
        coEvery {
            repo.getCollections(page = 1, sortBy = CollectionSortOption.LATEST, tags = null)
        } returns Result.success(page(listOf(collection("c1"))))
        coEvery {
            repo.searchCollections(
                query = "bts",
                page = 1,
                sortBy = CollectionSortOption.RELEVANCE,
                tags = null,
            )
        } returns Result.success(page(listOf(collection("s1"))))

        vm = DiscoverViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.onSearchChanged("bts")
        // Advance past the 350ms debounce + subsequent fetch
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals("bts", vm.state.value.searchQuery)
        assertEquals(listOf("s1"), vm.state.value.items.map { it.collectionId })
        coVerify(exactly = 1) {
            repo.searchCollections(
                query = "bts",
                page = 1,
                sortBy = CollectionSortOption.RELEVANCE,
                tags = null,
            )
        }
    }

    @Test
    fun `sort change resets page and refetches`() = runTest {
        coEvery {
            repo.getCollections(page = 1, sortBy = CollectionSortOption.LATEST, tags = null)
        } returns Result.success(page(listOf(collection("a"))))
        coEvery {
            repo.getCollections(page = 1, sortBy = CollectionSortOption.POPULAR, tags = null)
        } returns Result.success(page(listOf(collection("b"))))

        vm = DiscoverViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.onSortChange(CollectionSortOption.POPULAR)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(CollectionSortOption.POPULAR, vm.state.value.sortOption)
        assertEquals(listOf("b"), vm.state.value.items.map { it.collectionId })
        assertEquals(1, vm.state.value.currentPage)
    }

    @Test
    fun `onTagToggle adds tag and refetches with tags param`() = runTest {
        coEvery {
            repo.getCollections(page = 1, sortBy = CollectionSortOption.LATEST, tags = null)
        } returns Result.success(page(emptyList()))
        coEvery {
            repo.getCollections(page = 1, sortBy = CollectionSortOption.LATEST, tags = listOf("kpop"))
        } returns Result.success(page(listOf(collection("t1"))))

        vm = DiscoverViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.onTagToggle("kpop")
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(setOf("kpop"), vm.state.value.selectedTags)
        assertEquals(listOf("t1"), vm.state.value.items.map { it.collectionId })

        // Toggling again removes
        coEvery {
            repo.getCollections(page = 1, sortBy = CollectionSortOption.LATEST, tags = null)
        } returns Result.success(page(emptyList()))
        vm.onTagToggle("kpop")
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(emptySet<String>(), vm.state.value.selectedTags)
    }

    @Test
    fun `loadNextPage appends when hasNext is true`() = runTest {
        coEvery {
            repo.getCollections(page = 1, sortBy = CollectionSortOption.LATEST, tags = null)
        } returns Result.success(page(listOf(collection("p1")), currentPage = 1, hasNext = true))
        coEvery {
            repo.getCollections(page = 2, sortBy = CollectionSortOption.LATEST, tags = null)
        } returns Result.success(page(listOf(collection("p2")), currentPage = 2, hasNext = false))

        vm = DiscoverViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.loadNextPage()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(listOf("p1", "p2"), vm.state.value.items.map { it.collectionId })
        assertEquals(false, vm.state.value.hasNext)
        assertEquals(2, vm.state.value.currentPage)
    }

    @Test
    fun `loadNextPage no-op when hasNext is false`() = runTest {
        coEvery {
            repo.getCollections(page = 1, sortBy = CollectionSortOption.LATEST, tags = null)
        } returns Result.success(page(listOf(collection("only"))))

        vm = DiscoverViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.loadNextPage()
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 1) { repo.getCollections(page = 1, sortBy = CollectionSortOption.LATEST, tags = null) }
        coVerify(exactly = 0) { repo.getCollections(page = 2, sortBy = any(), tags = any()) }
    }

    @Test
    fun `error surfaces as AppError`() = runTest {
        coEvery {
            repo.getCollections(page = 1, sortBy = CollectionSortOption.LATEST, tags = null)
        } returns Result.failure(AppError.Network)

        vm = DiscoverViewModel(repo)
        dispatcher.scheduler.advanceUntilIdle()

        assertTrue(vm.state.value.items.isEmpty())
        assertSame(AppError.Network, vm.state.value.error)
    }
}
