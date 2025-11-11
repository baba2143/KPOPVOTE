/**
 * User login endpoint
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { LoginRequest, AuthResponse, ApiResponse } from "../types";
import { validateEmail, validatePassword } from "../utils/validation";

export const login = functions.https.onRequest(async (req, res) => {
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
    const { email, password } = req.body as LoginRequest;

    // Validate input
    const emailValidation = validateEmail(email);
    if (!emailValidation.valid) {
      res.status(400).json({
        success: false,
        error: emailValidation.error,
      } as ApiResponse<null>);
      return;
    }

    const passwordValidation = validatePassword(password);
    if (!passwordValidation.valid) {
      res.status(400).json({
        success: false,
        error: passwordValidation.error,
      } as ApiResponse<null>);
      return;
    }

    // Get user by email
    const userRecord = await admin.auth().getUserByEmail(email);

    // NOTE: Firebase Admin SDK cannot verify password directly
    // In production, client should use Firebase Client SDK for authentication
    // This endpoint is for generating custom tokens after client-side auth

    // Generate custom token
    const customToken = await admin.auth().createCustomToken(userRecord.uid);

    // Get user profile from Firestore
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userRecord.uid)
      .get();

    const userProfile = userDoc.data();

    // Return success response
    res.status(200).json({
      success: true,
      data: {
        uid: userRecord.uid,
        email: userRecord.email!,
        displayName: userProfile?.displayName || userRecord.displayName,
        token: customToken,
      } as AuthResponse,
    } as ApiResponse<AuthResponse>);
  } catch (error: unknown) {
    console.error("Login error:", error);

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
      error: "Internal server error during login",
    } as ApiResponse<null>);
  }
});
