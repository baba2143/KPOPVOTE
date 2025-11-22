//
// saveCollection.ts
// K-VOTE COLLECTOR - Toggle Save/Unsave Collection API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import { firestore } from "firebase-admin";

/**
 * Toggle Save/Unsave Collection
 * POST /api/collections/:collectionId/save
 *
 * Automatically toggles the save status based on current state.
 * No request body required.
 *
 * Response matches iOS SaveCollectionResponse:
 * {
 *   "success": true,
 *   "data": {
 *     "saved": boolean,
 *     "saveCount": number
 *   }
 * }
 */
export async function saveCollection(
  req: AuthenticatedRequest,
  res: Response
): Promise<void> {
  try {
    const userId = req.user?.uid;
    const collectionId = req.params.collectionId;

    console.log(`🔄 [saveCollection] Toggle save for collection: ${collectionId}, user: ${userId}`);

    if (!userId) {
      console.log("❌ [saveCollection] No user ID");
      res.status(401).json({
        success: false,
        error: "認証が必要です",
      });
      return;
    }

    if (!collectionId) {
      console.log("❌ [saveCollection] No collection ID");
      res.status(400).json({
        success: false,
        error: "コレクションIDが必要です",
      });
      return;
    }

    const db = firestore();

    // Check if collection exists and get current saveCount
    const collectionDoc = await db.collection("collections").doc(collectionId).get();
    if (!collectionDoc.exists) {
      console.log(`❌ [saveCollection] Collection not found: ${collectionId}`);
      res.status(404).json({
        success: false,
        error: "コレクションが見つかりません",
      });
      return;
    }

    const saveDocId = `${userId}_${collectionId}`;
    const saveDoc = db.collection("userCollectionSaves").doc(saveDocId);
    const saveDocSnapshot = await saveDoc.get();

    const currentlySaved = saveDocSnapshot.exists;
    console.log(`📊 [saveCollection] Current save status: ${currentlySaved ? "SAVED" : "NOT SAVED"}`);

    let newSaved: boolean;
    let newSaveCount: number;

    if (currentlySaved) {
      // Currently saved → Unsave
      console.log("🔓 [saveCollection] Unsaving collection...");

      await saveDoc.delete();
      await db.collection("collections").doc(collectionId).update({
        saveCount: firestore.FieldValue.increment(-1),
      });

      newSaved = false;

      // Get updated saveCount
      const updatedDoc = await db.collection("collections").doc(collectionId).get();
      newSaveCount = updatedDoc.data()?.saveCount || 0;

      console.log(`✅ [saveCollection] Unsaved successfully. New saveCount: ${newSaveCount}`);
    } else {
      // Currently not saved → Save
      console.log("🔒 [saveCollection] Saving collection...");

      await saveDoc.set({
        userId,
        collectionId,
        savedAt: firestore.Timestamp.now(),
        addedToTasks: false,
        addedTaskIds: [],
      });

      await db.collection("collections").doc(collectionId).update({
        saveCount: firestore.FieldValue.increment(1),
      });

      newSaved = true;

      // Get updated saveCount
      const updatedDoc = await db.collection("collections").doc(collectionId).get();
      newSaveCount = updatedDoc.data()?.saveCount || 0;

      console.log(`✅ [saveCollection] Saved successfully. New saveCount: ${newSaveCount}`);
    }

    // Return response matching iOS SaveCollectionResponse structure
    res.status(200).json({
      success: true,
      data: {
        saved: newSaved,
        saveCount: newSaveCount,
      },
    });
  } catch (error) {
    console.error("❌ [saveCollection] Error:", error);
    res.status(500).json({
      success: false,
      error: "コレクションの保存に失敗しました",
    });
  }
}
