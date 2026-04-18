package com.kpopvote.collector.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import com.kpopvote.collector.R
import com.kpopvote.collector.ui.theme.LocalSpacing

/**
 * Sprint 1 placeholder — replaced by full HomeScreen in Sprint 3.
 * Shown immediately after successful authentication to confirm the
 * auth-to-main graph transition works end to end.
 */
@Composable
fun HomePlaceholderScreen(
    onSignOut: () -> Unit,
) {
    val spacing = LocalSpacing.current

    Scaffold { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(spacing.large),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = stringResource(R.string.home_placeholder),
                style = MaterialTheme.typography.headlineSmall,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(spacing.large))
            TextButton(onClick = onSignOut) {
                Text(stringResource(R.string.auth_logout))
            }
        }
    }
}
