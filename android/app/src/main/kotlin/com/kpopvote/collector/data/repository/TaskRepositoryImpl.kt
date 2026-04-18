package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.toAppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.TaskIdBody
import com.kpopvote.collector.data.model.TaskListData
import com.kpopvote.collector.data.model.TaskStatus
import com.kpopvote.collector.data.model.TaskStatusBody
import com.kpopvote.collector.data.model.TaskWriteBody
import com.kpopvote.collector.data.model.UpdateTaskStatusData
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.data.model.deadlineMillis
import com.kpopvote.collector.data.model.isArchived
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TaskRepositoryImpl @Inject constructor(
    private val client: FunctionsClient,
    private val json: Json,
) : TaskRepository {

    override suspend fun getUserTasks(isCompleted: Boolean?): Result<List<VoteTask>> = runCatching {
        val query = isCompleted?.let { mapOf("isCompleted" to it.toString()) } ?: emptyMap()
        client.get(ApiPaths.GET_USER_TASKS, TaskListData.serializer(), query).tasks
    }.recoverCatching { throw it.toAppError() }

    override suspend fun getActiveTasks(): Result<List<VoteTask>> = runCatching {
        val now = System.currentTimeMillis()
        val all = client.get(
            ApiPaths.GET_USER_TASKS,
            TaskListData.serializer(),
            mapOf("isCompleted" to "false"),
        ).tasks
        all.asSequence()
            .filter { !it.isArchived }
            .filter { it.status != TaskStatus.COMPLETED }
            .filter { (it.deadlineMillis ?: Long.MAX_VALUE) > now }
            .sortedBy { it.deadlineMillis ?: Long.MAX_VALUE }
            .toList()
    }.recoverCatching { throw it.toAppError() }

    override suspend fun registerTask(input: TaskInput): Result<VoteTask> = runCatching {
        val body = json.encodeToString(TaskWriteBody.serializer(), input.toWriteBody(taskId = null))
        client.post(ApiPaths.REGISTER_TASK, body, VoteTask.serializer())
    }.recoverCatching { throw it.toAppError() }

    override suspend fun updateTask(taskId: String, input: TaskInput): Result<VoteTask> = runCatching {
        val body = json.encodeToString(TaskWriteBody.serializer(), input.toWriteBody(taskId = taskId))
        client.post(ApiPaths.UPDATE_TASK, body, VoteTask.serializer())
    }.recoverCatching { throw it.toAppError() }

    override suspend fun markCompleted(taskId: String): Result<Int?> = runCatching {
        val body = json.encodeToString(
            TaskStatusBody.serializer(),
            TaskStatusBody(taskId = taskId, isCompleted = true),
        )
        client.post(
            ApiPaths.UPDATE_TASK_STATUS,
            body,
            UpdateTaskStatusData.serializer(),
        ).pointsGranted
    }.recoverCatching { throw it.toAppError() }

    override suspend fun deleteTask(taskId: String): Result<Unit> = runCatching {
        val body = json.encodeToString(TaskIdBody.serializer(), TaskIdBody(taskId))
        client.postIgnoringData(ApiPaths.DELETE_TASK, body)
    }.recoverCatching { throw it.toAppError() }
}

private fun TaskInput.toWriteBody(taskId: String?): TaskWriteBody = TaskWriteBody(
    taskId = taskId,
    title = title,
    url = url,
    deadlineIso = deadlineIso,
    targetMembers = biasIds,
    externalAppId = externalAppId,
    coverImage = coverImage,
    coverImageSource = coverImageSource,
)
