package com.kpopvote.collector.ui.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.foundation.text.KeyboardOptions
import com.kpopvote.collector.R

@Composable
fun KpopvoteEmailField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    isError: Boolean = false,
    errorText: String? = null,
    enabled: Boolean = true,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(stringResource(R.string.auth_email_label)) },
        singleLine = true,
        enabled = enabled,
        isError = isError,
        supportingText = errorText?.let { { Text(it) } },
        keyboardOptions = KeyboardOptions(
            keyboardType = KeyboardType.Email,
            capitalization = KeyboardCapitalization.None,
        ),
        modifier = modifier.fillMaxWidth(),
    )
}

@Composable
fun KpopvotePasswordField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    isError: Boolean = false,
    errorText: String? = null,
    enabled: Boolean = true,
) {
    var visible by remember { mutableStateOf(false) }
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(stringResource(R.string.auth_password_label)) },
        placeholder = { Text(stringResource(R.string.auth_password_hint)) },
        singleLine = true,
        enabled = enabled,
        isError = isError,
        supportingText = errorText?.let { { Text(it) } },
        visualTransformation = if (visible) VisualTransformation.None else PasswordVisualTransformation(),
        trailingIcon = {
            IconButton(onClick = { visible = !visible }) {
                Icon(
                    imageVector = if (visible) Icons.Filled.VisibilityOff else Icons.Filled.Visibility,
                    contentDescription = stringResource(
                        if (visible) R.string.cd_hide_password else R.string.cd_show_password,
                    ),
                )
            }
        },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
        modifier = modifier.fillMaxWidth(),
    )
}
