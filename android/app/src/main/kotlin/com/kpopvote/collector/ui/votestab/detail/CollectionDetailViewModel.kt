package com.kpopvote.collector.ui.votestab.detail

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.AddSingleTaskData
import com.kpopvote.collector.data.model.AddToTasksData
import com.kpopvote.collector.data.model.CollectionDetailData
import com.kpopvote.collector.data.repository.CollectionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CollectionDetailUiState(
    val isLoading: Boolean = false,
    val detail: CollectionDetailData? = null,
    val isToggleSaving: Boolean = false,
    val isAdding: Boolean = false,
    val isSharing: Boolean = false,
    val isDeleting: Boolean = false,
    val addAllResult: AddToTasksData? = null,
    val addSingleResult: AddSingleTaskData? = null,
    val error: AppError? = null,
)

/** One-shot events for navigation/snackbar — consumed once by the screen. */
sealed interface CollectionDetailEvent {
    data class ShareSuccess(val postId: String) : CollectionDetailEvent
    data object Deleted : CollectionDetailEvent
}

/**
 * Drives [CollectionDetailScreen]. Reads `collectionId` from [SavedStateHandle] (type-safe
 * via [Route.CollectionDetail]). Save toggle is optimistic with rollback on failure.
 * Owner-only actions (`delete`) are gated via `detail.isOwner`.
 */
@HiltViewModel
class CollectionDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repo: CollectionRepository,
) : ViewModel() {

    private val collectionId: String = requireNotNull(savedStateHandle.get<String>(ARG_COLLECTION_ID)) {
        "collectionId argument missing from SavedStateHandle"
    }

    private val _state = MutableStateFlow(CollectionDetailUiState())
    val state: StateFlow<CollectionDetailUiState> = _state.asStateFlow()

    private val _events = Channel<CollectionDetailEvent>(Channel.BUFFERED)
    val events = _events.receiveAsFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            val result = repo.getCollectionDetail(collectionId)
            _state.update { prev ->
                prev.copy(
                    isLoading = false,
                    detail = result.getOrNull() ?: prev.detail,
                    error = result.exceptionOrNull() as? AppError,
                )
            }
        }
    }

    /**
     * Optimistic save toggle: flips isSaved + adjusts saveCount immediately, then fires the
     * request. On failure, rolls back to the pre-click snapshot and surfaces an error.
     */
    fun toggleSave() {
        val current = _state.value.detail ?: return
        if (_state.value.isToggleSaving) return

        val prevSaved = current.isSaved
        val prevCount = current.collection.saveCount
        val optimistic = current.copy(
            isSaved = !prevSaved,
            collection = current.collection.copy(
                saveCount = (prevCount + if (prevSaved) -1 else 1).coerceAtLeast(0),
            ),
        )
        _state.update { it.copy(detail = optimistic, isToggleSaving = true) }

        viewModelScope.launch {
            val result = repo.toggleSaveCollection(collectionId)
            _state.update { prev ->
                val data = result.getOrNull()
                if (data != null && prev.detail != null) {
                    prev.copy(
                        isToggleSaving = false,
                        detail = prev.detail.copy(
                            isSaved = data.saved,
                            collection = prev.detail.collection.copy(saveCount = data.saveCount),
                        ),
                    )
                } else {
                    // Rollback to pre-click snapshot
                    prev.copy(
                        isToggleSaving = false,
                        detail = prev.detail?.copy(
                            isSaved = prevSaved,
                            collection = prev.detail.collection.copy(saveCount = prevCount),
                        ),
                        error = result.exceptionOrNull() as? AppError,
                    )
                }
            }
        }
    }

    fun addAllToTasks() {
        if (_state.value.isAdding) return
        viewModelScope.launch {
            _state.update { it.copy(isAdding = true, error = null) }
            val result = repo.addCollectionToTasks(collectionId)
            _state.update { prev ->
                prev.copy(
                    isAdding = false,
                    addAllResult = result.getOrNull(),
                    error = result.exceptionOrNull() as? AppError,
                )
            }
        }
    }

    fun addSingleTask(taskId: String) {
        if (_state.value.isAdding) return
        viewModelScope.launch {
            _state.update { it.copy(isAdding = true, error = null) }
            val result = repo.addSingleTaskToTasks(collectionId, taskId)
            _state.update { prev ->
                prev.copy(
                    isAdding = false,
                    addSingleResult = result.getOrNull(),
                    error = result.exceptionOrNull() as? AppError,
                )
            }
        }
    }

    fun share(biasIds: List<String>, text: String) {
        if (_state.value.isSharing) return
        if (biasIds.isEmpty()) return
        viewModelScope.launch {
            _state.update { it.copy(isSharing = true, error = null) }
            val result = repo.shareCollectionToCommunity(collectionId, biasIds, text)
            _state.update { it.copy(isSharing = false, error = result.exceptionOrNull() as? AppError) }
            result.getOrNull()?.let { _events.send(CollectionDetailEvent.ShareSuccess(it.postId)) }
        }
    }

    fun delete() {
        val current = _state.value.detail ?: return
        if (!current.isOwner) {
            _state.update { it.copy(error = AppError.Collection.NotOwner) }
            return
        }
        if (_state.value.isDeleting) return

        viewModelScope.launch {
            _state.update { it.copy(isDeleting = true, error = null) }
            val result = repo.deleteCollection(collectionId)
            if (result.isSuccess) {
                _events.send(CollectionDetailEvent.Deleted)
                _state.update { it.copy(isDeleting = false) }
            } else {
                _state.update {
                    it.copy(isDeleting = false, error = result.exceptionOrNull() as? AppError)
                }
            }
        }
    }

    fun clearError() = _state.update { it.copy(error = null) }
    fun clearAddResults() =
        _state.update { it.copy(addAllResult = null, addSingleResult = null) }

    internal companion object {
        internal const val ARG_COLLECTION_ID = "collectionId"
    }
}
