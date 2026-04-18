package com.kpopvote.collector.data.model

import kotlinx.serialization.Serializable

/**
 * Open Graph Protocol metadata fetched via Cloud Functions `fetchTaskOGP`.
 * The iOS app defines this endpoint but does not wire it into the UI yet;
 * we provide the client side so Sprint 4+ can enable URL previews without a round trip.
 */
@Serializable
data class OgpMetadata(
    val title: String? = null,
    val description: String? = null,
    val imageUrl: String? = null,
    val siteName: String? = null,
)
