package com.kpopvote.collector.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.auth.AuthState
import com.kpopvote.collector.data.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthGateViewModel @Inject constructor(
    private val authRepository: AuthRepository,
) : ViewModel() {

    val authState: StateFlow<AuthState> = authRepository.authState

    fun signOut() {
        viewModelScope.launch { authRepository.signOut() }
    }
}
