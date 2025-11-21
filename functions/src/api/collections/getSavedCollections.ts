//
// getSavedCollections.ts
// K-VOTE COLLECTOR - Get User's Saved Collections API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import { firestore } from "firebase-admin";
import {
  VoteCollection,
  CollectionsListResponse,
} from "../../types/voteCollection";

/**
 * Get User's Saved Collections
 * GET /api/users/me/saved-collections
 *
 * Query Parameters:
 * - page: number (default: 1)
 * - limit: number (default: 20, max: 50)
 */
export async function getSavedCollections(
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

    // Get user's saved collection IDs
    const savesSnapshot = await db.collection("userCollectionSaves")
      .where("userId", "==", userId)
      .orderBy("savedAt", "desc")
      .get();

    const collectionIds = savesSnapshot.docs.map((doc) => doc.data().collectionId);

    if (collectionIds.length === 0) {
      res.status(200).json({
        success: true,
        data: {
          collections: [],
          pagination: {
            currentPage: page,
            totalPages: 0,
            totalCount: 0,
            hasNext: false,
          },
        },
      } as CollectionsListResponse);
      return;
    }

    // Get collections (Firestore 'in' query limit is 10)
    const chunkSize = 10;
    const chunks: string[][] = [];
    for (let i = 0; i < collectionIds.length; i += chunkSize) {
      chunks.push(collectionIds.slice(i, i + chunkSize));
    }

    const collectionsPromises = chunks.map((chunk) =>
      db.collection("collections")
        .where(firestore.FieldPath.documentId(), "in", chunk)
        .get()
    );

    const collectionsSnapshots = await Promise.all(collectionsPromises);

    const allCollections: VoteCollection[] = collectionsSnapshots
      .flatMap((snapshot) => snapshot.docs)
      .map((doc) => {
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

    // Sort by saved time (maintain order from saves query)
    const collectionIdOrder = new Map(collectionIds.map((id, index) => [id, index]));
    allCollections.sort((a, b) => {
      const aOrder = collectionIdOrder.get(a.collectionId) ?? 999999;
      const bOrder = collectionIdOrder.get(b.collectionId) ?? 999999;
      return aOrder - bOrder;
    });

    const totalCount = allCollections.length;

    // Apply pagination
    const offset = (page - 1) * limit;
    const paginatedCollections = allCollections.slice(offset, offset + limit);

    const response: CollectionsListResponse = {
      success: true,
      data: {
        collections: paginatedCollections,
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
    console.error("❌ [getSavedCollections] Error:", error);
    res.status(500).json({
      success: false,
      error: "保存済みコレクションの取得に失敗しました",
    });
  }
}
