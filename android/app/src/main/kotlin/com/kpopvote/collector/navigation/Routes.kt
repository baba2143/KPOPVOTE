package com.kpopvote.collector.navigation

import kotlinx.serialization.Serializable

/**
 * Type-safe navigation destinations.
 * Use with Navigation Compose 2.8+ (`composable<Route>` and `navigation<Graph>`).
 */
sealed interface Route {
    @Serializable data object Splash : Route

    // Auth graph
    @Serializable data object AuthGraph : Route
    @Serializable data object Login : Route
    @Serializable data object Register : Route

    // Main graph (bottom tabs)
    @Serializable data object MainGraph : Route
    @Serializable data object Home : Route
    @Serializable data object TaskList : Route
    @Serializable data object Ranking : Route
    @Serializable data object Votes : Route
    @Serializable data object Community : Route
    @Serializable data object Profile : Route

    // Top-level screens reachable from any tab
    @Serializable data class AddTask(val taskId: String? = null) : Route

    // Vote screens (Sprint 4)
    @Serializable data object VoteList : Route
    @Serializable data class VoteDetail(val voteId: String) : Route
    @Serializable data class VoteRanking(val voteId: String) : Route

    // Collection screens (Sprint 4 Phase 4)
    @Serializable data class CollectionDetail(val collectionId: String) : Route

    // Collection authoring screens (Sprint 4 Phase 5)
    @Serializable data object CollectionCreate : Route
    @Serializable data class CollectionEdit(val collectionId: String) : Route
}
