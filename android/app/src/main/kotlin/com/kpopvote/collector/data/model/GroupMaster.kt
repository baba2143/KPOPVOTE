package com.kpopvote.collector.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Mirrors iOS `GroupMaster.swift`. `groupId` is the stable backend id. */
@Serializable
data class GroupMaster(
    @SerialName("groupId") val id: String,
    val name: String,
    val imageUrl: String? = null,
    val createdAt: String? = null,
    val updatedAt: String? = null,
) {
    val hasImage: Boolean get() = !imageUrl.isNullOrBlank()
}

@Serializable
data class GroupListData(
    val groups: List<GroupMaster>,
    val count: Int = 0,
)
