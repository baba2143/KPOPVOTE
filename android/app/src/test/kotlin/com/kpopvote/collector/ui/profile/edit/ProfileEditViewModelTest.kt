package com.kpopvote.collector.ui.profile.edit

import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.User
import com.kpopvote.collector.data.repository.ProfileImageRepository
import com.kpopvote.collector.data.repository.UserRepository
import io.mockk.coEvery
import io.mockk.coVerify
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
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ProfileEditViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var userRepo: UserRepository
    private lateinit var imageRepo: ProfileImageRepository

    private fun existingUser() = User(
        id = "u1",
        email = "u1@example.com",
        displayName = "Alice",
        bio = "hello",
        photoURL = "https://cdn.example.com/old.jpg",
    )

    @Before
    fun setup() {
        Dispatchers.setMain(dispatcher)
        userRepo = mockk()
        imageRepo = mockk()
    }

    @After
    fun teardown() = Dispatchers.resetMain()

    @Test
    fun `init loads current user and has no validation errors`() = runTest {
        coEvery { userRepo.getCurrentUser() } returns Result.success(existingUser())

        val vm = ProfileEditViewModel(userRepo, imageRepo)
        dispatcher.scheduler.advanceUntilIdle()

        assertEquals("Alice", vm.state.value.displayName)
        assertEquals("hello", vm.state.value.bio)
        assertEquals("https://cdn.example.com/old.jpg", vm.state.value.photoRemoteUrl)
        assertTrue(vm.state.value.validationErrors.isEmpty())
    }

    @Test
    fun `empty displayName triggers DISPLAY_NAME_REQUIRED`() = runTest {
        coEvery { userRepo.getCurrentUser() } returns Result.success(existingUser())

        val vm = ProfileEditViewModel(userRepo, imageRepo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.onDisplayNameChange("   ")
        assertTrue(
            vm.state.value.validationErrors.contains(ProfileEditError.DISPLAY_NAME_REQUIRED)
        )
    }

    @Test
    fun `overlong bio triggers BIO_TOO_LONG`() = runTest {
        coEvery { userRepo.getCurrentUser() } returns Result.success(existingUser())

        val vm = ProfileEditViewModel(userRepo, imageRepo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.onBioChange("a".repeat(ProfileEditViewModel.BIO_MAX + 1))
        assertTrue(vm.state.value.validationErrors.contains(ProfileEditError.BIO_TOO_LONG))
    }

    @Test
    fun `photo bigger than 2MB triggers PHOTO_TOO_LARGE`() = runTest {
        coEvery { userRepo.getCurrentUser() } returns Result.success(existingUser())

        val vm = ProfileEditViewModel(userRepo, imageRepo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.onPhotoPicked(ByteArray(ProfileEditViewModel.PHOTO_MAX_BYTES + 1))
        assertTrue(vm.state.value.validationErrors.contains(ProfileEditError.PHOTO_TOO_LARGE))
    }

    @Test
    fun `submit uploads new photo then calls updateProfile`() = runTest {
        coEvery { userRepo.getCurrentUser() } returns Result.success(existingUser())
        coEvery { imageRepo.upload(any()) } returns Result.success("https://cdn/new.jpg")
        coEvery { userRepo.updateProfile(displayName = any(), bio = any(), photoURL = any()) } returns
            Result.success(existingUser().copy(photoURL = "https://cdn/new.jpg"))

        val vm = ProfileEditViewModel(userRepo, imageRepo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.onPhotoPicked(ByteArray(100))
        vm.submit()
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 1) { imageRepo.upload(any()) }
        coVerify(exactly = 1) {
            userRepo.updateProfile(
                displayName = "Alice",
                bio = "hello",
                photoURL = "https://cdn/new.jpg",
            )
        }
        assertTrue(vm.state.value.submitted)
        assertFalse(vm.state.value.isSubmitting)
        assertNull(vm.state.value.error)
    }

    @Test
    fun `submit without new photo skips upload and keeps existing photoURL`() = runTest {
        coEvery { userRepo.getCurrentUser() } returns Result.success(existingUser())
        coEvery { userRepo.updateProfile(displayName = any(), bio = any(), photoURL = any()) } returns
            Result.success(existingUser())

        val vm = ProfileEditViewModel(userRepo, imageRepo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.submit()
        dispatcher.scheduler.advanceUntilIdle()

        coVerify(exactly = 0) { imageRepo.upload(any()) }
        coVerify(exactly = 1) {
            userRepo.updateProfile(
                displayName = "Alice",
                bio = "hello",
                photoURL = "https://cdn.example.com/old.jpg",
            )
        }
    }

    @Test
    fun `submit surfaces updateProfile error without setting submitted`() = runTest {
        coEvery { userRepo.getCurrentUser() } returns Result.success(existingUser())
        coEvery { userRepo.updateProfile(displayName = any(), bio = any(), photoURL = any()) } returns
            Result.failure(AppError.Network)

        val vm = ProfileEditViewModel(userRepo, imageRepo)
        dispatcher.scheduler.advanceUntilIdle()

        vm.submit()
        dispatcher.scheduler.advanceUntilIdle()

        assertFalse(vm.state.value.submitted)
        assertFalse(vm.state.value.isSubmitting)
        assertSame(AppError.Network, vm.state.value.error)
    }
}
