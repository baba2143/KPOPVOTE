package com.kpopvote.collector.data.api

/**
 * Cloud Functions HTTP endpoint paths (relative to BuildConfig.FUNCTIONS_BASE_URL).
 * Mirrors iOS `Constants.API.*` entries. Only endpoints consumed in Sprint 2+ live here.
 */
object ApiPaths {
    // Master data
    const val LIST_IDOLS = "listIdols"
    const val LIST_GROUPS = "listGroups"
    const val LIST_EXTERNAL_APPS = "listExternalApps"

    // Bias
    const val GET_BIAS = "getBias"
    const val SET_BIAS = "setBias"

    // User profile
    const val UPDATE_USER_PROFILE = "updateUserProfile"
}
