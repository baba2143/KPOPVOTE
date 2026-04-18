package com.kpopvote.collector.ui.votestab.saved

import com.kpopvote.collector.data.model.CollectionsListData
import com.kpopvote.collector.data.repository.CollectionRepository
import com.kpopvote.collector.ui.votestab.PagedCollectionsViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class SavedCollectionsViewModel @Inject constructor(
    private val collectionRepository: CollectionRepository,
) : PagedCollectionsViewModel() {

    override suspend fun fetchPage(page: Int): Result<CollectionsListData> =
        collectionRepository.getSavedCollections(page = page)
}
