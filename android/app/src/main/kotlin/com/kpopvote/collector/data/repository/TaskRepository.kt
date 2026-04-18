package com.kpopvote.collector.data.repository

import com.kpopvote.collector.data.model.CoverImageSource
import com.kpopvote.collector.data.model.VoteTask

/**
 * Tasks (iOS `TaskService`). All CRUD goes through Cloud Functions HTTP; no direct Firestore
 * reads — matches iOS behaviour so permission rules and validation stay authoritative.
 */
interface TaskRepository {
    suspend fun getUserTasks(isCompleted: Boolean? = null): Result<List<VoteTask>>
    suspend fun getActiveTasks(): Result<List<VoteTask>>
    suspend fun registerTask(input: TaskInput): Result<VoteTask>
    suspend fun updateTask(taskId: String, input: TaskInput): Result<VoteTask>
    suspend fun markCompleted(taskId: String): Result<Int?>
    suspend fun deleteTask(taskId: String): Result<Unit>
}

data class TaskInput(
    val title: String,
    val url: String,
    val deadlineIso: String,
    val biasIds: List<String> = emptyList(),
    val externalAppId: String? = null,
    val coverImage: String? = null,
    val coverImageSource: CoverImageSource? = null,
)
