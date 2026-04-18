package com.kpopvote.collector.ui.votestab.saved

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.kpopvote.collector.ui.votestab.components.PagedCollectionsList

@Composable
fun SavedCollectionsScreen(
    onOpenCollection: (String) -> Unit,
    viewModel: SavedCollectionsViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    PagedCollectionsList(
        items = state.items,
        isLoading = state.isLoading,
        isPaginating = state.isPaginating,
        hasNext = state.hasNext,
        error = state.error,
        emptyMessage = "保存したコレクションはまだありません",
        onRefresh = viewModel::refresh,
        onLoadMore = viewModel::loadNextPage,
        onClearError = viewModel::clearError,
        onOpenCollection = onOpenCollection,
        modifier = Modifier.fillMaxSize(),
    )
}
