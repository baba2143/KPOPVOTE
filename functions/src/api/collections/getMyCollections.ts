//
// getMyCollections.ts
// K-VOTE COLLECTOR - Get User's Created Collections API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import * as admin from "firebase-admin";
import {
  VoteCollectionResponse,
  CollectionsListResponse,
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

    const db = admin.firestore();

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
