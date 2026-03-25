/**
 * Get idol ranking archive list (public API)
 * Returns list of available archive months
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { READ_HIGH_TRAFFIC_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export interface ArchiveListItem {
  id: string; // iOS互換: "2026-02" 形式
  label: string; // iOS互換: "2026年2月" 形式
  archiveId: string;
  archiveType: "monthly";
  year: number;
  month: number;
  createdAt: string;
}

export interface ArchiveListResponse {
  archives: ArchiveListItem[];
  total: number;
}

export const idolRankingGetArchiveList = functions
  .runWith(READ_HIGH_TRAFFIC_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    // Cache archive list for CDN (5min browser, 10min CDN - archives rarely change)
    res.set("Cache-Control", "public, max-age=300, s-maxage=600");

    if (req.method !== "GET") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use GET.",
      } as ApiResponse<null>);
      return;
    }

    try {
      // Parse query parameters
      const archiveType = (req.query.archiveType as string) || "monthly";
      const limit = parseInt(req.query.limit as string) || 24; // Default: last 2 years
      const offset = parseInt(req.query.offset as string) || 0;

      // Validate parameters
      if (archiveType !== "monthly") {
        res.status(400).json({
          success: false,
          error: "Invalid archiveType. Must be 'monthly'.",
        } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();

      // Query all archives (no compound index needed)
      const snapshot = await db
        .collection("idolRankingArchives")
        .get();

      // Filter by archiveType and sort by year/month descending
      let archives: ArchiveListItem[] = snapshot.docs
        .map((doc) => {
          const data = doc.data();
          const year = data.year as number;
          const month = data.month as number;
          return {
            id: data.archiveId, // iOS互換
            label: `${year}年${month}月`, // iOS互換
            archiveId: data.archiveId,
            archiveType: data.archiveType,
            year,
            month,
            createdAt: data.createdAt?.toDate?.()?.toISOString() || "",
          };
        })
        .filter((a) => a.archiveType === archiveType)
        .sort((a, b) => {
          if (b.year !== a.year) return b.year - a.year;
          return b.month - a.month;
        });

      const total = archives.length;

      // Apply pagination
      archives = archives.slice(offset, offset + limit);

      const response: ArchiveListResponse = {
        archives,
        total,
      };

      res.status(200).json({
        success: true,
        data: response,
      } as ApiResponse<ArchiveListResponse>);
    } catch (error: unknown) {
      console.error("Get idol ranking archive list error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
