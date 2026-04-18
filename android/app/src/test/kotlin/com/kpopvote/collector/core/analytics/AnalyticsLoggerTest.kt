package com.kpopvote.collector.core.analytics

import android.os.Bundle
import com.google.firebase.analytics.FirebaseAnalytics
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import org.junit.Assert.assertNotNull
import org.junit.Test

class AnalyticsLoggerTest {

    private val analytics: FirebaseAnalytics = mockk(relaxed = true)
    private val logger = AnalyticsLogger(analytics)

    @Test
    fun `logEvent forwards event name to FirebaseAnalytics`() {
        val nameSlot = slot<String>()
        val bundleSlot = slot<Bundle>()
        every { analytics.logEvent(capture(nameSlot), capture(bundleSlot)) } just Runs

        logger.logEvent(
            Events.VOTE_EXECUTED,
            mapOf(
                EventParams.VOTE_ID to "v-1",
                EventParams.VOTE_COUNT to 3,
            ),
        )

        assert(nameSlot.captured == Events.VOTE_EXECUTED)
        assertNotNull(bundleSlot.captured)
    }

    @Test
    fun `logEvent tolerates null values in params`() {
        logger.logEvent(
            Events.TASK_CREATED,
            mapOf(
                EventParams.TASK_ID to null,
                "kept" to "value",
            ),
        )

        verify(exactly = 1) { analytics.logEvent(Events.TASK_CREATED, any()) }
    }

    @Test
    fun `logScreenView forwards to SCREEN_VIEW event`() {
        logger.logScreenView("VoteDetail", "VoteDetailScreen")

        verify(exactly = 1) { analytics.logEvent(Events.SCREEN_VIEW, any()) }
    }

    @Test
    fun `setUserId forwards both uid and null to FirebaseAnalytics`() {
        logger.setUserId("uid-42")
        logger.setUserId(null)

        verify(exactly = 1) { analytics.setUserId("uid-42") }
        verify(exactly = 1) { analytics.setUserId(null) }
    }

    @Test
    fun `toBundle handles int long double float boolean and string primitives`() {
        val map: Map<String, Any?> = mapOf(
            "s" to "x",
            "i" to 1,
            "l" to 2L,
            "d" to 3.0,
            "f" to 4.0f,
            "b" to true,
            "obj" to object { override fun toString() = "custom" },
            "null" to null,
        )

        map.toBundle()
    }
}
