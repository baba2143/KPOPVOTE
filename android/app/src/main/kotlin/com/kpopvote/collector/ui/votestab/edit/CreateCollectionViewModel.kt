package com.kpopvote.collector.ui.votestab.edit

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.CollectionVisibility
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.data.repository.CollectionCoverImageRepository
import com.kpopvote.collector.data.repository.CollectionInput
import com.kpopvote.collector.data.repository.CollectionRepository
import com.kpopvote.collector.data.repository.TaskRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class CollectionFormMode { CREATE, EDIT }

enum class CollectionFormError {
    TITLE_REQUIRED,
    TITLE_TOO_LONG,
    DESCRIPTION_TOO_LONG,
    TAGS_TOO_MANY,
    TAGS_DUPLICATE,
    TASKS_REQUIRED,
    TASKS_TOO_MANY,
}

/**
 * Form state for create/edit collection screen. Uses [ByteArray] for the picked cover image
 * (mirrors [AddEditTaskViewModel]), uploaded to Firebase Storage on submit.
 *
 * `taskIds` preserves the user-selected order — the server persists `orderIndex` from list position.
 */
data class CollectionFormUiState(
    val mode: CollectionFormMode = CollectionFormMode.CREATE,
    val collectionId: String? = null,
    val title: String = "",
    val description: String = "",
    val tags: List<String> = emptyList(),
    val visibility: CollectionVisibility = CollectionVisibility.PUBLIC,
    val taskIds: List<String> = emptyList(),
    val availableTasks: List<VoteTask> = emptyList(),
    val coverImageBytes: ByteArray? = null,
    val coverImageRemoteUrl: String? = null,
    val isLoading: Boolean = false,
    val isSubmitting: Boolean = false,
    val validationErrors: Set<CollectionFormError> = emptySet(),
    val error: AppError? = null,
    val submitted: Boolean = false,
) {
    val selectedTasks: List<VoteTask>
        get() = taskIds.mapNotNull { id -> availableTasks.firstOrNull { it.id == id } }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is CollectionFormUiState) return false
        if (mode != other.mode) return false
        if (collectionId != other.collectionId) return false
        if (title != other.title) return false
        if (description != other.description) return false
        if (tags != other.tags) return false
        if (visibility != other.visibility) return false
        if (taskIds != other.taskIds) return false
        if (availableTasks != other.availableTasks) return false
        if (coverImageBytes != null) {
            if (other.coverImageBytes == null) return false
            if (!coverImageBytes.contentEquals(other.coverImageBytes)) return false
        } else if (other.coverImageBytes != null) return false
        if (coverImageRemoteUrl != other.coverImageRemoteUrl) return false
        if (isLoading != other.isLoading) return false
        if (isSubmitting != other.isSubmitting) return false
        if (validationErrors != other.validationErrors) return false
        if (error != other.error) return false
        if (submitted != other.submitted) return false
        return true
    }

    override fun hashCode(): Int {
        var result = mode.hashCode()
        result = 31 * result + (collectionId?.hashCode() ?: 0)
        result = 31 * result + title.hashCode()
        result = 31 * result + description.hashCode()
        result = 31 * result + tags.hashCode()
        result = 31 * result + visibility.hashCode()
        result = 31 * result + taskIds.hashCode()
        result = 31 * result + availableTasks.hashCode()
        result = 31 * result + (coverImageBytes?.contentHashCode() ?: 0)
        result = 31 * result + (coverImageRemoteUrl?.hashCode() ?: 0)
        result = 31 * result + isLoading.hashCode()
        result = 31 * result + isSubmitting.hashCode()
        result = 31 * result + validationErrors.hashCode()
        result = 31 * result + (error?.hashCode() ?: 0)
        result = 31 * result + submitted.hashCode()
        return result
    }
}

/**
 * Powers [CreateCollectionScreen] for both create and edit flows.
 * Mode is determined by `collectionId` presence in [SavedStateHandle] — matches iOS
 * `CollectionFormViewModel` and the existing [AddEditTaskViewModel] approach.
 *
 * Validation (iOS parity):
 *  - title: 1..50 chars trimmed
 *  - description: 0..500 chars
 *  - tags: <=10 entries, unique case-insensitive
 *  - tasks: 1..50
 */
