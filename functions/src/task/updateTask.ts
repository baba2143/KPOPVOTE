/**
 * Update task endpoint
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  TaskUpdateRequest,
  ApiResponse,
  TaskUpdateResponse,
} from "../types";
import { validateURL, validateISODate } from "../utils/validation";

export const updateTask = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Handle preflight request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Only accept POST requests
  if (req.method !== "POST") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use POST.",
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
    const {
      taskId,
      title,
      url,
      deadline,
      targetMembers,
      externalAppId,
      coverImage,
      coverImageSource,
    } = req.body as TaskUpdateRequest;

    // Validate taskId
    if (!taskId || typeof taskId !== "string" || taskId.trim().length === 0) {
      res.status(400).json({
        success: false,
        error: "Task ID is required",
      } as ApiResponse<null>);
      return;
    }

    // Validate required fields
    if (!title || typeof title !== "string" || title.trim().length === 0) {
      res.status(400).json({
        success: false,
        error: "Title is required",
      } as ApiResponse<null>);
      return;
    }

    // Validate URL
    const urlValidation = validateURL(url);
    if (!urlValidation.valid) {
      res.status(400).json({
        success: false,
        error: urlValidation.error,
      } as ApiResponse<null>);
      return;
    }

    // Validate deadline
    const deadlineValidation = validateISODate(deadline);
    if (!deadlineValidation.valid) {
      res.status(400).json({
        success: false,
        error: deadlineValidation.error,
      } as ApiResponse<null>);
      return;
    }

    // Validate targetMembers if provided
    if (targetMembers && !Array.isArray(targetMembers)) {
      res.status(400).json({
        success: false,
        error: "targetMembers must be an array",
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

    // Update task document in Firestore
    const taskData = {
      title: title.trim(),
      url,
      deadline: admin.firestore.Timestamp.fromDate(new Date(deadline)),
      targetMembers: targetMembers || [],
      externalAppId: externalAppId || null,
      coverImage: coverImage || null,
      coverImageSource: coverImageSource || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await taskRef.update(taskData);

    console.log(`✅ [updateTask] Task updated successfully: ${taskId}`);

    // Return success response
    res.status(200).json({
      success: true,
      data: {
        taskId: taskId,
        title: taskData.title,
        url: taskData.url,
        deadline: deadline,
        targetMembers: taskData.targetMembers,
        externalAppId: taskData.externalAppId,
        coverImage: taskData.coverImage,
        coverImageSource: taskData.coverImageSource,
      },
    } as ApiResponse<TaskUpdateResponse>);
  } catch (error: unknown) {
    console.error("❌ [updateTask] Update task error:", error);

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
