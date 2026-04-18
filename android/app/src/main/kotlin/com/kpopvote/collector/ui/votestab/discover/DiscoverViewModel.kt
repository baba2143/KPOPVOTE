package com.kpopvote.collector.ui.votestab.discover

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.CollectionSortOption
import com.kpopvote.collector.data.model.VoteCollection
import com.kpopvote.collector.data.repository.CollectionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DiscoverUiState(
    val isLoading: Boolean = false,
    val isPaginating: Boolean = false,
    val items: List<VoteCollection> = emptyList(),
    val selectedTags: Set<String> = emptySet(),
    val sortOption: CollectionSortOption = CollectionSortOption.LATEST,
    val searchQuery: String = "",
    val currentPage: Int = 1,
    val hasNext: Boolean = false,
    val error: AppError? = null,
)

/**
 * Browse + search screen for public collections. Search uses a 350ms debounce;
 * list vs search endpoints switch based on [DiscoverUiState.searchQuery].blank()`ness.
 * Pagination: `loadNextPage()` appends when [DiscoverUiState.hasNext].
 */
@OptIn(FlowPreview::class)
@HiltViewModel
class DiscoverViewModel @Inject constructor(
    private val collectionRepository: CollectionRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(DiscoverUiState())
    val state: StateFlow<DiscoverUiState> = _state.asStateFlow()

    private val queryFlow = MutableStateFlow("")

    init {
        queryFlow
            .drop(1) // skip initial empty emission; init { refresh() } handles first page
            .debounce(SEARCH_DEBOUNCE_MS)
            .distinctUntilChanged()
            .onEach { q ->
                _state.update { it.copy(searchQuery = q, currentPage = 1, items = emptyList()) }
                fetch(page = 1)
            }
            .launchIn(viewModelScope)
        refresh()
    }

    fun onSearchChanged(query: String) {
        queryFlow.value = query
    }

    fun onTagToggle(tag: String) {
        val current = _state.value.selectedTags
        val next = if (current.contains(tag)) current - tag else current + tag
        _state.update { it.copy(selectedTags = next, currentPage = 1, items = emptyList()) }
        viewModelScope.launch { fetch(page = 1) }
    }

    fun onSortChange(option: CollectionSortOption) {
        if (_state.value.sortOption == option) return
        _state.update { it.copy(sortOption = option, currentPage = 1, items = emptyList()) }
        viewModelScope.launch { fetch(page = 1) }
    }

    fun refresh() {
        _state.update { it.copy(currentPage = 1, items = emptyList()) }
        viewModelScope.launch { fetch(page = 1) }
    }

    fun loadNextPage() {
        val s = _state.value
        if (!s.hasNext || s.isPaginating || s.isLoading) return
        viewModelScope.launch { fetch(page = s.currentPage + 1, append = true) }
    }

    fun clearError() {
        _state.update { it.copy(error = null) }
    }

    private suspend fun fetch(page: Int, append: Boolean = false) {
        val s = _state.value
        _state.update {
            if (append) it.copy(isPaginating = true, error = null)
            else it.copy(isLoading = true, error = null)
        }
        val tags = s.selectedTags.takeIf { it.isNotEmpty() }?.toList()
        val query = s.searchQuery.trim()
        val result = if (query.isBlank()) {
            collectionRepository.getCollections(page = page, sortBy = s.sortOption, tags = tags)
        } else {
            val sortForSearch = if (s.sortOption == CollectionSortOption.LATEST) {
                CollectionSortOption.RELEVANCE
            } else {
                s.sortOption
            }
            collectionRepository.searchCollections(query = query, page = page, sortBy = sortForSearch, tags = tags)
        }
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

    private companion object {
        const val SEARCH_DEBOUNCE_MS = 350L
    }
}
