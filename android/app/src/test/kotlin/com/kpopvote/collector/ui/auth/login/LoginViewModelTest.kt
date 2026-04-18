package com.kpopvote.collector.ui.auth.login

import app.cash.turbine.test
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
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class LoginViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var authRepository: AuthRepository
    private lateinit var viewModel: LoginViewModel

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        authRepository = mockk(relaxed = true) {
            coEvery { authState } returns MutableStateFlow<AuthState>(AuthState.Unauthenticated) as StateFlow<AuthState>
        }
        viewModel = LoginViewModel(authRepository)
    }

    @After
    fun teardown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `onEmailChange updates email and clears error`() = runTest {
        viewModel.uiState.test {
            assertEquals("", awaitItem().email)
            viewModel.onEmailChange("test@example.com")
            val updated = awaitItem()
            assertEquals("test@example.com", updated.email)
            assertNull(updated.errorRes)
        }
    }

    @Test
    fun `onLoginClick with empty email shows error`() = runTest {
        viewModel.onPasswordChange("password123")
        viewModel.onLoginClick()
        assertEquals(R.string.auth_error_empty_email, viewModel.uiState.value.errorRes)
    }

    @Test
    fun `onLoginClick with invalid email shows format error`() = runTest {
        viewModel.onEmailChange("not-an-email")
        viewModel.onPasswordChange("password123")
        viewModel.onLoginClick()
        assertEquals(R.string.auth_error_invalid_email, viewModel.uiState.value.errorRes)
    }

    @Test
    fun `onLoginClick with valid input succeeds`() = runTest {
        coEvery { authRepository.signInWithEmail(any(), any()) } returns Result.success(Unit)

        viewModel.onEmailChange("test@example.com")
        viewModel.onPasswordChange("password123")
        viewModel.onLoginClick()

        dispatcher.scheduler.advanceUntilIdle()
        assertTrue(viewModel.uiState.value.isSuccess)
        assertNull(viewModel.uiState.value.errorRes)
    }

    @Test
    fun `onLoginClick with wrong credentials shows auth error`() = runTest {
        coEvery { authRepository.signInWithEmail(any(), any()) } returns
            Result.failure(AppError.Auth(AuthFailureReason.WRONG_CREDENTIALS))

        viewModel.onEmailChange("test@example.com")
        viewModel.onPasswordChange("wrong")
        viewModel.onLoginClick()

        dispatcher.scheduler.advanceUntilIdle()
        assertEquals(R.string.auth_error_wrong_credentials, viewModel.uiState.value.errorRes)
        assertTrue(!viewModel.uiState.value.isSuccess)
    }

    @Test
    fun `onLoginClick with network error shows network message`() = runTest {
        coEvery { authRepository.signInWithEmail(any(), any()) } returns
            Result.failure(AppError.Network)

        viewModel.onEmailChange("test@example.com")
        viewModel.onPasswordChange("password123")
        viewModel.onLoginClick()

        dispatcher.scheduler.advanceUntilIdle()
        assertEquals(R.string.auth_error_network, viewModel.uiState.value.errorRes)
    }
}
