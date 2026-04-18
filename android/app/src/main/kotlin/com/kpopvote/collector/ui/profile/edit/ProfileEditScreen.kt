package com.kpopvote.collector.ui.profile.edit

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import com.kpopvote.collector.core.util.ImageCompress
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileEditScreen(
    onBack: () -> Unit,
    viewModel: ProfileEditViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

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
            viewModel.onPhotoPicked(bytes)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("プロフィール編集") },
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
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            PhotoPicker(
                bytes = state.photoBytes,
                remoteUrl = state.photoRemoteUrl,
                onPick = {
                    pickMedia.launch(
                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly),
                    )
                },
                onClear = viewModel::onClearPhoto,
            )

            if (state.validationErrors.contains(ProfileEditError.PHOTO_TOO_LARGE)) {
                Text(
                    text = "写真のサイズが大きすぎます(2MB 以下を選択してください)",
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                )
            }

            OutlinedTextField(
                value = state.displayName,
                onValueChange = viewModel::onDisplayNameChange,
                label = { Text("表示名") },
                isError = state.validationErrors.any {
                    it == ProfileEditError.DISPLAY_NAME_REQUIRED ||
                        it == ProfileEditError.DISPLAY_NAME_TOO_LONG
                },
                supportingText = {
                    Text("${state.displayName.length}/${ProfileEditViewModel.DISPLAY_NAME_MAX}")
                },
                singleLine = true,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth(),
            )

            OutlinedTextField(
                value = state.bio,
                onValueChange = viewModel::onBioChange,
                label = { Text("自己紹介(任意)") },
                isError = state.validationErrors.contains(ProfileEditError.BIO_TOO_LONG),
                supportingText = {
                    Text("${state.bio.length}/${ProfileEditViewModel.BIO_MAX}")
                },
                minLines = 3,
                maxLines = 6,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth(),
            )

            Button(
                onClick = viewModel::submit,
                enabled = !state.isSubmitting && state.validationErrors.isEmpty(),
                modifier = Modifier.fillMaxWidth(),
            ) {
                if (state.isSubmitting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp,
                    )
                } else {
                    Text("保存する")
                }
            }
        }
    }
}

@Composable
private fun PhotoPicker(
    bytes: ByteArray?,
    remoteUrl: String?,
    onPick: () -> Unit,
    onClear: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Box(
            modifier = Modifier
                .size(96.dp)
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.surfaceVariant)
                .clickable(onClick = onPick),
            contentAlignment = Alignment.Center,
        ) {
            when {
                bytes != null -> AsyncImage(
                    model = bytes,
                    contentDescription = "プロフィール写真",
                    modifier = Modifier.size(96.dp),
                )
                !remoteUrl.isNullOrBlank() -> AsyncImage(
                    model = remoteUrl,
                    contentDescription = "プロフィール写真",
                    modifier = Modifier.size(96.dp),
                )
                else -> Icon(
                    Icons.Filled.Person,
                    contentDescription = null,
                    modifier = Modifier.size(56.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }

        Column {
            TextButton(onClick = onPick) { Text("写真を選択") }
            if (bytes != null || !remoteUrl.isNullOrBlank()) {
                TextButton(onClick = onClear) { Text("削除する") }
            }
        }
    }
}
