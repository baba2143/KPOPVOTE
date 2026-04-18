package com.kpopvote.collector.core.analytics

import android.os.Bundle
import com.google.firebase.analytics.FirebaseAnalytics
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Thin wrapper around [FirebaseAnalytics] so callers depend on a small, testable surface.
 *
 * Params must use only supported primitive types (String, Long, Double, Int, Boolean).
 * Unsupported types are silently dropped to keep callers defensive.
 */
@Singleton
class AnalyticsLogger @Inject constructor(
    private val analytics: FirebaseAnalytics,
) {
    fun logEvent(name: String, params: Map<String, Any?> = emptyMap()) {
        analytics.logEvent(name, params.toBundle())
    }

    fun logScreenView(screenName: String, screenClass: String) {
        logEvent(
            Events.SCREEN_VIEW,
            mapOf(
                EventParams.SCREEN_NAME to screenName,
                EventParams.SCREEN_CLASS to screenClass,
            ),
        )
    }

    fun setUserId(userId: String?) {
        analytics.setUserId(userId)
    }
}

internal fun Map<String, Any?>.toBundle(): Bundle = Bundle().also { bundle ->
    forEach { (key, value) ->
        when (value) {
            null -> Unit
            is String -> bundle.putString(key, value)
            is Int -> bundle.putInt(key, value)
            is Long -> bundle.putLong(key, value)
            is Double -> bundle.putDouble(key, value)
            is Float -> bundle.putFloat(key, value)
            is Boolean -> bundle.putBoolean(key, value)
            else -> bundle.putString(key, value.toString())
        }
    }
}
