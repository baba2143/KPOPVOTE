//
// getTrending.ts
// K-VOTE COLLECTOR - Get Trending Collections API
//

import { Request, Response } from "express";
import { firestore } from "firebase-admin";
import {
  VoteCollection,
  GetTrendingQuery,
} from "../../types/voteCollection";

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
  try {
    // Parse query parameters
    const query: GetTrendingQuery = {
      limit: Math.min(parseInt(req.query.limit as string) || 10, 50),
      period: (req.query.period as "24h" | "7d" | "30d") || "7d",
    };

    const db = firestore();

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

    // Get recent collections with high engagement
    // Trending score = (saveCount * 3) + (likeCount * 2) + (viewCount * 1)
    const snapshot = await db.collection("collections")
      .where("visibility", "==", "public")
      .where("createdAt", ">=", firestore.Timestamp.fromDate(timeThreshold))
      .get();

    const collectionsWithScores = snapshot.docs
      .map((doc) => {
        const data = doc.data();
        const trendingScore = (
          (data.saveCount || 0) * 3 +
          (data.likeCount || 0) * 2 +
          (data.viewCount || 0) * 1
        );

        return {
          collectionId: doc.id,
          creatorId: data.creatorId,
          creatorName: data.creatorName,
          creatorAvatarUrl: data.creatorAvatarUrl,
          title: data.title,
          description: data.description,
          coverImage: data.coverImage,
          tags: data.tags || [],
          tasks: data.tasks || [],
          taskCount: data.taskCount || 0,
          visibility: data.visibility || "public",
          likeCount: data.likeCount || 0,
          saveCount: data.saveCount || 0,
          viewCount: data.viewCount || 0,
          commentCount: data.commentCount || 0,
          createdAt: data.createdAt,
          updatedAt: data.updatedAt,
          trendingScore,
        };
      })
      .sort((a, b) => b.trendingScore - a.trendingScore)
      .slice(0, query.limit);

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const collections = collectionsWithScores.map(({ trendingScore: _trendingScore, ...collection }) =>
      collection as VoteCollection
    );

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
