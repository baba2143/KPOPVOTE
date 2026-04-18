package com.kpopvote.collector.ui.auth.login

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.kpopvote.collector.R
import com.kpopvote.collector.ui.components.KpopvoteEmailField
import com.kpopvote.collector.ui.components.KpopvoteGradientButton
import com.kpopvote.collector.ui.components.KpopvotePasswordField
import com.kpopvote.collector.ui.components.KpopvoteSecondaryButton
import com.kpopvote.collector.ui.theme.LocalSpacing

@Composable
fun LoginScreen(
    onNavigateToRegister: () -> Unit,
    onLoginSuccess: () -> Unit,
    viewModel: LoginViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val spacing = LocalSpacing.current

    LaunchedEffect(uiState.isSuccess) {
        if (uiState.isSuccess) onLoginSuccess()
    }

    Scaffold { innerPadding ->
        Box(modifier = Modifier.fillMaxSize().padding(innerPadding)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = spacing.large, vertical = spacing.extraLarge),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
            ) {
                Text(
                    text = stringResource(R.string.auth_welcome_title),
                    style = MaterialTheme.typography.headlineSmall,
                    textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(spacing.small))
                Text(
                    text = stringResource(R.string.auth_welcome_subtitle),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                )

                Spacer(Modifier.height(spacing.extraLarge))

                KpopvoteEmailField(
                    value = uiState.email,
                    onValueChange = viewModel::onEmailChange,
                    enabled = uiState.isFormEnabled,
                )
                Spacer(Modifier.height(spacing.medium))
                KpopvotePasswordField(
                    value = uiState.password,
                    onValueChange = viewModel::onPasswordChange,
                    enabled = uiState.isFormEnabled,
                )

                uiState.errorRes?.let { errorRes ->
                    Spacer(Modifier.height(spacing.small))
                    Text(
                        text = stringResource(errorRes),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.error,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth(),
                    )
                }

                Spacer(Modifier.height(spacing.large))

                KpopvoteGradientButton(
                    text = stringResource(R.string.auth_login_button),
                    onClick = viewModel::onLoginClick,
                    enabled = uiState.canSubmit,
                    loading = uiState.isLoading,
                )

                Spacer(Modifier.height(spacing.medium))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    HorizontalDivider(modifier = Modifier.weight(1f))
                    Text(
                        text = stringResource(R.string.auth_or_divider),
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(horizontal = spacing.medium),
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    HorizontalDivider(modifier = Modifier.weight(1f))
                }

                Spacer(Modifier.height(spacing.medium))

                KpopvoteSecondaryButton(
                    text = stringResource(R.string.auth_google_button),
                    onClick = { viewModel.onGoogleSignInClick(context) },
                    enabled = uiState.isFormEnabled,
                )

                Spacer(Modifier.height(spacing.large))

                TextButton(onClick = onNavigateToRegister) {
                    Text(stringResource(R.string.auth_switch_to_register))
                }
            }
        }
    }
}
