package com.kpopvote.collector.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Mirrors iOS `ExternalAppMaster.swift`. */
@Serializable
data class ExternalAppMaster(
    @SerialName("appId") val id: String,
    val appName: String,
    val appUrl: String,
    val iconUrl: String? = null,
    val defaultCoverImageUrl: String? = null,
    val createdAt: String? = null,
    val updatedAt: String? = null,
) {
    val displayName: String get() = appName
}

@Serializable
data class ExternalAppListData(
    val apps: List<ExternalAppMaster>,
    val count: Int = 0,
)
