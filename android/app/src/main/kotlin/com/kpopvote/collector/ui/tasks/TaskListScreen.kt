package com.kpopvote.collector.ui.tasks

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.kpopvote.collector.ui.tasks.components.TaskCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TaskListScreen(
    onBack: () -> Unit = {},
    onEditTask: (String) -> Unit,
    viewModel: TaskListViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(state.pointsGranted) {
        val granted = state.pointsGranted ?: return@LaunchedEffect
        val msg = if (granted > 0) "完了！+${granted}P" else "完了しました"
        snackbarHostState.showSnackbar(msg)
        viewModel.clearPointsBadge()
    }
    LaunchedEffect(state.error) {
        val err = state.error ?: return@LaunchedEffect
        snackbarHostState.showSnackbar(err.message ?: "エラーが発生しました")
        viewModel.clearError()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("タスク一覧") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "戻る")
                    }
                },
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        PullToRefreshBox(
            isRefreshing = state.isLoading,
            onRefresh = viewModel::refresh,
            modifier = Modifier.fillMaxSize().padding(padding),
        ) {
            LazyColumn(
                contentPadding = PaddingValues(vertical = 12.dp, horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxSize(),
            ) {
                item {
                    SegmentPicker(state.segment, viewModel::selectSegment)
                }
                if (state.visibleTasks.isEmpty() && !state.isLoading) {
                    item {
                        Box(
                            modifier = Modifier.fillMaxWidth().padding(32.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                text = emptyLabel(state.segment),
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                } else {
                    items(state.visibleTasks, key = { it.id }) { task ->
                        TaskCard(
                            task = task,
                            showCompleteButton = state.segment == TaskListSegment.ACTIVE,
                            onTap = { onEditTask(task.id) },
                            onComplete = { viewModel.completeTask(task) },
                            onDelete = { viewModel.deleteTask(task) },
                        )
                    }
                }
            }

            if (state.isLoading && state.allTasks.isEmpty()) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
        }
    }
}

@Composable
private fun SegmentPicker(current: TaskListSegment, onSelect: (TaskListSegment) -> Unit) {
    val segments = TaskListSegment.entries
    SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
        segments.forEachIndexed { index, seg ->
            SegmentedButton(
                selected = seg == current,
                onClick = { onSelect(seg) },
                shape = SegmentedButtonDefaults.itemShape(index = index, count = segments.size),
            ) {
                Text(labelFor(seg))
            }
        }
    }
}

private fun labelFor(seg: TaskListSegment) = when (seg) {
    TaskListSegment.ACTIVE -> "進行中"
    TaskListSegment.ARCHIVE -> "アーカイブ"
    TaskListSegment.COMPLETED -> "完了"
}

private fun emptyLabel(seg: TaskListSegment) = when (seg) {
    TaskListSegment.ACTIVE -> "アクティブなタスクはありません"
    TaskListSegment.ARCHIVE -> "アーカイブされたタスクはありません"
    TaskListSegment.COMPLETED -> "完了したタスクはありません"
}

