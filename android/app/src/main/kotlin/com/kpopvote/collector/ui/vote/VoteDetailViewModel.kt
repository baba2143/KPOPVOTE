package com.kpopvote.collector.ui.vote

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.InAppVote
import com.kpopvote.collector.data.model.VoteExecuteResult
import com.kpopvote.collector.data.repository.VoteRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class VoteDetailUiState(
    val isLoading: Boolean = false,
    val vote: InAppVote? = null,
    val selectedChoiceId: String? = null,
    val voteCount: Int = 1,
    val isVoting: Boolean = false,
    val error: AppError? = null,
    val lastResult: VoteExecuteResult? = null,
) {
    val canVote: Boolean
        get() = vote != null &&
            selectedChoiceId != null &&
            voteCount in 1..maxVotes &&
            !isVoting

    val maxVotes: Int
        get() = (vote?.userDailyRemaining ?: Int.MAX_VALUE).coerceAtLeast(1)
}

/** One-shot events emitted from [VoteDetailViewModel] to the UI. */
sealed class VoteEvent {
    data class Success(val result: VoteExecuteResult) : VoteEvent()
}

/**
 * Holds state for `VoteDetailScreen`. Mirrors iOS `VoteDetailViewModel`.
 * `voteId` comes via SavedStateHandle (route argument).
 */
@HiltViewModel
class VoteDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val voteRepository: VoteRepository,
) : ViewModel() {

    private val voteId: String = requireNotNull(savedStateHandle.get<String>(ARG_VOTE_ID)) {
        "voteId argument missing from SavedStateHandle"
    }

    private val _state = MutableStateFlow(VoteDetailUiState())
    val state: StateFlow<VoteDetailUiState> = _state.asStateFlow()

    private val _events = Channel<VoteEvent>(Channel.BUFFERED)
    val events: Flow<VoteEvent> = _events.receiveAsFlow()

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            val result = voteRepository.fetchVoteDetail(voteId)
            _state.update {
                val vote = result.getOrNull()
                it.copy(
                    isLoading = false,
                    vote = vote,
                    selectedChoiceId = it.selectedChoiceId?.takeIf { id ->
                        vote?.choices?.any { c -> c.choiceId == id } == true
                    },
                    voteCount = it.voteCount.coerceAtMost(
                        (vote?.userDailyRemaining ?: Int.MAX_VALUE).coerceAtLeast(1),
                    ),
                    error = result.exceptionOrNull() as? AppError,
                )
            }
        }
    }

    fun selectChoice(choiceId: String) {
        _state.update { it.copy(selectedChoiceId = choiceId) }
    }

    fun incVoteCount() {
        _state.update {
            it.copy(voteCount = (it.voteCount + 1).coerceAtMost(it.maxVotes))
        }
    }

    fun decVoteCount() {
        _state.update { it.copy(voteCount = (it.voteCount - 1).coerceAtLeast(1)) }
    }

    fun confirmVote() {
        val current = _state.value
        val choiceId = current.selectedChoiceId ?: return
        if (current.isVoting) return

        viewModelScope.launch {
            _state.update { it.copy(isVoting = true, error = null) }
            val result = voteRepository.executeVote(
                voteId = voteId,
                choiceId = choiceId,
                voteCount = current.voteCount,
            )
            result.onSuccess { executeResult ->
                _state.update { it.copy(isVoting = false, lastResult = executeResult) }
                _events.trySend(VoteEvent.Success(executeResult))
                load()
            }.onFailure { err ->
                _state.update { it.copy(isVoting = false, error = err as? AppError) }
            }
        }
    }

    fun dismissError() {
        _state.update { it.copy(error = null) }
    }

    fun clearLastResult() {
        _state.update { it.copy(lastResult = null) }
    }

    companion object {
        const val ARG_VOTE_ID = "voteId"
    }
}
