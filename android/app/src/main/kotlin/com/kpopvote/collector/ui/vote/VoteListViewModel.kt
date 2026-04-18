package com.kpopvote.collector.ui.vote

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.InAppVote
import com.kpopvote.collector.data.model.VoteStatus
import com.kpopvote.collector.data.repository.VoteRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class VoteListUiState(
    val isLoading: Boolean = false,
    val votes: List<InAppVote> = emptyList(),
    val statusFilter: VoteStatus? = null,
    val error: AppError? = null,
)

/**
 * Drives the full in-app vote list screen (entry point: HOME "すべての投票").
 * Mirrors iOS `VoteListViewModel`.
 */
@HiltViewModel
class VoteListViewModel @Inject constructor(
    private val voteRepository: VoteRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(VoteListUiState())
    val state: StateFlow<VoteListUiState> = _state.asStateFlow()

    init {
        refresh()
    }

    fun setStatus(status: VoteStatus?) {
        if (_state.value.statusFilter == status) return
        _state.update { it.copy(statusFilter = status) }
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            val result = voteRepository.fetchVotes(status = _state.value.statusFilter)
            _state.update {
                it.copy(
                    isLoading = false,
                    votes = result.getOrElse { emptyList() },
                    error = result.exceptionOrNull() as? AppError,
                )
            }
        }
    }

    fun clearError() {
        _state.update { it.copy(error = null) }
    }
}
