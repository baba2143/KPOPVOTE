/**
 * Get idol ranking (public API)
 * Returns ranking sorted by votes for the specified period
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { READ_HIGH_TRAFFIC_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export interface IdolRankingItem {
  rank: number;
  entityId: string;
  entityType: "individual" | "group";
  name: string;
  groupName?: string;
  imageUrl?: string;
  weeklyVotes: number;
  totalVotes: number;
  previousRank?: number;
  rankChange?: number;
}

export interface IdolRankingResponse {
  rankings: IdolRankingItem[];
  total: number;
  period: string;
  rankingType: "individual" | "group" | "all";
  lastUpdated: string;
}

export const idolRankingGetRanking = functions
  .runWith(READ_HIGH_TRAFFIC_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    // Cache control: allow refresh parameter to bypass CDN cache
    const refresh = req.query.refresh === "true";
    if (refresh) {
      res.set("Cache-Control", "no-store, no-cache, must-revalidate");
    } else {
      // Cache ranking data for CDN (60s browser, 120s CDN)
      res.set("Cache-Control", "public, max-age=60, s-maxage=120");
    }

    if (req.method !== "GET") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use GET.",
      } as ApiResponse<null>);
      return;
    }

    try {
    // Parse query parameters
      const rankingType = (req.query.rankingType as string) || "all";
      const period = (req.query.period as string) || "weekly";
      const limit = parseInt(req.query.limit as string) || 100;
      const offset = parseInt(req.query.offset as string) || 0;

      // Validate parameters
      if (!["individual", "group", "all"].includes(rankingType)) {
        res.status(400).json({
          success: false,
          error: "Invalid rankingType. Must be 'individual', 'group', or 'all'.",
        } as ApiResponse<null>);
        return;
      }

      if (!["weekly", "monthly", "total", "allTime"].includes(period)) {
        res.status(400).json({
          success: false,
          error: "Invalid period. Must be 'weekly', 'monthly', 'total', or 'allTime'.",
        } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();
      let query: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> =
      db.collection("idolRankings");

      // Filter by entity type if specified
      if (rankingType !== "all") {
        query = query.where("entityType", "==", rankingType);
      }

      // Sort by votes based on period (allTime is treated same as total)
      const sortField = (period === "total" || period === "allTime") ? "totalVotes" : "weeklyVotes";
      query = query.orderBy(sortField, "desc");

      // Apply pagination
      query = query.limit(limit).offset(offset);

      const snapshot = await query.get();

      // Get total count for pagination
      let countQuery: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> =
      db.collection("idolRankings");
      if (rankingType !== "all") {
        countQuery = countQuery.where("entityType", "==", rankingType);
      }
      const countSnapshot = await countQuery.count().get();
      const countData = countSnapshot.data();
      const total = countData?.count ?? 0;

      // Build ranking list with rank numbers
      const rankings: IdolRankingItem[] = snapshot.docs.map((doc, index) => {
        const data = doc.data();
        const rank = offset + index + 1;
        const previousRank = data.previousRank || null;
        const rankChange = previousRank ? previousRank - rank : null;

        return {
          rank,
          entityId: data.entityId,
          entityType: data.entityType,
          name: data.name,
          groupName: data.groupName || undefined,
          imageUrl: data.imageUrl || undefined,
          weeklyVotes: data.weeklyVotes || 0,
          totalVotes: data.totalVotes || 0,
          previousRank: previousRank || undefined,
          rankChange: rankChange !== null ? rankChange : undefined,
        };
      });

      const response: IdolRankingResponse = {
        rankings,
        total,
        period,
        rankingType: rankingType as "individual" | "group" | "all",
        lastUpdated: new Date().toISOString(),
      };

      res.status(200).json({
        success: true,
        data: response,
      } as ApiResponse<IdolRankingResponse>);
    } catch (error: unknown) {
      console.error("Get idol ranking error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
