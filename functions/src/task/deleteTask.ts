/**
 * Delete task endpoint
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";

export const deleteTask = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, DELETE");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Handle preflight request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Accept both POST and DELETE methods
  if (req.method !== "POST" && req.method !== "DELETE") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use POST or DELETE.",
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

    // Get taskId from request body
    const { taskId } = req.body;

    // Validate taskId
    if (!taskId || typeof taskId !== "string" || taskId.trim().length === 0) {
      res.status(400).json({
        success: false,
        error: "Task ID is required",
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

    // Delete the task
    await taskRef.delete();

    console.log(`✅ [deleteTask] Task deleted successfully: ${taskId}`);

    // Return success response
    res.status(200).json({
      success: true,
      data: {
        taskId: taskId,
        message: "Task deleted successfully",
      },
    } as ApiResponse<{ taskId: string; message: string }>);
  } catch (error: unknown) {
    console.error("❌ [deleteTask] Delete task error:", error);

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
