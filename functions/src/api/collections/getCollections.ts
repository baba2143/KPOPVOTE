//
// getCollections.ts
// K-VOTE COLLECTOR - Get Collections List API
//

import { Request, Response } from "express";
import { firestore } from "firebase-admin";
import {
  VoteCollection,
  GetCollectionsQuery,
  CollectionsListResponse,
} from "../../types/voteCollection";

/**
 * Get Collections List
 * GET /api/collections
 *
 * Query Parameters:
 * - page: number (default: 1)
 * - limit: number (default: 20, max: 50)
 * - sortBy: "latest" | "popular" | "trending" (default: "latest")
 * - tags: string[] (filter by tags)
 * - visibility: "public" | "followers" | "private"
 * @param {Request} req Express request
 * @param {Response} res Express response
 * @return {Promise<void>} Promise void
 */
export async function getCollections(
  req: Request,
  res: Response
): Promise<void> {
  try {
    // Parse query parameters
    const page = parseInt(req.query.page as string) || 1;
    const limit = Math.min(parseInt(req.query.limit as string) || 20, 50);

    const query: GetCollectionsQuery = {
      page,
      limit,
      sortBy:
        (req.query.sortBy as "latest" | "popular" | "trending") || "latest",
      tags: req.query.tags ?
        (Array.isArray(req.query.tags) ?
          req.query.tags as string[] : [req.query.tags as string]) :
        undefined,
      visibility:
        req.query.visibility as "public" | "followers" | "private" | undefined,
    };

    const db = firestore();
    let collectionQuery = db.collection("collections").where("visibility", "==", "public");

    // Apply tag filter
    if (query.tags && query.tags.length > 0) {
      collectionQuery = collectionQuery.where("tags", "array-contains-any", query.tags);
    }

    // Apply sorting
    switch (query.sortBy) {
    case "popular":
      collectionQuery = collectionQuery.orderBy("saveCount", "desc");
      break;
    case "trending":
      // Trending = high engagement in recent period
      collectionQuery = collectionQuery.orderBy("viewCount", "desc");
      break;
    case "latest":
    default:
      collectionQuery = collectionQuery.orderBy("createdAt", "desc");
      break;
    }

    // Get total count for pagination
    const countSnapshot = await collectionQuery.count().get();
    const totalCount = countSnapshot.data().count;

    // Apply pagination
    const offset = (page - 1) * limit;
    const snapshot = await collectionQuery
      .offset(offset)
      .limit(limit)
      .get();

    const collections: VoteCollection[] = snapshot.docs.map((doc) => ({
      collectionId: doc.id,
      creatorId: doc.data().creatorId,
      creatorName: doc.data().creatorName,
      creatorAvatarUrl: doc.data().creatorAvatarUrl,
      title: doc.data().title,
      description: doc.data().description,
      coverImage: doc.data().coverImage,
      tags: doc.data().tags || [],
      tasks: doc.data().tasks || [],
      taskCount: doc.data().taskCount || 0,
      visibility: doc.data().visibility || "public",
      likeCount: doc.data().likeCount || 0,
      saveCount: doc.data().saveCount || 0,
      viewCount: doc.data().viewCount || 0,
      commentCount: doc.data().commentCount || 0,
      createdAt: doc.data().createdAt,
      updatedAt: doc.data().updatedAt,
    }));

    const response: CollectionsListResponse = {
      success: true,
      data: {
        collections,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(totalCount / limit),
          totalCount,
          hasNext: page * limit < totalCount,
        },
      },
    };

    res.status(200).json(response);
  } catch (error) {
    console.error("❌ [getCollections] Error:", error);
    res.status(500).json({
      success: false,
      error: "コレクションの取得に失敗しました",
    });
  }
}
