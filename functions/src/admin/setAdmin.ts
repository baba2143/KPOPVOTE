/**
 * Set admin role for a user
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  AdminAuthRequest,
  ApiResponse,
  AdminAuthResponse,
} from "../types";

export const setAdmin = functions.https.onRequest(async (req, res) => {
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
    const callerUid = decodedToken.uid;

    // Check if caller is already an admin (for security)
    const callerRecord = await admin.auth().getUser(callerUid);
    const callerIsAdmin = callerRecord.customClaims?.admin === true;

    // For initial setup, allow the first user to become admin
    // In production, this should be restricted or done via Firebase CLI
    const { uid } = req.body as AdminAuthRequest;

    if (!uid || typeof uid !== "string") {
      res.status(400).json({
        success: false,
        error: "uid is required",
      } as ApiResponse<null>);
      return;
    }

    // TODO: Add proper authorization logic
    // For now, allow setting admin if caller is admin or if no admins exist yet
    if (!callerIsAdmin) {
      // Check if any admins exist
      const usersSnapshot = await admin.firestore().collection("users").get();
      let adminExists = false;

      for (const doc of usersSnapshot.docs) {
        const userRecord = await admin.auth().getUser(doc.id);
        if (userRecord.customClaims?.admin === true) {
          adminExists = true;
          break;
        }
      }

      if (adminExists) {
        res.status(403).json({
          success: false,
          error: "Forbidden: Admin access required",
        } as ApiResponse<null>);
        return;
      }
    }

    // Set admin custom claim
    await admin.auth().setCustomUserClaims(uid, { admin: true });

    // Also update Firestore user document
    await admin
      .firestore()
      .collection("users")
      .doc(uid)
      .set({ isAdmin: true }, { merge: true });

    // Return success response
    res.status(200).json({
      success: true,
      data: {
        uid,
        isAdmin: true,
      },
    } as ApiResponse<AdminAuthResponse>);
  } catch (error: unknown) {
    console.error("Set admin error:", error);

    // Handle specific Firebase errors
    if (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      error.code === "auth/user-not-found"
    ) {
      res.status(404).json({
        success: false,
        error: "User not found",
      } as ApiResponse<null>);
      return;
    }

    res.status(500).json({
      success: false,
      error: "Internal server error",
    } as ApiResponse<null>);
  }
});
