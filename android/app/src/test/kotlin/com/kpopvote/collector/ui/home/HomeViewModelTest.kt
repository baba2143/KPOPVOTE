package com.kpopvote.collector.ui.home

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.BiasSettings
import com.kpopvote.collector.data.model.TaskStatus
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.data.repository.BiasRepository
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
class HomeViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var taskRepository: TaskRepository
    private lateinit var biasRepository: BiasRepository

    private val task = VoteTask(
        id = "t1",
        userId = "u1",
        title = "Title",
        url = "https://example.com",
        deadlineIso = "2099-01-01T00:00:00Z",
        status = TaskStatus.PENDING,
    )
    private val bias = BiasSettings("a1", "Artist", listOf("m1"), listOf("M1"))

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        taskRepository = mockk(relaxed = true)
        biasRepository = mockk(relaxed = true)
    }

    @After
    fun teardown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `refresh loads activeTasks and bias`() = runTest {
        coEvery { taskRepository.getActiveTasks() } returns Result.success(listOf(task))
        coEvery { biasRepository.getBias() } returns Result.success(listOf(bias))

        val vm = HomeViewModel(taskRepository, biasRepository)
        dispatcher.scheduler.advanceUntilIdle()

        val state = vm.state.value
        assertEquals(listOf(task), state.activeTasks)
        assertEquals(listOf(bias), state.bias)
        assertEquals(false, state.isLoading)
    }

    @Test
    fun `completeTask optimistically removes task`() = runTest {
        coEvery { taskRepository.getActiveTasks() } returns Result.success(listOf(task))
        coEvery { biasRepository.getBias() } returns Result.success(emptyList())
        coEvery { taskRepository.markCompleted("t1") } returns Result.success(10)

        val vm = HomeViewModel(taskRepository, biasRepository)
        dispatcher.scheduler.advanceUntilIdle()
        assertEquals(1, vm.state.value.activeTasks.size)

        vm.completeTask("t1")
        dispatcher.scheduler.advanceUntilIdle()

        assertTrue(vm.state.value.activeTasks.isEmpty())
    }

    @Test
    fun `refresh error surfaces AppError`() = runTest {
        coEvery { taskRepository.getActiveTasks() } returns Result.failure(AppError.Network)
        coEvery { biasRepository.getBias() } returns Result.success(emptyList())

        val vm = HomeViewModel(taskRepository, biasRepository)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals(AppError.Network, vm.state.value.error)
    }
}
