package com.kpopvote.collector.data.repository

/**
 * Firebase Storage uploads. Mirrors iOS `ImageUploadService` but does not
 * perform image resizing / compression — callers are expected to pre-encode
 * bytes (see Sprint 6 for the Compose-side helpers).
 *
 * Common paths:
 * - `profiles/{uid}/profile.jpg`        profile photo
 * - `goods/{uid}/{uuid}.jpg`            task goods image
 * - `posts/{uid}/{postId}/{uuid}.jpg`   community post image
 */
interface StorageRepository {
    suspend fun uploadImage(
        bytes: ByteArray,
        path: String,
        contentType: String = "image/jpeg",
    ): Result<String>
}
