package com.kpopvote.collector.data.model

import com.kpopvote.collector.core.common.AppError

/**
 * Cache state for master data lists. Exposed via `StateFlow` so UI can observe
 * loading/error/data states without needing a separate ViewModel-level mapping.
 */
sealed interface MasterDataCache<out T> {
    data object Idle : MasterDataCache<Nothing>
    data object Loading : MasterDataCache<Nothing>
    data class Success<T>(
        val items: List<T>,
        val fetchedAtMillis: Long,
    ) : MasterDataCache<T>

    data class Failure(val error: AppError) : MasterDataCache<Nothing>
}
