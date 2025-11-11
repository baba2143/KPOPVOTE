/**
 * User registration endpoint
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { RegisterRequest, AuthResponse, ApiResponse } from "../types";
import {
  validateEmail,
  validatePassword,
  validateDisplayName,
} from "../utils/validation";

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
    const { email, password, displayName } = req.body as RegisterRequest;

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

    const displayNameValidation = validateDisplayName(displayName);
    if (!displayNameValidation.valid) {
      res.status(400).json({
        success: false,
        error: displayNameValidation.error,
      } as ApiResponse<null>);
      return;
    }

    // Create user with Firebase Authentication
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: displayName || email.split("@")[0],
    });

    // Create user profile in Firestore
    const userProfile = {
      uid: userRecord.uid,
      email: userRecord.email!,
      displayName: userRecord.displayName || email.split("@")[0],
      photoURL: null,
      myBias: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await admin
      .firestore()
      .collection("users")
      .doc(userRecord.uid)
      .set(userProfile);

    // Generate custom token for immediate login
    const customToken = await admin.auth().createCustomToken(userRecord.uid);

    // Return success response
    res.status(201).json({
      success: true,
      data: {
        uid: userRecord.uid,
        email: userRecord.email!,
        displayName: userRecord.displayName,
        token: customToken,
      } as AuthResponse,
    } as ApiResponse<AuthResponse>);
  } catch (error: unknown) {
    console.error("Registration error:", error);

    // Handle specific Firebase errors
    if (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      error.code === "auth/email-already-exists"
    ) {
      res.status(409).json({
        success: false,
        error: "Email already registered",
      } as ApiResponse<null>);
      return;
    }

    res.status(500).json({
      success: false,
      error: "Internal server error during registration",
    } as ApiResponse<null>);
  }
});
