package com.kpopvote.collector.ui.vote

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.VoteRanking
import com.kpopvote.collector.data.repository.VoteRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class VoteRankingUiState(
    val isLoading: Boolean = false,
    val ranking: VoteRanking? = null,
    val error: AppError? = null,
)

/**
 * Ranking view for a single in-app vote. `voteId` comes via SavedStateHandle.
 * Mirrors iOS `VoteRankingViewModel`; pull-to-refresh wires to [refresh].
 */
@HiltViewModel
class VoteRankingViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val voteRepository: VoteRepository,
) : ViewModel() {

    private val voteId: String = requireNotNull(savedStateHandle.get<String>(ARG_VOTE_ID)) {
        "voteId argument missing from SavedStateHandle"
    }

    private val _state = MutableStateFlow(VoteRankingUiState())
    val state: StateFlow<VoteRankingUiState> = _state.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            val result = voteRepository.fetchRanking(voteId)
            _state.update {
                it.copy(
                    isLoading = false,
                    ranking = result.getOrNull() ?: it.ranking,
                    error = result.exceptionOrNull() as? AppError,
                )
            }
        }
    }

    fun clearError() {
        _state.update { it.copy(error = null) }
    }

    companion object {
        const val ARG_VOTE_ID = "voteId"
    }
}
