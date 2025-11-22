//
// getCollectionDetail.ts
// K-VOTE COLLECTOR - Get Collection Detail API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import * as admin from "firebase-admin";
import {
  VoteCollectionResponse,
  CollectionDetailResponse,
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
 * Get Collection Detail
 * GET /api/collections/:collectionId
 *
 * Returns:
 * - Collection details
 * - User's save status (if authenticated)
 * - User's like status (if authenticated)
 * - Ownership status (if authenticated)
 */
export async function getCollectionDetail(
  req: AuthenticatedRequest,
  res: Response
): Promise<void> {
  try {
    const collectionId = req.params.collectionId;
    const userId = req.user?.uid;

    if (!collectionId) {
      res.status(400).json({
        success: false,
        error: "コレクションIDが必要です",
      });
      return;
    }

    const db = admin.firestore();

    // Get collection
    const collectionDoc = await db.collection("collections").doc(collectionId).get();

    if (!collectionDoc.exists) {
      res.status(404).json({
        success: false,
        error: "コレクションが見つかりません",
      });
      return;
    }

    const data = collectionDoc.data()!;

    // Check visibility
    if (data.visibility === "private" && data.creatorId !== userId) {
      res.status(403).json({
        success: false,
        error: "このコレクションは非公開です",
      });
      return;
    }

    const collection: VoteCollectionResponse = {
      collectionId: collectionDoc.id,
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

    // Increment view count (async, don't wait)
    db.collection("collections").doc(collectionId).update({
      viewCount: admin.firestore.FieldValue.increment(1),
    }).catch((error) => {
      console.error("⚠️ [getCollectionDetail] Failed to increment view count:", error);
    });

    let isSaved = false;
    let isLiked = false;
    let isOwner = false;

    if (userId) {
      isOwner = data.creatorId === userId;

      // Check if user saved this collection
      const saveDoc = await db.collection("userCollectionSaves")
        .doc(`${userId}_${collectionId}`)
        .get();
      isSaved = saveDoc.exists;

      // Check if user liked this collection
      const likeDoc = await db.collection("collectionLikes")
        .doc(`${userId}_${collectionId}`)
        .get();
      isLiked = likeDoc.exists;
    }

    const response: CollectionDetailResponse = {
      success: true,
      data: {
        collection,
        isSaved,
        isLiked,
        isOwner,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    console.error("❌ [getCollectionDetail] Error:", error);
    res.status(500).json({
      success: false,
      error: "コレクション詳細の取得に失敗しました",
    });
  }
}
