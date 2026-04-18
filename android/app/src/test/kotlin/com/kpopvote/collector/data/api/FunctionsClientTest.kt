package com.kpopvote.collector.data.api

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.common.IdTokenProvider
import com.kpopvote.collector.data.model.IdolListData
import io.mockk.coEvery
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import java.util.concurrent.TimeUnit

class FunctionsClientTest {

    private lateinit var server: MockWebServer
    private lateinit var client: FunctionsClient
    private val tokenProvider = mockk<IdTokenProvider>()
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    @Before
    fun setup() {
        server = MockWebServer()
        server.start()
        every { tokenProvider.currentUid() } returns "uid-test"
        coEvery { tokenProvider.currentIdToken(any()) } returns "test-token"
        client = FunctionsClient(
            httpClient = OkHttpClient.Builder()
                .connectTimeout(1, TimeUnit.SECONDS)
                .readTimeout(1, TimeUnit.SECONDS)
                .build(),
            tokenProvider = tokenProvider,
            json = json,
            baseUrl = server.url("/").toString().trimEnd('/'),
            ioDispatcher = Dispatchers.Unconfined,
        )
    }

    @After
    fun teardown() {
        server.shutdown()
    }

    private suspend inline fun <reified E : Throwable> expectError(block: suspend () -> Unit): E {
        return try {
            block()
            fail("Expected ${E::class.simpleName} but no error was thrown")
            error("unreachable")
        } catch (t: Throwable) {
            if (t is E) t else throw AssertionError("Expected ${E::class.simpleName} but got ${t::class.simpleName}: $t")
        }
    }

    @Test
    fun `200 success decodes envelope and sets Bearer header`() = runTest {
        server.enqueue(
            MockResponse().setResponseCode(200).setBody(
                """{"success":true,"data":{"idols":[{"idolId":"i1","name":"Alice","groupName":"G"}],"count":1}}"""
            )
        )

        val data = client.get("listIdols", IdolListData.serializer(), mapOf("limit" to "10"))

        assertEquals(1, data.idols.size)
        assertEquals("i1", data.idols[0].id)
        val recorded = server.takeRequest()
        assertEquals("Bearer test-token", recorded.getHeader("Authorization"))
        assertNotNull(recorded.path)
        assertTrue(recorded.path!!.contains("limit=10"))
    }

    @Test
    fun `missing token maps to Unauthorized before HTTP call`() = runTest {
        coEvery { tokenProvider.currentIdToken(any()) } returns null

        expectError<AppError.Unauthorized> {
            client.get("listIdols", IdolListData.serializer())
        }
        assertEquals(0, server.requestCount)
    }

    @Test
    fun `401 from server maps to Unauthorized`() = runTest {
        server.enqueue(MockResponse().setResponseCode(401).setBody("""{"error":"nope"}"""))

        expectError<AppError.Unauthorized> {
            client.get("listIdols", IdolListData.serializer())
        }
    }

    @Test
    fun `500 maps to Server error with decoded message`() = runTest {
        server.enqueue(
            MockResponse().setResponseCode(500).setBody("""{"success":false,"error":"boom"}""")
        )

        val thrown = expectError<AppError.Server> {
            client.get("listIdols", IdolListData.serializer())
        }
        assertEquals(500, thrown.code)
        assertEquals("boom", thrown.message)
    }

    @Test
    fun `success false in envelope is surfaced as Server error`() = runTest {
        server.enqueue(
            MockResponse().setResponseCode(200).setBody(
                """{"success":false,"data":{"idols":[],"count":0}}"""
            )
        )

        val thrown = expectError<AppError.Server> {
            client.get("listIdols", IdolListData.serializer())
        }
        assertEquals(200, thrown.code)
        assertFalse(thrown.message.isBlank())
    }

    @Test
    fun `invalid JSON maps to Validation error`() = runTest {
        server.enqueue(MockResponse().setResponseCode(200).setBody("not json"))

        val thrown = expectError<AppError.Validation> {
            client.get("listIdols", IdolListData.serializer())
        }
        assertTrue(thrown.message.contains("Invalid response"))
    }
}
