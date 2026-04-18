package com.kpopvote.collector.ui.profile

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.User
import com.kpopvote.collector.data.repository.AuthRepository
import com.kpopvote.collector.data.repository.UserRepository
import io.mockk.Runs
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.just
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ProfileViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var userRepo: UserRepository
    private lateinit var authRepo: AuthRepository
    private lateinit var vm: ProfileViewModel

    private fun user(id: String = "u1") =
        User(id = id, email = "$id@example.com", displayName = "Name", points = 42)

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        userRepo = mockk()
        authRepo = mockk()
    }

    @After
    fun teardown() = Dispatchers.resetMain()

    @Test
    fun `init refresh loads user on success`() = runTest {
        coEvery { userRepo.getCurrentUser() } returns Result.success(user())

        vm = ProfileViewModel(userRepo, authRepo)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals("u1", vm.state.value.user?.id)
        assertFalse(vm.state.value.isLoading)
        assertNull(vm.state.value.error)
    }

    @Test
    fun `refresh failure surfaces error and keeps existing user`() = runTest {
        coEvery { userRepo.getCurrentUser() } returnsMany listOf(
            Result.success(user("cached")),
            Result.failure(AppError.Network),
        )

        vm = ProfileViewModel(userRepo, authRepo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.refresh()
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals("cached", vm.state.value.user?.id)
        assertSame(AppError.Network, vm.state.value.error)
    }

    @Test
    fun `signOut calls auth repo then onComplete`() = runTest {
        coEvery { userRepo.getCurrentUser() } returns Result.success(user())
        coEvery { authRepo.signOut() } just Runs

        vm = ProfileViewModel(userRepo, authRepo)
        dispatcher.scheduler.advanceUntilIdle()

        var completed = false
        vm.signOut { completed = true }
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 1) { authRepo.signOut() }
        assertEquals(true, completed)
    }

    @Test
    fun `clearError resets error state`() = runTest {
        coEvery { userRepo.getCurrentUser() } returns Result.failure(AppError.Network)

        vm = ProfileViewModel(userRepo, authRepo)
        dispatcher.scheduler.advanceUntilIdle()
        assertSame(AppError.Network, vm.state.value.error)

        vm.clearError()
        assertNull(vm.state.value.error)
    }
}
