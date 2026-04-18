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

    // Tasks (Sprint 3)
    const val GET_USER_TASKS = "getUserTasks"
    const val REGISTER_TASK = "registerTask"
    const val UPDATE_TASK = "updateTask"
    const val UPDATE_TASK_STATUS = "updateTaskStatus"
    const val DELETE_TASK = "deleteTask"
    const val FETCH_TASK_OGP = "fetchTaskOGP"
}
