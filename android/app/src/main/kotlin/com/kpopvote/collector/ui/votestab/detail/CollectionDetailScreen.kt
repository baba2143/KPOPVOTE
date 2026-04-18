package com.kpopvote.collector.ui.votestab.detail

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.BookmarkBorder
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import com.kpopvote.collector.data.model.CollectionDetailData
import com.kpopvote.collector.data.model.CollectionTaskRef
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CollectionDetailScreen(
    onBack: () -> Unit,
    onEditCollection: (String) -> Unit = {},
    viewModel: CollectionDetailViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    var showDeleteConfirm by remember { mutableStateOf(false) }
    var showShareSheet by remember { mutableStateOf(false) }
    var menuOpen by remember { mutableStateOf(false) }

    // Error Snackbar
    LaunchedEffect(state.error) {
        val err = state.error ?: return@LaunchedEffect
        snackbarHostState.showSnackbar(err.message ?: "エラーが発生しました")
        viewModel.clearError()
    }

    // One-shot events: share success + deletion
    LaunchedEffect(Unit) {
        viewModel.events.collect { ev ->
            when (ev) {
                is CollectionDetailEvent.ShareSuccess -> {
                    showShareSheet = false
                    scope.launch { snackbarHostState.showSnackbar("コミュニティに共有しました") }
                }
                CollectionDetailEvent.Deleted -> onBack()
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("コレクション") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "戻る")
                    }
                },
                actions = {
                    state.detail?.let { detail ->
                        IconButton(
                            onClick = viewModel::toggleSave,
                            enabled = !state.isToggleSaving,
                        ) {
                            Icon(
                                imageVector = if (detail.isSaved) Icons.Filled.Bookmark else Icons.Filled.BookmarkBorder,
                                contentDescription = if (detail.isSaved) "保存解除" else "保存",
                                tint = if (detail.isSaved) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface,
                            )
                        }
                        if (detail.isOwner) {
                            IconButton(onClick = { menuOpen = true }) {
                                Icon(Icons.Filled.MoreVert, contentDescription = "メニュー")
                            }
                            DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                                DropdownMenuItem(
                                    text = { Text("編集") },
                                    onClick = {
                                        menuOpen = false
                                        onEditCollection(detail.collection.collectionId)
                                    },
                                )
                                DropdownMenuItem(
                                    text = {
                                        Text(
                                            "削除",
                                            color = MaterialTheme.colorScheme.error,
                                        )
                                    },
                                    leadingIcon = {
                                        Icon(
                                            Icons.Filled.Delete,
                                            contentDescription = null,
                                            tint = MaterialTheme.colorScheme.error,
                                        )
                                    },
                                    onClick = {
                                        menuOpen = false
                                        showDeleteConfirm = true
                                    },
                                )
                            }
                        }
                    }
                },
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when {
                state.isLoading && state.detail == null -> {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
                state.detail != null -> {
                    DetailContent(
                        detail = state.detail!!,
                        isAdding = state.isAdding,
                        onAddAll = viewModel::addAllToTasks,
                        onAddSingle = viewModel::addSingleTask,
                        onShare = { showShareSheet = true },
                    )
                }
                else -> {
                    // detail == null and not loading — typically an initial error
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(
                            text = "コレクションを読み込めませんでした",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }
        }
    }

    // Add-to-tasks result dialog
    state.addAllResult?.let { result ->
        AddToTasksResultDialog(
            result = result,
            onDismiss = { viewModel.clearAddResults() },
        )
    }
    state.addSingleResult?.let { single ->
        AlertDialog(
            onDismissRequest = { viewModel.clearAddResults() },
            confirmButton = {
                TextButton(onClick = { viewModel.clearAddResults() }) { Text("OK") }
            },
            title = { Text(if (single.alreadyAdded) "追加済み" else "追加しました") },
            text = {
                Text(
                    single.message.ifBlank {
                        if (single.alreadyAdded) "このタスクは既にあなたのタスク一覧にあります。" else "タスクに追加しました。"
                    },
                )
            },
        )
    }

    // Delete confirmation
    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteConfirm = false
                        viewModel.delete()
                    },
                ) { Text("削除", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteConfirm = false }) { Text("キャンセル") }
            },
            title = { Text("コレクションを削除") },
            text = { Text("このコレクションを削除しますか？ この操作は取り消せません。") },
        )
    }

    // Share bottom sheet
    if (showShareSheet) {
        ShareCollectionBottomSheet(
            isSubmitting = state.isSharing,
            onDismiss = { showShareSheet = false },
            onSubmit = { biasIds, text -> viewModel.share(biasIds, text) },
        )
    }
}

