package com.kpopvote.collector.ui.auth.register

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.R
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.common.AuthFailureReason
import com.kpopvote.collector.data.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class RegisterViewModel @Inject constructor(
    private val authRepository: AuthRepository,
) : ViewModel() {

    private val _uiState = MutableStateFlow(RegisterUiState())
    val uiState: StateFlow<RegisterUiState> = _uiState.asStateFlow()

    fun onEmailChange(email: String) {
        _uiState.update { it.copy(email = email, errorRes = null) }
    }

    fun onPasswordChange(password: String) {
        _uiState.update { it.copy(password = password, errorRes = null) }
    }

    fun onRegisterClick() {
        val snapshot = _uiState.value
        val validationError = validate(snapshot.email, snapshot.password)
        if (validationError != null) {
            _uiState.update { it.copy(errorRes = validationError) }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, errorRes = null) }
            authRepository.signUpWithEmail(snapshot.email, snapshot.password)
                .onSuccess {
                    _uiState.update { it.copy(isLoading = false, isSuccess = true) }
                }
                .onFailure { throwable ->
                    _uiState.update {
                        it.copy(isLoading = false, errorRes = throwable.toErrorRes())
                    }
                }
        }
    }

    private fun validate(email: String, password: String): Int? = when {
        email.isBlank() -> R.string.auth_error_empty_email
        !EMAIL_REGEX.matches(email) -> R.string.auth_error_invalid_email
        password.isBlank() -> R.string.auth_error_empty_password
        password.length < RegisterUiState.MIN_PASSWORD -> R.string.auth_error_password_too_short
        else -> null
    }

    private fun Throwable.toErrorRes(): Int = when (this) {
        is AppError.Network -> R.string.auth_error_network
        is AppError.Auth -> when (reason) {
            AuthFailureReason.EMAIL_ALREADY_IN_USE -> R.string.auth_error_email_in_use
            AuthFailureReason.WEAK_PASSWORD -> R.string.auth_error_password_too_short
            AuthFailureReason.INVALID_EMAIL -> R.string.auth_error_invalid_email
            else -> R.string.auth_error_unknown
        }
        else -> R.string.auth_error_unknown
    }

    companion object {
        private val EMAIL_REGEX =
            Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
    }
}
