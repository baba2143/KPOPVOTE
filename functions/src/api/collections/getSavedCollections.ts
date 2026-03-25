//
// getSavedCollections.ts
// K-VOTE COLLECTOR - Get User's Saved Collections API
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

    const db = admin.firestore();

    // Query-level pagination: fetch only up to needed page
    // Firestore doesn't support offset, so we fetch up to page * limit + 1 (for hasMore check)
    const maxDocsToFetch = page * limit + 1;

    const savesSnapshot = await db.collection("userCollectionSaves")
      .where("userId", "==", userId)
      .orderBy("savedAt", "desc")
      .limit(maxDocsToFetch)
      .get();

    // Extract the slice for current page
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + limit;
    const paginatedSavesDocs = savesSnapshot.docs.slice(startIndex, endIndex);
    const hasMore = savesSnapshot.size > page * limit;

    const collectionIds = paginatedSavesDocs.map((doc) => doc.data().collectionId);

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
        .where(admin.firestore.FieldPath.documentId(), "in", chunk)
        .get()
    );

    const collectionsSnapshots = await Promise.all(collectionsPromises);

    const allCollections: VoteCollectionResponse[] = collectionsSnapshots
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

    // Sort by saved time (maintain order from saves query)
    const collectionIdOrder = new Map(collectionIds.map((id, index) => [id, index]));
    allCollections.sort((a, b) => {
      const aOrder = collectionIdOrder.get(a.collectionId) ?? 999999;
      const bOrder = collectionIdOrder.get(b.collectionId) ?? 999999;
      return aOrder - bOrder;
    });

    // Note: With query-level pagination, we don't have total count without an extra query
    // For backward compatibility, we approximate based on current results
    const response: CollectionsListResponse = {
      success: true,
      data: {
        collections: allCollections,
        pagination: {
          currentPage: page,
          // Cannot determine totalPages without additional query; use hasNext for navigation
          totalPages: hasMore ? page + 1 : page,
          totalCount: hasMore ? page * limit + 1 : (page - 1) * limit + allCollections.length,
          hasNext: hasMore,
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
