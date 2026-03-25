/**
 * Cancel Scheduled Notification API
 * Allows administrators to cancel pending scheduled notifications
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

const db = admin.firestore();

export const cancelScheduledNotification = functions
  .runWith(ADMIN_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS
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
      // Verify admin authentication
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
      const adminUid = decodedToken.uid;

      // Verify admin privileges
      const userRecord = await admin.auth().getUser(adminUid);
      if (!userRecord.customClaims?.admin) {
        res.status(403).json({
          success: false,
          error: "Forbidden: Admin privileges required",
        } as ApiResponse<null>);
        return;
      }

      // Parse request body
      const { notificationId } = req.body as { notificationId: string };

      if (!notificationId) {
        res.status(400).json({
          success: false,
          error: "Missing required field: notificationId",
        } as ApiResponse<null>);
        return;
      }

      // Get the notification
      const notificationRef = db.collection("adminNotifications").doc(notificationId);
      const notificationDoc = await notificationRef.get();

      if (!notificationDoc.exists) {
        res.status(404).json({
          success: false,
          error: "Notification not found",
        } as ApiResponse<null>);
        return;
      }

      const notification = notificationDoc.data();

      // Check if notification is pending
      if (notification?.status !== "pending") {
        res.status(400).json({
          success: false,
          error: `Cannot cancel notification with status: ${notification?.status}. ` +
            "Only pending notifications can be cancelled.",
        } as ApiResponse<null>);
        return;
      }

      // Update status to cancelled
      await notificationRef.update({
        status: "cancelled",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Log admin action
      await db.collection("adminLogs").add({
        adminUid,
        action: "cancel_notification",
        details: {
          notificationId,
          title: notification.title,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ [CancelNotification] Cancelled: ${notificationId}`);

      res.status(200).json({
        success: true,
        data: {
          notificationId,
          status: "cancelled",
        },
      } as ApiResponse<{
        notificationId: string;
        status: string;
      }>);
    } catch (error) {
      console.error("❌ [CancelNotification] Error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
