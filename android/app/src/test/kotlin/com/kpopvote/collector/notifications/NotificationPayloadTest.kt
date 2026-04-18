package com.kpopvote.collector.notifications

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationPayloadTest {

    @Test
    fun `fromDataMap reads every known field`() {
        val data = mapOf(
            "type" to "vote",
            "notificationId" to "notif-1",
            "voteId" to "vote-42",
            "postId" to "post-9",
            "commentId" to "comment-3",
            "userId" to "user-u",
        )

        val payload = NotificationPayload.fromDataMap(data)

        assertEquals("vote", payload.type)
        assertEquals("notif-1", payload.notificationId)
        assertEquals("vote-42", payload.voteId)
        assertEquals("post-9", payload.postId)
        assertEquals("comment-3", payload.commentId)
        assertEquals("user-u", payload.userId)
    }

    @Test
    fun `fromDataMap treats empty strings as null`() {
        val data = mapOf(
            "type" to "follow",
            "notificationId" to "",
            "voteId" to "",
            "postId" to "",
            "commentId" to "",
            "userId" to "",
        )

        val payload = NotificationPayload.fromDataMap(data)

        assertEquals("follow", payload.type)
        assertNull(payload.notificationId)
        assertNull(payload.voteId)
        assertNull(payload.postId)
        assertNull(payload.commentId)
        assertNull(payload.userId)
    }

    @Test
    fun `fromDataMap falls back type to system when missing`() {
        val payload = NotificationPayload.fromDataMap(emptyMap())
        assertEquals("system", payload.type)
    }

    @Test
    fun `stableNotificationId is positive and deterministic`() {
        val a = NotificationPayload.fromDataMap(mapOf("type" to "vote", "notificationId" to "x1"))
        val b = NotificationPayload.fromDataMap(mapOf("type" to "vote", "notificationId" to "x1"))
        val c = NotificationPayload.fromDataMap(mapOf("type" to "vote", "notificationId" to "x2"))

        assertTrue(a.stableNotificationId() > 0)
        assertEquals(a.stableNotificationId(), b.stableNotificationId())
        assertNotEquals(a.stableNotificationId(), c.stableNotificationId())
    }

    @Test
    fun `stableNotificationId falls back to type + id composite when notificationId is null`() {
        val noId = NotificationPayload.fromDataMap(mapOf("type" to "vote", "voteId" to "v1"))
        val otherVote = NotificationPayload.fromDataMap(mapOf("type" to "vote", "voteId" to "v2"))

        assertNotEquals(noId.stableNotificationId(), otherVote.stableNotificationId())
    }
}
