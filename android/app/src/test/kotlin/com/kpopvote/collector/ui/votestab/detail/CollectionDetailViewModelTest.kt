package com.kpopvote.collector.ui.votestab.detail

import androidx.lifecycle.SavedStateHandle
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.AddSingleTaskData
import com.kpopvote.collector.data.model.AddToTasksData
import com.kpopvote.collector.data.model.CollectionDetailData
import com.kpopvote.collector.data.model.SaveData
import com.kpopvote.collector.data.model.ShareCollectionData
import com.kpopvote.collector.data.model.VoteCollection
import com.kpopvote.collector.data.repository.CollectionRepository
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
class CollectionDetailViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var repo: CollectionRepository

    private fun collection(
        id: String = "col1",
        saveCount: Int = 10,
    ) = VoteCollection(
        collectionId = id,
        ownerId = "user1",
        ownerName = "Alice",
        title = "My Favorite Votes",
        description = "A test collection",
        saveCount = saveCount,
        likeCount = 3,
    )

    private fun detail(
        isSaved: Boolean = false,
        isOwner: Boolean = true,
        saveCount: Int = 10,
    ) = CollectionDetailData(
        collection = collection(saveCount = saveCount),
        isSaved = isSaved,
        isOwner = isOwner,
    )

    private fun newVm(collectionId: String = "col1"): CollectionDetailViewModel =
        CollectionDetailViewModel(
            savedStateHandle = SavedStateHandle(
                mapOf(CollectionDetailViewModel.ARG_COLLECTION_ID to collectionId),
            ),
            repo = repo,
        )

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        repo = mockk(relaxed = true)
    }

    @After
    fun teardown() = Dispatchers.resetMain()

    @Test
    fun `load success populates detail`() = runTest {
        coEvery { repo.getCollectionDetail("col1") } returns Result.success(detail())

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals("col1", vm.state.value.detail?.collection?.collectionId)
        assertFalse(vm.state.value.isLoading)
        assertNull(vm.state.value.error)
    }

    @Test
    fun `toggleSave success applies server-returned state`() = runTest {
        coEvery { repo.getCollectionDetail("col1") } returns
            Result.success(detail(isSaved = false, saveCount = 10))
        coEvery { repo.toggleSaveCollection("col1") } returns
            Result.success(SaveData(saved = true, saveCount = 11))

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.toggleSave()
        dispatcher.scheduler.advanceUntilIdle()

        assertTrue(vm.state.value.detail?.isSaved == true)
        assertEquals(11, vm.state.value.detail?.collection?.saveCount)
        assertFalse(vm.state.value.isToggleSaving)
    }

    @Test
    fun `toggleSave failure rolls back to previous state`() = runTest {
        coEvery { repo.getCollectionDetail("col1") } returns
            Result.success(detail(isSaved = false, saveCount = 10))
        coEvery { repo.toggleSaveCollection("col1") } returns
            Result.failure(AppError.Network)

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.toggleSave()
        dispatcher.scheduler.advanceUntilIdle()

        assertFalse(vm.state.value.detail?.isSaved == true)
        assertEquals(10, vm.state.value.detail?.collection?.saveCount)
        assertSame(AppError.Network, vm.state.value.error)
        assertFalse(vm.state.value.isToggleSaving)
    }

    @Test
    fun `addAllToTasks populates addAllResult`() = runTest {
        coEvery { repo.getCollectionDetail("col1") } returns Result.success(detail())
        val result = AddToTasksData(addedCount = 3, skippedCount = 1, totalCount = 4)
        coEvery { repo.addCollectionToTasks("col1") } returns Result.success(result)

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.addAllToTasks()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(result, vm.state.value.addAllResult)
        assertFalse(vm.state.value.isAdding)
    }

    @Test
    fun `addSingleTask populates addSingleResult`() = runTest {
        coEvery { repo.getCollectionDetail("col1") } returns Result.success(detail())
        val result = AddSingleTaskData(taskId = "t1", alreadyAdded = false)
        coEvery { repo.addSingleTaskToTasks("col1", "t1") } returns Result.success(result)

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.addSingleTask("t1")
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(result, vm.state.value.addSingleResult)
        assertFalse(vm.state.value.isAdding)
    }

    @Test
    fun `share success emits ShareSuccess event`() = runTest {
        coEvery { repo.getCollectionDetail("col1") } returns Result.success(detail())
        coEvery {
            repo.shareCollectionToCommunity("col1", listOf("a1"), "hello")
        } returns Result.success(ShareCollectionData(postId = "p1", collectionId = "col1"))

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.share(listOf("a1"), "hello")
        dispatcher.scheduler.advanceUntilIdle()

        val event = vm.events.first()
        assertTrue(event is CollectionDetailEvent.ShareSuccess)
        assertEquals("p1", (event as CollectionDetailEvent.ShareSuccess).postId)
        assertFalse(vm.state.value.isSharing)
    }

    @Test
    fun `share with empty biasIds is no-op`() = runTest {
        coEvery { repo.getCollectionDetail("col1") } returns Result.success(detail())

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.share(biasIds = emptyList(), text = "")
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 0) { repo.shareCollectionToCommunity(any(), any(), any()) }
    }

    @Test
    fun `delete when not owner sets NotOwner error without calling repo`() = runTest {
        coEvery { repo.getCollectionDetail("col1") } returns
            Result.success(detail(isOwner = false))

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.delete()
        dispatcher.scheduler.advanceUntilIdle()

        assertSame(AppError.Collection.NotOwner, vm.state.value.error)
        coVerify(exactly = 0) { repo.deleteCollection(any()) }
    }

    @Test
    fun `delete success emits Deleted event`() = runTest {
        coEvery { repo.getCollectionDetail("col1") } returns
            Result.success(detail(isOwner = true))
        coEvery { repo.deleteCollection("col1") } returns Result.success(Unit)

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.delete()
        dispatcher.scheduler.advanceUntilIdle()

        val event = vm.events.first()
        assertSame(CollectionDetailEvent.Deleted, event)
        assertFalse(vm.state.value.isDeleting)
    }
}
