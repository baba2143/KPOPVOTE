/**
 * Set user notification settings endpoint
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

/**
 * Request body for setNotificationSettings endpoint
 * All fields are optional to support partial updates
 */
interface SetNotificationSettingsRequest {
  pushEnabled?: boolean;
  likes?: boolean;
  comments?: boolean;
  mentions?: boolean;
  followers?: boolean;
  newPosts?: boolean;
  voteReminders?: boolean;
  calendarReminders?: boolean;
  announcements?: boolean;
  directMessages?: boolean;
}

export const setNotificationSettings = functions
  .runWith(STANDARD_CONFIG)
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

      // Get request body
      const settings = req.body as SetNotificationSettingsRequest;

      // Validate that at least one field is provided
      if (Object.keys(settings).length === 0) {
        res.status(400).json({
          success: false,
          error: "At least one notification setting must be provided",
        } as ApiResponse<null>);
        return;
      }

      // Validate all provided fields are booleans
      const validFields = [
        "pushEnabled",
        "likes",
        "comments",
        "mentions",
        "followers",
        "newPosts",
        "voteReminders",
        "calendarReminders",
        "announcements",
        "directMessages",
      ];

      for (const [key, value] of Object.entries(settings)) {
        if (!validFields.includes(key)) {
          res.status(400).json({
            success: false,
            error: `Invalid field: ${key}`,
          } as ApiResponse<null>);
          return;
        }

        if (typeof value !== "boolean") {
          res.status(400).json({
            success: false,
            error: `Field ${key} must be a boolean`,
          } as ApiResponse<null>);
          return;
        }
      }

      // Prepare update data
      const updateData: Record<string, unknown> = {
        ...settings,
        userId: uid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Check if document exists
      const settingsDoc = await admin
        .firestore()
        .collection("userNotificationSettings")
        .doc(uid)
        .get();

      if (!settingsDoc.exists) {
        // Create new document with defaults
        updateData.createdAt = admin.firestore.FieldValue.serverTimestamp();
        updateData.pushEnabled = settings.pushEnabled ?? true;
        updateData.likes = settings.likes ?? true;
        updateData.comments = settings.comments ?? true;
        updateData.mentions = settings.mentions ?? true;
        updateData.followers = settings.followers ?? true;
        updateData.newPosts = settings.newPosts ?? true;
        updateData.voteReminders = settings.voteReminders ?? true;
        updateData.calendarReminders = settings.calendarReminders ?? true;
        updateData.announcements = settings.announcements ?? true;
        updateData.directMessages = settings.directMessages ?? true;
      }

      // Update notification settings in Firestore (merge for partial update)
      await admin
        .firestore()
        .collection("userNotificationSettings")
        .doc(uid)
        .set(updateData, { merge: true });

      // Return success response
      res.status(200).json({
        success: true,
        data: { updated: true },
      } as ApiResponse<{ updated: boolean }>);
    } catch (error: unknown) {
      console.error("Set notification settings error:", error);

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
