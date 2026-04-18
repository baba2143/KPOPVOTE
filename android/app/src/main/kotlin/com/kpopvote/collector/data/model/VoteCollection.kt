package com.kpopvote.collector.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * User-authored vote collection. Mirrors iOS `VoteCollection` (Models/VoteCollection.swift).
 * `tasks[].snapshot` may be absent for list endpoints and populated for detail.
 */
@Serializable
data class VoteCollection(
    val collectionId: String,
    val ownerId: String,
    val ownerName: String? = null,
    val ownerAvatarUrl: String? = null,
    val title: String,
    val description: String = "",
    val coverImage: String? = null,
    val tags: List<String> = emptyList(),
    val tasks: List<CollectionTaskRef> = emptyList(),
    val visibility: CollectionVisibility = CollectionVisibility.PUBLIC,
    val saveCount: Int = 0,
    val likeCount: Int = 0,
    val createdAt: String? = null,
    val updatedAt: String? = null,
)

@Serializable
data class CollectionTaskRef(
    val taskId: String,
    val orderIndex: Int = 0,
    val snapshot: VoteTask? = null,
)

@Serializable
enum class CollectionVisibility {
    @SerialName("public") PUBLIC,
    @SerialName("followers") FOLLOWERS,
    @SerialName("private") PRIVATE,
}

@Serializable
data class CollectionsListData(
    val collections: List<VoteCollection> = emptyList(),
    val pagination: PaginationInfo = PaginationInfo(),
)

@Serializable
data class PaginationInfo(
    val currentPage: Int = 1,
    val totalPages: Int = 0,
    val totalCount: Int = 0,
    val hasNext: Boolean = false,
)

@Serializable
data class CollectionDetailData(
    val collection: VoteCollection,
    val isSaved: Boolean = false,
    val isLiked: Boolean = false,
    val isOwner: Boolean = false,
    val isFollowingCreator: Boolean = false,
)

@Serializable
data class TrendingData(
    val collections: List<VoteCollection> = emptyList(),
    val period: String = "7d",
)

@Serializable
data class SaveData(
    val saved: Boolean,
    val saveCount: Int = 0,
)

@Serializable
data class AddToTasksData(
    val addedCount: Int = 0,
    val skippedCount: Int = 0,
    val totalCount: Int = 0,
    val addedTaskIds: List<String> = emptyList(),
)

@Serializable
data class AddSingleTaskData(
    val taskId: String,
    val alreadyAdded: Boolean = false,
    val message: String = "",
)

@Serializable
data class ShareCollectionData(
    val postId: String,
    val collectionId: String,
)

@Serializable
data class CollectionWriteBody(
    val title: String,
    val description: String = "",
    val coverImage: String? = null,
    val tags: List<String> = emptyList(),
    val tasks: List<CollectionTaskWrite> = emptyList(),
    val visibility: String = "public",
)

@Serializable
data class CollectionTaskWrite(
    val taskId: String,
    val orderIndex: Int,
)

@Serializable
data class ShareCollectionBody(
    val biasIds: List<String>,
    val text: String = "",
)

/** Sort option for collection list endpoints. Matches iOS `CollectionSortOption`. */
enum class CollectionSortOption(val apiValue: String) {
    LATEST("latest"),
    POPULAR("popular"),
    TRENDING("trending"),
    RELEVANCE("relevance"),
}

/** Trending window parameter for `trendingCollections`. */
enum class TrendingPeriod(val apiValue: String) {
    LAST_24H("24h"),
    LAST_7D("7d"),
    LAST_30D("30d"),
}
