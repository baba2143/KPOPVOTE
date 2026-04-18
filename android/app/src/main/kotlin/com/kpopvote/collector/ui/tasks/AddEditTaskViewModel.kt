package com.kpopvote.collector.ui.tasks

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.analytics.AnalyticsLogger
import com.kpopvote.collector.core.analytics.EventParams
import com.kpopvote.collector.core.analytics.Events
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.util.IsoDate
import com.kpopvote.collector.data.model.CoverImageSource
import com.kpopvote.collector.data.model.ExternalAppMaster
import com.kpopvote.collector.data.model.IdolMaster
import com.kpopvote.collector.data.model.MasterDataCache
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.data.model.deadlineMillis
import com.kpopvote.collector.data.repository.BiasRepository
import com.kpopvote.collector.data.repository.MasterDataRepository
import com.kpopvote.collector.data.repository.TaskCoverImageRepository
import com.kpopvote.collector.data.repository.TaskInput
import com.kpopvote.collector.data.repository.TaskRepository
import com.kpopvote.collector.navigation.Route
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * Registration / edit screen state. iOS parity: `TaskRegistrationViewModel`.
 *
 * Edit mode is triggered when [Route.AddTask.taskId] is non-null. The existing
 * task is loaded once via [TaskRepository.getUserTasks] (no dedicated `getTaskById`
 * endpoint on the backend — matches iOS which also filters the list).
 */
data class AddEditTaskUiState(
    val taskId: String? = null,
    val isEditMode: Boolean = false,
    val title: String = "",
    val url: String = "",
    val deadlineMillis: Long? = null,
    val selectedMemberIds: List<String> = emptyList(),
    val externalApps: List<ExternalAppMaster> = emptyList(),
    val selectedAppId: String? = null,
    val coverImageBytes: ByteArray? = null,
    val coverImageUrl: String? = null,
    val coverImageSource: CoverImageSource? = null,
    val allIdols: List<IdolMaster> = emptyList(),
    val isLoading: Boolean = false,
    val isSubmitting: Boolean = false,
    val error: AppError? = null,
    val submitted: Boolean = false,
) {
    val selectedApp: ExternalAppMaster?
        get() = externalApps.firstOrNull { it.id == selectedAppId }

    val selectedMemberNames: List<String>
        get() = selectedMemberIds.mapNotNull { id -> allIdols.firstOrNull { it.id == id }?.name }

    val isFormValid: Boolean
        get() = title.isNotBlank() &&
            isUrlValid(url) &&
            (deadlineMillis ?: 0L) > System.currentTimeMillis()

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is AddEditTaskUiState) return false
        if (taskId != other.taskId) return false
        if (isEditMode != other.isEditMode) return false
        if (title != other.title) return false
        if (url != other.url) return false
        if (deadlineMillis != other.deadlineMillis) return false
        if (selectedMemberIds != other.selectedMemberIds) return false
        if (externalApps != other.externalApps) return false
        if (selectedAppId != other.selectedAppId) return false
        if (coverImageBytes != null) {
            if (other.coverImageBytes == null) return false
            if (!coverImageBytes.contentEquals(other.coverImageBytes)) return false
        } else if (other.coverImageBytes != null) return false
        if (coverImageUrl != other.coverImageUrl) return false
        if (coverImageSource != other.coverImageSource) return false
        if (allIdols != other.allIdols) return false
        if (isLoading != other.isLoading) return false
        if (isSubmitting != other.isSubmitting) return false
        if (error != other.error) return false
        if (submitted != other.submitted) return false
        return true
    }

    override fun hashCode(): Int {
        var result = taskId?.hashCode() ?: 0
        result = 31 * result + isEditMode.hashCode()
        result = 31 * result + title.hashCode()
        result = 31 * result + url.hashCode()
        result = 31 * result + (deadlineMillis?.hashCode() ?: 0)
        result = 31 * result + selectedMemberIds.hashCode()
        result = 31 * result + externalApps.hashCode()
        result = 31 * result + (selectedAppId?.hashCode() ?: 0)
        result = 31 * result + (coverImageBytes?.contentHashCode() ?: 0)
        result = 31 * result + (coverImageUrl?.hashCode() ?: 0)
        result = 31 * result + (coverImageSource?.hashCode() ?: 0)
        result = 31 * result + allIdols.hashCode()
        result = 31 * result + isLoading.hashCode()
        result = 31 * result + isSubmitting.hashCode()
        result = 31 * result + (error?.hashCode() ?: 0)
        result = 31 * result + submitted.hashCode()
        return result
    }

    companion object {
        fun isUrlValid(url: String): Boolean {
            if (url.isBlank()) return false
            return url.startsWith("http://", ignoreCase = true) ||
                url.startsWith("https://", ignoreCase = true)
        }
    }
}

