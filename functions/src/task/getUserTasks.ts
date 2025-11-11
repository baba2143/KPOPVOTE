/**
 * Get user tasks endpoint
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";

export const getUserTasks = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Handle preflight request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Only accept GET requests
  if (req.method !== "GET") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use GET.",
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

    // Get query parameters
    const isCompleted = req.query.isCompleted;
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 100;

    // Build Firestore query
    let query = admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("tasks")
      .orderBy("deadline", "asc")
      .limit(limit);

    // Filter by completion status if specified
    if (isCompleted !== undefined) {
      const completedFilter = isCompleted === "true";
      query = query.where("isCompleted", "==", completedFilter) as any;
    }

    // Execute query
    const snapshot = await query.get();

    // Transform tasks data
    const tasks = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        taskId: doc.id,
        title: data.title,
        url: data.url,
        deadline: data.deadline.toDate().toISOString(),
        targetMembers: data.targetMembers || [],
        isCompleted: data.isCompleted,
        completedAt: data.completedAt
          ? data.completedAt.toDate().toISOString()
          : null,
        ogpTitle: data.ogpTitle || null,
        ogpImage: data.ogpImage || null,
        createdAt: data.createdAt
          ? data.createdAt.toDate().toISOString()
          : null,
        updatedAt: data.updatedAt
          ? data.updatedAt.toDate().toISOString()
          : null,
      };
    });

    // Return success response
    res.status(200).json({
      success: true,
      data: {
        tasks,
        count: tasks.length,
      },
    } as ApiResponse<any>);
  } catch (error: unknown) {
    console.error("Get user tasks error:", error);

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
