package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.AddSingleTaskData
import com.kpopvote.collector.data.model.AddToTasksData
import com.kpopvote.collector.data.model.CollectionDetailData
import com.kpopvote.collector.data.model.CollectionSortOption
import com.kpopvote.collector.data.model.CollectionVisibility
import com.kpopvote.collector.data.model.CollectionsListData
import com.kpopvote.collector.data.model.PaginationInfo
import com.kpopvote.collector.data.model.SaveData
import com.kpopvote.collector.data.model.ShareCollectionData
import com.kpopvote.collector.data.model.TrendingData
import com.kpopvote.collector.data.model.TrendingPeriod
import com.kpopvote.collector.data.model.VoteCollection
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CollectionRepositoryImplTest {

    private val client: FunctionsClient = mockk(relaxUnitFun = true)
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val repo = CollectionRepositoryImpl(client, json)

    private val sample = VoteCollection(
        collectionId = "c1",
        ownerId = "u1",
        title = "Favorites",
        visibility = CollectionVisibility.PUBLIC,
    )

    private fun list(vararg items: VoteCollection) =
        CollectionsListData(items.toList(), PaginationInfo(1, 1, items.size, false))

    @Test
    fun `getCollections sends pagination + sort + multi tags`() = runTest {
        val querySlot = slot<List<Pair<String, String>>>()
        coEvery {
            client.getMulti(ApiPaths.COLLECTIONS, CollectionsListData.serializer(), capture(querySlot))
        } returns list(sample)

        val result = repo.getCollections(
            page = 2,
            limit = 30,
            sortBy = CollectionSortOption.POPULAR,
            tags = listOf("kpop", "bts"),
        )

        assertTrue(result.isSuccess)
        assertEquals(
            listOf(
                "page" to "2",
                "limit" to "30",
                "sortBy" to "popular",
                "tags" to "kpop",
                "tags" to "bts",
            ),
            querySlot.captured,
        )
    }

    @Test
    fun `searchCollections prepends q param`() = runTest {
        val querySlot = slot<List<Pair<String, String>>>()
        coEvery {
            client.getMulti(ApiPaths.SEARCH_COLLECTIONS, CollectionsListData.serializer(), capture(querySlot))
        } returns list(sample)

        val result = repo.searchCollections(
            query = "newjeans",
            sortBy = CollectionSortOption.RELEVANCE,
            tags = listOf("jp"),
        )

        assertTrue(result.isSuccess)
        assertEquals("q", querySlot.captured.first().first)
        assertEquals("newjeans", querySlot.captured.first().second)
        assertTrue(querySlot.captured.contains("tags" to "jp"))
        assertTrue(querySlot.captured.contains("sortBy" to "relevance"))
    }

    @Test
    fun `getTrendingCollections returns inner list`() = runTest {
        coEvery {
            client.get(
                ApiPaths.TRENDING_COLLECTIONS,
                TrendingData.serializer(),
                mapOf("period" to "7d", "limit" to "10"),
            )
        } returns TrendingData(listOf(sample), "7d")

        val result = repo.getTrendingCollections(period = TrendingPeriod.LAST_7D, limit = 10)

        assertTrue(result.isSuccess)
        assertEquals(listOf(sample), result.getOrNull())
    }

    @Test
    fun `getCollectionDetail appends id to path`() = runTest {
        coEvery {
            client.get("${ApiPaths.COLLECTIONS}/c1", CollectionDetailData.serializer())
        } returns CollectionDetailData(sample, isSaved = true, isOwner = true)

        val result = repo.getCollectionDetail("c1")

        assertTrue(result.isSuccess)
        assertEquals(sample, result.getOrNull()?.collection)
        assertTrue(result.getOrNull()?.isOwner == true)
    }

    @Test
    fun `getMyCollections passes pagination`() = runTest {
        coEvery {
            client.get(
                ApiPaths.MY_COLLECTIONS,
                CollectionsListData.serializer(),
                mapOf("page" to "1", "limit" to "20"),
            )
        } returns list()

        val result = repo.getMyCollections()
        assertTrue(result.isSuccess)
    }

    @Test
    fun `getSavedCollections passes pagination`() = runTest {
        coEvery {
            client.get(
                ApiPaths.SAVED_COLLECTIONS,
                CollectionsListData.serializer(),
                mapOf("page" to "3", "limit" to "50"),
            )
        } returns list()

        val result = repo.getSavedCollections(page = 3, limit = 50)
        assertTrue(result.isSuccess)
    }

    @Test
    fun `toggleSaveCollection posts to save subpath with empty body`() = runTest {
        val bodySlot = slot<String>()
        coEvery {
            client.post(
                "${ApiPaths.COLLECTIONS}/c1/save",
                capture(bodySlot),
                SaveData.serializer(),
            )
        } returns SaveData(saved = true, saveCount = 7)

        val result = repo.toggleSaveCollection("c1")

        assertTrue(result.isSuccess)
        assertEquals(true, result.getOrNull()?.saved)
        assertEquals("{}", bodySlot.captured)
    }

    @Test
    fun `addCollectionToTasks posts to add-to-tasks subpath`() = runTest {
        coEvery {
            client.post(
                "${ApiPaths.COLLECTIONS}/c1/add-to-tasks",
                any(),
                AddToTasksData.serializer(),
            )
        } returns AddToTasksData(addedCount = 3, skippedCount = 1, totalCount = 4)

        val result = repo.addCollectionToTasks("c1")

        assertTrue(result.isSuccess)
        assertEquals(3, result.getOrNull()?.addedCount)
    }

    @Test
    fun `addSingleTaskToTasks posts to nested task subpath`() = runTest {
        coEvery {
            client.post(
                "${ApiPaths.COLLECTIONS}/c1/tasks/t9/add",
                any(),
                AddSingleTaskData.serializer(),
            )
        } returns AddSingleTaskData(taskId = "t9", alreadyAdded = false, message = "ok")

        val result = repo.addSingleTaskToTasks("c1", "t9")

        assertTrue(result.isSuccess)
        assertEquals("t9", result.getOrNull()?.taskId)
    }

    @Test
    fun `shareCollectionToCommunity serializes biasIds and text`() = runTest {
        val bodySlot = slot<String>()
        coEvery {
            client.post(
                "${ApiPaths.COLLECTIONS}/c1/share-to-community",
                capture(bodySlot),
                ShareCollectionData.serializer(),
            )
        } returns ShareCollectionData(postId = "p1", collectionId = "c1")

        val result = repo.shareCollectionToCommunity(
            collectionId = "c1",
            biasIds = listOf("b1", "b2"),
            text = "check this",
        )

        assertTrue(result.isSuccess)
        assertTrue(bodySlot.captured.contains("\"biasIds\":[\"b1\",\"b2\"]"))
        assertTrue(bodySlot.captured.contains("\"text\":\"check this\""))
    }

    @Test
    fun `updateCollection sends PUT with ordered tasks`() = runTest {
        val bodySlot = slot<String>()
        coEvery {
            client.put(
                "${ApiPaths.COLLECTIONS}/c1",
                capture(bodySlot),
                UpdateCollectionData.serializer(),
            )
        } returns UpdateCollectionData(sample.copy(title = "Updated"))

        val result = repo.updateCollection(
            "c1",
            CollectionInput(
                title = "Updated",
                taskIds = listOf("t1", "t2"),
                tags = listOf("a"),
                visibility = "public",
            ),
        )

        assertTrue(result.isSuccess)
        assertEquals("Updated", result.getOrNull()?.title)
        assertTrue(bodySlot.captured.contains("\"taskId\":\"t1\""))
        assertTrue(bodySlot.captured.contains("\"orderIndex\":1"))
    }

    @Test
    fun `deleteCollection calls DELETE verb`() = runTest {
        coEvery { client.delete("${ApiPaths.COLLECTIONS}/c1") } returns Unit

        val result = repo.deleteCollection("c1")

        assertTrue(result.isSuccess)
        coVerify(exactly = 1) { client.delete("${ApiPaths.COLLECTIONS}/c1") }
    }

    @Test
    fun `errors are normalised to AppError`() = runTest {
        coEvery {
            client.get(ApiPaths.MY_COLLECTIONS, CollectionsListData.serializer(), any())
        } throws RuntimeException("boom")

        val result = repo.getMyCollections()

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError)
    }
}
