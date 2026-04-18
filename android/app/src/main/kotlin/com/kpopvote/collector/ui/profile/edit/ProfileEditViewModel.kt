package com.kpopvote.collector.ui.profile.edit

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.repository.ProfileImageRepository
import com.kpopvote.collector.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class ProfileEditError {
    DISPLAY_NAME_REQUIRED,
    DISPLAY_NAME_TOO_LONG,
    BIO_TOO_LONG,
    PHOTO_TOO_LARGE,
}

data class ProfileEditUiState(
    val displayName: String = "",
    val bio: String = "",
    val photoBytes: ByteArray? = null,
    val photoRemoteUrl: String? = null,
    val isLoading: Boolean = false,
    val isSubmitting: Boolean = false,
    val validationErrors: Set<ProfileEditError> = emptySet(),
    val error: AppError? = null,
    val submitted: Boolean = false,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ProfileEditUiState) return false
        if (displayName != other.displayName) return false
        if (bio != other.bio) return false
        if (photoBytes != null) {
            if (other.photoBytes == null) return false
            if (!photoBytes.contentEquals(other.photoBytes)) return false
        } else if (other.photoBytes != null) return false
        if (photoRemoteUrl != other.photoRemoteUrl) return false
        if (isLoading != other.isLoading) return false
        if (isSubmitting != other.isSubmitting) return false
        if (validationErrors != other.validationErrors) return false
        if (error != other.error) return false
        if (submitted != other.submitted) return false
        return true
    }

    override fun hashCode(): Int {
        var result = displayName.hashCode()
        result = 31 * result + bio.hashCode()
        result = 31 * result + (photoBytes?.contentHashCode() ?: 0)
        result = 31 * result + (photoRemoteUrl?.hashCode() ?: 0)
        result = 31 * result + isLoading.hashCode()
        result = 31 * result + isSubmitting.hashCode()
        result = 31 * result + validationErrors.hashCode()
        result = 31 * result + (error?.hashCode() ?: 0)
        result = 31 * result + submitted.hashCode()
        return result
    }
}

/**
 * Validation (iOS parity `ProfileEditViewModel.swift`):
 *  - displayName: 1..30 chars trimmed
 *  - bio: 0..150 chars
 *  - photo: <=2MB compressed bytes (R2 in sprint7-spec.md)
 */
@HiltViewModel
class ProfileEditViewModel @Inject constructor(
    private val userRepository: UserRepository,
    private val profileImageRepository: ProfileImageRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(ProfileEditUiState().revalidate())
    val state: StateFlow<ProfileEditUiState> = _state.asStateFlow()

    init {
        loadCurrent()
    }

    private fun loadCurrent() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            val result = userRepository.getCurrentUser()
            result.onSuccess { user ->
                _state.update {
                    it.copy(
                        isLoading = false,
                        displayName = user?.displayName.orEmpty(),
                        bio = user?.bio.orEmpty(),
                        photoRemoteUrl = user?.photoURL,
                    ).revalidate()
                }
            }.onFailure { err ->
                _state.update { it.copy(isLoading = false, error = err as? AppError) }
            }
        }
    }

    fun onDisplayNameChange(value: String) {
        _state.update { it.copy(displayName = value).revalidate() }
    }

    fun onBioChange(value: String) {
        _state.update { it.copy(bio = value).revalidate() }
    }

    fun onPhotoPicked(bytes: ByteArray) {
        _state.update { it.copy(photoBytes = bytes).revalidate() }
    }

    fun onClearPhoto() {
        _state.update { it.copy(photoBytes = null, photoRemoteUrl = null).revalidate() }
    }

    fun clearError() = _state.update { it.copy(error = null) }

    fun submit() {
        val current = _state.value.revalidate()
        _state.value = current
        if (current.validationErrors.isNotEmpty() || current.isSubmitting) return

        viewModelScope.launch {
            _state.update { it.copy(isSubmitting = true, error = null) }

            var photoUrl: String? = current.photoRemoteUrl
            if (current.photoBytes != null) {
                val uploadResult = profileImageRepository.upload(current.photoBytes)
                val url = uploadResult.getOrElse {
                    _state.update { s -> s.copy(isSubmitting = false, error = it as? AppError) }
                    return@launch
                }
                photoUrl = url
            }

            val result = userRepository.updateProfile(
                displayName = current.displayName.trim(),
                bio = current.bio.trim(),
                photoURL = photoUrl,
            )
            result.onSuccess {
                _state.update { it.copy(isSubmitting = false, submitted = true) }
            }.onFailure { err ->
                _state.update { it.copy(isSubmitting = false, error = err as? AppError) }
            }
        }
    }

    internal companion object {
        internal const val DISPLAY_NAME_MAX = 30
        internal const val BIO_MAX = 150
        internal const val PHOTO_MAX_BYTES = 2_000_000
    }
}

private fun ProfileEditUiState.revalidate(): ProfileEditUiState {
    val errors = buildSet {
        val trimmed = displayName.trim()
        if (trimmed.isEmpty()) add(ProfileEditError.DISPLAY_NAME_REQUIRED)
        if (trimmed.length > ProfileEditViewModel.DISPLAY_NAME_MAX) add(ProfileEditError.DISPLAY_NAME_TOO_LONG)
        if (bio.length > ProfileEditViewModel.BIO_MAX) add(ProfileEditError.BIO_TOO_LONG)
        if (photoBytes != null && photoBytes.size > ProfileEditViewModel.PHOTO_MAX_BYTES) {
            add(ProfileEditError.PHOTO_TOO_LARGE)
        }
    }
    return copy(validationErrors = errors)
}
