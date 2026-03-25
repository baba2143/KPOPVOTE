//
// getTrending.ts
// K-VOTE COLLECTOR - Get Trending Collections API
//

import { Request, Response } from "express";
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  VoteCollectionResponse,
  GetTrendingQuery,
} from "../../types/voteCollection";

/**
 * Convert Date to ISO8601 string without milliseconds
 * Swift's .iso8601 decoder doesn't support milliseconds
 * @param date Date to convert
 * @returns ISO8601 string without milliseconds (e.g. "2025-11-22T09:24:00Z")
 */
const toISOStringWithoutMillis = (date: Date): string => {
  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
};

/**
 * Get Trending Collections
 * GET /api/collections/trending
 *
 * Query Parameters:
 * - limit: number (default: 10, max: 50)
 * - period: "24h" | "7d" | "30d" (default: "7d")
 */
export async function getTrending(
  req: Request,
  res: Response
): Promise<void> {
  const startTime = Date.now();

  try {
    // Parse query parameters
    const limitParam = Math.min(parseInt(req.query.limit as string) || 10, 50);
    const query: GetTrendingQuery = {
      limit: limitParam,
      period: (req.query.period as "24h" | "7d" | "30d") || "7d",
    };

    const db = admin.firestore();

    // Calculate time threshold based on period
    const now = new Date();
    let timeThreshold: Date;
    switch (query.period) {
    case "24h":
      timeThreshold = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      break;
    case "30d":
      timeThreshold = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      break;
    case "7d":
    default:
      timeThreshold = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      break;
    }

    // Get trending collections using pre-computed trendingScore field
    // Score is computed by scheduled function: (saveCount * 3) + (likeCount * 2) + (viewCount * 1)
    // This allows Firestore to sort directly via index instead of in-memory sorting
    const snapshot = await db.collection("collections")
      .where("visibility", "==", "public")
      .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(timeThreshold))
      .orderBy("trendingScore", "desc")
      .orderBy("createdAt", "desc")
      .limit(limitParam)
      .get();

    const collections: VoteCollectionResponse[] = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        collectionId: doc.id,
        creatorId: data.creatorId,
        creatorName: data.creatorName,
        creatorAvatarUrl: data.creatorAvatarUrl,
        title: data.title,
        description: data.description,
        coverImage: data.coverImage,
        tags: data.tags || [],
        tasks: (data.tasks || []).map((task: any) => ({
          ...task,
          deadline: task.deadline?.toDate ? toISOStringWithoutMillis(task.deadline.toDate()) : task.deadline,
        })),
        taskCount: data.taskCount || 0,
        visibility: data.visibility || "public",
        likeCount: data.likeCount || 0,
        saveCount: data.saveCount || 0,
        viewCount: data.viewCount || 0,
        commentCount: data.commentCount || 0,
        createdAt: data.createdAt?.toDate ?
          toISOStringWithoutMillis(data.createdAt.toDate()) :
          toISOStringWithoutMillis(new Date()),
        updatedAt: data.updatedAt?.toDate ?
          toISOStringWithoutMillis(data.updatedAt.toDate()) :
          toISOStringWithoutMillis(new Date()),
      };
    });

    const duration = Date.now() - startTime;
    functions.logger.info("[PERF] getTrending completed", {
      duration: `${duration}ms`,
      itemCount: collections.length,
    });

    // CDN cache for trending data (5min browser, 10min CDN)
    res.set("Cache-Control", "public, max-age=300, s-maxage=600");
    res.status(200).json({
      success: true,
      data: {
        collections,
        period: query.period,
      },
    });
  } catch (error) {
    console.error("❌ [getTrending] Error:", error);
    res.status(500).json({
      success: false,
      error: "トレンドコレクションの取得に失敗しました",
    });
  }
}