@HiltViewModel
class AddEditTaskViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val taskRepository: TaskRepository,
    private val biasRepository: BiasRepository,
    private val masterDataRepository: MasterDataRepository,
    private val coverImageRepository: TaskCoverImageRepository,
    private val analyticsLogger: AnalyticsLogger,
) : ViewModel() {

    private val taskId: String? = savedStateHandle.get<String>("taskId")

    private val _state = MutableStateFlow(
        AddEditTaskUiState(taskId = taskId, isEditMode = taskId != null),
    )
    val state: StateFlow<AddEditTaskUiState> = _state.asStateFlow()

    init {
        loadMasters()
        if (taskId == null) {
            // 新規作成時は Bias から初期メンバーを入れる（iOS parity）
            seedDefaultMembersFromBias()
        } else {
            loadExistingTask(taskId)
        }
    }

    private fun loadMasters() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            masterDataRepository.refreshExternalApps()
            masterDataRepository.refreshIdols()
            masterDataRepository.refreshGroups()
            val apps = (masterDataRepository.externalApps.value as? MasterDataCache.Success)?.items
                ?: emptyList()
            val idols = (masterDataRepository.idols.value as? MasterDataCache.Success)?.items
                ?: emptyList()
            _state.update {
                it.copy(externalApps = apps, allIdols = idols, isLoading = false)
            }
        }
    }

    private fun seedDefaultMembersFromBias() {
        viewModelScope.launch {
            val bias = biasRepository.getBias().getOrElse { return@launch }
            val ids = bias.flatMap { it.memberIds }.distinct()
            if (ids.isNotEmpty()) {
                _state.update { it.copy(selectedMemberIds = ids) }
            }
        }
    }

    private fun loadExistingTask(id: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            val tasks = taskRepository.getUserTasks().getOrElse {
                _state.update { s -> s.copy(isLoading = false, error = it as? AppError) }
                return@launch
            }
            val task = tasks.firstOrNull { it.id == id }
            if (task == null) {
                _state.update {
                    it.copy(
                        isLoading = false,
                        error = AppError.Validation("タスクが見つかりません"),
                    )
                }
                return@launch
            }
            _state.update { it.presetFromTask(task) }
        }
    }

    fun onTitleChange(value: String) {
        _state.update { it.copy(title = value) }
    }

    fun onUrlChange(value: String) {
        _state.update { it.copy(url = value) }
    }

    fun onDeadlineChange(millis: Long?) {
        _state.update { it.copy(deadlineMillis = millis) }
    }

    fun onExternalAppSelected(appId: String?) {
        _state.update { current ->
            val app = current.externalApps.firstOrNull { it.id == appId }
            current.copy(
                selectedAppId = appId,
                coverImageUrl = app?.defaultCoverImageUrl
                    ?: current.coverImageUrl.takeIf { current.coverImageSource == CoverImageSource.USER_UPLOAD },
                coverImageSource = when {
                    app?.defaultCoverImageUrl != null -> CoverImageSource.EXTERNAL_APP
                    current.coverImageSource == CoverImageSource.USER_UPLOAD -> CoverImageSource.USER_UPLOAD
                    else -> null
                },
            )
        }
    }

    fun onSelectedMembersChange(memberIds: List<String>) {
        _state.update { it.copy(selectedMemberIds = memberIds) }
    }

    fun onCoverImagePicked(bytes: ByteArray) {
        _state.update {
            it.copy(
                coverImageBytes = bytes,
                coverImageSource = CoverImageSource.USER_UPLOAD,
                // プレビューはローカル bitmap、URL はアップロード後にセット
                coverImageUrl = null,
            )
        }
    }

    fun onClearCoverImage() {
        _state.update {
            it.copy(
                coverImageBytes = null,
                coverImageUrl = null,
                coverImageSource = null,
            )
        }
    }

    fun clearError() {
        _state.update { it.copy(error = null) }
    }

    fun submit() {
        val current = _state.value
        if (!current.isFormValid || current.isSubmitting) return
        val deadline = current.deadlineMillis ?: return

        viewModelScope.launch {
            _state.update { it.copy(isSubmitting = true, error = null) }

            var coverUrl = current.coverImageUrl
            var coverSource = current.coverImageSource
            if (current.coverImageBytes != null && current.coverImageSource == CoverImageSource.USER_UPLOAD) {
                val uploadResult = coverImageRepository.upload(current.coverImageBytes)
                val url = uploadResult.getOrElse {
                    _state.update { s -> s.copy(isSubmitting = false, error = it as? AppError) }
                    return@launch
                }
                coverUrl = url
                coverSource = CoverImageSource.USER_UPLOAD
            }

            val input = TaskInput(
                title = current.title.trim(),
                url = current.url.trim(),
                deadlineIso = IsoDate.millisToIso(deadline),
                biasIds = current.selectedMemberIds,
                externalAppId = current.selectedAppId,
                coverImage = coverUrl,
                coverImageSource = coverSource,
            )

            val result = if (current.isEditMode && current.taskId != null) {
                taskRepository.updateTask(current.taskId, input)
            } else {
                taskRepository.registerTask(input)
            }

            result.onSuccess { savedTask ->
                val event = if (current.isEditMode) Events.TASK_UPDATED else Events.TASK_CREATED
                analyticsLogger.logEvent(
                    event,
                    mapOf(EventParams.TASK_ID to savedTask.id),
                )
                _state.update { it.copy(isSubmitting = false, submitted = true) }
            }.onFailure { err ->
                _state.update { it.copy(isSubmitting = false, error = err as? AppError) }
            }
        }
    }
}

private fun AddEditTaskUiState.presetFromTask(task: VoteTask): AddEditTaskUiState = copy(
    isLoading = false,
    title = task.title,
    url = task.url,
    deadlineMillis = task.deadlineMillis,
    selectedMemberIds = task.biasIds,
    selectedAppId = task.externalAppId,
    coverImageUrl = task.coverImage,
    coverImageSource = task.coverImageSource,
)
