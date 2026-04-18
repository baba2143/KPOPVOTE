package com.kpopvote.collector.navigation

import android.os.Bundle
import com.kpopvote.collector.notifications.EXTRA_NOTIFICATION_TYPE
import com.kpopvote.collector.notifications.EXTRA_VOTE_ID

/**
 * In-app destination derived from a notification tap's intent extras.
 *
 * v1.0 only resolves `type == "vote"` to a specific screen; all other types fall back to
 * [OpenHome]. Community / DM / post-detail destinations land in v1.1 when those graphs ship.
 */
sealed interface DeepLinkIntent {
    data object OpenHome : DeepLinkIntent
    data class OpenVote(val voteId: String) : DeepLinkIntent

    companion object {
        fun fromBundle(extras: Bundle?): DeepLinkIntent? {
            if (extras == null) return null
            val type = extras.getString(EXTRA_NOTIFICATION_TYPE) ?: return null
            val voteId = extras.getString(EXTRA_VOTE_ID)
            return resolve(type, voteId)
        }

        /** Pure-JVM resolver — no Android deps, used by `fromBundle` and unit tests. */
        internal fun resolve(type: String?, voteId: String?): DeepLinkIntent? {
            if (type == null) return null
            return when (type) {
                "vote" -> {
                    val safeVoteId = voteId?.takeIf { it.isNotEmpty() }
                    if (safeVoteId != null) OpenVote(safeVoteId) else OpenHome
                }
                // Known iOS types we don't yet have a destination for — route to Home.
                "follow", "like", "comment", "mention", "dm", "system", "sameBiasFans" -> OpenHome
                else -> null
            }
        }
    }
}
