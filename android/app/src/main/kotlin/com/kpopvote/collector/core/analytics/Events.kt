package com.kpopvote.collector.core.analytics

/**
 * Analytics event names shared between Android and iOS.
 *
 * iOS parity: `ios/KPOPVOTE/KPOPVOTE/Services/AnalyticsService.swift`.
 * Keep names ≤ 40 chars, lowercase snake_case (Firebase Analytics constraint).
 */
object Events {
    const val TASK_CREATED = "task_created"
    const val TASK_UPDATED = "task_updated"
    const val VOTE_EXECUTED = "vote_executed"
    const val COLLECTION_SAVED = "collection_saved"
    const val SCREEN_VIEW = "screen_view"
}

object EventParams {
    const val TASK_ID = "task_id"
    const val VOTE_ID = "vote_id"
    const val VOTE_COUNT = "vote_count"
    const val COLLECTION_ID = "collection_id"
    const val SCREEN_NAME = "screen_name"
    const val SCREEN_CLASS = "screen_class"
}
