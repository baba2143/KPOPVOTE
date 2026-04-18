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
    ): R = withContext(ioDispatcher) {
        val url = buildUrl(path, query)
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
    ): R = withContext(ioDispatcher) {
        val url = buildUrl(path, emptyMap())
        val body = bodyJson.toRequestBody(JSON_MEDIA_TYPE)
        val request = Request.Builder()
            .url(url)
            .post(body)
            .bearerAuth()
            .build()
        execute(request, dataSerializer)
    }

    private fun buildUrl(path: String, query: Map<String, String>): okhttp3.HttpUrl {
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
