package com.kpopvote.collector.ui.auth.login

import androidx.annotation.StringRes

data class LoginUiState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    @StringRes val errorRes: Int? = null,
    val isSuccess: Boolean = false,
) {
    val isFormEnabled: Boolean get() = !isLoading && !isSuccess
    val canSubmit: Boolean get() = email.isNotBlank() && password.isNotBlank() && !isLoading
}
