/**
 * Get Idol Ranking endpoint
 * GET /idolRankingGetRanking
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  GetRankingResponse,
  IdolRankingEntry,
  RankingType,
  RankingPeriod,
} from "../types";

export const idolRankingGetRanking = functions
  .runWith({ memory: "256MB", timeoutSeconds: 60, maxInstances: 100 })
  .https.onRequest(async (req, res) => {
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
    // Get query parameters
    const rankingType = req.query.rankingType as RankingType;
    const period = req.query.period as RankingPeriod;
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;

    // Validate rankingType
    if (!rankingType || !["individual", "group"].includes(rankingType)) {
      res.status(400).json({
        success: false,
        error: "rankingType must be 'individual' or 'group'",
      } as ApiResponse<null>);
      return;
    }

    // Validate period
    if (!period || !["weekly", "allTime"].includes(period)) {
      res.status(400).json({
        success: false,
        error: "period must be 'weekly' or 'allTime'",
      } as ApiResponse<null>);
      return;
    }

    // Validate limit
    if (limit < 1 || limit > 100) {
      res.status(400).json({
        success: false,
        error: "limit must be between 1 and 100",
      } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();

    // Determine sort field based on period
    const sortField = period === "weekly" ? "weeklyVotes" : "allTimeVotes";

    // Query rankings
    const rankingsQuery = db
      .collection("idolRankingVotes")
      .where("rankingType", "==", rankingType)
      .orderBy(sortField, "desc")
      .limit(limit + offset);

    const snapshot = await rankingsQuery.get();

    // Get total count for this ranking type
    const countSnapshot = await db
      .collection("idolRankingVotes")
      .where("rankingType", "==", rankingType)
      .count()
      .get();
    const total = countSnapshot.data().count;

    // Convert to response format with pagination
    const rankings: IdolRankingEntry[] = [];
    let currentRank = 1;

    snapshot.docs.forEach((doc, index) => {
      // Skip documents before offset
      if (index < offset) {
        currentRank++;
        return;
      }

      const data = doc.data();
      const votes = period === "weekly" ? data.weeklyVotes : data.allTimeVotes;

      rankings.push({
        rank: currentRank,
        entityId: data.entityId,
        entityType: data.rankingType,
        name: data.name,
        groupName: data.groupName || undefined,
        imageUrl: data.imageUrl,
        votes: votes || 0,
      });

      currentRank++;
    });

    // CDN cache: 10s browser, 30s CDN edge
    res.set("Cache-Control", "public, max-age=10, s-maxage=30");

    res.status(200).json({
      success: true,
      data: {
        rankings,
        total,
        period,
        rankingType,
      },
    } as ApiResponse<GetRankingResponse>);
  } catch (error: unknown) {
    console.error("Get idol ranking error:", error);

    res.status(500).json({
      success: false,
      error: "Internal server error",
    } as ApiResponse<null>);
  }
});
