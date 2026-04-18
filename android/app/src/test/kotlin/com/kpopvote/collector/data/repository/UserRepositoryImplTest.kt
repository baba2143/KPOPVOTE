package com.kpopvote.collector.data.repository

import com.google.firebase.firestore.FirebaseFirestore
import com.kpopvote.collector.core.auth.AuthStateHolder
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.common.IdTokenProvider
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.User
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class UserRepositoryImplTest {

    private val firestore: FirebaseFirestore = mockk(relaxed = true)
    private val client: FunctionsClient = mockk()
    private val tokenProvider: IdTokenProvider = mockk()
    private val authStateHolder: AuthStateHolder = mockk(relaxed = true)
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val repo = UserRepositoryImpl(firestore, client, tokenProvider, authStateHolder, json)

    @Test
    fun `updateProfile sends only non-null fields`() = runTest {
        val responded = User(id = "u1", email = "e@x.com", displayName = "New Name")
        val bodySlot = slot<String>()
        coEvery {
            client.post("updateUserProfile", capture(bodySlot), User.serializer())
        } returns responded

        val result = repo.updateProfile(displayName = "New Name", bio = null, biasIds = listOf("b1"))

        assertTrue(result.isSuccess)
        assertEquals(responded, result.getOrNull())
        val sent = bodySlot.captured
        assertTrue("displayName should be in body: $sent", sent.contains("\"displayName\""))
        assertTrue("biasIds should be in body: $sent", sent.contains("\"biasIds\""))
        assertTrue("bio should be omitted: $sent", !sent.contains("\"bio\""))
    }

    @Test
    fun `updateProfile maps backend error to AppError`() = runTest {
        coEvery {
            client.post("updateUserProfile", any(), User.serializer())
        } throws AppError.Server(500, "oops")

        val result = repo.updateProfile(displayName = "X")

        assertTrue(result.isFailure)
        val error = result.exceptionOrNull()
        assertTrue(error is AppError.Server)
        assertEquals(500, (error as AppError.Server).code)
    }

    @Test
    fun `getCurrentUser without uid returns Unauthorized`() = runTest {
        coEvery { tokenProvider.currentUid() } returns null

        val result = repo.getCurrentUser()

        assertTrue(result.isFailure)
        assertEquals(AppError.Unauthorized, result.exceptionOrNull())
    }
}
