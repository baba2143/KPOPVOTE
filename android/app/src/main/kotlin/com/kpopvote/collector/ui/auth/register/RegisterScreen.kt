package com.kpopvote.collector.ui.auth.register

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.kpopvote.collector.R
import com.kpopvote.collector.ui.components.KpopvoteEmailField
import com.kpopvote.collector.ui.components.KpopvoteGradientButton
import com.kpopvote.collector.ui.components.KpopvotePasswordField
import com.kpopvote.collector.ui.theme.LocalSpacing

@Composable
fun RegisterScreen(
    onNavigateBack: () -> Unit,
    onRegisterSuccess: () -> Unit,
    viewModel: RegisterViewModel = hiltViewModel(),
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val spacing = LocalSpacing.current

    LaunchedEffect(uiState.isSuccess) {
        if (uiState.isSuccess) onRegisterSuccess()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.auth_register_button)) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = null)
                    }
                },
            )
        },
    ) { innerPadding ->
        Box(modifier = Modifier.fillMaxSize().padding(innerPadding)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = spacing.large, vertical = spacing.extraLarge),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Top,
            ) {
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
                    text = stringResource(R.string.auth_register_button),
                    onClick = viewModel::onRegisterClick,
                    enabled = uiState.canSubmit,
                    loading = uiState.isLoading,
                )

                Spacer(Modifier.height(spacing.large))

                TextButton(onClick = onNavigateBack) {
                    Text(stringResource(R.string.auth_switch_to_login))
                }
            }
        }
    }
}
