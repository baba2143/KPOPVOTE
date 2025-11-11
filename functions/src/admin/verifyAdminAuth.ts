/**
 * Verify admin authentication
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse, AdminAuthResponse } from "../types";

export const verifyAdminAuth = functions.https.onRequest(async (req, res) => {
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

    // Get user custom claims
    const userRecord = await admin.auth().getUser(uid);
    const isAdmin = userRecord.customClaims?.admin === true;

    // Return success response
    res.status(200).json({
      success: true,
      data: {
        uid,
        isAdmin,
      },
    } as ApiResponse<AdminAuthResponse>);
  } catch (error: unknown) {
    console.error("Verify admin auth error:", error);

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
