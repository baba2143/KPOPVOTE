package com.kpopvote.collector.navigation

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class DeepLinkIntentTest {

    @Test
    fun `vote type with voteId resolves to OpenVote`() {
        val result = DeepLinkIntent.resolve(type = "vote", voteId = "v-42")
        assertTrue(result is DeepLinkIntent.OpenVote)
        assertEquals("v-42", (result as DeepLinkIntent.OpenVote).voteId)
    }

    @Test
    fun `vote type without voteId falls back to OpenHome`() {
        val result = DeepLinkIntent.resolve(type = "vote", voteId = null)
        assertSame(DeepLinkIntent.OpenHome, result)
    }

    @Test
    fun `vote type with empty voteId falls back to OpenHome`() {
        val result = DeepLinkIntent.resolve(type = "vote", voteId = "")
        assertSame(DeepLinkIntent.OpenHome, result)
    }

    @Test
    fun `known non-vote types map to OpenHome`() {
        listOf("follow", "like", "comment", "mention", "dm", "system", "sameBiasFans").forEach { type ->
            val result = DeepLinkIntent.resolve(type = type, voteId = null)
            assertSame("type=$type should resolve to OpenHome", DeepLinkIntent.OpenHome, result)
        }
    }

    @Test
    fun `unknown type returns null`() {
        val result = DeepLinkIntent.resolve(type = "unknown-type", voteId = null)
        assertNull(result)
    }

    @Test
    fun `null type returns null`() {
        assertNull(DeepLinkIntent.resolve(type = null, voteId = null))
    }
}
