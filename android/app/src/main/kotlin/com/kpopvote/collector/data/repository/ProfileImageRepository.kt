package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.common.IdTokenProvider
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Thin wrapper around [StorageRepository] for profile photos.
 * Path: `profiles/{uid}/profile.jpg` — fixed filename overwrites previous photo (iOS parity,
 * see `ImageUploadService.uploadProfilePhoto`).
 */
interface ProfileImageRepository {
    suspend fun upload(bytes: ByteArray): Result<String>
}

@Singleton
class ProfileImageRepositoryImpl @Inject constructor(
    private val storageRepository: StorageRepository,
    private val tokenProvider: IdTokenProvider,
) : ProfileImageRepository {

    override suspend fun upload(bytes: ByteArray): Result<String> {
        val uid = tokenProvider.currentUid()
            ?: return Result.failure(AppError.Unauthorized)
        val path = "profiles/$uid/profile.jpg"
        return storageRepository.uploadImage(bytes, path, contentType = "image/jpeg")
    }
}
