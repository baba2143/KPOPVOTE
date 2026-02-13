/**
 * Get Archive List endpoint
 * GET /idolRankingGetArchiveList
 * Returns list of available archive periods (monthly/weekly)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  ArchiveType,
  ArchiveListResponse,
  ArchiveListItem,
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

export const idolRankingGetArchiveList = functions
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

      // Validate archiveType
      if (!archiveType || !["monthly", "weekly"].includes(archiveType)) {
        res.status(400).json({
          success: false,
          error: "archiveType must be 'monthly' or 'weekly'",
        } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();

      // Determine collection based on archive type
      const collectionName = archiveType === "monthly"
        ? "idolRankingMonthlySnapshots"
        : "idolRankingWeeklySnapshots";

      // Get all snapshots, ordered by date field descending (newest first)
      // Monthly snapshots have 'month' field, weekly have 'date' field
      const orderField = archiveType === "monthly" ? "month" : "date";
      const snapshot = await db
        .collection(collectionName)
        .orderBy(orderField, "desc")
        .get();

      // Build archive list
      const archives: ArchiveListItem[] = snapshot.docs.map((doc) => {
        const id = doc.id;
        const label = archiveType === "monthly"
          ? formatMonthlyLabel(id)
          : formatWeeklyLabel(id);

        return { id, label };
      });

      // CDN cache: 5min browser, 10min CDN edge (archives don't change frequently)
      res.set("Cache-Control", "public, max-age=300, s-maxage=600");

      res.status(200).json({
        success: true,
        data: {
          archiveType,
          archives,
        },
      } as ApiResponse<ArchiveListResponse>);
    } catch (error: unknown) {
      console.error("Get archive list error:", error);

      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
