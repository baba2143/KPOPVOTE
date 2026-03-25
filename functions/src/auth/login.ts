/**
 * User login endpoint - iOS Client-Side Auth Pattern
 *
 * iOS authenticates with Firebase Auth first, then calls this endpoint
 * with ID token to fetch user profile data
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { AUTH_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

// iOS response format
interface IOSLoginResponse {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  points: number;
  isSuspended: boolean;
}

export const login = functions
  .runWith(AUTH_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

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

      let userProfile;

      if (!userDoc.exists) {
      // 電話番号認証の新規ユーザーの場合、プロファイルを自動作成
        console.log(`[login] Creating new user profile for: ${uid}`);

        const phoneNumber = req.body?.phoneNumber || decodedToken.phone_number || "";
        const newUserData = {
          uid: uid,
          email: decodedToken.email || "",
          phoneNumber: phoneNumber,
          displayName: "",
          photoURL: null,
          points: 100, // 初期ポイント
          isSuspended: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await admin.firestore().collection("users").doc(uid).set(newUserData);
        console.log(`[login] New user profile created for: ${uid}`);

        userProfile = newUserData;
      } else {
        userProfile = userDoc.data()!;
      }

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
          email: userProfile.email || decodedToken.email || "",
          displayName: userProfile.displayName || null,
          photoURL: userProfile.photoURL || null,
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
