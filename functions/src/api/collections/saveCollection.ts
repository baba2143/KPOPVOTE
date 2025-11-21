//
// saveCollection.ts
// K-VOTE COLLECTOR - Save/Unsave Collection API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import { firestore } from "firebase-admin";

/**
 * Save/Unsave Collection
 * POST /api/collections/:collectionId/save
 *
 * Request Body:
 * - save: boolean (true = save, false = unsave)
 */
export async function saveCollection(
  req: AuthenticatedRequest,
  res: Response
): Promise<void> {
  try {
    const userId = req.user?.uid;
    const collectionId = req.params.collectionId;
    const shouldSave = req.body.save === true;

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

    // Check if collection exists
    const collectionDoc = await db.collection("collections").doc(collectionId).get();
    if (!collectionDoc.exists) {
      res.status(404).json({
        success: false,
        error: "コレクションが見つかりません",
      });
      return;
    }

    const saveDocId = `${userId}_${collectionId}`;
    const saveDoc = db.collection("userCollectionSaves").doc(saveDocId);

    if (shouldSave) {
      // Save collection
      const saveDocSnapshot = await saveDoc.get();

      if (saveDocSnapshot.exists) {
        res.status(200).json({
          success: true,
          data: {
            message: "既に保存済みです",
            isSaved: true,
          },
        });
        return;
      }

      // Create save record
      await saveDoc.set({
        userId,
        collectionId,
        savedAt: firestore.Timestamp.now(),
        addedToTasks: false,
        addedTaskIds: [],
      });

      // Increment saveCount
      await db.collection("collections").doc(collectionId).update({
        saveCount: firestore.FieldValue.increment(1),
      });

      res.status(200).json({
        success: true,
        data: {
          message: "コレクションを保存しました",
          isSaved: true,
        },
      });
    } else {
      // Unsave collection
      const saveDocSnapshot = await saveDoc.get();

      if (!saveDocSnapshot.exists) {
        res.status(200).json({
          success: true,
          data: {
            message: "保存されていません",
            isSaved: false,
          },
        });
        return;
      }

      // Delete save record
      await saveDoc.delete();

      // Decrement saveCount
      await db.collection("collections").doc(collectionId).update({
        saveCount: firestore.FieldValue.increment(-1),
      });

      res.status(200).json({
        success: true,
        data: {
          message: "コレクションの保存を解除しました",
          isSaved: false,
        },
      });
    }
  } catch (error) {
    console.error("❌ [saveCollection] Error:", error);
    res.status(500).json({
      success: false,
      error: "コレクションの保存に失敗しました",
    });
  }
}
