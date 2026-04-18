package com.kpopvote.collector.ui.votestab.detail

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.kpopvote.collector.data.model.AddToTasksData

/**
 * Summary dialog shown after "タスクに追加". Server returns per-task granular counts —
 * `addedCount` (new), `skippedCount` (already in user's task list), `totalCount` (tasks in collection).
 */
@Composable
fun AddToTasksResultDialog(
    result: AddToTasksData,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = onDismiss) { Text("OK") }
        },
        title = { Text("タスクに追加しました") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("追加: ${result.addedCount} 件", style = MaterialTheme.typography.bodyMedium)
                if (result.skippedCount > 0) {
                    Text(
                        "スキップ (追加済み): ${result.skippedCount} 件",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Spacer(Modifier.height(4.dp))
                Text(
                    "合計: ${result.totalCount} 件",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
    )
}
