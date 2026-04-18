package com.kpopvote.collector.data.api

import com.kpopvote.collector.core.common.IdTokenProvider
import com.kpopvote.collector.di.IoDispatcher
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.withContext
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import timber.log.Timber
import java.io.IOException
import javax.inject.Inject
import javax.inject.Named
import javax.inject.Singleton
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlinx.coroutines.suspendCancellableCoroutine
import com.kpopvote.collector.core.common.AppError

/**
 * Thin HTTP client for Firebase Cloud Functions that are exposed as `onRequest` (not callable).
 * Matches the iOS URLSession + Bearer token pattern used by services like `IdolService`, `BiasService`.
 *
 * All failures are normalized to [AppError]:
 * - No current user or token → [AppError.Unauthorized]
 * - 401                        → [AppError.Unauthorized]
 * - 4xx/5xx                    → [AppError.Server]
 * - IOException                → [AppError.Network]
 * - JSON decode                → [AppError.Validation]
 */
@Singleton
class FunctionsClient @Inject constructor(
    private val httpClient: OkHttpClient,
    private val tokenProvider: IdTokenProvider,
    private val json: Json,
    @Named("functionsBaseUrl") private val baseUrl: String,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher,
) {

    /** HTTP GET. `R` is the unwrapped [ApiEnvelope.data] type. */
    suspend fun <R : Any> get(
        path: String,
        dataSerializer: KSerializer<R>,
        query: Map<String, String> = emptyMap(),
    ): R = getMulti(path, dataSerializer, query.map { it.toPair() })

    /**
     * HTTP GET accepting repeated query params (e.g. `?tags=a&tags=b`).
     * Preserves order and duplicate keys, which [Map]-based [get] cannot express.
     */
    suspend fun <R : Any> getMulti(
        path: String,
        dataSerializer: KSerializer<R>,
        query: List<Pair<String, String>> = emptyList(),
    ): R = withContext(ioDispatcher) {
        val url = buildUrlMulti(path, query)
        val request = Request.Builder()
            .url(url)
            .get()
            .bearerAuth()
            .build()
        execute(request, dataSerializer)
    }

    /** HTTP POST with JSON body. [bodyJson] is the serialized body; use [Json.encodeToString] upstream. */
    suspend fun <R : Any> post(
        path: String,
        bodyJson: String,
        dataSerializer: KSerializer<R>,
        extraHeaders: Map<String, String> = emptyMap(),
    ): R = withContext(ioDispatcher) {
        val url = buildUrl(path, emptyMap())
        val body = bodyJson.toRequestBody(JSON_MEDIA_TYPE)
        val builder = Request.Builder()
            .url(url)
            .post(body)
            .bearerAuth()
        extraHeaders.forEach { (k, v) -> builder.header(k, v) }
        execute(builder.build(), dataSerializer)
    }

    /**
     * HTTP POST that ignores the response `data` payload — only `{success: true}` in the envelope
     * matters. Useful for endpoints like `deleteTask` where the server returns a confirmation
     * whose shape we don't depend on.
     */
    suspend fun postIgnoringData(
        path: String,
        bodyJson: String,
        extraHeaders: Map<String, String> = emptyMap(),
    ) {
        post(path, bodyJson, kotlinx.serialization.json.JsonElement.serializer(), extraHeaders)
    }

    /** HTTP PUT with JSON body. Used for full-resource updates (e.g. `PUT /collections/{id}`). */
    suspend fun <R : Any> put(
        path: String,
        bodyJson: String,
        dataSerializer: KSerializer<R>,
    ): R = withContext(ioDispatcher) {
        val url = buildUrl(path, emptyMap())
        val body = bodyJson.toRequestBody(JSON_MEDIA_TYPE)
        val request = Request.Builder()
            .url(url)
            .put(body)
            .bearerAuth()
            .build()
        execute(request, dataSerializer)
    }

    /** HTTP DELETE. Only the envelope `success` is inspected. */
    suspend fun delete(path: String): Unit = withContext(ioDispatcher) {
        val url = buildUrl(path, emptyMap())
        val request = Request.Builder()
            .url(url)
            .delete()
            .bearerAuth()
            .build()
        execute(request, kotlinx.serialization.json.JsonElement.serializer())
        Unit
    }

    private fun buildUrl(path: String, query: Map<String, String>): okhttp3.HttpUrl =
        buildUrlMulti(path, query.map { it.toPair() })

    private fun buildUrlMulti(path: String, query: List<Pair<String, String>>): okhttp3.HttpUrl {
        val builder = "$baseUrl/$path".toHttpUrl().newBuilder()
        query.forEach { (k, v) -> builder.addQueryParameter(k, v) }
        return builder.build()
    }

    private suspend fun Request.Builder.bearerAuth(): Request.Builder {
        val token = tokenProvider.currentIdToken(forceRefresh = false)
            ?: throw AppError.Unauthorized
        return header("Authorization", "Bearer $token")
    }

    private suspend fun <R : Any> execute(
        request: Request,
        dataSerializer: KSerializer<R>,
    ): R {
        val response = try {
            httpClient.newCall(request).awaitResponse()
        } catch (e: IOException) {
            Timber.w(e, "Network error calling ${request.url}")
            throw AppError.Network
        }

        response.use { resp ->
            val bodyString = resp.body?.string().orEmpty()
            when {
                resp.code == 401 -> throw AppError.Unauthorized
                !resp.isSuccessful -> {
                    val message = runCatching {
                        json.decodeFromString(ApiErrorBody.serializer(), bodyString).displayMessage
                    }.getOrNull()
                    throw AppError.Server(resp.code, message ?: bodyString.take(200))
                }
            }

            val envelopeSerializer = ApiEnvelope.serializer(dataSerializer)
            val envelope = try {
                json.decodeFromString(envelopeSerializer, bodyString)
            } catch (e: SerializationException) {
                Timber.w(e, "Decode failure for ${request.url}: body=$bodyString")
                throw AppError.Validation("Invalid response from ${request.url}")
            }

            if (!envelope.success) {
                throw AppError.Server(resp.code, "Backend returned success=false")
            }
            return envelope.data
        }
    }

    private companion object {
        val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()
    }
}

private suspend fun okhttp3.Call.awaitResponse(): okhttp3.Response =
    suspendCancellableCoroutine { cont ->
        enqueue(object : okhttp3.Callback {
            override fun onFailure(call: okhttp3.Call, e: IOException) {
                if (cont.isActive) cont.resumeWithException(e)
            }

            override fun onResponse(call: okhttp3.Call, response: okhttp3.Response) {
                if (cont.isActive) cont.resume(response)
            }
        })
        cont.invokeOnCancellation {
            runCatching { cancel() }
        }
    }
