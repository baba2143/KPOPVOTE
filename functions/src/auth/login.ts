/**
 * User login endpoint - iOS Client-Side Auth Pattern
 *
 * iOS authenticates with Firebase Auth first, then calls this endpoint
 * with ID token to fetch user profile data
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";

// iOS response format
interface IOSLoginResponse {
  uid: string;
  email: string;
  displayName?: string;
  points: number;
  isSuspended: boolean;
}

export const login = functions.https.onRequest(async (req, res) => {
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
    // Extract ID token from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({
        success: false,
        error: "Missing or invalid Authorization header",
      } as ApiResponse<null>);
      return;
    }

    const idToken = authHeader.split("Bearer ")[1];

    // Verify ID token
    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      console.error("Token verification failed:", error);
      res.status(401).json({
        success: false,
        error: "Invalid or expired ID token",
      } as ApiResponse<null>);
      return;
    }

    const uid = decodedToken.uid;

    // Get user profile from Firestore
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(uid)
      .get();

    if (!userDoc.exists) {
      res.status(404).json({
        success: false,
        error: "User profile not found in database",
      } as ApiResponse<null>);
      return;
    }

    const userProfile = userDoc.data()!;

    // Check if user is suspended
    if (userProfile.isSuspended) {
      res.status(403).json({
        success: false,
        error: "Account is suspended",
      } as ApiResponse<null>);
      return;
    }

    // Return success response in iOS expected format
    res.status(200).json({
      success: true,
      data: {
        uid: uid,
        email: userProfile.email || decodedToken.email,
        displayName: userProfile.displayName,
        points: userProfile.points || 0,
        isSuspended: userProfile.isSuspended || false,
      } as IOSLoginResponse,
    } as ApiResponse<IOSLoginResponse>);
  } catch (error: unknown) {
    console.error("Login error:", error);

    res.status(500).json({
      success: false,
      error: "Internal server error during login",
    } as ApiResponse<null>);
  }
});
