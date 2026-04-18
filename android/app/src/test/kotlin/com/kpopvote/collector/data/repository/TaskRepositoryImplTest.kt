package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.CoverImageSource
import com.kpopvote.collector.data.model.TaskListData
import com.kpopvote.collector.data.model.TaskStatus
import com.kpopvote.collector.data.model.UpdateTaskStatusData
import com.kpopvote.collector.data.model.VoteTask
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TaskRepositoryImplTest {

    private val client: FunctionsClient = mockk(relaxUnitFun = true)
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val repo = TaskRepositoryImpl(client, json)

    private val sampleTask = VoteTask(
        id = "t1",
        userId = "u1",
        title = "Vote A",
        url = "https://example.com",
        deadlineIso = "2030-12-31T23:59:59Z",
        status = TaskStatus.PENDING,
        biasIds = listOf("m1", "m2"),
    )

    @Test
    fun `getUserTasks returns list`() = runTest {
        coEvery {
            client.get(ApiPaths.GET_USER_TASKS, TaskListData.serializer(), emptyMap())
        } returns TaskListData(listOf(sampleTask), 1)

        val result = repo.getUserTasks()

        assertTrue(result.isSuccess)
        assertEquals(listOf(sampleTask), result.getOrNull())
    }

    @Test
    fun `getUserTasks forwards isCompleted query`() = runTest {
        coEvery {
            client.get(ApiPaths.GET_USER_TASKS, TaskListData.serializer(), mapOf("isCompleted" to "true"))
        } returns TaskListData(emptyList(), 0)

        val result = repo.getUserTasks(isCompleted = true)

        assertTrue(result.isSuccess)
        coVerify(exactly = 1) {
            client.get(ApiPaths.GET_USER_TASKS, TaskListData.serializer(), mapOf("isCompleted" to "true"))
        }
    }

    @Test
    fun `getActiveTasks filters completed archived and expired`() = runTest {
        val now = System.currentTimeMillis()
        val future = "2099-01-01T00:00:00Z"
        val past = "2000-01-01T00:00:00Z"
        val active = sampleTask.copy(id = "active", deadlineIso = future)
        val expired = sampleTask.copy(id = "expired", deadlineIso = past)
        val completed = sampleTask.copy(id = "done", deadlineIso = future, status = TaskStatus.COMPLETED)
        val archived = sampleTask.copy(id = "arch", deadlineIso = future, status = TaskStatus.ARCHIVED)
        coEvery {
            client.get(ApiPaths.GET_USER_TASKS, TaskListData.serializer(), mapOf("isCompleted" to "false"))
        } returns TaskListData(listOf(active, expired, completed, archived), 4)

        val result = repo.getActiveTasks()

        assertTrue(result.isSuccess)
        assertEquals(listOf("active"), result.getOrNull()?.map { it.id })
        assertTrue(now > 0)
    }

    @Test
    fun `registerTask encodes targetMembers and posts`() = runTest {
        val bodySlot = slot<String>()
        coEvery {
            client.post(ApiPaths.REGISTER_TASK, capture(bodySlot), VoteTask.serializer())
        } returns sampleTask

        val result = repo.registerTask(
            TaskInput(
                title = "Vote A",
                url = "https://example.com",
                deadlineIso = "2030-12-31T23:59:59Z",
                biasIds = listOf("m1", "m2"),
                externalAppId = "app1",
                coverImage = "https://img",
                coverImageSource = CoverImageSource.EXTERNAL_APP,
            ),
        )

        assertTrue(result.isSuccess)
        assertTrue(bodySlot.captured.contains("\"targetMembers\""))
        assertTrue(bodySlot.captured.contains("\"externalAppId\":\"app1\""))
        assertTrue(bodySlot.captured.contains("\"coverImageSource\":\"externalApp\""))
        assertFalse(bodySlot.captured.contains("\"biasIds\""))
    }

    @Test
    fun `markCompleted returns pointsGranted from envelope`() = runTest {
        coEvery {
            client.post(ApiPaths.UPDATE_TASK_STATUS, any(), UpdateTaskStatusData.serializer())
        } returns UpdateTaskStatusData(pointsGranted = 5)

        val result = repo.markCompleted("t1")

        assertTrue(result.isSuccess)
        assertEquals(5, result.getOrNull())
    }

    @Test
    fun `deleteTask surfaces AppError`() = runTest {
        coEvery { client.postIgnoringData(ApiPaths.DELETE_TASK, any()) } throws AppError.Server(404, "not found")

        val result = repo.deleteTask("t1")

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError)
    }

    @Test
    fun `deleteTask success`() = runTest {
        val bodySlot = slot<String>()
        coEvery { client.postIgnoringData(ApiPaths.DELETE_TASK, capture(bodySlot)) } returns Unit

        val result = repo.deleteTask("t1")

        assertTrue(result.isSuccess)
        assertTrue(bodySlot.captured.contains("\"taskId\":\"t1\""))
    }
}
