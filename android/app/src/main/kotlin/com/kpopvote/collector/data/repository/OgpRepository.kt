package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.toAppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.OgpMetadata
import javax.inject.Inject
import javax.inject.Singleton

/**
 * URL preview metadata. Not wired to any screen in Sprint 3 (iOS parity — same
 * deferral), but kept ready for the Add Task URL preview planned for Sprint 4+.
 */
interface OgpRepository {
    suspend fun fetchOgp(url: String): Result<OgpMetadata>
}

@Singleton
class OgpRepositoryImpl @Inject constructor(
    private val client: FunctionsClient,
) : OgpRepository {
    override suspend fun fetchOgp(url: String): Result<OgpMetadata> = runCatching {
        client.get(
            ApiPaths.FETCH_TASK_OGP,
            OgpMetadata.serializer(),
            mapOf("url" to url),
        )
    }.recoverCatching { throw it.toAppError() }
}
