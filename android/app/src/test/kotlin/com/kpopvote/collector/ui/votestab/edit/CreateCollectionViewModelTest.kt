package com.kpopvote.collector.ui.votestab.edit

import androidx.lifecycle.SavedStateHandle
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.CollectionDetailData
import com.kpopvote.collector.data.model.CollectionTaskRef
import com.kpopvote.collector.data.model.CollectionVisibility
import com.kpopvote.collector.data.model.VoteCollection
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.data.repository.CollectionCoverImageRepository
import com.kpopvote.collector.data.repository.CollectionInput
import com.kpopvote.collector.data.repository.CollectionRepository
import com.kpopvote.collector.data.repository.TaskRepository
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
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
class CreateCollectionViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var collectionRepo: CollectionRepository
    private lateinit var taskRepo: TaskRepository
    private lateinit var coverRepo: CollectionCoverImageRepository

    private fun task(id: String, title: String = "Task $id") = VoteTask(
        id = id,
        userId = "u1",
        title = title,
        url = "https://example.com/$id",
        deadlineIso = "2026-12-31T00:00:00Z",
    )

    private fun newVm(collectionId: String? = null): CreateCollectionViewModel {
        val handle = if (collectionId != null) {
            SavedStateHandle(mapOf(CreateCollectionViewModel.ARG_COLLECTION_ID to collectionId))
        } else {
            SavedStateHandle()
        }
        return CreateCollectionViewModel(
            savedStateHandle = handle,
            collectionRepository = collectionRepo,
            taskRepository = taskRepo,
            coverImageRepository = coverRepo,
        )
    }

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        collectionRepo = mockk(relaxed = true)
        taskRepo = mockk(relaxed = true)
        coverRepo = mockk(relaxed = true)
        // Default: empty task list
        coEvery { taskRepo.getUserTasks() } returns Result.success(emptyList())
    }

    @After
    fun teardown() = Dispatchers.resetMain()

    @Test
    fun `initial state is CREATE mode with TITLE_REQUIRED and TASKS_REQUIRED errors`() = runTest {
        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(CollectionFormMode.CREATE, vm.state.value.mode)
        assertNull(vm.state.value.collectionId)
        assertTrue(vm.state.value.validationErrors.contains(CollectionFormError.TITLE_REQUIRED))
        assertTrue(vm.state.value.validationErrors.contains(CollectionFormError.TASKS_REQUIRED))
    }

    @Test
    fun `EDIT mode prefills from existing collection`() = runTest {
        val existing = VoteCollection(
            collectionId = "c1",
            ownerId = "u1",
            title = "Existing",
            description = "desc",
            tags = listOf("kpop", "live"),
            tasks = listOf(
                CollectionTaskRef(taskId = "t1", orderIndex = 0),
                CollectionTaskRef(taskId = "t2", orderIndex = 1),
            ),
            visibility = CollectionVisibility.FOLLOWERS,
            coverImage = "https://cdn/cover.jpg",
        )
        coEvery { collectionRepo.getCollectionDetail("c1") } returns
            Result.success(CollectionDetailData(collection = existing, isOwner = true))

        val vm = newVm(collectionId = "c1")
        dispatcher.scheduler.advanceUntilIdle()

        val s = vm.state.value
        assertEquals(CollectionFormMode.EDIT, s.mode)
        assertEquals("Existing", s.title)
        assertEquals("desc", s.description)
        assertEquals(listOf("kpop", "live"), s.tags)
        assertEquals(listOf("t1", "t2"), s.taskIds)
        assertEquals(CollectionVisibility.FOLLOWERS, s.visibility)
        assertEquals("https://cdn/cover.jpg", s.coverImageRemoteUrl)
    }

    @Test
    fun `title length validation`() = runTest {
        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.onTitleChange("OK")
        assertFalse(vm.state.value.validationErrors.contains(CollectionFormError.TITLE_REQUIRED))
        assertFalse(vm.state.value.validationErrors.contains(CollectionFormError.TITLE_TOO_LONG))

        vm.onTitleChange("a".repeat(51))
        assertTrue(vm.state.value.validationErrors.contains(CollectionFormError.TITLE_TOO_LONG))
    }

    @Test
    fun `addTag rejects duplicates case-insensitively`() = runTest {
        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.addTag("KPop")
        vm.addTag("  kpop  ")
        vm.addTag("Live")

        assertEquals(listOf("KPop", "Live"), vm.state.value.tags)
        assertFalse(vm.state.value.validationErrors.contains(CollectionFormError.TAGS_DUPLICATE))
    }

    @Test
    fun `addTag beyond 10 flags TAGS_TOO_MANY`() = runTest {
        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        repeat(11) { vm.addTag("tag$it") }

        assertEquals(11, vm.state.value.tags.size)
        assertTrue(vm.state.value.validationErrors.contains(CollectionFormError.TAGS_TOO_MANY))
    }

    @Test
    fun `toggleTask adds and removes preserving order`() = runTest {
        coEvery { taskRepo.getUserTasks() } returns
            Result.success(listOf(task("t1"), task("t2"), task("t3")))

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.toggleTask("t2")
        vm.toggleTask("t1")
        vm.toggleTask("t3")
        assertEquals(listOf("t2", "t1", "t3"), vm.state.value.taskIds)

        vm.toggleTask("t1")
        assertEquals(listOf("t2", "t3"), vm.state.value.taskIds)
    }

    @Test
    fun `moveTaskUp shifts task toward index 0 and clamps`() = runTest {
        coEvery { taskRepo.getUserTasks() } returns
            Result.success(listOf(task("t1"), task("t2"), task("t3")))

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.toggleTask("t1")
        vm.toggleTask("t2")
        vm.toggleTask("t3")

        vm.moveTaskUp("t3")
        assertEquals(listOf("t1", "t3", "t2"), vm.state.value.taskIds)

        vm.moveTaskUp("t1") // already first → no-op
        assertEquals(listOf("t1", "t3", "t2"), vm.state.value.taskIds)
    }

    @Test
    fun `submit in CREATE mode uploads cover then creates`() = runTest {
        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.onTitleChange("My Collection")
        vm.addTag("kpop")
        // Need at least one task
        coEvery { taskRepo.getUserTasks() } returns Result.success(listOf(task("t1")))
        vm.toggleTask("t1")

        val bytes = byteArrayOf(1, 2, 3)
        vm.onCoverImagePicked(bytes)

        val uploadedUrl = "https://storage/cover.jpg"
        coEvery { coverRepo.upload(bytes) } returns Result.success(uploadedUrl)
        val inputSlot = slot<CollectionInput>()
        coEvery { collectionRepo.createCollection(capture(inputSlot)) } returns
            Result.success(
                VoteCollection(
                    collectionId = "new",
                    ownerId = "u1",
                    title = "My Collection",
                ),
            )

        vm.submit()
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 1) { coverRepo.upload(bytes) }
        coVerify(exactly = 1) { collectionRepo.createCollection(any()) }
        assertEquals("My Collection", inputSlot.captured.title)
        assertEquals(uploadedUrl, inputSlot.captured.coverImage)
        assertEquals(listOf("t1"), inputSlot.captured.taskIds)
        assertTrue(vm.state.value.submitted)
        assertFalse(vm.state.value.isSubmitting)
    }

    @Test
    fun `submit in EDIT mode calls updateCollection`() = runTest {
        val existing = VoteCollection(
            collectionId = "c1",
            ownerId = "u1",
            title = "Old",
            tasks = listOf(CollectionTaskRef(taskId = "t1", orderIndex = 0)),
        )
        coEvery { collectionRepo.getCollectionDetail("c1") } returns
            Result.success(CollectionDetailData(collection = existing, isOwner = true))
        coEvery { collectionRepo.updateCollection("c1", any()) } returns
            Result.success(existing.copy(title = "New"))

        val vm = newVm(collectionId = "c1")
        dispatcher.scheduler.advanceUntilIdle()

        vm.onTitleChange("New")
        vm.submit()
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 1) { collectionRepo.updateCollection("c1", any()) }
        coVerify(exactly = 0) { collectionRepo.createCollection(any()) }
        assertTrue(vm.state.value.submitted)
    }

    @Test
    fun `submit blocks when validation fails`() = runTest {
        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        // title is empty, tasks are empty — submit should do nothing
        vm.submit()
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 0) { collectionRepo.createCollection(any()) }
        assertFalse(vm.state.value.submitted)
    }

    @Test
    fun `submit surfaces cover upload failure without calling create`() = runTest {
        coEvery { taskRepo.getUserTasks() } returns Result.success(listOf(task("t1")))

        val vm = newVm()
        dispatcher.scheduler.advanceUntilIdle()

        vm.onTitleChange("Title")
        vm.toggleTask("t1")
        vm.onCoverImagePicked(byteArrayOf(1))

        coEvery { coverRepo.upload(any()) } returns Result.failure(AppError.Network)

        vm.submit()
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 0) { collectionRepo.createCollection(any()) }
        assertSame(AppError.Network, vm.state.value.error)
        assertFalse(vm.state.value.submitted)
        assertFalse(vm.state.value.isSubmitting)
    }
}
