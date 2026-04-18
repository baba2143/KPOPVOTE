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

    // Invite (Sprint 7)
    const val GENERATE_INVITE_CODE = "generateInviteCode"
    const val APPLY_INVITE_CODE = "applyInviteCode"

    // Tasks (Sprint 3)
    const val GET_USER_TASKS = "getUserTasks"
    const val REGISTER_TASK = "registerTask"
    const val UPDATE_TASK = "updateTask"
    const val UPDATE_TASK_STATUS = "updateTaskStatus"
    const val DELETE_TASK = "deleteTask"
    const val FETCH_TASK_OGP = "fetchTaskOGP"

    // In-App Votes (Sprint 4)
    const val LIST_IN_APP_VOTES = "listInAppVotes"
    const val GET_IN_APP_VOTE = "getInAppVoteDetail"
    const val EXECUTE_VOTE = "executeVote"
    const val GET_RANKING = "getRanking"

    // Collections (Sprint 4)
    const val COLLECTIONS = "collections"
    const val SEARCH_COLLECTIONS = "searchCollections"
    const val TRENDING_COLLECTIONS = "trendingCollections"
    const val MY_COLLECTIONS = "myCollections"
    const val SAVED_COLLECTIONS = "savedCollections"

    // FCM (Sprint 8)
    const val REGISTER_FCM_TOKEN = "registerFcmToken"
    const val UNREGISTER_FCM_TOKEN = "unregisterFcmToken"
}
