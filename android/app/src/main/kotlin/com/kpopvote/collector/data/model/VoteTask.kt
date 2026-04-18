package com.kpopvote.collector.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Mirrors iOS `VoteTask` (Models/Task.swift). All timestamps travel as ISO8601 strings;
 * conversion to epoch millis happens at the UI boundary via [com.kpopvote.collector.core.util.IsoDate].
 *
 * Note the iOS API uses `targetMembers` for the bias id list; we keep the Kotlin-side name
 * `biasIds` for readability but preserve the wire name via [SerialName].
 */
@Serializable
data class VoteTask(
    @SerialName("taskId") val id: String,
    val userId: String,
    val title: String,
    val url: String,
    @SerialName("deadline") val deadlineIso: String,
    val status: TaskStatus = TaskStatus.PENDING,
    @SerialName("targetMembers") val biasIds: List<String> = emptyList(),
    val externalAppId: String? = null,
    val externalAppName: String? = null,
    val externalAppIconUrl: String? = null,
    val coverImage: String? = null,
    val coverImageSource: CoverImageSource? = null,
    @SerialName("createdAt") val createdAtIso: String? = null,
    @SerialName("updatedAt") val updatedAtIso: String? = null,
)

@Serializable
enum class TaskStatus {
    @SerialName("pending") PENDING,
    @SerialName("completed") COMPLETED,
    @SerialName("expired") EXPIRED,
    @SerialName("archived") ARCHIVED,
}

@Serializable
enum class CoverImageSource {
    @SerialName("externalApp") EXTERNAL_APP,
    @SerialName("userUpload") USER_UPLOAD,
}

@Serializable
data class TaskListData(
    val tasks: List<VoteTask> = emptyList(),
    val count: Int = 0,
)

/**
 * Cloud Functions response for `updateTaskStatus`. Points awarded on first-complete or streak bonus.
 */
@Serializable
data class UpdateTaskStatusData(
    val pointsGranted: Int? = null,
)

/**
 * Wire DTO for register/update task. Mirrors iOS request body exactly, including the
 * `targetMembers` name translation for bias ids.
 */
@Serializable
data class TaskWriteBody(
    val taskId: String? = null,
    val title: String,
    val url: String,
    @SerialName("deadline") val deadlineIso: String,
    val targetMembers: List<String> = emptyList(),
    val externalAppId: String? = null,
    val coverImage: String? = null,
    val coverImageSource: CoverImageSource? = null,
)

@Serializable
data class TaskStatusBody(
    val taskId: String,
    val isCompleted: Boolean,
)

@Serializable
data class TaskIdBody(val taskId: String)
