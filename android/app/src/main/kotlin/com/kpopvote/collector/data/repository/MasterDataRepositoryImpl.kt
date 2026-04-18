package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.common.toAppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.ExternalAppListData
import com.kpopvote.collector.data.model.ExternalAppMaster
import com.kpopvote.collector.data.model.GroupListData
import com.kpopvote.collector.data.model.GroupMaster
import com.kpopvote.collector.data.model.IdolListData
import com.kpopvote.collector.data.model.IdolMaster
import com.kpopvote.collector.data.model.MasterDataCache
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

private const val CACHE_TTL_MILLIS = 10 * 60 * 1000L  // 10 minutes

@Singleton
class MasterDataRepositoryImpl @Inject constructor(
    private val client: FunctionsClient,
    private val clock: () -> Long = System::currentTimeMillis,
) : MasterDataRepository {

    private val _idols = MutableStateFlow<MasterDataCache<IdolMaster>>(MasterDataCache.Idle)
    override val idols: StateFlow<MasterDataCache<IdolMaster>> = _idols.asStateFlow()

    private val _groups = MutableStateFlow<MasterDataCache<GroupMaster>>(MasterDataCache.Idle)
    override val groups: StateFlow<MasterDataCache<GroupMaster>> = _groups.asStateFlow()

    private val _externalApps = MutableStateFlow<MasterDataCache<ExternalAppMaster>>(MasterDataCache.Idle)
    override val externalApps: StateFlow<MasterDataCache<ExternalAppMaster>> = _externalApps.asStateFlow()

    private val idolsMutex = Mutex()
    private val groupsMutex = Mutex()
    private val externalAppsMutex = Mutex()

    override suspend fun refreshIdols(force: Boolean, groupName: String?): Result<List<IdolMaster>> =
        idolsMutex.withLock {
            val cached = _idols.value
            if (!force && cached is MasterDataCache.Success && isFresh(cached.fetchedAtMillis)) {
                return@withLock Result.success(cached.items)
            }
            _idols.value = MasterDataCache.Loading
            runCatching {
                val query = buildMap<String, String> {
                    put("limit", "10000")
                    groupName?.let { put("groupName", it) }
                }
                val data = client.get(ApiPaths.LIST_IDOLS, IdolListData.serializer(), query)
                _idols.value = MasterDataCache.Success(data.idols, clock())
                data.idols
            }.onFailure { t ->
                val err = t.toAppError()
                Timber.w(t, "refreshIdols failed")
                _idols.value = MasterDataCache.Failure(err)
            }.recoverCatching { throw it.toAppError() }
        }

    override suspend fun refreshGroups(force: Boolean): Result<List<GroupMaster>> =
        groupsMutex.withLock {
            val cached = _groups.value
            if (!force && cached is MasterDataCache.Success && isFresh(cached.fetchedAtMillis)) {
                return@withLock Result.success(cached.items)
            }
            _groups.value = MasterDataCache.Loading
            runCatching {
                val data = client.get(
                    ApiPaths.LIST_GROUPS,
                    GroupListData.serializer(),
                    mapOf("limit" to "1000"),
                )
                _groups.value = MasterDataCache.Success(data.groups, clock())
                data.groups
            }.onFailure { t ->
                val err = t.toAppError()
                Timber.w(t, "refreshGroups failed")
                _groups.value = MasterDataCache.Failure(err)
            }.recoverCatching { throw it.toAppError() }
        }

    override suspend fun refreshExternalApps(force: Boolean): Result<List<ExternalAppMaster>> =
        externalAppsMutex.withLock {
            val cached = _externalApps.value
            if (!force && cached is MasterDataCache.Success && isFresh(cached.fetchedAtMillis)) {
                return@withLock Result.success(cached.items)
            }
            _externalApps.value = MasterDataCache.Loading
            runCatching {
                val data = client.get(ApiPaths.LIST_EXTERNAL_APPS, ExternalAppListData.serializer())
                _externalApps.value = MasterDataCache.Success(data.apps, clock())
                data.apps
            }.onFailure { t ->
                val err = t.toAppError()
                Timber.w(t, "refreshExternalApps failed")
                _externalApps.value = MasterDataCache.Failure(err)
            }.recoverCatching { throw it.toAppError() }
        }

    private fun isFresh(fetchedAtMillis: Long): Boolean =
        clock() - fetchedAtMillis < CACHE_TTL_MILLIS
}
