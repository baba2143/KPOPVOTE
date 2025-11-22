//
// createCollection.ts
// K-VOTE COLLECTOR - Create Collection API
//

import { Response } from "express";
import { AuthenticatedRequest } from "../../middleware/auth";
import * as admin from "firebase-admin";
import {
  CreateCollectionRequest,
  VoteCollection,
  VoteTaskInCollection,
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

    const db = admin.firestore();

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
        console.log(`⚠️ [createCollection] Task not found: ${taskRef.taskId}`);
        return null;
      }
      const taskData = taskDoc.data()!;
      console.log(`✅ [createCollection] Task found: ${taskDoc.id}, deadline type: ${typeof taskData.deadline}`);
      const taskInCollection: VoteTaskInCollection = {
        taskId: taskDoc.id,
        title: taskData.title,
        url: taskData.url,
        deadline: taskData.deadline,
        orderIndex: taskRef.orderIndex,
        ...(taskData.externalAppId && { externalAppId: taskData.externalAppId }),
        ...(taskData.externalAppName && { externalAppName: taskData.externalAppName }),
        ...(taskData.externalAppIconUrl && { externalAppIconUrl: taskData.externalAppIconUrl }),
        ...(taskData.coverImage && { coverImage: taskData.coverImage }),
      };
      return taskInCollection;
    });

    const tasks = (await Promise.all(taskPromises)).filter(
      (task): task is VoteTaskInCollection => task !== null
    );
    console.log(`📊 [createCollection] Tasks retrieved: ${tasks.length}`);

    if (tasks.length === 0) {
      res.status(400).json({
        success: false,
        error: "有効なタスクが見つかりません",
      });
      return;
    }

    // Create collection
    const now = admin.firestore.Timestamp.now();
    console.log(`🔨 [createCollection] Building collection data for: ${body.title}`);
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

    console.log("💾 [createCollection] Saving to Firestore...");
    const collectionRef = await db.collection("collections").add(collectionData);
    console.log(`✅ [createCollection] Collection created with ID: ${collectionRef.id}`);

    collectionData.collectionId = collectionRef.id;

    res.status(201).json({
      success: true,
      data: {
        collectionId: collectionRef.id,
        title: collectionData.title,
        createdAt: collectionData.createdAt.toDate().toISOString(),
      },
    });
  } catch (error) {
    console.error("❌ [createCollection] Error:", error);
    console.error("❌ [createCollection] Error stack:", error instanceof Error ? error.stack : "No stack");
    console.error("❌ [createCollection] Error message:", error instanceof Error ? error.message : String(error));
    res.status(500).json({
      success: false,
      error: "コレクションの作成に失敗しました",
    });
  }
}
