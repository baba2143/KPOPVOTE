//
// addToTasks.ts
// K-VOTE COLLECTOR - Add Collection Tasks to User's Tasks API
//

import { Response } from "express";
import { firestore } from "firebase-admin";
import { AddToTasksResponse } from "../../types/voteCollection";
import { AuthenticatedRequest } from "../../middleware/auth";

/**
 * Add Collection Tasks to User's Tasks
 * POST /api/collections/:collectionId/add-to-tasks
 *
 * Behavior:
 * - Checks for duplicates based on URL
 * - Skips already existing tasks
 * - Adds only new tasks to user's TASKS tab
 * - Updates save record with addedTaskIds
 */
export async function addToTasks(
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
    const tasks = collectionData.tasks || [];

    if (tasks.length === 0) {
      res.status(400).json({
        success: false,
        error: "コレクションにタスクがありません",
      });
      return;
    }

    // Get user's existing tasks
    const userTasksSnapshot = await db.collection("tasks")
      .where("userId", "==", userId)
      .get();

    const existingTaskUrls = new Set(
      userTasksSnapshot.docs.map((doc) => doc.data().url)
    );

    // Filter out duplicates (based on URL)
    const newTasks = tasks.filter((task: any) => !existingTaskUrls.has(task.url));
    const skippedCount = tasks.length - newTasks.length;

    if (newTasks.length === 0) {
      res.status(200).json({
        success: true,
        data: {
          addedCount: 0,
          skippedCount,
          totalCount: tasks.length,
          addedTaskIds: [],
          message: "全てのタスクが既に登録されています",
        },
      } as AddToTasksResponse);
      return;
    }

    // Add new tasks
    const batch = db.batch();
    const addedTaskIds: string[] = [];
    const now = firestore.Timestamp.now();

    for (const task of newTasks) {
      const taskRef = db.collection("tasks").doc();
      batch.set(taskRef, {
        userId,
        title: task.title,
        url: task.url,
        deadline: task.deadline,
        externalAppId: task.externalAppId || null,
        externalAppName: task.externalAppName || null,
        externalAppIconUrl: task.externalAppIconUrl || null,
        coverImage: task.coverImage || null,
        status: "active",
        reminderEnabled: false,
        reminderTime: null,
        addedFromCollectionId: collectionId,
        createdAt: now,
        updatedAt: now,
      });
      addedTaskIds.push(taskRef.id);
    }

    // Update save record
    const saveDocId = `${userId}_${collectionId}`;
    const saveDoc = db.collection("userCollectionSaves").doc(saveDocId);
    const saveSnapshot = await saveDoc.get();

    if (saveSnapshot.exists) {
      batch.update(saveDoc, {
        addedToTasks: true,
        addedTaskIds,
      });
    } else {
      // Create save record if it doesn't exist
      batch.set(saveDoc, {
        userId,
        collectionId,
        savedAt: now,
        addedToTasks: true,
        addedTaskIds,
      });

      // Increment saveCount
      batch.update(db.collection("collections").doc(collectionId), {
        saveCount: firestore.FieldValue.increment(1),
      });
    }

    await batch.commit();

    const response: AddToTasksResponse = {
      success: true,
      data: {
        addedCount: newTasks.length,
        skippedCount,
        totalCount: tasks.length,
        addedTaskIds,
        message: `${newTasks.length}件のタスクを追加しました`,
      },
    };

    res.status(200).json(response);
  } catch (error) {
    console.error("❌ [addToTasks] Error:", error);
    res.status(500).json({
      success: false,
      error: "タスクの追加に失敗しました",
    });
  }
}
