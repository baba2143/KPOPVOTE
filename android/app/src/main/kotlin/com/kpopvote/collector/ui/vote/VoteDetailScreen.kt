package com.kpopvote.collector.ui.vote

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.EmojiEvents
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import com.kpopvote.collector.data.model.InAppVote
import com.kpopvote.collector.data.model.VoteChoice
import com.kpopvote.collector.data.model.VoteExecuteResult
import com.kpopvote.collector.ui.vote.components.VoteStatusBadge

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VoteDetailScreen(
    onBack: () -> Unit,
    onOpenRanking: (String) -> Unit,
    viewModel: VoteDetailViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(state.error) {
        val err = state.error ?: return@LaunchedEffect
        snackbarHostState.showSnackbar(err.message ?: "エラーが発生しました")
        viewModel.dismissError()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("投票詳細") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "戻る")
                    }
                },
                actions = {
                    state.vote?.voteId?.let { id ->
                        IconButton(onClick = { onOpenRanking(id) }) {
                            Icon(Icons.Filled.EmojiEvents, contentDescription = "ランキング")
                        }
                    }
                },
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            val vote = state.vote
            when {
                state.isLoading && vote == null -> {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
                vote == null -> {
                    Box(Modifier.fillMaxSize().padding(32.dp), contentAlignment = Alignment.Center) {
                        Text("投票を読み込めませんでした", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                else -> VoteDetailContent(
                    vote = vote,
                    state = state,
                    onSelectChoice = viewModel::selectChoice,
                    onInc = viewModel::incVoteCount,
                    onDec = viewModel::decVoteCount,
                    onConfirm = viewModel::confirmVote,
                )
            }
        }
    }

    state.lastResult?.let { result ->
        VoteResultDialog(result = result, onDismiss = viewModel::clearLastResult)
    }
}

@Composable
private fun VoteDetailContent(
    vote: InAppVote,
    state: VoteDetailUiState,
    onSelectChoice: (String) -> Unit,
    onInc: () -> Unit,
    onDec: () -> Unit,
    onConfirm: () -> Unit,
) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
        modifier = Modifier.fillMaxSize(),
    ) {
        item { VoteHeader(vote) }
        item { VoteMetaRow(vote) }
        item {
            Text(
                "選択肢",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
            )
        }
        items(vote.choices, key = { it.choiceId }) { choice ->
            ChoiceCard(
                choice = choice,
                selected = state.selectedChoiceId == choice.choiceId,
                onTap = { onSelectChoice(choice.choiceId) },
            )
        }
        item {
            VoteCountStepper(
                count = state.voteCount,
                maxCount = state.maxVotes,
                onInc = onInc,
                onDec = onDec,
            )
        }
        item {
            Button(
                onClick = onConfirm,
                enabled = state.canVote,
                modifier = Modifier.fillMaxWidth().height(52.dp),
            ) {
                if (state.isVoting) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp,
                    )
                } else {
                    Text("投票する", fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

@Composable
private fun VoteHeader(vote: InAppVote) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
    ) {
        Column {
            if (!vote.coverImageUrl.isNullOrBlank()) {
                AsyncImage(
                    model = vote.coverImageUrl,
                    contentDescription = null,
                    modifier = Modifier.fillMaxWidth().height(180.dp),
                )
            }
            Column(Modifier.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = vote.title,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        modifier = Modifier.weight(1f),
                    )
                    Spacer(Modifier.width(8.dp))
                    VoteStatusBadge(vote.status)
                }
                if (!vote.description.isNullOrBlank()) {
                    Spacer(Modifier.height(8.dp))
                    Text(
                        text = vote.description,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}

@Composable
private fun VoteMetaRow(vote: InAppVote) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        MetaChip(title = "本日の残り", value = (vote.userDailyRemaining ?: 0).toString(), modifier = Modifier.weight(1f))
        MetaChip(title = "1日の上限", value = (vote.userDailyLimit ?: 0).toString(), modifier = Modifier.weight(1f))
        MetaChip(title = "合計", value = "${vote.totalVotes}票", modifier = Modifier.weight(1f))
    }
}

@Composable
private fun MetaChip(title: String, value: String, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(vertical = 10.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                title,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(2.dp))
            Text(
                value,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
            )
        }
    }
}

@Composable
private fun ChoiceCard(
    choice: VoteChoice,
    selected: Boolean,
    onTap: () -> Unit,
) {
    val borderColor = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = if (selected) 2.dp else 1.dp,
                color = borderColor,
                shape = RoundedCornerShape(12.dp),
            ),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (selected) MaterialTheme.colorScheme.primaryContainer
            else MaterialTheme.colorScheme.surface,
        ),
        onClick = onTap,
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(MaterialTheme.colorScheme.surfaceVariant),
                contentAlignment = Alignment.Center,
            ) {
                if (!choice.imageUrl.isNullOrBlank()) {
                    AsyncImage(
                        model = choice.imageUrl,
                        contentDescription = null,
                        modifier = Modifier.size(56.dp),
                    )
                } else {
                    Text("🎤", style = MaterialTheme.typography.titleLarge)
                }
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    choice.displayName,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(
                    "${choice.voteCount}票",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun VoteCountStepper(count: Int, maxCount: Int, onInc: () -> Unit, onDec: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        OutlinedButton(
            onClick = onDec,
            enabled = count > 1,
            shape = RoundedCornerShape(50),
            contentPadding = PaddingValues(0.dp),
            modifier = Modifier.size(44.dp),
        ) {
            Icon(Icons.Filled.Remove, contentDescription = "減らす")
        }
        Text(
            text = "$count / $maxCount 票",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
        )
        OutlinedButton(
            onClick = onInc,
            enabled = count < maxCount,
            shape = RoundedCornerShape(50),
            contentPadding = PaddingValues(0.dp),
            modifier = Modifier.size(44.dp),
        ) {
            Icon(Icons.Filled.Add, contentDescription = "増やす")
        }
    }
}

@Composable
private fun VoteResultDialog(result: VoteExecuteResult, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("投票完了") },
        text = {
            Column {
                Text("${result.voteCount}票投票しました。")
                result.userDailyRemaining?.let {
                    Spacer(Modifier.height(4.dp))
                    Text("本日の残り: $it 票", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                if (result.pointsDeducted > 0) {
                    Spacer(Modifier.height(4.dp))
                    Text("消費ポイント: ${result.pointsDeducted}P", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) { Text("OK") }
        },
        shape = RoundedCornerShape(12.dp),
    )
}
