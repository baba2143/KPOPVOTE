package com.kpopvote.collector.ui.tasks.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.kpopvote.collector.data.model.TaskStatus
import com.kpopvote.collector.data.model.VoteTask
import com.kpopvote.collector.data.model.isExpired
import com.kpopvote.collector.data.model.timeRemaining

@Composable
fun TaskCard(
    task: VoteTask,
    showCompleteButton: Boolean,
    onTap: () -> Unit,
    onComplete: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
        shape = RoundedCornerShape(12.dp),
        onClick = onTap,
    ) {
        Column(Modifier.padding(12.dp)) {
            if (!task.coverImage.isNullOrBlank()) {
                AsyncImage(
                    model = task.coverImage,
                    contentDescription = null,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp)
                        .clip(RoundedCornerShape(8.dp)),
                )
                Spacer(Modifier.height(8.dp))
            }
            if (!task.externalAppName.isNullOrBlank()) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (!task.externalAppIconUrl.isNullOrBlank()) {
                        AsyncImage(
                            model = task.externalAppIconUrl,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp).clip(RoundedCornerShape(4.dp)),
                        )
                        Spacer(Modifier.width(4.dp))
                    }
                    Text(
                        text = task.externalAppName,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Spacer(Modifier.height(4.dp))
            }
            Text(
                text = task.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(4.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                StatusChip(task)
                Text(
                    text = task.timeRemaining(),
                    style = MaterialTheme.typography.labelMedium,
                    color = if (task.isExpired()) MaterialTheme.colorScheme.error
                    else MaterialTheme.colorScheme.primary,
                )
            }
            Spacer(Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End,
            ) {
                if (showCompleteButton && task.status != TaskStatus.COMPLETED) {
                    IconButton(onClick = onComplete) {
                        Icon(Icons.Filled.Check, contentDescription = "完了")
                    }
                }
                IconButton(onClick = onDelete) {
                    Icon(
                        Icons.Filled.Delete,
                        contentDescription = "削除",
                        tint = MaterialTheme.colorScheme.error,
                    )
                }
            }
        }
    }
}

@Composable
private fun StatusChip(task: VoteTask) {
    val (label, color) = when {
        task.status == TaskStatus.COMPLETED -> "完了" to MaterialTheme.colorScheme.tertiary
        task.status == TaskStatus.ARCHIVED -> "アーカイブ" to MaterialTheme.colorScheme.outline
        task.isExpired() -> "期限切れ" to MaterialTheme.colorScheme.error
        else -> "進行中" to MaterialTheme.colorScheme.primary
    }
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .padding(horizontal = 0.dp),
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = color,
            modifier = Modifier
                .clip(RoundedCornerShape(50))
                .padding(horizontal = 8.dp, vertical = 2.dp),
        )
    }
}
