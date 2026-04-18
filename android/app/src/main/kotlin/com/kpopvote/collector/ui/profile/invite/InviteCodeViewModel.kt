package com.kpopvote.collector.ui.profile.invite

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.repository.InviteRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class InviteCodeUiState(
    val ownCode: String? = null,
    val ownLink: String? = null,
    val isGenerating: Boolean = false,
    val manualCode: String = "",
    val isApplying: Boolean = false,
    val applySuccessMessage: String? = null,
    val error: AppError? = null,
)

@HiltViewModel
class InviteCodeViewModel @Inject constructor(
    private val inviteRepository: InviteRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(InviteCodeUiState())
    val state: StateFlow<InviteCodeUiState> = _state.asStateFlow()

    init {
        generate()
    }

    private fun generate() {
        if (_state.value.ownCode != null) return
        viewModelScope.launch {
            _state.update { it.copy(isGenerating = true, error = null) }
            inviteRepository.generateInviteCode()
                .onSuccess { data ->
                    _state.update {
                        it.copy(
                            isGenerating = false,
                            ownCode = data.inviteCode,
                            ownLink = data.inviteLink,
                        )
                    }
                }
                .onFailure { err ->
                    _state.update { it.copy(isGenerating = false, error = err as? AppError) }
                }
        }
    }

    fun onManualCodeChange(value: String) {
        val normalized = value.uppercase().trim()
        _state.update { it.copy(manualCode = normalized) }
    }

    fun clearError() = _state.update { it.copy(error = null) }
    fun clearApplySuccess() = _state.update { it.copy(applySuccessMessage = null) }

    fun applyManualCode() {
        val current = _state.value
        val code = current.manualCode
        if (code.isBlank() || current.isApplying) return

        viewModelScope.launch {
            _state.update { it.copy(isApplying = true, error = null) }
            inviteRepository.applyInviteCode(code)
                .onSuccess { data ->
                    val message = data.inviterDisplayName?.let { "${it}さんからの招待が適用されました！" }
                        ?: "招待コードが適用されました！"
                    _state.update {
                        it.copy(
                            isApplying = false,
                            applySuccessMessage = message,
                            manualCode = "",
                        )
                    }
                }
                .onFailure { err ->
                    _state.update { it.copy(isApplying = false, error = err as? AppError) }
                }
        }
    }
}
