package com.kpopvote.collector.ui.votestab.detail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.model.BiasSettings
import com.kpopvote.collector.data.repository.BiasRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ShareCollectionUiState(
    val isLoading: Boolean = false,
    val biases: List<BiasSettings> = emptyList(),
    val selectedArtistIds: Set<String> = emptySet(),
    val text: String = "",
    val error: AppError? = null,
)

/**
 * Feeds [ShareCollectionBottomSheet] with the user's bias list and collects the
 * multi-select state. The actual share POST lives on [CollectionDetailViewModel.share] —
 * this VM only handles bias selection + text drafting so it can be reused if a
 * standalone share flow ever appears.
 */
@HiltViewModel
class ShareCollectionViewModel @Inject constructor(
    private val biasRepository: BiasRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(ShareCollectionUiState())
    val state: StateFlow<ShareCollectionUiState> = _state.asStateFlow()

    init {
        loadBiases()
    }

    fun loadBiases() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            val result = biasRepository.getBias()
            _state.update {
                it.copy(
                    isLoading = false,
                    biases = result.getOrNull().orEmpty(),
                    error = result.exceptionOrNull() as? AppError,
                )
            }
        }
    }

    fun toggleBias(artistId: String) {
        _state.update {
            val next = if (it.selectedArtistIds.contains(artistId)) {
                it.selectedArtistIds - artistId
            } else {
                it.selectedArtistIds + artistId
            }
            it.copy(selectedArtistIds = next)
        }
    }

    fun onTextChange(text: String) {
        _state.update { it.copy(text = text) }
    }

    fun reset() {
        _state.update { it.copy(selectedArtistIds = emptySet(), text = "") }
    }

    fun clearError() = _state.update { it.copy(error = null) }
}
