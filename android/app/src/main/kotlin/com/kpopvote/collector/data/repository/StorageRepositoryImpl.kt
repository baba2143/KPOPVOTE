package com.kpopvote.collector.data.repository

import com.google.firebase.storage.FirebaseStorage
import com.google.firebase.storage.StorageMetadata
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.common.IdTokenProvider
import com.kpopvote.collector.core.common.toAppError
import com.kpopvote.collector.di.IoDispatcher
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class StorageRepositoryImpl @Inject constructor(
    private val storage: FirebaseStorage,
    private val tokenProvider: IdTokenProvider,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher,
) : StorageRepository {

    override suspend fun uploadImage(
        bytes: ByteArray,
        path: String,
        contentType: String,
    ): Result<String> = withContext(ioDispatcher) {
        runCatching {
            tokenProvider.currentUid() ?: throw AppError.Unauthorized
            val ref = storage.reference.child(path)
            val metadata = StorageMetadata.Builder().setContentType(contentType).build()
            ref.putBytes(bytes, metadata).await()
            ref.downloadUrl.await().toString()
        }.recoverCatching { throw it.toAppError() }
    }
}
