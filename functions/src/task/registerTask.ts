/**
 * Register voting task endpoint
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  TaskRegisterRequest,
  ApiResponse,
  TaskRegisterResponse,
} from "../types";
import { validateURL, validateISODate } from "../utils/validation";

export const registerTask = functions.https.onRequest(async (req, res) => {
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
    const { title, url, deadline, targetMembers, externalAppId, coverImage, coverImageSource } =
      req.body as TaskRegisterRequest;

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

    // Create task document in Firestore
    const tasksCollection = admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("tasks");

    const taskData = {
      title: title.trim(),
      url,
      deadline: admin.firestore.Timestamp.fromDate(new Date(deadline)),
      targetMembers: targetMembers || [],
      externalAppId: externalAppId || null,
      isCompleted: false,
      completedAt: null,
      coverImage: coverImage || null,
      coverImageSource: coverImageSource || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const taskRef = await tasksCollection.add(taskData);

    // Return success response with taskId
    res.status(201).json({
      success: true,
      data: {
        taskId: taskRef.id,
        title: taskData.title,
        url: taskData.url,
        deadline: deadline,
        targetMembers: taskData.targetMembers,
        externalAppId: taskData.externalAppId,
        isCompleted: taskData.isCompleted,
        completedAt: null,
        coverImage: taskData.coverImage,
        coverImageSource: taskData.coverImageSource,
      },
    } as ApiResponse<TaskRegisterResponse>);
  } catch (error: unknown) {
    console.error("Register task error:", error);

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
