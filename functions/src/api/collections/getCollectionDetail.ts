//
// getCollectionDetail.ts
// K-VOTE COLLECTOR - Get Collection Detail API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import { firestore } from "firebase-admin";
import {
  VoteCollection,
  CollectionDetailResponse,
} from "../../types/voteCollection";

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

    const db = firestore();

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

    const collection: VoteCollection = {
      collectionId: collectionDoc.id,
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

    // Increment view count (async, don't wait)
    db.collection("collections").doc(collectionId).update({
      viewCount: firestore.FieldValue.increment(1),
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
