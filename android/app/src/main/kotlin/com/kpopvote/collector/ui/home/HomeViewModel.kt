package com.kpopvote.collector.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.BiasSettings
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.data.repository.BiasRepository
import com.kpopvote.collector.data.repository.TaskRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeUiState(
    val activeTasks: List<VoteTask> = emptyList(),
    val bias: List<BiasSettings> = emptyList(),
    val isLoading: Boolean = false,
    val error: AppError? = null,
    val completingTaskIds: Set<String> = emptySet(),
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val taskRepository: TaskRepository,
    private val biasRepository: BiasRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(HomeUiState())
    val state: StateFlow<HomeUiState> = _state.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            val tasks = taskRepository.getActiveTasks()
            val bias = biasRepository.getBias()
            _state.update {
                it.copy(
                    isLoading = false,
                    activeTasks = tasks.getOrElse { emptyList() },
                    bias = bias.getOrElse { emptyList() },
                    error = tasks.exceptionOrNull()?.let { e -> e as? AppError }
                        ?: bias.exceptionOrNull()?.let { e -> e as? AppError },
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
