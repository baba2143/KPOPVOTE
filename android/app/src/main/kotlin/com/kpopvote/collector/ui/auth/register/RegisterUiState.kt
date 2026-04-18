package com.kpopvote.collector.ui.auth.register

import androidx.annotation.StringRes

data class RegisterUiState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    @StringRes val errorRes: Int? = null,
    val isSuccess: Boolean = false,
) {
    val isFormEnabled: Boolean get() = !isLoading && !isSuccess
    val canSubmit: Boolean get() = email.isNotBlank() && password.length >= MIN_PASSWORD && !isLoading

    companion object {
        const val MIN_PASSWORD = 8
    }
}
