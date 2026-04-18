package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.GroupListData
import com.kpopvote.collector.data.model.GroupMaster
import com.kpopvote.collector.data.model.IdolListData
import com.kpopvote.collector.data.model.IdolMaster
import com.kpopvote.collector.data.model.MasterDataCache
import io.mockk.Runs
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.just
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MasterDataRepositoryImplTest {

    private val client: FunctionsClient = mockk()

    private fun repo(clockMillis: () -> Long = { 0L }) =
        MasterDataRepositoryImpl(client, clockMillis)

    @Test
    fun `first refresh fetches and caches`() = runTest {
        coEvery {
            client.get("listIdols", IdolListData.serializer(), any())
        } returns IdolListData(listOf(IdolMaster("i1", "A", "G")), 1)

        val repo = repo()
        val result = repo.refreshIdols()

        assertTrue(result.isSuccess)
        assertEquals(1, result.getOrNull()!!.size)
        val cache = repo.idols.value
        assertTrue(cache is MasterDataCache.Success)
        assertEquals("i1", (cache as MasterDataCache.Success).items[0].id)
    }

    @Test
    fun `second refresh within TTL hits cache, not HTTP`() = runTest {
        coEvery {
            client.get("listIdols", IdolListData.serializer(), any())
        } returns IdolListData(listOf(IdolMaster("i1", "A", "G")), 1)

        var now = 0L
        val repo = repo { now }
        repo.refreshIdols()
        now += 5 * 60 * 1000L  // 5 minutes
        val second = repo.refreshIdols()

        assertTrue(second.isSuccess)
        coVerify(exactly = 1) {
            client.get("listIdols", IdolListData.serializer(), any())
        }
    }

    @Test
    fun `refresh past TTL re-fetches`() = runTest {
        coEvery {
            client.get("listIdols", IdolListData.serializer(), any())
        } returns IdolListData(listOf(IdolMaster("i1", "A", "G")), 1)

        var now = 0L
        val repo = repo { now }
        repo.refreshIdols()
        now += 11 * 60 * 1000L  // 11 minutes > 10m TTL
        repo.refreshIdols()

        coVerify(exactly = 2) {
            client.get("listIdols", IdolListData.serializer(), any())
        }
    }

    @Test
    fun `force true bypasses cache`() = runTest {
        coEvery {
            client.get("listIdols", IdolListData.serializer(), any())
        } returns IdolListData(emptyList(), 0)

        val repo = repo()
        repo.refreshIdols()
        repo.refreshIdols(force = true)

        coVerify(exactly = 2) {
            client.get("listIdols", IdolListData.serializer(), any())
        }
    }

    @Test
    fun `failure sets Failure state and returns Result failure`() = runTest {
        coEvery {
            client.get("listIdols", IdolListData.serializer(), any())
        } throws AppError.Network

        val repo = repo()
        val result = repo.refreshIdols()

        assertTrue(result.isFailure)
        val cache = repo.idols.value
        assertTrue(cache is MasterDataCache.Failure)
        assertEquals(AppError.Network, (cache as MasterDataCache.Failure).error)
    }

    @Test
    fun `groups refresh uses limit=1000`() = runTest {
        coEvery {
            client.get("listGroups", GroupListData.serializer(), mapOf("limit" to "1000"))
        } returns GroupListData(listOf(GroupMaster("g1", "Group1")), 1)

        val repo = repo()
        val result = repo.refreshGroups()

        assertTrue(result.isSuccess)
        assertEquals("g1", result.getOrNull()!![0].id)
    }

    @Test
    fun `refreshIdols passes groupName query when provided`() = runTest {
        coEvery {
            client.get(
                "listIdols",
                IdolListData.serializer(),
                mapOf("limit" to "10000", "groupName" to "BTS"),
            )
        } returns IdolListData(emptyList(), 0)

        val repo = repo()
        val result = repo.refreshIdols(groupName = "BTS")

        assertTrue(result.isSuccess)
    }
}
