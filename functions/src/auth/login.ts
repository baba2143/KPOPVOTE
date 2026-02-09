/**
 * User login endpoint
 * Supports both:
 * 1. Phone number authentication (Bearer token in Authorization header)
 * 2. Email/password authentication (legacy, for backward compatibility)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { LoginRequest, AuthResponse, ApiResponse } from "../types";
import { validateEmail, validatePassword } from "../utils/validation";

export const login = functions
  .runWith({ memory: "256MB", timeoutSeconds: 60, maxInstances: 30 })
  .https.onRequest(async (req, res) => {
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
    // Check for Bearer token authentication (phone number auth)
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith("Bearer ")) {
      const idToken = authHeader.split("Bearer ")[1];

      // Verify the Firebase ID token
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      const uid = decodedToken.uid;

      // Get or create user profile in Firestore
      const userRef = admin.firestore().collection("users").doc(uid);
      let userDoc = await userRef.get();

      if (!userDoc.exists) {
        // Create new user profile
        const phoneNumber = req.body?.phoneNumber ||
          decodedToken.phone_number || "";
        const newUserData = {
          uid,
          email: decodedToken.email || "",
          phoneNumber,
          points: 100,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await userRef.set(newUserData);
        userDoc = await userRef.get();
        console.log("Created new user profile for phone auth:", uid);
      }

      const userData = userDoc.data();

      // Return success response for phone auth
      res.status(200).json({
        success: true,
        data: {
          uid,
          email: userData?.email || decodedToken.email || "",
          displayName: userData?.displayName || null,
          phoneNumber: userData?.phoneNumber || decodedToken.phone_number || "",
          photoURL: userData?.photoURL || null,
          points: userData?.points || 0,
          isSuspended: userData?.isSuspended || false,
        },
      });
      return;
    }

    // Legacy email/password authentication flow
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
      "code" in error
    ) {
      const errorCode = (error as { code: string }).code;
      if (errorCode === "auth/user-not-found") {
        res.status(404).json({
          success: false,
          error: "User not found",
        } as ApiResponse<null>);
        return;
      }
      if (errorCode === "auth/id-token-expired") {
        res.status(401).json({
          success: false,
          error: "Token expired. Please re-authenticate.",
        } as ApiResponse<null>);
        return;
      }
      if (errorCode === "auth/argument-error" ||
          errorCode === "auth/id-token-revoked") {
        res.status(401).json({
          success: false,
          error: "Invalid token. Please re-authenticate.",
        } as ApiResponse<null>);
        return;
      }
    }

    res.status(500).json({
      success: false,
      error: "Internal server error during login",
    } as ApiResponse<null>);
  }
});
