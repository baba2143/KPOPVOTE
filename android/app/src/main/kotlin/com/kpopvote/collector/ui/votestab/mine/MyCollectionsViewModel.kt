package com.kpopvote.collector.ui.votestab.mine

import com.kpopvote.collector.data.model.CollectionsListData
import com.kpopvote.collector.data.repository.CollectionRepository
import com.kpopvote.collector.ui.votestab.PagedCollectionsViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class MyCollectionsViewModel @Inject constructor(
    private val collectionRepository: CollectionRepository,
) : PagedCollectionsViewModel() {

    override suspend fun fetchPage(page: Int): Result<CollectionsListData> =
        collectionRepository.getMyCollections(page = page)
}
