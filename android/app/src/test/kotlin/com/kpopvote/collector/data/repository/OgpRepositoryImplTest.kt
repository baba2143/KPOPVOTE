package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.OgpMetadata
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class OgpRepositoryImplTest {

    private val client: FunctionsClient = mockk()
    private val repo = OgpRepositoryImpl(client)

    @Test
    fun `fetchOgp returns metadata`() = runTest {
        val meta = OgpMetadata(title = "Hello", description = null, imageUrl = null, siteName = null)
        coEvery {
            client.get(ApiPaths.FETCH_TASK_OGP, OgpMetadata.serializer(), mapOf("url" to "https://x"))
        } returns meta

        val result = repo.fetchOgp("https://x")

        assertTrue(result.isSuccess)
        assertEquals(meta, result.getOrNull())
    }

    @Test
    fun `fetchOgp surfaces AppError`() = runTest {
        coEvery {
            client.get(ApiPaths.FETCH_TASK_OGP, OgpMetadata.serializer(), mapOf("url" to "https://x"))
        } throws AppError.Server(500, "boom")

        val result = repo.fetchOgp("https://x")

        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is AppError.Server)
    }
}
