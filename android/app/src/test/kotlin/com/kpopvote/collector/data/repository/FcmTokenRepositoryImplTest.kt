package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.local.DeviceIdDataStore
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class FcmTokenRepositoryImplTest {

    private val client: FunctionsClient = mockk(relaxUnitFun = true)
    private val deviceIdDataStore: DeviceIdDataStore = mockk()
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val repo = FcmTokenRepositoryImpl(client, deviceIdDataStore, json)

    @Test
    fun `register posts token + deviceId + platform=android`() = runTest {
        coEvery { deviceIdDataStore.getOrCreate() } returns "device-abc"
        val bodySlot = slot<String>()
        coEvery {
            client.postIgnoringData(ApiPaths.REGISTER_FCM_TOKEN, capture(bodySlot), emptyMap())
        } returns Unit

        val result = repo.register("fcm-token-xyz")

        assertTrue(result.isSuccess)
        assertTrue(bodySlot.captured.contains("\"token\":\"fcm-token-xyz\""))
        assertTrue(bodySlot.captured.contains("\"deviceId\":\"device-abc\""))
        assertTrue(bodySlot.captured.contains("\"platform\":\"android\""))
    }

    @Test
    fun `register maps 401 to Unauthorized`() = runTest {
        coEvery { deviceIdDataStore.getOrCreate() } returns "device-abc"
        coEvery {
            client.postIgnoringData(ApiPaths.REGISTER_FCM_TOKEN, any(), any())
        } throws AppError.Unauthorized

        val result = repo.register("fcm-token-xyz")

        assertTrue(result.isFailure)
        assertSame(AppError.Unauthorized, result.exceptionOrNull())
    }

    @Test
    fun `unregister posts deviceId`() = runTest {
        coEvery { deviceIdDataStore.getOrCreate() } returns "device-abc"
        val bodySlot = slot<String>()
        coEvery {
            client.postIgnoringData(ApiPaths.UNREGISTER_FCM_TOKEN, capture(bodySlot), emptyMap())
        } returns Unit

        val result = repo.unregister()

        assertTrue(result.isSuccess)
        assertTrue(bodySlot.captured.contains("\"deviceId\":\"device-abc\""))
        coVerify(exactly = 1) { deviceIdDataStore.getOrCreate() }
    }

    @Test
    fun `unregister maps network failure to AppError Network`() = runTest {
        coEvery { deviceIdDataStore.getOrCreate() } returns "device-abc"
        coEvery {
            client.postIgnoringData(ApiPaths.UNREGISTER_FCM_TOKEN, any(), any())
        } throws AppError.Network

        val result = repo.unregister()

        assertTrue(result.isFailure)
        assertSame(AppError.Network, result.exceptionOrNull())
    }

    @Test
    fun `register uses deviceId from DataStore for each call`() = runTest {
        coEvery { deviceIdDataStore.getOrCreate() } returns "device-abc"
        coEvery {
            client.postIgnoringData(ApiPaths.REGISTER_FCM_TOKEN, any(), any())
        } returns Unit

        repo.register("token-1")
        repo.register("token-2")

        coVerify(exactly = 2) { deviceIdDataStore.getOrCreate() }
        assertEquals("device-abc", deviceIdDataStore.getOrCreate())
    }
}
