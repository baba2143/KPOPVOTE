package com.kpopvote.collector.notifications

/**
 * Parsed representation of the FCM `data` payload (all fields are strings in transit).
 * Mirrors the keys emitted by `functions/src/utils/fcmHelper.ts#toStringMap`.
 *
 * This is a plain data class (no Android deps) so it can be unit-tested on the JVM.
 */
data class NotificationPayload(
    val type: String,
    val notificationId: String?,
    val voteId: String?,
    val postId: String?,
    val commentId: String?,
    val userId: String?,
) {
    companion object {
        /** Treat empty strings as null — the backend emits "" for missing ids. */
        fun fromDataMap(data: Map<String, String>): NotificationPayload = NotificationPayload(
            type = data["type"].orEmpty().ifEmpty { "system" },
            notificationId = data["notificationId"].nonEmptyOrNull(),
            voteId = data["voteId"].nonEmptyOrNull(),
            postId = data["postId"].nonEmptyOrNull(),
            commentId = data["commentId"].nonEmptyOrNull(),
            userId = data["userId"].nonEmptyOrNull(),
        )

        private fun String?.nonEmptyOrNull(): String? =
            this?.takeIf { it.isNotEmpty() }
    }
}
