package com.kpopvote.collector.ui.profile.bias

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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckBox
import androidx.compose.material.icons.filled.CheckBoxOutlineBlank
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import com.kpopvote.collector.data.model.GroupMaster
import com.kpopvote.collector.data.model.IdolMaster

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BiasSettingsScreen(
    onBack: () -> Unit,
    viewModel: BiasSettingsViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(state.error) {
        val err = state.error ?: return@LaunchedEffect
        snackbarHostState.showSnackbar(err.message ?: "エラーが発生しました")
        viewModel.clearError()
    }

    LaunchedEffect(state.saved) {
        if (state.saved) {
            snackbarHostState.showSnackbar("推し設定を保存しました")
            onBack()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("推し設定") },
                navigationIcon = {
                    IconButton(onClick = onBack, enabled = !state.isSaving) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "戻る")
                    }
                },
                actions = {
                    TextButton(onClick = viewModel::save, enabled = !state.isSaving && !state.isLoading) {
                        if (state.isSaving) {
                            CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        } else {
                            Text("保存", fontWeight = FontWeight.Bold)
                        }
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

        Column(Modifier.fillMaxSize().padding(padding)) {
            ModeSelector(
                mode = state.mode,
                onChange = viewModel::setMode,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
            )

            SearchField(
                value = state.searchText,
                placeholder = if (state.mode == BiasSelectionMode.GROUP) {
                    "グループ名で検索"
                } else {
                    "アイドル名・グループ名で検索"
                },
                onChange = viewModel::setSearchText,
                modifier = Modifier.padding(horizontal = 16.dp),
            )

            Spacer(Modifier.height(8.dp))

            when (state.mode) {
                BiasSelectionMode.GROUP -> GroupList(
                    groups = filteredGroups(state),
                    selectedIds = state.selectedGroupIds,
                    onToggle = viewModel::toggleGroup,
                )
                BiasSelectionMode.MEMBER -> IdolList(
                    groupedIdols = groupedFilteredIdols(state),
                    selectedIds = state.selectedIdolIds,
                    onToggle = viewModel::toggleIdol,
                )
            }
        }
    }
}

private fun filteredGroups(state: BiasSettingsUiState): List<GroupMaster> {
    val q = state.searchText.trim().lowercase()
    val base = if (q.isBlank()) state.allGroups else state.allGroups.filter { it.name.lowercase().contains(q) }
    return base.sortedBy { it.name }
}

private fun groupedFilteredIdols(state: BiasSettingsUiState): List<Pair<String, List<IdolMaster>>> {
    val q = state.searchText.trim().lowercase()
    val base = if (q.isBlank()) {
        state.allIdols
    } else {
        state.allIdols.filter {
            it.name.lowercase().contains(q) || it.groupName.lowercase().contains(q)
        }
    }
    return base.groupBy { it.groupName }.toSortedMap().toList()
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ModeSelector(
    mode: BiasSelectionMode,
    onChange: (BiasSelectionMode) -> Unit,
    modifier: Modifier = Modifier,
) {
    SingleChoiceSegmentedButtonRow(modifier = modifier.fillMaxWidth()) {
        BiasSelectionMode.entries.forEachIndexed { index, item ->
            SegmentedButton(
                selected = mode == item,
                onClick = { onChange(item) },
                shape = SegmentedButtonDefaults.itemShape(index, BiasSelectionMode.entries.size),
            ) {
                Text(item.label)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SearchField(
    value: String,
    placeholder: String,
    onChange: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        placeholder = { Text(placeholder) },
        leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
        trailingIcon = {
            if (value.isNotEmpty()) {
                IconButton(onClick = { onChange("") }) {
                    Icon(Icons.Filled.Close, contentDescription = "クリア")
                }
            }
        },
        singleLine = true,
        shape = RoundedCornerShape(12.dp),
        modifier = modifier.fillMaxWidth(),
    )
}

@Composable
private fun GroupList(
    groups: List<GroupMaster>,
    selectedIds: Set<String>,
    onToggle: (String) -> Unit,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        item {
            SelectedCountLabel(count = selectedIds.size)
        }
        items(groups, key = { it.id }) { group ->
            GroupRow(
                group = group,
                isSelected = group.id in selectedIds,
                onToggle = { onToggle(group.id) },
            )
        }
    }
}

@Composable
private fun IdolList(
    groupedIdols: List<Pair<String, List<IdolMaster>>>,
    selectedIds: Set<String>,
    onToggle: (String) -> Unit,
) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        item {
            SelectedCountLabel(count = selectedIds.size)
        }
        groupedIdols.forEach { (groupName, idols) ->
            item(key = "header-$groupName") {
                Text(
                    text = "$groupName (${idols.size})",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.padding(top = 12.dp, bottom = 4.dp),
                )
            }
            items(idols, key = { it.id }) { idol ->
                IdolRow(
                    idol = idol,
                    isSelected = idol.id in selectedIds,
                    onToggle = { onToggle(idol.id) },
                )
            }
        }
    }
}

@Composable
private fun SelectedCountLabel(count: Int) {
    Text(
        text = "選択中 ($count)",
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(vertical = 4.dp),
    )
}

@Composable
private fun GroupRow(
    group: GroupMaster,
    isSelected: Boolean,
    onToggle: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onToggle)
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CheckBoxIcon(isSelected)
        Spacer(Modifier.width(12.dp))
        AvatarImage(imageUrl = group.imageUrl, fallback = group.name.take(1))
        Spacer(Modifier.width(12.dp))
        Text(group.name, style = MaterialTheme.typography.bodyLarge)
    }
}

@Composable
private fun IdolRow(
    idol: IdolMaster,
    isSelected: Boolean,
    onToggle: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onToggle)
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        CheckBoxIcon(isSelected)
        Spacer(Modifier.width(12.dp))
        AvatarImage(imageUrl = idol.imageUrl, fallback = idol.name.take(1))
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(idol.name, style = MaterialTheme.typography.bodyLarge)
            Text(
                text = idol.groupName,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun CheckBoxIcon(isSelected: Boolean) {
    Icon(
        imageVector = if (isSelected) Icons.Filled.CheckBox else Icons.Filled.CheckBoxOutlineBlank,
        contentDescription = null,
        tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

@Composable
private fun AvatarImage(imageUrl: String?, fallback: String) {
    Box(
        modifier = Modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.surfaceVariant),
        contentAlignment = Alignment.Center,
    ) {
        if (!imageUrl.isNullOrBlank()) {
            AsyncImage(model = imageUrl, contentDescription = null, modifier = Modifier.fillMaxSize())
        } else {
            Text(
                text = fallback.uppercase(),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

