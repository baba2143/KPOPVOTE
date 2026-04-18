package com.kpopvote.collector.ui.votestab

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.kpopvote.collector.ui.votestab.discover.DiscoverScreen
import com.kpopvote.collector.ui.votestab.mine.MyCollectionsScreen
import com.kpopvote.collector.ui.votestab.saved.SavedCollectionsScreen

/**
 * iOS `VotesTabView` equivalent: 3 segments — Discover / Saved / MyCollections.
 * Reached from the bottom NavigationBar "Votes" tab. Each segment owns its own ViewModel
 * (scoped to the Hilt nav-entry), so switching tabs preserves scroll/state.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VotesTabScreen(
    onOpenCollection: (String) -> Unit,
    onCreateCollection: () -> Unit,
    viewModel: VotesTabsViewModel = hiltViewModel(),
) {
    val selectedTab by viewModel.selectedTab.collectAsStateWithLifecycle()

    Scaffold(
        topBar = { TopAppBar(title = { Text("投票") }) },
    ) { padding ->
        Column(Modifier.fillMaxSize().padding(padding)) {
            TabRow(selectedTabIndex = selectedTab.ordinal) {
                VotesTab.entries.forEach { tab ->
                    Tab(
                        selected = selectedTab == tab,
                        onClick = { viewModel.selectTab(tab) },
                        text = { Text(tab.label()) },
                    )
                }
            }
            when (selectedTab) {
                VotesTab.DISCOVER -> DiscoverScreen(onOpenCollection = onOpenCollection)
                VotesTab.SAVED -> SavedCollectionsScreen(onOpenCollection = onOpenCollection)
                VotesTab.MY_COLLECTIONS -> MyCollectionsScreen(
                    onOpenCollection = onOpenCollection,
                    onCreateCollection = onCreateCollection,
                )
            }
        }
    }
}

private fun VotesTab.label(): String = when (this) {
    VotesTab.DISCOVER -> "探す"
    VotesTab.SAVED -> "保存済み"
    VotesTab.MY_COLLECTIONS -> "マイコレクション"
}
