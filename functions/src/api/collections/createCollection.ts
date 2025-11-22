//
// createCollection.ts
// K-VOTE COLLECTOR - Create Collection API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import { firestore } from "firebase-admin";
import {
  CreateCollectionRequest,
  VoteCollection,
} from "../../types/voteCollection";

/**
 * Create Collection
 * POST /api/collections
 *
 * Request Body:
 * - title: string (max 50 characters, required)
 * - description: string (max 500 characters, required)
 * - coverImage: string (optional)
 * - tags: string[] (max 10 tags, required)
 * - tasks: Array<{ taskId, orderIndex }> (max 50 tasks, required)
 * - visibility: "public" | "followers" | "private" (required)
 */
export async function createCollection(
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

    const body = req.body as CreateCollectionRequest;

    // Validation
    if (!body.title || body.title.trim().length === 0) {
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

    if (!body.description || body.description.trim().length === 0) {
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

    if (!body.tags || body.tags.length === 0) {
      res.status(400).json({
        success: false,
        error: "タグが必要です",
      });
      return;
    }

    if (body.tags.length > 10) {
      res.status(400).json({
        success: false,
        error: "タグは10個以内で入力してください",
      });
      return;
    }

    if (!body.tasks || body.tasks.length === 0) {
      res.status(400).json({
        success: false,
        error: "タスクが必要です",
      });
      return;
    }

    if (body.tasks.length > 50) {
      res.status(400).json({
        success: false,
        error: "タスクは50個以内で登録してください",
      });
      return;
    }

    if (!["public", "followers", "private"].includes(body.visibility)) {
      res.status(400).json({
        success: false,
        error: "無効な公開設定です",
      });
      return;
    }

    const db = firestore();

    // Get user info
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      res.status(404).json({
        success: false,
        error: "ユーザーが見つかりません",
      });
      return;
    }

    const userData = userDoc.data()!;

    // Get task details from user's tasks subcollection
    const taskPromises = body.tasks.map(async (taskRef) => {
      const taskDoc = await db
        .collection("users")
        .doc(userId)
        .collection("tasks")
        .doc(taskRef.taskId)
        .get();
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

    if (tasks.length === 0) {
      res.status(400).json({
        success: false,
        error: "有効なタスクが見つかりません",
      });
      return;
    }

    // Create collection
    const now = firestore.Timestamp.now();
    const collectionData: VoteCollection = {
      collectionId: "",
      creatorId: userId,
      creatorName: userData.displayName || "匿名ユーザー",
      creatorAvatarUrl: userData.photoURL,
      title: body.title.trim(),
      description: body.description.trim(),
      coverImage: body.coverImage,
      tags: body.tags,
      tasks,
      taskCount: tasks.length,
      visibility: body.visibility,
      likeCount: 0,
      saveCount: 0,
      viewCount: 0,
      commentCount: 0,
      createdAt: now,
      updatedAt: now,
    };

    const collectionRef = await db.collection("collections").add(collectionData);

    collectionData.collectionId = collectionRef.id;

    res.status(201).json({
      success: true,
      data: {
        collection: collectionData,
      },
    });
  } catch (error) {
    console.error("❌ [createCollection] Error:", error);
    res.status(500).json({
      success: false,
      error: "コレクションの作成に失敗しました",
    });
  }
}
