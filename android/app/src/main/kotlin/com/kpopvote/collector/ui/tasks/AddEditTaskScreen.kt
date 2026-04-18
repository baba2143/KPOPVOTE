package com.kpopvote.collector.ui.tasks

import android.graphics.BitmapFactory
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Image
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TimePicker
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.text.KeyboardOptions
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import com.kpopvote.collector.core.util.ImageCompress
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddEditTaskScreen(
    onBack: () -> Unit,
    viewModel: AddEditTaskViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var showBiasSheet by remember { mutableStateOf(false) }
    var showDatePicker by remember { mutableStateOf(false) }
    var showTimePicker by remember { mutableStateOf(false) }
    var pickedDateMillis by remember { mutableStateOf<Long?>(null) }
    var appMenuExpanded by remember { mutableStateOf(false) }

    LaunchedEffect(state.submitted) {
        if (state.submitted) onBack()
    }
    LaunchedEffect(state.error) {
        val err = state.error ?: return@LaunchedEffect
        snackbarHostState.showSnackbar(err.message ?: "エラーが発生しました")
        viewModel.clearError()
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

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (state.isEditMode) "タスクを編集" else "タスクを追加") },
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
                .padding(horizontal = 16.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            OutlinedTextField(
                value = state.title,
                onValueChange = viewModel::onTitleChange,
                label = { Text("タイトル") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )

            OutlinedTextField(
                value = state.url,
                onValueChange = viewModel::onUrlChange,
                label = { Text("URL") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                isError = state.url.isNotBlank() && !AddEditTaskUiState.isUrlValid(state.url),
                supportingText = {
                    if (state.url.isNotBlank() && !AddEditTaskUiState.isUrlValid(state.url)) {
                        Text("http(s):// から始まる URL を入力してください")
                    }
                },
                modifier = Modifier.fillMaxWidth(),
            )

            DeadlineField(
                deadlineMillis = state.deadlineMillis,
                onClick = { showDatePicker = true },
            )

            ExposedDropdownMenuBox(
                expanded = appMenuExpanded,
                onExpandedChange = { appMenuExpanded = it },
            ) {
                OutlinedTextField(
                    value = state.selectedApp?.appName ?: "（選択なし）",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("外部アプリ") },
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(expanded = appMenuExpanded)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                )
                ExposedDropdownMenu(
                    expanded = appMenuExpanded,
                    onDismissRequest = { appMenuExpanded = false },
                ) {
                    DropdownMenuItem(
                        text = { Text("（選択なし）") },
                        onClick = {
                            viewModel.onExternalAppSelected(null)
                            appMenuExpanded = false
                        },
                    )
                    state.externalApps.forEach { app ->
                        DropdownMenuItem(
                            text = { Text(app.appName) },
                            onClick = {
                                viewModel.onExternalAppSelected(app.id)
                                appMenuExpanded = false
                            },
                        )
                    }
                }
            }

            MemberChipsRow(
                memberNames = state.selectedMemberNames,
                onOpenSelector = { showBiasSheet = true },
            )

            CoverImageField(
                coverImageBytes = state.coverImageBytes,
                coverImageUrl = state.coverImageUrl,
                onPick = {
                    pickMedia.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                },
                onClear = viewModel::onClearCoverImage,
            )

            GradientSubmitButton(
                enabled = state.isFormValid && !state.isSubmitting,
                isLoading = state.isSubmitting,
                label = if (state.isEditMode) "更新する" else "追加する",
                onClick = viewModel::submit,
            )
        }
    }

    if (showBiasSheet) {
        BiasSelectionBottomSheet(
            allIdols = state.allIdols,
            initialSelected = state.selectedMemberIds,
            onDismiss = { showBiasSheet = false },
            onConfirm = { ids ->
                viewModel.onSelectedMembersChange(ids)
                showBiasSheet = false
            },
        )
    }

    if (showDatePicker) {
        val datePickerState = rememberDatePickerState(
            initialSelectedDateMillis = state.deadlineMillis ?: System.currentTimeMillis(),
        )
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                Button(onClick = {
                    pickedDateMillis = datePickerState.selectedDateMillis
                    showDatePicker = false
                    if (pickedDateMillis != null) showTimePicker = true
                }) { Text("次へ") }
            },
            dismissButton = {
                OutlinedButton(onClick = { showDatePicker = false }) { Text("キャンセル") }
            },
        ) {
            DatePicker(state = datePickerState)
        }
    }

    if (showTimePicker) {
        val now = state.deadlineMillis?.let { ZonedDateTime.ofInstant(Instant.ofEpochMilli(it), ZoneId.systemDefault()) }
            ?: ZonedDateTime.now()
        val timeState = rememberTimePickerState(
            initialHour = now.hour,
            initialMinute = now.minute,
            is24Hour = true,
        )
        DatePickerDialog(
            onDismissRequest = { showTimePicker = false },
            confirmButton = {
                Button(onClick = {
                    val dateMillis = pickedDateMillis ?: return@Button
                    val date = Instant.ofEpochMilli(dateMillis).atZone(ZoneId.systemDefault()).toLocalDate()
                    val merged = date.atTime(timeState.hour, timeState.minute)
                        .atZone(ZoneId.systemDefault())
                        .toInstant()
                        .toEpochMilli()
                    viewModel.onDeadlineChange(merged)
                    showTimePicker = false
                }) { Text("決定") }
            },
            dismissButton = {
                OutlinedButton(onClick = { showTimePicker = false }) { Text("キャンセル") }
            },
        ) {
            Box(Modifier.padding(16.dp), contentAlignment = Alignment.Center) {
                TimePicker(state = timeState)
            }
        }
    }
}