@HiltViewModel
class CreateCollectionViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val collectionRepository: CollectionRepository,
    private val taskRepository: TaskRepository,
    private val coverImageRepository: CollectionCoverImageRepository,
) : ViewModel() {

    private val collectionId: String? = savedStateHandle.get<String>(ARG_COLLECTION_ID)

    private val _state = MutableStateFlow(
        CollectionFormUiState(
            mode = if (collectionId == null) CollectionFormMode.CREATE else CollectionFormMode.EDIT,
            collectionId = collectionId,
        ).revalidate(),
    )
    val state: StateFlow<CollectionFormUiState> = _state.asStateFlow()

    init {
        loadAvailableTasks()
        if (collectionId != null) {
            loadExistingCollection(collectionId)
        }
    }

    private fun loadAvailableTasks() {
        viewModelScope.launch {
            val result = taskRepository.getUserTasks()
            result.onSuccess { tasks ->
                _state.update { it.copy(availableTasks = tasks) }
            }
        }
    }

    private fun loadExistingCollection(id: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            val result = collectionRepository.getCollectionDetail(id)
            result.onSuccess { detail ->
                val c = detail.collection
                _state.update {
                    it.copy(
                        isLoading = false,
                        title = c.title,
                        description = c.description,
                        tags = c.tags,
                        visibility = c.visibility,
                        taskIds = c.tasks.sortedBy { t -> t.orderIndex }.map { t -> t.taskId },
                        coverImageRemoteUrl = c.coverImage,
                    )
                }
            }.onFailure { err ->
                _state.update { it.copy(isLoading = false, error = err as? AppError) }
            }
        }
    }

    fun onTitleChange(value: String) {
        _state.update { it.copy(title = value).revalidate() }
    }

    fun onDescriptionChange(value: String) {
        _state.update { it.copy(description = value).revalidate() }
    }

    fun onVisibilityChange(value: CollectionVisibility) {
        _state.update { it.copy(visibility = value) }
    }

    /**
     * Add a tag (trimmed). Duplicates (case-insensitive) and empty strings are dropped silently.
     * Validation errors surface via [CollectionFormUiState.validationErrors] after [revalidate].
     */
    fun addTag(raw: String) {
        val tag = raw.trim()
        if (tag.isEmpty()) return
        _state.update { current ->
            if (current.tags.any { it.equals(tag, ignoreCase = true) }) return@update current
            current.copy(tags = current.tags + tag).revalidate()
        }
    }

    fun removeTag(tag: String) {
        _state.update { current ->
            current.copy(tags = current.tags.filterNot { it == tag }).revalidate()
        }
    }

    /** Toggle a task into/out of the selection. Preserves order of insertion. */
    fun toggleTask(taskId: String) {
        _state.update { current ->
            val next = if (current.taskIds.contains(taskId)) {
                current.taskIds - taskId
            } else {
                current.taskIds + taskId
            }
            current.copy(taskIds = next).revalidate()
        }
    }

    fun moveTaskUp(taskId: String) = moveTask(taskId, offset = -1)
    fun moveTaskDown(taskId: String) = moveTask(taskId, offset = +1)

    private fun moveTask(taskId: String, offset: Int) {
        _state.update { current ->
            val idx = current.taskIds.indexOf(taskId)
            if (idx < 0) return@update current
            val newIdx = (idx + offset).coerceIn(0, current.taskIds.lastIndex)
            if (newIdx == idx) return@update current
            val next = current.taskIds.toMutableList().apply {
                removeAt(idx)
                add(newIdx, taskId)
            }
            current.copy(taskIds = next)
        }
    }

    fun onCoverImagePicked(bytes: ByteArray) {
        _state.update { it.copy(coverImageBytes = bytes) }
    }

    fun onClearCoverImage() {
        _state.update { it.copy(coverImageBytes = null, coverImageRemoteUrl = null) }
    }

    fun clearError() = _state.update { it.copy(error = null) }

    fun submit() {
        val current = _state.value.revalidate()
        _state.value = current
        if (current.validationErrors.isNotEmpty() || current.isSubmitting) return

        viewModelScope.launch {
            _state.update { it.copy(isSubmitting = true, error = null) }

            // Upload cover image if a new one was picked
            var coverUrl: String? = current.coverImageRemoteUrl
            if (current.coverImageBytes != null) {
                val uploadResult = coverImageRepository.upload(current.coverImageBytes)
                val url = uploadResult.getOrElse {
                    _state.update { s -> s.copy(isSubmitting = false, error = it as? AppError) }
                    return@launch
                }
                coverUrl = url
            }

            val input = CollectionInput(
                title = current.title.trim(),
                description = current.description.trim(),
                coverImage = coverUrl,
                tags = current.tags,
                taskIds = current.taskIds,
                visibility = current.visibility.wireValue,
            )

            val result = if (current.mode == CollectionFormMode.EDIT && current.collectionId != null) {
                collectionRepository.updateCollection(current.collectionId, input)
            } else {
                collectionRepository.createCollection(input)
            }

            result.onSuccess {
                _state.update { it.copy(isSubmitting = false, submitted = true) }
            }.onFailure { err ->
                _state.update { it.copy(isSubmitting = false, error = err as? AppError) }
            }
        }
    }

    internal companion object {
        internal const val ARG_COLLECTION_ID = "collectionId"
        internal const val TITLE_MAX = 50
        internal const val DESCRIPTION_MAX = 500
        internal const val TAGS_MAX = 10
        internal const val TASKS_MAX = 50
    }
}

private fun CollectionFormUiState.revalidate(): CollectionFormUiState {
    val errors = buildSet {
        val trimmedTitle = title.trim()
        if (trimmedTitle.isEmpty()) add(CollectionFormError.TITLE_REQUIRED)
        if (trimmedTitle.length > CreateCollectionViewModel.TITLE_MAX) add(CollectionFormError.TITLE_TOO_LONG)
        if (description.length > CreateCollectionViewModel.DESCRIPTION_MAX) add(CollectionFormError.DESCRIPTION_TOO_LONG)
        if (tags.size > CreateCollectionViewModel.TAGS_MAX) add(CollectionFormError.TAGS_TOO_MANY)
        if (tags.map { it.lowercase() }.toSet().size != tags.size) add(CollectionFormError.TAGS_DUPLICATE)
        if (taskIds.isEmpty()) add(CollectionFormError.TASKS_REQUIRED)
        if (taskIds.size > CreateCollectionViewModel.TASKS_MAX) add(CollectionFormError.TASKS_TOO_MANY)
    }
    return copy(validationErrors = errors)
}

private val CollectionVisibility.wireValue: String
    get() = when (this) {
        CollectionVisibility.PUBLIC -> "public"
        CollectionVisibility.FOLLOWERS -> "followers"
        CollectionVisibility.PRIVATE -> "private"
    }
