/**
 * User registration endpoint - iOS Client-Side Auth Pattern
 *
 * iOS creates Firebase Auth user first, then calls this endpoint
 * to create Firestore user profile
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { validateEmail } from "../utils/validation";

// iOS request format
interface IOSRegisterRequest {
  uid: string;
  email: string;
  displayName?: string;
}

// iOS response format
interface IOSRegisterResponse {
  uid: string;
  email: string;
  points: number;
}

export const register = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type");

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
    const { uid, email, displayName } = req.body as IOSRegisterRequest;

    // Validate required fields
    if (!uid || !email) {
      res.status(400).json({
        success: false,
        error: "Missing required fields: uid and email",
      } as ApiResponse<null>);
      return;
    }

    // Validate email format
    const emailValidation = validateEmail(email);
    if (!emailValidation.valid) {
      res.status(400).json({
        success: false,
        error: emailValidation.error,
      } as ApiResponse<null>);
      return;
    }

    // Verify Firebase Auth user exists
    try {
      await admin.auth().getUser(uid);
    } catch (error) {
      console.error("User not found in Firebase Auth:", error);
      res.status(404).json({
        success: false,
        error: "Firebase Auth user not found. Please create user first.",
      } as ApiResponse<null>);
      return;
    }

    // Create user profile in Firestore
    const userProfile = {
      uid: uid,
      email: email,
      displayName: displayName || email.split("@")[0],
      photoURL: null,
      myBias: [],
      points: 0, // Initial points
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await admin
      .firestore()
      .collection("users")
      .doc(uid)
      .set(userProfile);

    // Return success response in iOS expected format
    res.status(200).json({
      success: true,
      data: {
        uid: uid,
        email: email,
        points: 0,
      } as IOSRegisterResponse,
    } as ApiResponse<IOSRegisterResponse>);
  } catch (error: unknown) {
    console.error("Registration error:", error);

    // Handle Firestore errors
    if (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      error.code === 6 // ALREADY_EXISTS
    ) {
      res.status(409).json({
        success: false,
        error: "User profile already exists",
      } as ApiResponse<null>);
      return;
    }

    res.status(500).json({
      success: false,
      error: "Internal server error during registration",
    } as ApiResponse<null>);
  }
});
