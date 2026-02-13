/**
 * Get Archive Detail endpoint
 * GET /idolRankingGetArchive
 * Returns ranking data for a specific archive period
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  ArchiveType,
  RankingType,
  ArchiveDetailResponse,
  ArchiveRankingEntry,
} from "../types";

/**
 * Format monthly archive ID to Japanese label
 * @param id - Archive ID in YYYY-MM format
 * @returns Formatted label like "2025年2月"
 */
function formatMonthlyLabel(id: string): string {
  const [year, month] = id.split("-");
  return `${year}年${parseInt(month, 10)}月`;
}

/**
 * Format weekly archive ID to Japanese label
 * @param id - Archive ID in YYYY-MM-DD format
 * @returns Formatted label like "2025年2月10日週"
 */
function formatWeeklyLabel(id: string): string {
  const [year, month, day] = id.split("-");
  return `${year}年${parseInt(month, 10)}月${parseInt(day, 10)}日週`;
}

export const idolRankingGetArchive = functions
  .runWith({ memory: "256MB", timeoutSeconds: 60, maxInstances: 50 })
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
      const archiveType = req.query.archiveType as ArchiveType;
      const archiveId = req.query.archiveId as string;
      const rankingType = req.query.rankingType as RankingType;
      const limit = Math.min(parseInt(req.query.limit as string) || 50, 100);
      const offset = parseInt(req.query.offset as string) || 0;

      // Validate archiveType
      if (!archiveType || !["monthly", "weekly"].includes(archiveType)) {
        res.status(400).json({
          success: false,
          error: "archiveType must be 'monthly' or 'weekly'",
        } as ApiResponse<null>);
        return;
      }

      // Validate archiveId
      if (!archiveId) {
        res.status(400).json({
          success: false,
          error: "archiveId is required",
        } as ApiResponse<null>);
        return;
      }

      // Validate archiveId format
      const monthlyPattern = /^\d{4}-\d{2}$/;
      const weeklyPattern = /^\d{4}-\d{2}-\d{2}$/;

      if (archiveType === "monthly" && !monthlyPattern.test(archiveId)) {
        res.status(400).json({
          success: false,
          error: "archiveId must be in YYYY-MM format for monthly archives",
        } as ApiResponse<null>);
        return;
      }

      if (archiveType === "weekly" && !weeklyPattern.test(archiveId)) {
        res.status(400).json({
          success: false,
          error: "archiveId must be in YYYY-MM-DD format for weekly archives",
        } as ApiResponse<null>);
        return;
      }

      // Validate rankingType
      if (!rankingType || !["individual", "group"].includes(rankingType)) {
        res.status(400).json({
          success: false,
          error: "rankingType must be 'individual' or 'group'",
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

      // Determine collection based on archive type
      const collectionName = archiveType === "monthly"
        ? "idolRankingMonthlySnapshots"
        : "idolRankingWeeklySnapshots";

      // Get the snapshot document
      const snapshotDoc = await db
        .collection(collectionName)
        .doc(archiveId)
        .get();

      if (!snapshotDoc.exists) {
        res.status(404).json({
          success: false,
          error: `Archive not found: ${archiveId}`,
        } as ApiResponse<null>);
        return;
      }

      const snapshotData = snapshotDoc.data();
      if (!snapshotData) {
        res.status(404).json({
          success: false,
          error: `Archive data is empty: ${archiveId}`,
        } as ApiResponse<null>);
        return;
      }

      // Get the appropriate rankings array based on rankingType
      const rawRankings = rankingType === "individual"
        ? snapshotData.individualRankings || []
        : snapshotData.groupRankings || [];

      // Determine vote field name based on archive type
      const voteField = archiveType === "monthly" ? "monthlyVotes" : "weeklyVotes";

      // Apply pagination and format response
      const total = rawRankings.length;
      const paginatedRankings = rawRankings.slice(offset, offset + limit);

      const rankings: ArchiveRankingEntry[] = paginatedRankings.map(
        (entry: Record<string, unknown>, index: number) => ({
          rank: offset + index + 1,
          entityId: entry.entityId as string,
          name: entry.name as string,
          groupName: (entry.groupName as string) || undefined,
          votes: (entry[voteField] as number) || 0,
        })
      );

      // Generate label
      const label = archiveType === "monthly"
        ? formatMonthlyLabel(archiveId)
        : formatWeeklyLabel(archiveId);

      // CDN cache: 5min browser, 10min CDN edge (archives don't change)
      res.set("Cache-Control", "public, max-age=300, s-maxage=600");

      res.status(200).json({
        success: true,
        data: {
          archiveType,
          archiveId,
          label,
          rankingType,
          rankings,
          total,
        },
      } as ApiResponse<ArchiveDetailResponse>);
    } catch (error: unknown) {
      console.error("Get archive error:", error);

      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
