package com.kpopvote.collector.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.ui.tasks.components.TaskCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onOpenTaskList: () -> Unit,
    onEditTask: (String) -> Unit,
    viewModel: HomeViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("KPOP VOTE", fontWeight = FontWeight.Bold) },
            )
        },
    ) { padding ->
        PullToRefreshBox(
            isRefreshing = state.isLoading,
            onRefresh = viewModel::refresh,
            modifier = Modifier.fillMaxSize().padding(padding),
        ) {
            LazyColumn(
                contentPadding = PaddingValues(vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(24.dp),
                modifier = Modifier.fillMaxSize(),
            ) {
                item { ActiveTasksSection(state.activeTasks, onOpenTaskList, onEditTask, viewModel::completeTask) }
                item { BiasSection(state.bias.map { it.artistName }) }
                item { FeaturedVotesPlaceholder() }

                state.error?.let { err ->
                    item {
                        Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                            Text(
                                text = err.message ?: "エラーが発生しました",
                                color = MaterialTheme.colorScheme.error,
                            )
                        }
                    }
                }
            }

            if (state.isLoading && state.activeTasks.isEmpty()) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
        }
    }
}

@Composable
private fun ActiveTasksSection(
    tasks: List<VoteTask>,
    onOpenTaskList: () -> Unit,
    onEditTask: (String) -> Unit,
    onComplete: (String) -> Unit,
) {
    Column(Modifier.padding(horizontal = 16.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = "参加中の推し投票",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
            )
            TextButton(onClick = onOpenTaskList) { Text("一覧を見る") }
        }
        Spacer(Modifier.height(8.dp))
        if (tasks.isEmpty()) {
            EmptyStateBox(text = "進行中のタスクはありません")
        } else {
            LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                items(tasks, key = { it.id }) { task ->
                    TaskCard(
                        task = task,
                        showCompleteButton = true,
                        onTap = { onEditTask(task.id) },
                        onComplete = { onComplete(task.id) },
                        onDelete = { /* Home からの削除はリスト側で */ },
                        modifier = Modifier.width(260.dp),
                    )
                }
            }
        }
    }
}

@Composable
private fun BiasSection(biasNames: List<String>) {
    Column(Modifier.padding(horizontal = 16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.Favorite, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            Spacer(Modifier.width(6.dp))
            Text(
                text = "あなたの推し",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
            )
        }
        Spacer(Modifier.height(8.dp))
        if (biasNames.isEmpty()) {
            EmptyStateBox(text = "推し設定はまだありません")
        } else {
            Text(
                text = biasNames.joinToString("・"),
                style = MaterialTheme.typography.bodyLarge,
            )
        }
    }
}

@Composable
private fun FeaturedVotesPlaceholder() {
    Column(Modifier.padding(horizontal = 16.dp)) {
        Text(
            text = "注目の投票",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
        )
        Spacer(Modifier.height(8.dp))
        EmptyStateBox(text = "Sprint 4 で実装予定")
    }
}

@Composable
private fun EmptyStateBox(text: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(96.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(text = text, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
