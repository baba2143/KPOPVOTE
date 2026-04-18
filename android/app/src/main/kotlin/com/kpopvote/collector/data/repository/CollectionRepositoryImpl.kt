package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.toAppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.AddSingleTaskData
import com.kpopvote.collector.data.model.AddToTasksData
import com.kpopvote.collector.data.model.CollectionDetailData
import com.kpopvote.collector.data.model.CollectionSortOption
import com.kpopvote.collector.data.model.CollectionTaskWrite
import com.kpopvote.collector.data.model.CollectionWriteBody
import com.kpopvote.collector.data.model.CollectionsListData
import com.kpopvote.collector.data.model.SaveData
import com.kpopvote.collector.data.model.ShareCollectionBody
import com.kpopvote.collector.data.model.ShareCollectionData
import com.kpopvote.collector.data.model.TrendingData
import com.kpopvote.collector.data.model.TrendingPeriod
import com.kpopvote.collector.data.model.VoteCollection
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CollectionRepositoryImpl @Inject constructor(
    private val client: FunctionsClient,
    private val json: Json,
) : CollectionRepository {

    override suspend fun getCollections(
        page: Int,
        limit: Int,
        sortBy: CollectionSortOption,
        tags: List<String>?,
    ): Result<CollectionsListData> = runCatching {
        val query = buildListQuery(page, limit, sortBy.apiValue, tags)
        client.getMulti(ApiPaths.COLLECTIONS, CollectionsListData.serializer(), query)
    }.recoverCatching { throw it.toAppError() }

    override suspend fun searchCollections(
        query: String,
        page: Int,
        limit: Int,
        sortBy: CollectionSortOption,
        tags: List<String>?,
    ): Result<CollectionsListData> = runCatching {
        val params = buildList {
            add("q" to query)
            addAll(buildListQuery(page, limit, sortBy.apiValue, tags))
        }
        client.getMulti(ApiPaths.SEARCH_COLLECTIONS, CollectionsListData.serializer(), params)
    }.recoverCatching { throw it.toAppError() }

    override suspend fun getTrendingCollections(
        period: TrendingPeriod,
        limit: Int,
    ): Result<List<VoteCollection>> = runCatching {
        client.get(
            ApiPaths.TRENDING_COLLECTIONS,
            TrendingData.serializer(),
            mapOf("period" to period.apiValue, "limit" to limit.toString()),
        ).collections
    }.recoverCatching { throw it.toAppError() }

    override suspend fun getCollectionDetail(collectionId: String): Result<CollectionDetailData> =
        runCatching {
            client.get(
                "${ApiPaths.COLLECTIONS}/$collectionId",
                CollectionDetailData.serializer(),
            )
        }.recoverCatching { throw it.toAppError() }

    override suspend fun getMyCollections(page: Int, limit: Int): Result<CollectionsListData> =
        runCatching {
            client.get(
                ApiPaths.MY_COLLECTIONS,
                CollectionsListData.serializer(),
                mapOf("page" to page.toString(), "limit" to limit.toString()),
            )
        }.recoverCatching { throw it.toAppError() }

    override suspend fun getSavedCollections(page: Int, limit: Int): Result<CollectionsListData> =
        runCatching {
            client.get(
                ApiPaths.SAVED_COLLECTIONS,
                CollectionsListData.serializer(),
                mapOf("page" to page.toString(), "limit" to limit.toString()),
            )
        }.recoverCatching { throw it.toAppError() }

    override suspend fun toggleSaveCollection(collectionId: String): Result<SaveData> = runCatching {
        client.post(
            "${ApiPaths.COLLECTIONS}/$collectionId/save",
            EMPTY_BODY,
            SaveData.serializer(),
        )
    }.recoverCatching { throw it.toAppError() }

    override suspend fun addCollectionToTasks(collectionId: String): Result<AddToTasksData> =
        runCatching {
            client.post(
                "${ApiPaths.COLLECTIONS}/$collectionId/add-to-tasks",
                EMPTY_BODY,
                AddToTasksData.serializer(),
            )
        }.recoverCatching { throw it.toAppError() }

    override suspend fun addSingleTaskToTasks(
        collectionId: String,
        taskId: String,
    ): Result<AddSingleTaskData> = runCatching {
        client.post(
            "${ApiPaths.COLLECTIONS}/$collectionId/tasks/$taskId/add",
            EMPTY_BODY,
            AddSingleTaskData.serializer(),
        )
    }.recoverCatching { throw it.toAppError() }

    override suspend fun shareCollectionToCommunity(
        collectionId: String,
        biasIds: List<String>,
        text: String,
    ): Result<ShareCollectionData> = runCatching {
        val body = json.encodeToString(
            ShareCollectionBody.serializer(),
            ShareCollectionBody(biasIds = biasIds, text = text),
        )
        client.post(
            "${ApiPaths.COLLECTIONS}/$collectionId/share-to-community",
            body,
            ShareCollectionData.serializer(),
        )
    }.recoverCatching { throw it.toAppError() }

    override suspend fun createCollection(input: CollectionInput): Result<VoteCollection> =
        runCatching {
            val body = json.encodeToString(CollectionWriteBody.serializer(), input.toWriteBody())
            val envelope = client.post(
                ApiPaths.COLLECTIONS,
                body,
                UpdateCollectionData.serializer(),
            )
            envelope.collection
        }.recoverCatching { throw it.toAppError() }

    override suspend fun updateCollection(
        collectionId: String,
        input: CollectionInput,
    ): Result<VoteCollection> = runCatching {
        val body = json.encodeToString(CollectionWriteBody.serializer(), input.toWriteBody())
        val envelope = client.put(
            "${ApiPaths.COLLECTIONS}/$collectionId",
            body,
            UpdateCollectionData.serializer(),
        )
        envelope.collection
    }.recoverCatching { throw it.toAppError() }

    override suspend fun deleteCollection(collectionId: String): Result<Unit> = runCatching {
        client.delete("${ApiPaths.COLLECTIONS}/$collectionId")
    }.recoverCatching { throw it.toAppError() }

    private fun buildListQuery(
        page: Int,
        limit: Int,
        sortBy: String,
        tags: List<String>?,
    ): List<Pair<String, String>> = buildList {
        add("page" to page.toString())
        add("limit" to limit.toString())
        add("sortBy" to sortBy)
        tags?.forEach { add("tags" to it) }
    }

    private companion object {
        const val EMPTY_BODY = "{}"
    }
}

/** Internal envelope for `PUT /collections/{id}`. iOS `UpdateCollectionData`. */
@kotlinx.serialization.Serializable
internal data class UpdateCollectionData(
    val collection: VoteCollection,
)

private fun CollectionInput.toWriteBody(): CollectionWriteBody = CollectionWriteBody(
    title = title,
    description = description,
    coverImage = coverImage,
    tags = tags,
    tasks = taskIds.mapIndexed { i, id -> CollectionTaskWrite(taskId = id, orderIndex = i) },
    visibility = visibility,
)
