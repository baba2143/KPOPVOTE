/**
 * Get Daily Limit for Idol Ranking endpoint
 * GET /idolRankingGetDailyLimit
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  DailyLimitResponse,
  VoteDetail,
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

export const idolRankingGetDailyLimit = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Handle preflight request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Only accept GET requests
  if (req.method !== "GET") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use GET.",
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

    const db = admin.firestore();
    const today = getTodayDateString();

    // Get daily limit document
    const dailyLimitDocId = `${uid}_${today}`;
    const dailyLimitRef = db.collection("idolRankingDailyLimits").doc(dailyLimitDocId);
    const dailyLimitDoc = await dailyLimitRef.get();

    let votesUsed = 0;
    let voteDetails: VoteDetail[] = [];

    if (dailyLimitDoc.exists) {
      const data = dailyLimitDoc.data()!;
      votesUsed = data.votesUsed || 0;
      voteDetails = (data.voteDetails || []).map((detail: { entityId: string; entityType: "individual" | "group"; votedAt: admin.firestore.Timestamp }) => ({
        entityId: detail.entityId,
        entityType: detail.entityType,
        votedAt: detail.votedAt.toDate(),
      }));
    }

    res.status(200).json({
      success: true,
      data: {
        votesUsed,
        maxVotes: MAX_DAILY_VOTES,
        remainingVotes: MAX_DAILY_VOTES - votesUsed,
        voteDetails,
      },
    } as ApiResponse<DailyLimitResponse>);
  } catch (error: unknown) {
    console.error("Get daily limit error:", error);

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
