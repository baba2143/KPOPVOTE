//
// getMyCollections.ts
// K-VOTE COLLECTOR - Get User's Created Collections API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import { firestore } from "firebase-admin";
import {
  VoteCollection,
  CollectionsListResponse,
} from "../../types/voteCollection";

/**
 * Get User's Created Collections
 * GET /api/users/me/collections
 *
 * Query Parameters:
 * - page: number (default: 1)
 * - limit: number (default: 20, max: 50)
 */
export async function getMyCollections(
  req: AuthenticatedRequest,
  res: Response
): Promise<void> {
  try {
    const userId = req.user?.uid;

    if (!userId) {
      res.status(401).json({
        success: false,
        error: "認証が必要です",
      });
      return;
    }

    // Parse query parameters
    const page = parseInt(req.query.page as string) || 1;
    const limit = Math.min(parseInt(req.query.limit as string) || 20, 50);

    const db = firestore();

    // Get total count
    const countSnapshot = await db.collection("collections")
      .where("creatorId", "==", userId)
      .count()
      .get();
    const totalCount = countSnapshot.data().count;

    // Get user's collections
    const offset = (page - 1) * limit;
    const snapshot = await db.collection("collections")
      .where("creatorId", "==", userId)
      .orderBy("createdAt", "desc")
      .offset(offset)
      .limit(limit)
      .get();

    const collections: VoteCollection[] = snapshot.docs.map((doc) => {
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
        tasks: data.tasks || [],
        taskCount: data.taskCount || 0,
        visibility: data.visibility || "public",
        likeCount: data.likeCount || 0,
        saveCount: data.saveCount || 0,
        viewCount: data.viewCount || 0,
        commentCount: data.commentCount || 0,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
      };
    });

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
    console.error("❌ [getMyCollections] Error:", error);
    res.status(500).json({
      success: false,
      error: "マイコレクションの取得に失敗しました",
    });
  }
}
