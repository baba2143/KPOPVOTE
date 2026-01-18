/**
 * Get user notification settings endpoint
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { UserNotificationSettings, ApiResponse } from "../types";

export const getNotificationSettings = functions.https.onRequest(
  async (req, res) => {
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

      // Get notification settings from Firestore
      const settingsDoc = await admin
        .firestore()
        .collection("userNotificationSettings")
        .doc(uid)
        .get();

      let settings: Omit<UserNotificationSettings, "createdAt" | "updatedAt"> & {
        createdAt: string | null;
        updatedAt: string | null;
      };

      if (!settingsDoc.exists) {
        // Return default settings (all enabled)
        settings = {
          userId: uid,
          pushEnabled: true,
          likes: true,
          comments: true,
          mentions: true,
          followers: true,
          newPosts: true,
          voteReminders: true,
          calendarReminders: true,
          announcements: true,
          directMessages: true,
          createdAt: null,
          updatedAt: null,
        };
      } else {
        const data = settingsDoc.data();
        settings = {
          userId: uid,
          pushEnabled: data?.pushEnabled ?? true,
          likes: data?.likes ?? true,
          comments: data?.comments ?? true,
          mentions: data?.mentions ?? true,
          followers: data?.followers ?? true,
          newPosts: data?.newPosts ?? true,
          voteReminders: data?.voteReminders ?? true,
          calendarReminders: data?.calendarReminders ?? true,
          announcements: data?.announcements ?? true,
          directMessages: data?.directMessages ?? true,
          createdAt: data?.createdAt?.toDate().toISOString() ?? null,
          updatedAt: data?.updatedAt?.toDate().toISOString() ?? null,
        };
      }

      // Return success response
      res.status(200).json({
        success: true,
        data: settings,
      } as ApiResponse<typeof settings>);
    } catch (error: unknown) {
      console.error("Get notification settings error:", error);

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
  }
);
