package com.kpopvote.collector.ui.tasks

import com.kpopvote.collector.data.model.TaskStatus
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.data.repository.TaskRepository
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class TaskListViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var taskRepository: TaskRepository
    private lateinit var viewModel: TaskListViewModel

    private fun task(id: String, deadlineIso: String, status: TaskStatus = TaskStatus.PENDING) = VoteTask(
        id = id,
        userId = "u1",
        title = "T $id",
        url = "https://example.com",
        deadlineIso = deadlineIso,
        status = status,
    )

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        taskRepository = mockk(relaxed = true)
    }

    @After
    fun teardown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `refresh populates allTasks`() = runTest {
        val tasks = listOf(task("a", "2099-01-01T00:00:00Z"))
        coEvery { taskRepository.getUserTasks(null) } returns Result.success(tasks)

        viewModel = TaskListViewModel(taskRepository)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(tasks, viewModel.state.value.allTasks)
        assertEquals(false, viewModel.state.value.isLoading)
    }

    @Test
    fun `active segment filters archived completed and expired`() = runTest {
        val active = task("active", "2099-01-01T00:00:00Z")
        val expired = task("expired", "2000-01-01T00:00:00Z")
        val completed = task("completed", "2099-01-01T00:00:00Z", TaskStatus.COMPLETED)
        val archived = task("archived", "2099-01-01T00:00:00Z", TaskStatus.ARCHIVED)
        coEvery { taskRepository.getUserTasks(null) } returns
            Result.success(listOf(active, expired, completed, archived))

        viewModel = TaskListViewModel(taskRepository)
        dispatcher.scheduler.advanceUntilIdle()

        val activeIds = viewModel.state.value.activeTasks.map { it.id }
        assertEquals(listOf("active"), activeIds)
    }

    @Test
    fun `completed segment includes completed tasks`() = runTest {
        val completed = task("done", "2099-01-01T00:00:00Z", TaskStatus.COMPLETED)
            .copy(updatedAtIso = "2025-01-01T10:00:00Z")
        coEvery { taskRepository.getUserTasks(null) } returns Result.success(listOf(completed))

        viewModel = TaskListViewModel(taskRepository)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(listOf("done"), viewModel.state.value.completedTasks.map { it.id })
    }

    @Test
    fun `deleteTask optimistically removes task and reloads on failure`() = runTest {
        val a = task("a", "2099-01-01T00:00:00Z")
        val b = task("b", "2099-01-02T00:00:00Z")
        coEvery { taskRepository.getUserTasks(null) } returns Result.success(listOf(a, b))
        coEvery { taskRepository.deleteTask("a") } returns Result.success(Unit)

        viewModel = TaskListViewModel(taskRepository)
        dispatcher.scheduler.advanceUntilIdle()

        viewModel.deleteTask(a)
        dispatcher.scheduler.advanceUntilIdle()

        val remaining = viewModel.state.value.allTasks.map { it.id }
        assertTrue("b" in remaining)
        assertEquals(1, remaining.size)
    }

    @Test
    fun `completeTask sets pointsGranted on success`() = runTest {
        val a = task("a", "2099-01-01T00:00:00Z")
        coEvery { taskRepository.getUserTasks(null) } returns Result.success(listOf(a))
        coEvery { taskRepository.markCompleted("a") } returns Result.success(5)

        viewModel = TaskListViewModel(taskRepository)
        dispatcher.scheduler.advanceUntilIdle()

        viewModel.completeTask(a)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(5, viewModel.state.value.pointsGranted)
        val updated = viewModel.state.value.allTasks.first { it.id == "a" }
        assertEquals(TaskStatus.COMPLETED, updated.status)
    }
}
