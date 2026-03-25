/**
 * Get idol ranking archive (public API)
 * Returns archived ranking data for a specific month
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { READ_HIGH_TRAFFIC_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export interface ArchiveRankingItem {
  rank: number;
  entityId: string;
  entityType: "individual" | "group";
  name: string;
  groupName?: string;
  imageUrl: string | null;
  votes: number;
  weeklyVotes: number;
  totalVotes: number;
  previousRank: number | null;
  rankChange: number | null;
}

export interface ArchiveResponse {
  archiveId: string;
  archiveType: "monthly";
  year: number;
  month: number;
  createdAt: string;
  rankings: ArchiveRankingItem[];
  total: number;
  rankingType: "individual" | "group" | "all";
}

export const idolRankingGetArchive = functions
  .runWith(READ_HIGH_TRAFFIC_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    // Cache archive data for long time (archives are immutable)
    res.set("Cache-Control", "public, max-age=3600, s-maxage=86400");

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
      const archiveId = req.query.archiveId as string;
      const rankingType = (req.query.rankingType as string) || "all";
      const limit = parseInt(req.query.limit as string) || 100;
      const offset = parseInt(req.query.offset as string) || 0;

      // Validate parameters
      if (archiveType !== "monthly") {
        res.status(400).json({
          success: false,
          error: "Invalid archiveType. Must be 'monthly'.",
        } as ApiResponse<null>);
        return;
      }

      if (!archiveId) {
        res.status(400).json({
          success: false,
          error: "archiveId is required (format: YYYY-MM, e.g., '2026-02').",
        } as ApiResponse<null>);
        return;
      }

      // Validate archiveId format (YYYY-MM)
      if (!/^\d{4}-\d{2}$/.test(archiveId)) {
        res.status(400).json({
          success: false,
          error: "Invalid archiveId format. Must be YYYY-MM (e.g., '2026-02').",
        } as ApiResponse<null>);
        return;
      }

      if (!["individual", "group", "all"].includes(rankingType)) {
        res.status(400).json({
          success: false,
          error: "Invalid rankingType. Must be 'individual', 'group', or 'all'.",
        } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();

      // Get archive document
      const archiveDoc = await db
        .collection("idolRankingArchives")
        .doc(archiveId)
        .get();

      if (!archiveDoc.exists) {
        res.status(404).json({
          success: false,
          error: `Archive not found: ${archiveId}`,
        } as ApiResponse<null>);
        return;
      }

      const archiveData = archiveDoc.data()!;

      // Collect all entityIds to fetch imageUrls
      const allEntries = [
        ...(archiveData.rankings?.individual || []),
        ...(archiveData.rankings?.group || []),
      ];
      const entityIds = allEntries.map((e: { entityId: string }) => e.entityId);

      // Fetch imageUrls from idolRankings collection
      const imageUrlMap: { [entityId: string]: string | null } = {};
      if (entityIds.length > 0) {
        // Firestore 'in' query supports max 30 items, so we batch
        const batchSize = 30;
        for (let i = 0; i < entityIds.length; i += batchSize) {
          const batch = entityIds.slice(i, i + batchSize);
          const rankingsSnapshot = await db
            .collection("idolRankings")
            .where(admin.firestore.FieldPath.documentId(), "in", batch)
            .get();

          rankingsSnapshot.docs.forEach((doc) => {
            const data = doc.data();
            imageUrlMap[doc.id] = data.imageUrl || null;
          });
        }
      }

      // Helper to transform archive entry to iOS-compatible format
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const transformEntry = (r: any): ArchiveRankingItem => ({
        rank: r.rank,
        entityId: r.entityId,
        entityType: r.entityType,
        name: r.name,
        groupName: r.groupName,
        imageUrl: imageUrlMap[r.entityId] || null,
        votes: r.votes,
        weeklyVotes: r.votes, // Archive stores total votes for the month
        totalVotes: r.votes,
        previousRank: null,
        rankChange: null,
      });

      // Get rankings based on rankingType
      let rankings: ArchiveRankingItem[] = [];

      if (rankingType === "all") {
        // Combine individual and group rankings, then sort
        const individualRankings = archiveData.rankings?.individual || [];
        const groupRankings = archiveData.rankings?.group || [];

        const combined = [
          ...individualRankings.map((r: ArchiveRankingItem) => ({
            ...transformEntry(r),
            entityType: "individual" as const,
          })),
          ...groupRankings.map((r: ArchiveRankingItem) => ({
            ...transformEntry(r),
            entityType: "group" as const,
          })),
        ];

        // Sort by votes descending and reassign ranks
        combined.sort((a, b) => b.votes - a.votes);
        rankings = combined.map((r, index) => ({
          ...r,
          rank: index + 1,
        }));
      } else if (rankingType === "individual") {
        rankings = (archiveData.rankings?.individual || []).map(transformEntry);
      } else if (rankingType === "group") {
        rankings = (archiveData.rankings?.group || []).map(transformEntry);
      }

      const total = rankings.length;

      // Apply pagination
      const paginatedRankings = rankings.slice(offset, offset + limit);

      const response: ArchiveResponse = {
        archiveId: archiveData.archiveId,
        archiveType: archiveData.archiveType,
        year: archiveData.year,
        month: archiveData.month,
        createdAt: archiveData.createdAt?.toDate?.()?.toISOString() || "",
        rankings: paginatedRankings,
        total,
        rankingType: rankingType as "individual" | "group" | "all",
      };

      res.status(200).json({
        success: true,
        data: response,
      } as ApiResponse<ArchiveResponse>);
    } catch (error: unknown) {
      console.error("Get idol ranking archive error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
