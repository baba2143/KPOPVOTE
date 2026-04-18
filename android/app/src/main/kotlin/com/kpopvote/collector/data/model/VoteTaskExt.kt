package com.kpopvote.collector.data.model

import com.kpopvote.collector.core.util.IsoDate
import java.util.concurrent.TimeUnit

val VoteTask.deadlineMillis: Long?
    get() = IsoDate.parseToMillis(deadlineIso)

val VoteTask.updatedAtMillis: Long?
    get() = IsoDate.parseToMillis(updatedAtIso)

fun VoteTask.isExpired(now: Long = System.currentTimeMillis()): Boolean {
    val dl = deadlineMillis ?: return false
    return dl < now && status != TaskStatus.COMPLETED && status != TaskStatus.ARCHIVED
}

val VoteTask.isCompleted: Boolean get() = status == TaskStatus.COMPLETED
val VoteTask.isArchived: Boolean get() = status == TaskStatus.ARCHIVED

/**
 * Coarse-grained "time remaining" label (Japanese) matching iOS `timeRemaining`.
 * Returns "期限切れ" if already past or status is completed/archived.
 */
fun VoteTask.timeRemaining(now: Long = System.currentTimeMillis()): String {
    val dl = deadlineMillis ?: return "-"
    val diff = dl - now
    if (diff <= 0) return "期限切れ"
    val days = TimeUnit.MILLISECONDS.toDays(diff)
    if (days >= 1) return "${days}日"
    val hours = TimeUnit.MILLISECONDS.toHours(diff)
    if (hours >= 1) return "${hours}時間"
    val minutes = TimeUnit.MILLISECONDS.toMinutes(diff)
    return "${minutes}分"
}
