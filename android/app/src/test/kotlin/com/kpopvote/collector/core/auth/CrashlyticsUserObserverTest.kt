package com.kpopvote.collector.core.auth

import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.kpopvote.collector.core.analytics.AnalyticsLogger
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class CrashlyticsUserObserverTest {

    private val dispatcher = StandardTestDispatcher()
    private val authStateFlow = MutableStateFlow<AuthState>(AuthState.Loading)
    private val authStateHolder: AuthStateHolder = mockk(relaxed = true)
    private val crashlytics: FirebaseCrashlytics = mockk(relaxed = true)
    private val analyticsLogger: AnalyticsLogger = mockk(relaxed = true)

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        every { authStateHolder.authState } returns
            authStateFlow as StateFlow<AuthState>
        every { crashlytics.setUserId(any()) } just Runs
        every { analyticsLogger.setUserId(any()) } just Runs
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `Authenticated sets uid on both Crashlytics and Analytics`() = runTest(dispatcher) {
        val observer = CrashlyticsUserObserver(authStateHolder, crashlytics, analyticsLogger, TestScope(dispatcher))

        observer.start()
        authStateFlow.value = AuthState.Authenticated("uid-1", "a@b.com", "Alice")
        advanceUntilIdle()

        verify(exactly = 1) { crashlytics.setUserId("uid-1") }
        verify(exactly = 1) { analyticsLogger.setUserId("uid-1") }
    }

    @Test
    fun `Unauthenticated clears uid on both sinks`() = runTest(dispatcher) {
        val observer = CrashlyticsUserObserver(authStateHolder, crashlytics, analyticsLogger, TestScope(dispatcher))

        observer.start()
        authStateFlow.value = AuthState.Unauthenticated
        advanceUntilIdle()

        verify(exactly = 1) { crashlytics.setUserId("") }
        verify(exactly = 1) { analyticsLogger.setUserId(null) }
    }

    @Test
    fun `Loading state does not touch the sinks`() = runTest(dispatcher) {
        val observer = CrashlyticsUserObserver(authStateHolder, crashlytics, analyticsLogger, TestScope(dispatcher))

        observer.start()
        advanceUntilIdle()

        verify(exactly = 0) { crashlytics.setUserId(any()) }
        verify(exactly = 0) { analyticsLogger.setUserId(any()) }
    }
}
