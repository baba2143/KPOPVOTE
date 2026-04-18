package com.kpopvote.collector.data.repository

import com.kpopvote.collector.core.appcheck.AppCheckTokenProvider
import com.kpopvote.collector.core.common.AppError
import com.kpopvote.collector.data.api.ApiPaths
import com.kpopvote.collector.data.api.FunctionsClient
import com.kpopvote.collector.data.model.InAppVote
import com.kpopvote.collector.data.model.RankingEntry
import com.kpopvote.collector.data.model.VoteChoice
import com.kpopvote.collector.data.model.VoteExecuteResult
import com.kpopvote.collector.data.model.VoteListData
import com.kpopvote.collector.data.model.VoteRanking
import com.kpopvote.collector.data.model.VoteStatus
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import io.mockk.slot
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class VoteRepositoryImplTest {

    private val client: FunctionsClient = mockk(relaxUnitFun = true)
    private val appCheck: AppCheckTokenProvider = mockk()
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val repo = VoteRepositoryImpl(client, appCheck, json)

    private val sampleVote = InAppVote(
        voteId = "v1",
        title = "Best stage",
        status = VoteStatus.ACTIVE,
        startAt = "2026-04-01T00:00:00Z",
        endAt = "2026-04-30T00:00:00Z",
        choices = listOf(
            VoteChoice(choiceId = "c1", displayName = "Alpha", voteCount = 10),
            VoteChoice(choiceId = "c2", displayName = "Beta", voteCount = 4),
        ),
    )

    @Test
    fun `fetchFeaturedVotes passes featured=true query`() = runTest {
        coEvery {
            client.get(ApiPaths.LIST_IN_APP_VOTES, VoteListData.serializer(), mapOf("featured" to "true"))
        } returns VoteListData(listOf(sampleVote), 1)

        val result = repo.fetchFeaturedVotes()

        assertTrue(result.isSuccess)
        assertEquals(listOf(sampleVote), result.getOrNull())
    }

    @Test
    fun `fetchVotes with null status sends empty query`() = runTest {
        coEvery {
            client.get(ApiPaths.LIST_IN_APP_VOTES, VoteListData.serializer(), emptyMap())
        } returns VoteListData(listOf(sampleVote), 1)

        val result = repo.fetchVotes(status = null)

        assertTrue(result.isSuccess)
        coVerify(exactly = 1) {
            client.get(ApiPaths.LIST_IN_APP_VOTES, VoteListData.serializer(), emptyMap())
        }
    }

    @Test
    fun `fetchVotes with ACTIVE status maps to active wire name`() = runTest {
        coEvery {
            client.get(ApiPaths.LIST_IN_APP_VOTES, VoteListData.serializer(), mapOf("status" to "active"))
        } returns VoteListData(emptyList(), 0)

        val result = repo.fetchVotes(status = VoteStatus.ACTIVE)

        assertTrue(result.isSuccess)
    }

    @Test
    fun `fetchVoteDetail passes voteId`() = runTest {
        coEvery {
            client.get(ApiPaths.GET_IN_APP_VOTE, InAppVote.serializer(), mapOf("voteId" to "v1"))
        } returns sampleVote

        val result = repo.fetchVoteDetail("v1")

        assertTrue(result.isSuccess)
        assertEquals(sampleVote, result.getOrNull())
    }

    @Test
    fun `executeVote attaches X-Firebase-AppCheck header when provider returns token`() = runTest {
        coEvery { appCheck.getToken(any()) } returns "app-check-123"
        val headersSlot = slot<Map<String, String>>()
        val bodySlot = slot<String>()
        coEvery {
            client.post(
                ApiPaths.EXECUTE_VOTE,
                capture(bodySlot),
                VoteExecuteResult.serializer(),
                capture(headersSlot),
            )
        } returns VoteExecuteResult(
            voteId = "v1",
            choiceId = "c1",
            voteCount = 1,
            pointsDeducted = 1,
        )

        val result = repo.executeVote("v1", "c1")

        assertTrue(result.isSuccess)
        assertEquals("app-check-123", headersSlot.captured["X-Firebase-AppCheck"])
        assertTrue(bodySlot.captured.contains("\"voteId\":\"v1\""))
        assertTrue(bodySlot.captured.contains("\"choiceId\":\"c1\""))
        assertTrue(bodySlot.captured.contains("\"voteCount\":1"))
        assertTrue(bodySlot.captured.contains("\"pointSelection\":\"auto\""))
    }

    @Test
    fun `executeVote omits AppCheck header when provider returns null`() = runTest {
        coEvery { appCheck.getToken(any()) } returns null
        val headersSlot = slot<Map<String, String>>()
        coEvery {
            client.post(
                ApiPaths.EXECUTE_VOTE,
                any(),
                VoteExecuteResult.serializer(),
                capture(headersSlot),
            )
        } returns VoteExecuteResult(
            voteId = "v1",
            choiceId = "c1",
            voteCount = 1,
            pointsDeducted = 1,
        )

        val result = repo.executeVote("v1", "c1")

        assertTrue(result.isSuccess)
        assertTrue(headersSlot.captured.isEmpty())
    }

    @Test
    fun `executeVote maps 400 already voted server error to Vote_AlreadyVoted`() = runTest {
        coEvery { appCheck.getToken(any()) } returns null
        coEvery {
            client.post(ApiPaths.EXECUTE_VOTE, any(), VoteExecuteResult.serializer(), any())
        } throws AppError.Server(400, "Already voted today")

        val result = repo.executeVote("v1", "c1")

        assertTrue(result.isFailure)
        assertSame(AppError.Vote.AlreadyVoted, result.exceptionOrNull())
    }

    @Test
    fun `executeVote maps 400 insufficient points to Vote_InsufficientPoints`() = runTest {
        coEvery { appCheck.getToken(any()) } returns null
        coEvery {
            client.post(ApiPaths.EXECUTE_VOTE, any(), VoteExecuteResult.serializer(), any())
        } throws AppError.Server(400, "Insufficient points")

        val result = repo.executeVote("v1", "c1")

        assertTrue(result.isFailure)
        assertSame(AppError.Vote.InsufficientPoints, result.exceptionOrNull())
    }

    @Test
    fun `executeVote passes non-400 server error through unchanged`() = runTest {
        coEvery { appCheck.getToken(any()) } returns null
        val underlying = AppError.Server(500, "backend explosion")
        coEvery {
            client.post(ApiPaths.EXECUTE_VOTE, any(), VoteExecuteResult.serializer(), any())
        } throws underlying

        val result = repo.executeVote("v1", "c1")

        assertTrue(result.isFailure)
        assertSame(underlying, result.exceptionOrNull())
    }

    @Test
    fun `fetchRanking returns ranking data`() = runTest {
        val ranking = VoteRanking(
            voteId = "v1",
            rankings = listOf(
                RankingEntry(rank = 1, choiceId = "c1", displayName = "Alpha", voteCount = 10, percentage = 71.4),
                RankingEntry(rank = 2, choiceId = "c2", displayName = "Beta", voteCount = 4, percentage = 28.6),
            ),
            totalVotes = 14,
        )
        coEvery {
            client.get(ApiPaths.GET_RANKING, VoteRanking.serializer(), mapOf("voteId" to "v1"))
        } returns ranking

        val result = repo.fetchRanking("v1")

        assertTrue(result.isSuccess)
        assertEquals(ranking, result.getOrNull())
    }
}
