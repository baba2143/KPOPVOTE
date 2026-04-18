package com.kpopvote.collector.ui.votestab.mine

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.kpopvote.collector.ui.votestab.components.PagedCollectionsList

@Composable
fun MyCollectionsScreen(
    onOpenCollection: (String) -> Unit,
    onCreateCollection: () -> Unit,
    viewModel: MyCollectionsViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    Box(Modifier.fillMaxSize()) {
        PagedCollectionsList(
            items = state.items,
            isLoading = state.isLoading,
            isPaginating = state.isPaginating,
            hasNext = state.hasNext,
            error = state.error,
            emptyMessage = "作成したコレクションはまだありません",
            onRefresh = viewModel::refresh,
            onLoadMore = viewModel::loadNextPage,
            onClearError = viewModel::clearError,
            onOpenCollection = onOpenCollection,
            modifier = Modifier.fillMaxSize(),
        )
        ExtendedFloatingActionButton(
            onClick = onCreateCollection,
            icon = { Icon(Icons.Filled.Add, contentDescription = null) },
            text = { Text("新規作成") },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp),
        )
    }
}
