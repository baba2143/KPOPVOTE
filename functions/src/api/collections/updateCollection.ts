//
// updateCollection.ts
// K-VOTE COLLECTOR - Update Collection API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import { firestore } from "firebase-admin";
import {
  UpdateCollectionRequest,
  VoteCollection,
} from "../../types/voteCollection";

/**
 * Update Collection
 * PUT /api/collections/:collectionId
 *
 * Request Body:
 * - title: string (max 50 characters, optional)
 * - description: string (max 500 characters, optional)
 * - coverImage: string (optional)
 * - tags: string[] (max 10 tags, optional)
 * - tasks: Array<{ taskId, orderIndex }> (max 50 tasks, optional)
 * - visibility: "public" | "followers" | "private" (optional)
 */
export async function updateCollection(
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

    const body = req.body as UpdateCollectionRequest;

    // Validation
    if (body.title !== undefined) {
      if (body.title.trim().length === 0) {
        res.status(400).json({
          success: false,
          error: "タイトルが必要です",
        });
        return;
      }

      if (body.title.length > 50) {
        res.status(400).json({
          success: false,
          error: "タイトルは50文字以内で入力してください",
        });
        return;
      }
    }

    if (body.description !== undefined) {
      if (body.description.trim().length === 0) {
        res.status(400).json({
          success: false,
          error: "説明が必要です",
        });
        return;
      }

      if (body.description.length > 500) {
        res.status(400).json({
          success: false,
          error: "説明は500文字以内で入力してください",
        });
        return;
      }
    }

    if (body.tags !== undefined && body.tags.length > 10) {
      res.status(400).json({
        success: false,
        error: "タグは10個以内で入力してください",
      });
      return;
    }

    if (body.tasks !== undefined && body.tasks.length > 50) {
      res.status(400).json({
        success: false,
        error: "タスクは50個以内で登録してください",
      });
      return;
    }

    if (body.visibility !== undefined && !["public", "followers", "private"].includes(body.visibility)) {
      res.status(400).json({
        success: false,
        error: "無効な公開設定です",
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
        error: "このコレクションを編集する権限がありません",
      });
      return;
    }

    // Prepare update data
    const updateData: any = {
      updatedAt: firestore.Timestamp.now(),
    };

    if (body.title !== undefined) {
      updateData.title = body.title.trim();
    }

    if (body.description !== undefined) {
      updateData.description = body.description.trim();
    }

    if (body.coverImage !== undefined) {
      updateData.coverImage = body.coverImage || null;
    }

    if (body.tags !== undefined) {
      updateData.tags = body.tags;
    }

    if (body.visibility !== undefined) {
      updateData.visibility = body.visibility;
    }

    if (body.tasks !== undefined) {
      // Get task details
      const taskPromises = body.tasks.map(async (taskRef) => {
        const taskDoc = await db.collection("tasks").doc(taskRef.taskId).get();
        if (!taskDoc.exists) {
          return null;
        }
        const taskData = taskDoc.data()!;
        return {
          taskId: taskDoc.id,
          title: taskData.title,
          url: taskData.url,
          deadline: taskData.deadline,
          externalAppId: taskData.externalAppId,
          externalAppName: taskData.externalAppName,
          externalAppIconUrl: taskData.externalAppIconUrl,
          coverImage: taskData.coverImage,
          orderIndex: taskRef.orderIndex,
        };
      });

      const tasks = (await Promise.all(taskPromises)).filter((task) => task !== null);

      updateData.tasks = tasks;
      updateData.taskCount = tasks.length;
    }

    // Update collection
    await db.collection("collections").doc(collectionId).update(updateData);

    // Get updated collection
    const updatedDoc = await db.collection("collections").doc(collectionId).get();
    const updatedData = updatedDoc.data()!;

    const updatedCollection: VoteCollection = {
      collectionId: updatedDoc.id,
      creatorId: updatedData.creatorId,
      creatorName: updatedData.creatorName,
      creatorAvatarUrl: updatedData.creatorAvatarUrl,
      title: updatedData.title,
      description: updatedData.description,
      coverImage: updatedData.coverImage,
      tags: updatedData.tags || [],
      tasks: updatedData.tasks || [],
      taskCount: updatedData.taskCount || 0,
      visibility: updatedData.visibility || "public",
      likeCount: updatedData.likeCount || 0,
      saveCount: updatedData.saveCount || 0,
      viewCount: updatedData.viewCount || 0,
      commentCount: updatedData.commentCount || 0,
      createdAt: updatedData.createdAt,
      updatedAt: updatedData.updatedAt,
    };

    res.status(200).json({
      success: true,
      data: {
        collection: updatedCollection,
      },
    });
  } catch (error) {
    console.error("❌ [updateCollection] Error:", error);
    res.status(500).json({
      success: false,
      error: "コレクションの更新に失敗しました",
    });
  }
}
