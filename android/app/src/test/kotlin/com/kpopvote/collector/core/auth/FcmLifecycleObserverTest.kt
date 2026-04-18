package com.kpopvote.collector.core.auth

import com.kpopvote.collector.data.repository.FcmTokenRepository
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
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
class FcmLifecycleObserverTest {

    private val dispatcher = StandardTestDispatcher()
    private val authStateFlow = MutableStateFlow<AuthState>(AuthState.Loading)
    private val authStateHolder: AuthStateHolder = mockk(relaxed = true)
    private val repo: FcmTokenRepository = mockk(relaxed = true)
    private val fetcher: FcmTokenFetcher = FcmTokenFetcher { "test-token" }

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        io.mockk.every { authStateHolder.authState } returns
            authStateFlow as kotlinx.coroutines.flow.StateFlow<AuthState>
        coEvery { repo.register(any()) } returns Result.success(Unit)
        coEvery { repo.unregister() } returns Result.success(Unit)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `Authenticated transition triggers register with fetched token`() = runTest(dispatcher) {
        val observer = FcmLifecycleObserver(authStateHolder, repo, TestScope(dispatcher), fetcher)

        observer.start()
        authStateFlow.value = AuthState.Authenticated("uid-1", "a@b.com", "Alice")
        advanceUntilIdle()

        coVerify(exactly = 1) { repo.register("test-token") }
        coVerify(exactly = 0) { repo.unregister() }
    }

    @Test
    fun `Unauthenticated transition triggers unregister`() = runTest(dispatcher) {
        val observer = FcmLifecycleObserver(authStateHolder, repo, TestScope(dispatcher), fetcher)

        observer.start()
        authStateFlow.value = AuthState.Unauthenticated
        advanceUntilIdle()

        coVerify(exactly = 1) { repo.unregister() }
        coVerify(exactly = 0) { repo.register(any()) }
    }

    @Test
    fun `token fetch failure does not crash and skips register`() = runTest(dispatcher) {
        val throwingFetcher = FcmTokenFetcher { error("fetch failed") }
        val observer = FcmLifecycleObserver(authStateHolder, repo, TestScope(dispatcher), throwingFetcher)

        observer.start()
        authStateFlow.value = AuthState.Authenticated("uid-1", null, null)
        advanceUntilIdle()

        coVerify(exactly = 0) { repo.register(any()) }
    }

    @Test
    fun `Loading state does not trigger register or unregister`() = runTest(dispatcher) {
        val observer = FcmLifecycleObserver(authStateHolder, repo, TestScope(dispatcher), fetcher)

        observer.start()
        // Flow stays in Loading
        advanceUntilIdle()

        coVerify(exactly = 0) { repo.register(any()) }
        coVerify(exactly = 0) { repo.unregister() }
    }
}
