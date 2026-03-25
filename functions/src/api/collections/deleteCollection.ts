//
// deleteCollection.ts
// K-VOTE COLLECTOR - Delete Collection API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import { firestore } from "firebase-admin";

/**
 * Delete Collection
 * DELETE /api/collections/:collectionId
 *
 * Deletes:
 * - Collection document
 * - All saves (userCollectionSaves)
 * - All likes (collectionLikes)
 */
export async function deleteCollection(
  req: AuthenticatedRequest,
  res: Response
): Promise<void> {
  try {
    const userId = req.user?.uid;
    const collectionId = req.params.collectionId;

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

    // Check ownership
    if (collectionData.creatorId !== userId) {
      res.status(403).json({
        success: false,
        error: "このコレクションを削除する権限がありません",
      });
      return;
    }

    // Delete related data in batch
    const batch = db.batch();

    // Delete collection
    batch.delete(collectionDoc.ref);

    // Delete all saves
    const savesSnapshot = await db.collection("userCollectionSaves")
      .where("collectionId", "==", collectionId)
      .get();
    savesSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // Delete all likes
    const likesSnapshot = await db.collection("collectionLikes")
      .where("collectionId", "==", collectionId)
      .get();
    likesSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // Commit batch
    await batch.commit();

    res.status(200).json({
      success: true,
      data: {
        message: "コレクションを削除しました",
      },
    });
  } catch (error) {
    console.error("❌ [deleteCollection] Error:", error);
    res.status(500).json({
      success: false,
      error: "コレクションの削除に失敗しました",
    });
  }
}
