package com.kpopvote.collector.ui.profile.bias

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.BiasSettings
import com.kpopvote.collector.data.model.GroupMaster
import com.kpopvote.collector.data.model.IdolMaster
import com.kpopvote.collector.data.repository.BiasRepository
import com.kpopvote.collector.data.repository.MasterDataRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class BiasSelectionMode(val label: String) {
    GROUP("グループ"),
    MEMBER("メンバー"),
}

data class BiasSettingsUiState(
    val allGroups: List<GroupMaster> = emptyList(),
    val allIdols: List<IdolMaster> = emptyList(),
    val selectedGroupIds: Set<String> = emptySet(),
    val selectedIdolIds: Set<String> = emptySet(),
    val mode: BiasSelectionMode = BiasSelectionMode.GROUP,
    val searchText: String = "",
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val error: AppError? = null,
    val saved: Boolean = false,
)

@HiltViewModel
class BiasSettingsViewModel @Inject constructor(
    private val masterDataRepository: MasterDataRepository,
    private val biasRepository: BiasRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(BiasSettingsUiState())
    val state: StateFlow<BiasSettingsUiState> = _state.asStateFlow()

    init {
        loadAll()
    }

    private fun loadAll() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            val loadResult = runCatching {
                coroutineScope {
                    val groupsDeferred = async { masterDataRepository.refreshGroups().getOrThrow() }
                    val idolsDeferred = async { masterDataRepository.refreshIdols().getOrThrow() }
                    groupsDeferred.await() to idolsDeferred.await()
                }
            }
            loadResult.onFailure { err ->
                _state.update { it.copy(isLoading = false, error = err as? AppError) }
                return@launch
            }
            val (groups, idols) = loadResult.getOrThrow()
            val current = biasRepository.getBias().getOrElse { emptyList() }

            val selectedGroupIds = mutableSetOf<String>()
            val selectedIdolIds = mutableSetOf<String>()
            current.forEach { setting ->
                if (setting.isGroupLevel) {
                    groups.firstOrNull { it.name == setting.artistName }?.let { selectedGroupIds.add(it.id) }
                } else {
                    selectedIdolIds.addAll(setting.memberIds)
                }
            }

            _state.update {
                it.copy(
                    isLoading = false,
                    allGroups = groups,
                    allIdols = idols,
                    selectedGroupIds = selectedGroupIds,
                    selectedIdolIds = selectedIdolIds,
                )
            }
        }
    }

    fun setMode(mode: BiasSelectionMode) = _state.update { it.copy(mode = mode) }
    fun setSearchText(text: String) = _state.update { it.copy(searchText = text) }

    fun toggleGroup(groupId: String) = _state.update { s ->
        val next = s.selectedGroupIds.toMutableSet().also {
            if (!it.add(groupId)) it.remove(groupId)
        }
        s.copy(selectedGroupIds = next)
    }

    fun toggleIdol(idolId: String) = _state.update { s ->
        val next = s.selectedIdolIds.toMutableSet().also {
            if (!it.add(idolId)) it.remove(idolId)
        }
        s.copy(selectedIdolIds = next)
    }

    fun clearError() = _state.update { it.copy(error = null) }

    fun save() {
        val current = _state.value
        if (current.isSaving) return
        viewModelScope.launch {
            _state.update { it.copy(isSaving = true, error = null) }
            val settings = buildBiasSettings(current)
            biasRepository.setBias(settings)
                .onSuccess {
                    _state.update { it.copy(isSaving = false, saved = true) }
                }
                .onFailure { err ->
                    _state.update { it.copy(isSaving = false, error = err as? AppError) }
                }
        }
    }

    private fun buildBiasSettings(s: BiasSettingsUiState): List<BiasSettings> {
        val list = mutableListOf<BiasSettings>()
        s.allGroups.filter { it.id in s.selectedGroupIds }.forEach { group ->
            list.add(
                BiasSettings(
                    artistId = group.id,
                    artistName = group.name,
                    memberIds = emptyList(),
                    memberNames = emptyList(),
                    isGroupLevel = true,
                )
            )
        }
        val idolsByGroup = s.allIdols.filter { it.id in s.selectedIdolIds }.groupBy { it.groupName }
        idolsByGroup.forEach { (groupName, idols) ->
            list.add(
                BiasSettings(
                    artistId = groupName.lowercase().replace(' ', '_').replace('-', '_'),
                    artistName = groupName,
                    memberIds = idols.map { it.id },
                    memberNames = idols.map { it.name },
                    isGroupLevel = false,
                )
            )
        }
        return list
    }
}