@Composable
private fun DeadlineField(deadlineMillis: Long?, onClick: () -> Unit) {
    OutlinedTextField(
        value = deadlineMillis?.let { formatDeadline(it) } ?: "",
        onValueChange = {},
        label = { Text("期日") },
        readOnly = true,
        trailingIcon = {
            IconButton(onClick = onClick) {
                Icon(Icons.Filled.ExpandMore, contentDescription = "期日を選択")
            }
        },
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
    )
}

@Composable
private fun MemberChipsRow(memberNames: List<String>, onOpenSelector: () -> Unit) {
    Column {
        Text(
            text = "対象メンバー",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(Modifier.height(6.dp))
        if (memberNames.isEmpty()) {
            OutlinedButton(onClick = onOpenSelector, modifier = Modifier.fillMaxWidth()) {
                Text("メンバーを選択")
            }
        } else {
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                contentPadding = PaddingValues(vertical = 4.dp),
            ) {
                items(memberNames) { name ->
                    AssistChip(
                        onClick = onOpenSelector,
                        label = { Text(name) },
                    )
                }
                item {
                    AssistChip(
                        onClick = onOpenSelector,
                        label = { Text("編集") },
                    )
                }
            }
        }
    }
}

@Composable
private fun CoverImageField(
    coverImageBytes: ByteArray?,
    coverImageUrl: String?,
    onPick: () -> Unit,
    onClear: () -> Unit,
) {
    Column {
        Text(
            text = "カバー画像",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
        )
        Spacer(Modifier.height(6.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(160.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant)
                .clickable(onClick = onPick),
            contentAlignment = Alignment.Center,
        ) {
            when {
                coverImageBytes != null -> {
                    val bitmap = remember(coverImageBytes) {
                        BitmapFactory.decodeByteArray(coverImageBytes, 0, coverImageBytes.size)
                    }
                    if (bitmap != null) {
                        androidx.compose.foundation.Image(
                            bitmap = bitmap.asImageBitmap(),
                            contentDescription = null,
                            modifier = Modifier.fillMaxWidth().height(160.dp),
                        )
                    }
                }
                !coverImageUrl.isNullOrBlank() -> {
                    AsyncImage(
                        model = coverImageUrl,
                        contentDescription = null,
                        modifier = Modifier.fillMaxWidth().height(160.dp),
                    )
                }
                else -> {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Filled.Image,
                            contentDescription = null,
                            modifier = Modifier.size(32.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        Spacer(Modifier.height(4.dp))
                        Text(
                            text = "タップして画像を選択",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                }
            }

            if (coverImageBytes != null || !coverImageUrl.isNullOrBlank()) {
                IconButton(
                    onClick = onClear,
                    modifier = Modifier.align(Alignment.TopEnd),
                ) {
                    Icon(
                        Icons.Filled.Close,
                        contentDescription = "削除",
                        tint = Color.White,
                    )
                }
            }
        }
    }
}

@Composable
private fun GradientSubmitButton(
    enabled: Boolean,
    isLoading: Boolean,
    label: String,
    onClick: () -> Unit,
) {
    val brush = Brush.horizontalGradient(
        listOf(
            MaterialTheme.colorScheme.primary,
            MaterialTheme.colorScheme.tertiary,
        ),
    )
    Button(
        onClick = onClick,
        enabled = enabled,
        colors = ButtonDefaults.buttonColors(
            containerColor = Color.Transparent,
            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant,
        ),
        border = if (!enabled) BorderStroke(1.dp, MaterialTheme.colorScheme.outline) else null,
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp)
            .then(
                if (enabled) Modifier.background(brush, RoundedCornerShape(26.dp))
                else Modifier,
            ),
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                color = Color.White,
                modifier = Modifier.size(22.dp),
                strokeWidth = 2.dp,
            )
        } else {
            Text(
                text = label,
                color = if (enabled) Color.White else MaterialTheme.colorScheme.onSurfaceVariant,
                fontWeight = FontWeight.Bold,
            )
        }
    }
}

private val DEADLINE_FORMATTER: DateTimeFormatter =
    DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm", Locale.JAPAN)

private fun formatDeadline(millis: Long): String =
    Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()).format(DEADLINE_FORMATTER)
