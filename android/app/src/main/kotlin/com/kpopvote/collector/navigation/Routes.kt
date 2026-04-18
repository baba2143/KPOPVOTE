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

    // Main graph
    @Serializable data object MainGraph : Route
    @Serializable data object Home : Route
}
