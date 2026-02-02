/**
 * Idol Ranking Vote endpoint
 * POST /idolRankingVote
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  IdolRankingVoteRequest,
  IdolRankingVoteResponse,
  RankingType,
} from "../types";

const MAX_DAILY_VOTES = 5;

// Get today's date in YYYY-MM-DD format (JST)
function getTodayDateString(): string {
  const now = new Date();
  // Convert to JST (UTC+9)
  const jstOffset = 9 * 60 * 60 * 1000;
  const jstDate = new Date(now.getTime() + jstOffset);
  return jstDate.toISOString().split("T")[0];
}

export const idolRankingVote = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Handle preflight request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Only accept POST requests
  if (req.method !== "POST") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use POST.",
    } as ApiResponse<null>);
    return;
  }

  try {
    // Verify authentication token
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({
        success: false,
        error: "Unauthorized: No token provided",
      } as ApiResponse<null>);
      return;
    }

    const token = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = decodedToken.uid;

    // Get request body
    const { entityId, entityType, name, groupName, imageUrl } =
      req.body as IdolRankingVoteRequest;

    // Validate required fields
    if (!entityId || typeof entityId !== "string") {
      res.status(400).json({
        success: false,
        error: "entityId is required",
      } as ApiResponse<null>);
      return;
    }

    if (!entityType || !["individual", "group"].includes(entityType)) {
      res.status(400).json({
        success: false,
        error: "entityType must be 'individual' or 'group'",
      } as ApiResponse<null>);
      return;
    }

    if (!name || typeof name !== "string") {
      res.status(400).json({
        success: false,
        error: "name is required",
      } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();
    const today = getTodayDateString();

    // Check daily limit
    const dailyLimitDocId = `${uid}_${today}`;
    const dailyLimitRef = db.collection("idolRankingDailyLimits").doc(dailyLimitDocId);

    // Use transaction to ensure atomic operation
    const result = await db.runTransaction(async (transaction) => {
      // Check daily limit
      const dailyLimitDoc = await transaction.get(dailyLimitRef);
      let votesUsed = 0;
      let voteDetails: { entityId: string; entityType: RankingType; votedAt: admin.firestore.Timestamp }[] = [];

      if (dailyLimitDoc.exists) {
        const data = dailyLimitDoc.data()!;
        votesUsed = data.votesUsed || 0;
        voteDetails = data.voteDetails || [];
      }

      if (votesUsed >= MAX_DAILY_VOTES) {
        throw new Error("DAILY_LIMIT_EXCEEDED");
      }

      // Update or create idol ranking vote document
      const voteDocId = `${entityType}_${entityId}`;
      const voteRef = db.collection("idolRankingVotes").doc(voteDocId);
      const voteDoc = await transaction.get(voteRef);

      let newWeeklyVotes = 1;
      let newAllTimeVotes = 1;

      if (voteDoc.exists) {
        const voteData = voteDoc.data()!;
        newWeeklyVotes = (voteData.weeklyVotes || 0) + 1;
        newAllTimeVotes = (voteData.allTimeVotes || 0) + 1;

        transaction.update(voteRef, {
          weeklyVotes: newWeeklyVotes,
          allTimeVotes: newAllTimeVotes,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(voteRef, {
          entityId,
          rankingType: entityType,
          name,
          groupName: entityType === "individual" ? groupName || null : null,
          imageUrl: imageUrl || null,
          weeklyVotes: 1,
          allTimeVotes: 1,
          lastWeeklyReset: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Update daily limit
      const newVoteDetail = {
        entityId,
        entityType,
        votedAt: admin.firestore.Timestamp.now(),
      };

      if (dailyLimitDoc.exists) {
        transaction.update(dailyLimitRef, {
          votesUsed: votesUsed + 1,
          voteDetails: [...voteDetails, newVoteDetail],
        });
      } else {
        transaction.set(dailyLimitRef, {
          userId: uid,
          date: today,
          votesUsed: 1,
          voteDetails: [newVoteDetail],
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return {
        remainingVotes: MAX_DAILY_VOTES - (votesUsed + 1),
        totalVotes: newAllTimeVotes,
      };
    });

    res.status(200).json({
      success: true,
      data: {
        success: true,
        remainingVotes: result.remainingVotes,
        totalVotes: result.totalVotes,
      },
    } as ApiResponse<IdolRankingVoteResponse>);
  } catch (error: unknown) {
    console.error("Idol ranking vote error:", error);

    if (error instanceof Error && error.message === "DAILY_LIMIT_EXCEEDED") {
      res.status(429).json({
        success: false,
        error: "Daily vote limit exceeded. You can vote up to 5 times per day.",
      } as ApiResponse<null>);
      return;
    }

    // Handle specific Firebase errors
    if (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      error.code === "auth/id-token-expired"
    ) {
      res.status(401).json({
        success: false,
        error: "Token expired",
      } as ApiResponse<null>);
      return;
    }

    res.status(500).json({
      success: false,
      error: "Internal server error",
    } as ApiResponse<null>);
  }
});
