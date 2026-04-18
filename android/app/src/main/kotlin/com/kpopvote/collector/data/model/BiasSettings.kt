package com.kpopvote.collector.data.model

import kotlinx.serialization.Serializable

/**
 * Mirrors iOS `BiasSettings` (see `Bias.swift:BiasSettings`).
 * One entry per artist (group) the user marks as bias.
 */
@Serializable
data class BiasSettings(
    val artistId: String,
    val artistName: String,
    val memberIds: List<String> = emptyList(),
    val memberNames: List<String> = emptyList(),
    val isGroupLevel: Boolean = false,
) {
    val displayMembers: String get() = memberNames.joinToString(", ")
    val memberCount: Int get() = memberNames.size
}

/** Response / request wrapper used by `getBias` / `setBias`. */
@Serializable
data class BiasData(
    val myBias: List<BiasSettings> = emptyList(),
)
