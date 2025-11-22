//
// addSingleTask.ts
// K-VOTE COLLECTOR - Add Single Task from Collection to User's Tasks API
//

import { Response } from "express";
import { firestore } from "firebase-admin";
import { AuthenticatedRequest } from "../../middleware/auth";

/**
 * Response for adding a single task
 */
export interface AddSingleTaskResponse {
  success: boolean;
  data?: {
    taskId: string;
    alreadyAdded: boolean;
    message: string;
  };
  error?: string;
}

/**
 * Add Single Task from Collection to User's Tasks
 * POST /api/collections/:collectionId/tasks/:taskId/add
 *
 * Behavior:
 * - Finds the specific task within the collection
 * - Checks for duplicates based on URL
 * - Adds task to user's TASKS tab if not already added
 */
export async function addSingleTask(
  req: AuthenticatedRequest,
  res: Response
): Promise<void> {
  try {
    const userId = req.user?.uid;
    const collectionId = req.params.collectionId;
    const taskId = req.params.taskId;

    console.log(`🔄 [addSingleTask] Request: collectionId=${collectionId}, taskId=${taskId}, userId=${userId}`);

    if (!userId) {
      console.log("❌ [addSingleTask] No user ID");
      res.status(401).json({
        success: false,
        error: "認証が必要です",
      });
      return;
    }

    if (!collectionId || !taskId) {
      console.log("❌ [addSingleTask] Missing collectionId or taskId");
      res.status(400).json({
        success: false,
        error: "コレクションIDとタスクIDが必要です",
      });
      return;
    }

    const db = firestore();

    // Get collection
    const collectionDoc = await db.collection("collections").doc(collectionId).get();
    if (!collectionDoc.exists) {
      console.log(`❌ [addSingleTask] Collection not found: ${collectionId}`);
      res.status(404).json({
        success: false,
        error: "コレクションが見つかりません",
      });
      return;
    }

    const collectionData = collectionDoc.data()!;
    const tasks = collectionData.tasks || [];

    // Find the specific task by ID
    const targetTask = tasks.find((task: any) => task.id === taskId);

    if (!targetTask) {
      console.log(`❌ [addSingleTask] Task not found in collection: ${taskId}`);
      res.status(404).json({
        success: false,
        error: "指定されたタスクがコレクション内に見つかりません",
      });
      return;
    }

    console.log(`📋 [addSingleTask] Found task: ${targetTask.title}`);

    // Check if user already has this task (by URL)
    const userTasksSnapshot = await db.collection("tasks")
      .where("userId", "==", userId)
      .where("url", "==", targetTask.url)
      .get();

    if (!userTasksSnapshot.empty) {
      console.log(`⚠️ [addSingleTask] Task already added (URL match): ${targetTask.url}`);
      res.status(200).json({
        success: true,
        data: {
          taskId,
          alreadyAdded: true,
          message: "このタスクは既に追加されています",
        },
      } as AddSingleTaskResponse);
      return;
    }

    // Add the task
    const now = firestore.Timestamp.now();
    const taskRef = db.collection("tasks").doc();

    await taskRef.set({
      userId,
      title: targetTask.title,
      url: targetTask.url,
      deadline: targetTask.deadline,
      externalAppId: targetTask.externalAppId || null,
      externalAppName: targetTask.externalAppName || null,
      externalAppIconUrl: targetTask.externalAppIconUrl || null,
      coverImage: targetTask.coverImage || null,
      status: "active",
      reminderEnabled: false,
      reminderTime: null,
      addedFromCollectionId: collectionId,
      addedFromTaskId: taskId,
      createdAt: now,
      updatedAt: now,
    });

    console.log(`✅ [addSingleTask] Task added successfully: ${taskRef.id}`);

    const response: AddSingleTaskResponse = {
      success: true,
      data: {
        taskId: taskRef.id,
        alreadyAdded: false,
        message: "タスクをTASKSに追加しました",
      },
    };

    res.status(200).json(response);
  } catch (error) {
    console.error("❌ [addSingleTask] Error:", error);
    res.status(500).json({
      success: false,
      error: "タスクの追加に失敗しました",
    });
  }
}
