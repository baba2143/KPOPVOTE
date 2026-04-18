package com.kpopvote.collector.ui.auth.register

import com.kpopvote.collector.R
import com.kpopvote.collector.core.auth.AuthState
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.core.common.AuthFailureReason
import com.kpopvote.collector.data.repository.AuthRepository
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class RegisterViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var authRepository: AuthRepository
    private lateinit var viewModel: RegisterViewModel

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        authRepository = mockk(relaxed = true) {
            coEvery { authState } returns MutableStateFlow<AuthState>(AuthState.Unauthenticated) as StateFlow<AuthState>
        }
        viewModel = RegisterViewModel(authRepository)
    }

    @After
    fun teardown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `password shorter than 8 characters shows error`() = runTest {
        viewModel.onEmailChange("test@example.com")
        viewModel.onPasswordChange("short")
        viewModel.onRegisterClick()
        assertEquals(R.string.auth_error_password_too_short, viewModel.uiState.value.errorRes)
    }

    @Test
    fun `valid registration succeeds`() = runTest {
        coEvery { authRepository.signUpWithEmail(any(), any()) } returns Result.success(Unit)

        viewModel.onEmailChange("new@example.com")
        viewModel.onPasswordChange("password123")
        viewModel.onRegisterClick()

        dispatcher.scheduler.advanceUntilIdle()
        assertTrue(viewModel.uiState.value.isSuccess)
    }

    @Test
    fun `email already in use shows error`() = runTest {
        coEvery { authRepository.signUpWithEmail(any(), any()) } returns
            Result.failure(AppError.Auth(AuthFailureReason.EMAIL_ALREADY_IN_USE))

        viewModel.onEmailChange("existing@example.com")
        viewModel.onPasswordChange("password123")
        viewModel.onRegisterClick()

        dispatcher.scheduler.advanceUntilIdle()
        assertEquals(R.string.auth_error_email_in_use, viewModel.uiState.value.errorRes)
    }
}
