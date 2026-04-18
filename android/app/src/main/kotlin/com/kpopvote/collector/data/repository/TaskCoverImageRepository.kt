package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.common.IdTokenProvider
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Thin wrapper around [StorageRepository] that owns the iOS-parity path
 * `task-cover-images/{uid}/{uuid}.jpg` so callers don't have to.
 */
interface TaskCoverImageRepository {
    suspend fun upload(bytes: ByteArray): Result<String>
}

@Singleton
class TaskCoverImageRepositoryImpl @Inject constructor(
    private val storageRepository: StorageRepository,
    private val tokenProvider: IdTokenProvider,
) : TaskCoverImageRepository {

    override suspend fun upload(bytes: ByteArray): Result<String> {
        val uid = tokenProvider.currentUid()
            ?: return Result.failure(AppError.Unauthorized)
        val path = "task-cover-images/$uid/${UUID.randomUUID()}.jpg"
        return storageRepository.uploadImage(bytes, path, contentType = "image/jpeg")
    }
}
