/**
 * Update task status endpoint
 * タスク完了時にポイント報酬を付与
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  TaskUpdateStatusRequest,
  ApiResponse,
  TaskStatusResponse,
} from "../types";
import { grantRewardPoints } from "../utils/rewardHelper";

export const updateTaskStatus = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, PATCH");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Handle preflight request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Accept both POST and PATCH requests
  if (req.method !== "PATCH" && req.method !== "POST") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use POST or PATCH.",
    } as ApiResponse<null>);
    return;
  }

  try {
    // Verify authentication token
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({
        success: false,
        error: "Unauthorized: No token provided",
      } as ApiResponse<null>);
      return;
    }

    const token = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = decodedToken.uid;

    // Get request body
    const { taskId, isCompleted } = req.body as TaskUpdateStatusRequest;

    // Validate required fields
    if (!taskId || typeof taskId !== "string") {
      res.status(400).json({
        success: false,
        error: "taskId is required",
      } as ApiResponse<null>);
      return;
    }

    if (typeof isCompleted !== "boolean") {
      res.status(400).json({
        success: false,
        error: "isCompleted must be a boolean",
      } as ApiResponse<null>);
      return;
    }

    // Get task reference
    const taskRef = admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("tasks")
      .doc(taskId);

    // Check if task exists
    const taskDoc = await taskRef.get();

    if (!taskDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Task not found",
      } as ApiResponse<null>);
      return;
    }

    const taskData = taskDoc.data()!;
    const wasCompleted = taskData.isCompleted || false;

    // Update task status
    const updateData: {
      isCompleted: boolean;
      updatedAt: admin.firestore.FieldValue;
      completedAt: admin.firestore.FieldValue | null;
    } = {
      isCompleted,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      completedAt: null,
    };

    // Set completedAt timestamp if task is being completed
    if (isCompleted) {
      updateData.completedAt = admin.firestore.FieldValue.serverTimestamp();
    }

    await taskRef.update(updateData);

    // タスク完了報酬の付与（未完了→完了の場合のみ）
    let pointsGranted = 0;
    if (!wasCompleted && isCompleted) {
      try {
        // ユーザー情報を取得（サブスク状態確認）
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        if (userDoc.exists) {
          const userData = userDoc.data()!;
          const isPremium = userData.isPremium || false;

          // タスク完了報酬を付与（rewardSettingsから動的取得）
          pointsGranted = await grantRewardPoints(
            uid,
            "task_completion",
            isPremium,
            taskId,
          );

          console.log(
            "✅ [updateTaskStatus] Task completion reward granted: " +
              `user=${uid}, task=${taskId}, points=${pointsGranted}P, ` +
              `type=${isPremium ? "premium" : "regular"}`,
          );
        }
      } catch (rewardError) {
        // 報酬付与エラーはログに記録するが、タスク更新は成功させる
        console.error(
          `⚠️ [updateTaskStatus] Failed to grant reward for task ${taskId}:`,
          rewardError,
        );
      }
    }

    // Get updated task data
    const updatedDoc = await taskRef.get();
    const updatedData = updatedDoc.data();

    // Return success response (報酬情報を含む)
    res.status(200).json({
      success: true,
      data: {
        taskId: updatedDoc.id,
        isCompleted: updatedData?.isCompleted,
        completedAt: updatedData?.completedAt ?
          updatedData.completedAt.toDate().toISOString() :
          null,
        updatedAt: updatedData?.updatedAt ?
          updatedData.updatedAt.toDate().toISOString() :
          null,
        pointsGranted: pointsGranted > 0 ? pointsGranted : undefined,
      },
    } as ApiResponse<TaskStatusResponse>);
  } catch (error: unknown) {
    console.error("Update task status error:", error);

    // Handle specific Firebase errors
    if (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      error.code === "auth/id-token-expired"
    ) {
      res.status(401).json({
        success: false,
        error: "Token expired",
      } as ApiResponse<null>);
      return;
    }

    res.status(500).json({
      success: false,
      error: "Internal server error",
    } as ApiResponse<null>);
  }
});
