//
// shareToCoommunity.ts
// K-VOTE COLLECTOR - Share Collection to Community API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import { firestore } from "firebase-admin";

/**
 * Share Collection to Community
 * POST /api/collections/:collectionId/share-to-community
 *
 * Body:
 * - biasIds: string[] (required)
 * - text?: string (optional message)
 */
export async function shareToCoommunity(
  req: AuthenticatedRequest,
  res: Response
): Promise<void> {
  try {
    const collectionId = req.params.collectionId;
    const userId = req.user?.uid;
    const { biasIds, text } = req.body;

    if (!userId) {
      res.status(401).json({
        success: false,
        error: "認証が必要です",
      });
      return;
    }

    if (!collectionId) {
      res.status(400).json({
        success: false,
        error: "コレクションIDが必要です",
      });
      return;
    }

    if (!biasIds || !Array.isArray(biasIds) || biasIds.length === 0) {
      res.status(400).json({
        success: false,
        error: "biasIdsが必要です（空でない配列）",
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

    const collectionData = collectionDoc.data()!;

    // Verify ownership
    if (collectionData.creatorId !== userId) {
      res.status(403).json({
        success: false,
        error: "自分のコレクションのみ投稿できます",
      });
      return;
    }

    // Create community post
    const postRef = db.collection("posts").doc();
    const postData = {
      id: postRef.id,
      userId,
      type: "collection",
      content: {
        text: text || "",
        collectionId,
        collectionTitle: collectionData.title,
        collectionDescription: collectionData.description,
        collectionCoverImage: collectionData.coverImage || null,
        collectionTaskCount: collectionData.taskCount || 0,
      },
      biasIds,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      isReported: false,
      reportCount: 0,
      createdAt: firestore.FieldValue.serverTimestamp(),
      updatedAt: firestore.FieldValue.serverTimestamp(),
    };

    await postRef.set(postData);

    // Increment user's postsCount
    const userRef = db.collection("users").doc(userId);
    await userRef.update({
      postsCount: firestore.FieldValue.increment(1),
      updatedAt: firestore.FieldValue.serverTimestamp(),
    });

    // Increment collection's shareCount (optional)
    await collectionDoc.ref.update({
      shareCount: firestore.FieldValue.increment(1),
    });

    res.status(201).json({
      success: true,
      data: {
        postId: postRef.id,
        collectionId,
      },
    });
  } catch (error: unknown) {
    console.error("❌ [shareToCoommunity] Error:", error);
    res.status(500).json({
      success: false,
      error: "コミュニティへの投稿に失敗しました",
    });
  }
}
