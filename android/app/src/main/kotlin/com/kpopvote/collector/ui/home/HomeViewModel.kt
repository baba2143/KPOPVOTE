package com.kpopvote.collector.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.BiasSettings
import com.kpopvote.collector.data.model.InAppVote
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.data.repository.BiasRepository
import com.kpopvote.collector.data.repository.TaskRepository
import com.kpopvote.collector.data.repository.VoteRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeUiState(
    val activeTasks: List<VoteTask> = emptyList(),
    val bias: List<BiasSettings> = emptyList(),
    val featuredVotes: List<InAppVote> = emptyList(),
    val isLoading: Boolean = false,
    val error: AppError? = null,
    val completingTaskIds: Set<String> = emptySet(),
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val taskRepository: TaskRepository,
    private val biasRepository: BiasRepository,
    private val voteRepository: VoteRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(HomeUiState())
    val state: StateFlow<HomeUiState> = _state.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }

            // Parallel fetch: tasks + bias + featured votes. Featured failures are swallowed
            // into an empty list so they can't block the active-tasks strip (spec R12).
            val tasksDeferred = async { taskRepository.getActiveTasks() }
            val biasDeferred = async { biasRepository.getBias() }
            val featuredDeferred = async { voteRepository.fetchFeaturedVotes() }

            val tasksResult = tasksDeferred.await()
            val biasResult = biasDeferred.await()
            val featuredResult = featuredDeferred.await()

            _state.update {
                it.copy(
                    isLoading = false,
                    activeTasks = tasksResult.getOrElse { emptyList() },
                    bias = biasResult.getOrElse { emptyList() },
                    featuredVotes = featuredResult.getOrElse { emptyList() },
                    error = tasksResult.exceptionOrNull()?.let { e -> e as? AppError }
                        ?: biasResult.exceptionOrNull()?.let { e -> e as? AppError },
                )
            }
        }
    }

    fun completeTask(taskId: String) {
        viewModelScope.launch {
            _state.update { it.copy(completingTaskIds = it.completingTaskIds + taskId) }
            val result = taskRepository.markCompleted(taskId)
            _state.update { current ->
                val updatedTasks = if (result.isSuccess) {
                    current.activeTasks.filterNot { it.id == taskId }
                } else current.activeTasks
                current.copy(
                    activeTasks = updatedTasks,
                    completingTaskIds = current.completingTaskIds - taskId,
                    error = result.exceptionOrNull() as? AppError,
                )
            }
        }
    }

    fun clearError() {
        _state.update { it.copy(error = null) }
    }
}
