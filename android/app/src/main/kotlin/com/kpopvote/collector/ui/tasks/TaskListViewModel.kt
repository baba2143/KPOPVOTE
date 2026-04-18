package com.kpopvote.collector.ui.tasks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.TaskStatus
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.data.model.deadlineMillis
import com.kpopvote.collector.data.model.isArchived
import com.kpopvote.collector.data.model.isCompleted
import com.kpopvote.collector.data.model.isExpired
import com.kpopvote.collector.data.model.updatedAtMillis
import com.kpopvote.collector.data.repository.TaskRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class TaskListSegment { ACTIVE, ARCHIVE, COMPLETED }

data class TaskListUiState(
    val allTasks: List<VoteTask> = emptyList(),
    val segment: TaskListSegment = TaskListSegment.ACTIVE,
    val isLoading: Boolean = false,
    val error: AppError? = null,
    val pointsGranted: Int? = null,
) {
    private val now: Long get() = System.currentTimeMillis()

    val activeTasks: List<VoteTask>
        get() = allTasks.asSequence()
            .filter { !it.isCompleted && !it.isArchived && !it.isExpired(now) }
            .sortedBy { it.deadlineMillis ?: Long.MAX_VALUE }
            .toList()

    val archivedTasks: List<VoteTask>
        get() = allTasks.asSequence()
            .filter { it.isArchived || (it.isExpired(now) && !it.isCompleted) }
            .sortedByDescending { it.deadlineMillis ?: 0L }
            .toList()

    val completedTasks: List<VoteTask>
        get() = allTasks.asSequence()
            .filter { it.isCompleted }
            .sortedByDescending { it.updatedAtMillis ?: 0L }
            .toList()

    val visibleTasks: List<VoteTask>
        get() = when (segment) {
            TaskListSegment.ACTIVE -> activeTasks
            TaskListSegment.ARCHIVE -> archivedTasks
            TaskListSegment.COMPLETED -> completedTasks
        }
}

@HiltViewModel
class TaskListViewModel @Inject constructor(
    private val taskRepository: TaskRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(TaskListUiState())
    val state: StateFlow<TaskListUiState> = _state.asStateFlow()

    init {
        refresh()
    }

    fun refresh() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            val result = taskRepository.getUserTasks(isCompleted = null)
            _state.update {
                it.copy(
                    isLoading = false,
                    allTasks = result.getOrElse { emptyList() },
                    error = result.exceptionOrNull() as? AppError,
                )
            }
        }
    }

    fun selectSegment(segment: TaskListSegment) {
        _state.update { it.copy(segment = segment) }
    }

    fun completeTask(task: VoteTask) {
        viewModelScope.launch {
            val result = taskRepository.markCompleted(task.id)
            result.onSuccess { granted ->
                _state.update { current ->
                    current.copy(
                        allTasks = current.allTasks.map {
                            if (it.id == task.id) it.copy(status = TaskStatus.COMPLETED) else it
                        },
                        pointsGranted = granted,
                    )
                }
            }.onFailure { err ->
                _state.update { it.copy(error = err as? AppError) }
            }
        }
    }

    fun deleteTask(task: VoteTask) {
        viewModelScope.launch {
            _state.update { current ->
                current.copy(allTasks = current.allTasks.filterNot { it.id == task.id })
            }
            val result = taskRepository.deleteTask(task.id)
            if (result.isFailure) {
                refresh()
                _state.update { it.copy(error = result.exceptionOrNull() as? AppError) }
            }
        }
    }

    fun clearError() { _state.update { it.copy(error = null) } }
    fun clearPointsBadge() { _state.update { it.copy(pointsGranted = null) } }
}