@Composable
private fun DetailContent(
    detail: CollectionDetailData,
    isAdding: Boolean,
    onAddAll: () -> Unit,
    onAddSingle: (String) -> Unit,
    onShare: () -> Unit,
) {
    val scrollState = rememberScrollState()
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(scrollState),
    ) {
        CoverHeader(url = detail.collection.coverImage)

        Column(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = detail.collection.title,
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.SemiBold,
            )
            if (detail.collection.description.isNotBlank()) {
                Text(
                    text = detail.collection.description,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            if (detail.collection.tags.isNotEmpty()) {
                TagRow(tags = detail.collection.tags)
            }
            CreatorStrip(
                ownerName = detail.collection.ownerName ?: "",
                ownerAvatarUrl = detail.collection.ownerAvatarUrl,
                saveCount = detail.collection.saveCount,
                likeCount = detail.collection.likeCount,
            )
        }

        HorizontalDivider()

        // Action row: add all + share
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Button(
                onClick = onAddAll,
                enabled = !isAdding && detail.collection.tasks.isNotEmpty(),
                modifier = Modifier.weight(1f),
            ) {
                if (isAdding) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp,
                    )
                } else {
                    Text("すべてタスクに追加")
                }
            }
            OutlinedButton(onClick = onShare, modifier = Modifier.weight(1f)) {
                Icon(Icons.Filled.Share, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(4.dp))
                Text("共有")
            }
        }

        HorizontalDivider()

        // Task list
        Text(
            text = "含まれるタスク (${detail.collection.tasks.size})",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
        )

        if (detail.collection.tasks.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxWidth().padding(32.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "タスクがありません",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        } else {
            Column(
                modifier = Modifier.padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                detail.collection.tasks.forEach { taskRef ->
                    TaskRow(
                        taskRef = taskRef,
                        isAdding = isAdding,
                        onAdd = { onAddSingle(taskRef.taskId) },
                    )
                }
                Spacer(Modifier.height(16.dp))
            }
        }
    }
}

@Composable
private fun CoverHeader(url: String?) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
            .background(MaterialTheme.colorScheme.surfaceVariant),
        contentAlignment = Alignment.Center,
    ) {
        if (!url.isNullOrBlank()) {
            AsyncImage(
                model = url,
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
            )
        } else {
            Text("📂", style = MaterialTheme.typography.displayMedium)
        }
    }
}

@Composable
private fun TagRow(tags: List<String>) {
    val scrollState = rememberScrollState()
    Row(
        modifier = Modifier.horizontalScroll(scrollState),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        tags.forEach { tag ->
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(50))
                    .background(MaterialTheme.colorScheme.primaryContainer)
                    .padding(horizontal = 10.dp, vertical = 4.dp),
            ) {
                Text(
                    text = "#$tag",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                )
            }
        }
    }
}

@Composable
private fun CreatorStrip(
    ownerName: String,
    ownerAvatarUrl: String?,
    saveCount: Int,
    likeCount: Int,
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        if (!ownerAvatarUrl.isNullOrBlank()) {
            AsyncImage(
                model = ownerAvatarUrl,
                contentDescription = null,
                modifier = Modifier
                    .size(32.dp)
                    .clip(RoundedCornerShape(50)),
            )
        }
        if (ownerName.isNotBlank()) {
            Text(
                text = "by $ownerName",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        Spacer(Modifier.weight(1f))
        Text(
            text = "🔖 $saveCount  ❤ $likeCount",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun TaskRow(
    taskRef: CollectionTaskRef,
    isAdding: Boolean,
    onAdd: () -> Unit,
) {
    val snapshot = taskRef.snapshot
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = snapshot?.title ?: "タスク #${taskRef.orderIndex + 1}",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (!snapshot?.externalAppName.isNullOrBlank()) {
                Text(
                    text = snapshot.externalAppName!!,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        TextButton(onClick = onAdd, enabled = !isAdding) {
            Text("追加")
        }
    }
}
