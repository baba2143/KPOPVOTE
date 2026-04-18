package com.kpopvote.collector.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Mirrors iOS `IdolMaster.swift`. `idolId` is the stable backend id. */
@Serializable
data class IdolMaster(
    @SerialName("idolId") val id: String,
    val name: String,
    val groupName: String,
    val imageUrl: String? = null,
    val createdAt: String? = null,
    val updatedAt: String? = null,
) {
    val displayName: String get() = "$name ($groupName)"
    val hasImage: Boolean get() = !imageUrl.isNullOrBlank()
}

/** Raw response shape: `{ idols: [...], count: N }`. */
@Serializable
data class IdolListData(
    val idols: List<IdolMaster>,
    val count: Int = 0,
)
