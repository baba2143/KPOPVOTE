package com.kpopvote.collector.ui.votestab

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

enum class VotesTab { DISCOVER, SAVED, MY_COLLECTIONS }

/**
 * Holds the selected segment for `VotesTabScreen`. Child leaf screens
 * (Discover / Saved / MyCollections) observe this to decide whether to load.
 */
@HiltViewModel
class VotesTabsViewModel @Inject constructor() : ViewModel() {

    private val _selectedTab = MutableStateFlow(VotesTab.DISCOVER)
    val selectedTab: StateFlow<VotesTab> = _selectedTab.asStateFlow()

    fun selectTab(tab: VotesTab) {
        _selectedTab.value = tab
    }
}
