package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.common.IdTokenProvider
import io.mockk.coEvery
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class CollectionCoverImageRepositoryTest {

    private val storage: StorageRepository = mockk()
    private val tokenProvider: IdTokenProvider = mockk()
    private val repo = CollectionCoverImageRepositoryImpl(storage, tokenProvider)

    @Test
    fun `upload returns Unauthorized when no uid`() = runTest {
        coEvery { tokenProvider.currentUid() } returns null

        val result = repo.upload(ByteArray(8))

        assertTrue(result.isFailure)
        assertSame(AppError.Unauthorized, result.exceptionOrNull())
    }

    @Test
    fun `upload uses collections slash uid slash uuid path`() = runTest {
        coEvery { tokenProvider.currentUid() } returns "user-42"
        val pathSlot = slot<String>()
        coEvery { storage.uploadImage(any(), capture(pathSlot), "image/jpeg") } returns Result.success("https://cdn/x.jpg")

        val result = repo.upload(ByteArray(16))

        assertTrue(result.isSuccess)
        assertEquals("https://cdn/x.jpg", result.getOrNull())
        assertTrue(pathSlot.captured.startsWith("collections/user-42/"))
        assertTrue(pathSlot.captured.endsWith(".jpg"))
    }
}
