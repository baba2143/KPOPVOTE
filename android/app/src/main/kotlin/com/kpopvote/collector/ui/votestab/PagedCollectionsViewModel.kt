package com.kpopvote.collector.ui.votestab

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.CollectionsListData
import com.kpopvote.collector.data.model.VoteCollection
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** Paginated list of collections shared between Saved / MyCollections screens. */
data class PagedCollectionsUiState(
    val isLoading: Boolean = false,
    val isPaginating: Boolean = false,
    val items: List<VoteCollection> = emptyList(),
    val currentPage: Int = 1,
    val hasNext: Boolean = false,
    val error: AppError? = null,
)

/**
 * Shared pagination ViewModel for `SavedCollectionsScreen` and `MyCollectionsScreen`.
 * Subclasses supply the backing repo method via [fetchPage].
 */
abstract class PagedCollectionsViewModel : ViewModel() {

    private val _state = MutableStateFlow(PagedCollectionsUiState())
    val state: StateFlow<PagedCollectionsUiState> = _state.asStateFlow()

    init {
        refresh()
    }

    protected abstract suspend fun fetchPage(page: Int): Result<CollectionsListData>

    fun refresh() {
        _state.update { it.copy(currentPage = 1, items = emptyList()) }
        viewModelScope.launch { load(page = 1) }
    }

    fun loadNextPage() {
        val s = _state.value
        if (!s.hasNext || s.isPaginating || s.isLoading) return
        viewModelScope.launch { load(page = s.currentPage + 1, append = true) }
    }

    fun clearError() {
        _state.update { it.copy(error = null) }
    }

    private suspend fun load(page: Int, append: Boolean = false) {
        _state.update {
            if (append) it.copy(isPaginating = true, error = null)
            else it.copy(isLoading = true, error = null)
        }
        val result = fetchPage(page)
        _state.update { prev ->
            val data = result.getOrNull()
            val newItems = data?.collections.orEmpty()
            prev.copy(
                isLoading = false,
                isPaginating = false,
                items = if (append) prev.items + newItems else newItems,
                currentPage = data?.pagination?.currentPage ?: page,
                hasNext = data?.pagination?.hasNext ?: false,
                error = result.exceptionOrNull() as? AppError,
            )
        }
    }
}
