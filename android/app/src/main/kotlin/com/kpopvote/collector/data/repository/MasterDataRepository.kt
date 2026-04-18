package com.kpopvote.collector.data.repository

import com.kpopvote.collector.data.model.ExternalAppMaster
import com.kpopvote.collector.data.model.GroupMaster
import com.kpopvote.collector.data.model.IdolMaster
import com.kpopvote.collector.data.model.MasterDataCache
import kotlinx.coroutines.flow.StateFlow

/**
 * Read-only master data (idols / groups / external apps). The same Firestore
 * collections back iOS; refresh actions hit the Cloud Functions HTTP endpoints.
 *
 * Caches are held in-memory with a 10-minute TTL; call `refresh(force = true)`
 * to bypass.
 */
interface MasterDataRepository {
    val idols: StateFlow<MasterDataCache<IdolMaster>>
    val groups: StateFlow<MasterDataCache<GroupMaster>>
    val externalApps: StateFlow<MasterDataCache<ExternalAppMaster>>

    suspend fun refreshIdols(
        force: Boolean = false,
        groupName: String? = null,
    ): Result<List<IdolMaster>>

    suspend fun refreshGroups(force: Boolean = false): Result<List<GroupMaster>>

    suspend fun refreshExternalApps(force: Boolean = false): Result<List<ExternalAppMaster>>
}
