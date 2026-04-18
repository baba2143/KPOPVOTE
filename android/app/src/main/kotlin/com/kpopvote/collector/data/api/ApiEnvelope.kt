package com.kpopvote.collector.data.api

import kotlinx.serialization.Serializable

/**
 * Shared response envelope used by Cloud Functions: `{ success, data }`.
 * See iOS `IdolListResponse`, `GroupListResponse`, `BiasResponse` for the contract.
 */
@Serializable
data class ApiEnvelope<T>(
    val success: Boolean,
    val data: T,
)

/** Generic error body shape: `{ success: false, error: "message" }`. */
@Serializable
data class ApiErrorBody(
    val success: Boolean = false,
    val error: String? = null,
    val message: String? = null,
) {
    val displayMessage: String? get() = error ?: message
}
