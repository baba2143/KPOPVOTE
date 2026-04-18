package com.kpopvote.collector.ui.votestab.edit

import android.graphics.BitmapFactory
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.painter.BitmapPainter
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import com.kpopvote.collector.core.util.ImageCompress
import com.kpopvote.collector.data.model.CollectionVisibility
import com.kpopvote.collector.data.model.VoteTask
import kotlinx.coroutines.launch

/**
 * Create / edit a collection. Mode is decided by `Route.CollectionEdit` vs `Route.CollectionCreate`
 * via [CreateCollectionViewModel]'s SavedStateHandle.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateCollectionScreen(
    onBack: () -> Unit,
    viewModel: CreateCollectionViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var showTaskPicker by remember { mutableStateOf(false) }
    var tagDraft by remember { mutableStateOf("") }

    LaunchedEffect(state.error) {
        val err = state.error ?: return@LaunchedEffect
        snackbarHostState.showSnackbar(err.message ?: "エラーが発生しました")
        viewModel.clearError()
    }

    LaunchedEffect(state.submitted) {
        if (state.submitted) onBack()
    }

    val pickMedia = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia(),
    ) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        scope.launch {
            val bytes = ImageCompress.compressUri(context.contentResolver, uri)
            viewModel.onCoverImagePicked(bytes)
        }
    }

    val isEdit = state.mode == CollectionFormMode.EDIT

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (isEdit) "コレクションを編集" else "コレクションを作成") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "戻る")
                    }
                },
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        if (state.isLoading) {
            Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
            return@Scaffold
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            // Cover image
            CoverImagePicker(
                bytes = state.coverImageBytes,
                remoteUrl = state.coverImageRemoteUrl,
                onPick = {
                    pickMedia.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                },
                onClear = viewModel::onClearCoverImage,
            )

            // Title
            OutlinedTextField(
                value = state.title,
                onValueChange = viewModel::onTitleChange,
                label = { Text("タイトル") },
                placeholder = { Text("例: 今週の推し活") },
                isError = state.validationErrors.any {
                    it == CollectionFormError.TITLE_REQUIRED || it == CollectionFormError.TITLE_TOO_LONG
                },
                supportingText = {
                    Text("${state.title.length}/${CreateCollectionViewModel.TITLE_MAX}")
                },
                singleLine = true,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth(),
            )

            // Description
            OutlinedTextField(
                value = state.description,
                onValueChange = viewModel::onDescriptionChange,
                label = { Text("説明（任意）") },
                supportingText = {
                    Text("${state.description.length}/${CreateCollectionViewModel.DESCRIPTION_MAX}")
                },
                isError = state.validationErrors.contains(CollectionFormError.DESCRIPTION_TOO_LONG),
                minLines = 2,
                maxLines = 5,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth(),
            )

            // Tags
            TagsSection(
                tags = state.tags,
                draft = tagDraft,
                onDraftChange = { tagDraft = it },
                onAdd = {
                    viewModel.addTag(tagDraft)
                    tagDraft = ""
                },
                onRemove = viewModel::removeTag,
                hasError = state.validationErrors.contains(CollectionFormError.TAGS_TOO_MANY) ||
                    state.validationErrors.contains(CollectionFormError.TAGS_DUPLICATE),
            )

            // Visibility
            VisibilitySection(
                current = state.visibility,
                onChange = viewModel::onVisibilityChange,
            )

            HorizontalDivider()

            // Tasks
            TasksSection(
                selectedTasks = state.selectedTasks,
                hasError = state.validationErrors.contains(CollectionFormError.TASKS_REQUIRED) ||
                    state.validationErrors.contains(CollectionFormError.TASKS_TOO_MANY),
                onPickTasks = { showTaskPicker = true },
                onMoveUp = viewModel::moveTaskUp,
                onMoveDown = viewModel::moveTaskDown,
                onRemove = viewModel::toggleTask,
            )

            Spacer(Modifier.height(8.dp))

            // Submit
            Button(
                onClick = viewModel::submit,
                enabled = state.validationErrors.isEmpty() && !state.isSubmitting,
                modifier = Modifier.fillMaxWidth(),
            ) {
                if (state.isSubmitting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp,
                    )
                } else {
                    Text(if (isEdit) "更新する" else "作成する")
                }
            }
        }
    }

    if (showTaskPicker) {
        TaskPickerBottomSheet(
            availableTasks = state.availableTasks,
            selectedIds = state.taskIds,
            onToggle = viewModel::toggleTask,
            onDismiss = { showTaskPicker = false },
        )
    }
}

@Composable
private fun CoverImagePicker(
    bytes: ByteArray?,
    remoteUrl: String?,
    onPick: () -> Unit,
    onClear: () -> Unit,
) {
    val preview: ImageBitmap? = remember(bytes) {
        bytes?.let { BitmapFactory.decodeByteArray(it, 0, it.size)?.asImageBitmap() }
    }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("カバー画像", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(180.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant),
            contentAlignment = Alignment.Center,
        ) {
            when {
                preview != null -> {
                    androidx.compose.foundation.Image(
                        painter = BitmapPainter(preview),
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize(),
                    )
                }
                !remoteUrl.isNullOrBlank() -> {
                    AsyncImage(
                        model = remoteUrl,
                        contentDescription = null,
                        modifier = Modifier.fillMaxSize(),
                    )
                }
                else -> Text("📂", style = MaterialTheme.typography.displayMedium)
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(onClick = onPick) { Text(if (bytes == null && remoteUrl.isNullOrBlank()) "画像を選択" else "画像を変更") }
            if (bytes != null || !remoteUrl.isNullOrBlank()) {
                TextButton(onClick = onClear) { Text("クリア") }
            }
        }
    }
}

@Composable
private fun TagsSection(
    tags: List<String>,
    draft: String,
    onDraftChange: (String) -> Unit,
    onAdd: () -> Unit,
    onRemove: (String) -> Unit,
    hasError: Boolean,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            "タグ（最大${CreateCollectionViewModel.TAGS_MAX}個）",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
        )
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(
                value = draft,
                onValueChange = onDraftChange,
                placeholder = { Text("タグを追加") },
                singleLine = true,
                isError = hasError,
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(12.dp),
            )
            IconButton(onClick = onAdd, enabled = draft.isNotBlank()) {
                Icon(Icons.Filled.Add, contentDescription = "追加")
            }
        }
        if (tags.isNotEmpty()) {
            val scrollState = rememberScrollState()
            Row(
                modifier = Modifier.horizontalScroll(scrollState),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                tags.forEach { tag ->
                    AssistChip(
                        onClick = { onRemove(tag) },
                        label = { Text("#$tag") },
                        trailingIcon = {
                            Icon(Icons.Filled.Close, contentDescription = "削除", modifier = Modifier.size(16.dp))
                        },
                    )
                }
            }
        }
    }
}

@Composable
private fun VisibilitySection(
    current: CollectionVisibility,
    onChange: (CollectionVisibility) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("公開範囲", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold)
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            VisibilityOption(CollectionVisibility.PUBLIC, "公開", current, onChange)
            VisibilityOption(CollectionVisibility.FOLLOWERS, "フォロワー", current, onChange)
            VisibilityOption(CollectionVisibility.PRIVATE, "非公開", current, onChange)
        }
    }
}

@Composable
private fun VisibilityOption(
    value: CollectionVisibility,
    label: String,
    current: CollectionVisibility,
    onChange: (CollectionVisibility) -> Unit,
) {
    FilterChip(
        selected = value == current,
        onClick = { onChange(value) },
        label = { Text(label) },
    )
}

@Composable
private fun TasksSection(
    selectedTasks: List<VoteTask>,
    hasError: Boolean,
    onPickTasks: () -> Unit,
    onMoveUp: (String) -> Unit,
    onMoveDown: (String) -> Unit,
    onRemove: (String) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "タスク (${selectedTasks.size})",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f),
                color = if (hasError) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface,
            )
            OutlinedButton(onClick = onPickTasks) { Text("タスクを追加") }
        }
        if (selectedTasks.isEmpty()) {
            Text(
                text = "最低 1 件のタスクを追加してください",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                selectedTasks.forEachIndexed { index, task ->
                    SelectedTaskRow(
                        index = index,
                        total = selectedTasks.size,
                        task = task,
                        onMoveUp = { onMoveUp(task.id) },
                        onMoveDown = { onMoveDown(task.id) },
                        onRemove = { onRemove(task.id) },
                    )
                }
            }
        }
    }
}

@Composable
private fun SelectedTaskRow(
    index: Int,
    total: Int,
    task: VoteTask,
    onMoveUp: () -> Unit,
    onMoveDown: () -> Unit,
    onRemove: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(horizontal = 8.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(
            text = "${index + 1}.",
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.width(28.dp),
        )
        Text(
            text = task.title,
            style = MaterialTheme.typography.bodyMedium,
            modifier = Modifier.weight(1f),
            maxLines = 1,
        )
        IconButton(onClick = onMoveUp, enabled = index > 0) {
            Icon(Icons.Filled.ArrowUpward, contentDescription = "上へ")
        }
        IconButton(onClick = onMoveDown, enabled = index < total - 1) {
            Icon(Icons.Filled.ArrowDownward, contentDescription = "下へ")
        }
        IconButton(onClick = onRemove) {
            Icon(Icons.Filled.Close, contentDescription = "削除")
        }
    }
}
