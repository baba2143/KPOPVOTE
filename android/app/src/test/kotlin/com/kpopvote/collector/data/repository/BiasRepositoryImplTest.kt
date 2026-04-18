package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.BiasData
import com.kpopvote.collector.data.model.BiasSettings
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BiasRepositoryImplTest {

    private val client: FunctionsClient = mockk()
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val repo = BiasRepositoryImpl(client, json)

    @Test
    fun `getBias returns myBias list`() = runTest {
        val settings = listOf(BiasSettings("a1", "Artist1", listOf("m1"), listOf("M1")))
        coEvery { client.get("getBias", BiasData.serializer(), emptyMap()) } returns BiasData(settings)

        val result = repo.getBias()

        assertTrue(result.isSuccess)
        assertEquals(settings, result.getOrNull())
    }

    @Test
    fun `getBias surfaces AppError on failure`() = runTest {
        coEvery { client.get("getBias", BiasData.serializer(), emptyMap()) } throws AppError.Network

        val result = repo.getBias()

        assertTrue(result.isFailure)
        assertEquals(AppError.Network, result.exceptionOrNull())
    }

    @Test
    fun `setBias posts myBias body`() = runTest {
        val settings = listOf(BiasSettings("a1", "Artist1", listOf("m1"), listOf("M1")))
        coEvery {
            client.post("setBias", any(), BiasData.serializer())
        } returns BiasData(settings)

        val result = repo.setBias(settings)

        assertTrue(result.isSuccess)
        coVerify(exactly = 1) {
            client.post("setBias", match { it.contains("\"myBias\"") && it.contains("a1") }, BiasData.serializer())
        }
    }
}
