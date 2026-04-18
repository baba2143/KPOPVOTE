package com.kpopvote.collector.data.repository

import com.kpopvote.collector.data.model.AddSingleTaskData
import com.kpopvote.collector.data.model.AddToTasksData
import com.kpopvote.collector.data.model.CollectionDetailData
import com.kpopvote.collector.data.model.CollectionSortOption
import com.kpopvote.collector.data.model.CollectionsListData
import com.kpopvote.collector.data.model.ShareCollectionData
import com.kpopvote.collector.data.model.SaveData
import com.kpopvote.collector.data.model.TrendingPeriod
import com.kpopvote.collector.data.model.VoteCollection

/**
 * Vote collections (iOS `CollectionService`). All calls go through Cloud Functions HTTP.
 * Browsing endpoints (`list`, `search`, `trending`) work with any authenticated user;
 * mutation endpoints require ownership checks on the server.
 */
interface CollectionRepository {
    suspend fun getCollections(
        page: Int = 1,
        limit: Int = 20,
        sortBy: CollectionSortOption = CollectionSortOption.LATEST,
        tags: List<String>? = null,
    ): Result<CollectionsListData>

    suspend fun searchCollections(
        query: String,
        page: Int = 1,
        limit: Int = 20,
        sortBy: CollectionSortOption = CollectionSortOption.RELEVANCE,
        tags: List<String>? = null,
    ): Result<CollectionsListData>

    suspend fun getTrendingCollections(
        period: TrendingPeriod = TrendingPeriod.LAST_7D,
        limit: Int = 10,
    ): Result<List<VoteCollection>>

    suspend fun getCollectionDetail(collectionId: String): Result<CollectionDetailData>

    suspend fun getMyCollections(page: Int = 1, limit: Int = 20): Result<CollectionsListData>

    suspend fun getSavedCollections(page: Int = 1, limit: Int = 20): Result<CollectionsListData>

    suspend fun toggleSaveCollection(collectionId: String): Result<SaveData>

    suspend fun addCollectionToTasks(collectionId: String): Result<AddToTasksData>

    suspend fun addSingleTaskToTasks(
        collectionId: String,
        taskId: String,
    ): Result<AddSingleTaskData>

    suspend fun shareCollectionToCommunity(
        collectionId: String,
        biasIds: List<String>,
        text: String = "",
    ): Result<ShareCollectionData>

    suspend fun createCollection(input: CollectionInput): Result<VoteCollection>

    suspend fun updateCollection(
        collectionId: String,
        input: CollectionInput,
    ): Result<VoteCollection>

    suspend fun deleteCollection(collectionId: String): Result<Unit>
}

/** Write-side input for create/update operations. Order of [taskIds] is preserved. */
data class CollectionInput(
    val title: String,
    val description: String = "",
    val coverImage: String? = null,
    val tags: List<String> = emptyList(),
    val taskIds: List<String> = emptyList(),
    val visibility: String = "public",
)
