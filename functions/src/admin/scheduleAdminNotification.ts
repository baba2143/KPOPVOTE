/**
 * Schedule Admin Notification API
 * Allows administrators to schedule push notifications for future delivery
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  ScheduleAdminNotificationRequest,
  AdminNotification,
} from "../types";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

const db = admin.firestore();

/**
 * Get target name for display
 */
async function getTargetName(
  targetType: "all" | "group" | "member",
  targetId?: string
): Promise<string | undefined> {
  if (targetType === "all") {
    return "全ユーザー";
  }

  if (targetType === "group" && targetId) {
    const groupDoc = await db.collection("groupMasters").doc(targetId).get();
    return groupDoc.data()?.name;
  }

  if (targetType === "member" && targetId) {
    const idolDoc = await db.collection("idolMasters").doc(targetId).get();
    return idolDoc.data()?.name;
  }

  return undefined;
}

export const scheduleAdminNotification = functions
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
      const {
        title,
        body,
        targetType,
        targetId,
        deepLinkUrl,
        scheduledAt,
      } = req.body as ScheduleAdminNotificationRequest;

      // Validate required fields
      if (!title || !body || !targetType || !scheduledAt) {
        res.status(400).json({
          success: false,
          error: "Missing required fields: title, body, targetType, scheduledAt",
        } as ApiResponse<null>);
        return;
      }

      // Validate title and body length
      if (title.length > 50) {
        res.status(400).json({
          success: false,
          error: "Title must be 50 characters or less",
        } as ApiResponse<null>);
        return;
      }

      if (body.length > 200) {
        res.status(400).json({
          success: false,
          error: "Body must be 200 characters or less",
        } as ApiResponse<null>);
        return;
      }

      // Validate targetType
      if (!["all", "group", "member"].includes(targetType)) {
        res.status(400).json({
          success: false,
          error: "targetType must be 'all', 'group', or 'member'",
        } as ApiResponse<null>);
        return;
      }

      // Validate targetId for group/member
      if ((targetType === "group" || targetType === "member") && !targetId) {
        res.status(400).json({
          success: false,
          error: "targetId is required for group or member targeting",
        } as ApiResponse<null>);
        return;
      }

      // Parse and validate scheduledAt
      const scheduledDate = new Date(scheduledAt);
      if (isNaN(scheduledDate.getTime())) {
        res.status(400).json({
          success: false,
          error: "Invalid scheduledAt format. Use ISO 8601 format.",
        } as ApiResponse<null>);
        return;
      }

      // Ensure scheduled time is in the future
      if (scheduledDate.getTime() <= Date.now()) {
        res.status(400).json({
          success: false,
          error: "scheduledAt must be in the future",
        } as ApiResponse<null>);
        return;
      }

      console.log(
        `📅 [AdminNotification] Scheduling: targetType=${targetType}, scheduledAt=${scheduledAt}`
      );

      // Get target name
      const targetName = await getTargetName(targetType, targetId);

      // Create notification document with pending status
      const notificationRef = db.collection("adminNotifications").doc();
      const now = admin.firestore.FieldValue.serverTimestamp();

      const notificationData: Omit<AdminNotification, "id" | "createdAt" | "updatedAt" | "scheduledAt"> & {
        id: string;
        createdAt: admin.firestore.FieldValue;
        updatedAt: admin.firestore.FieldValue;
        scheduledAt: admin.firestore.Timestamp;
      } = {
        id: notificationRef.id,
        title,
        body,
        targetType,
        targetId: targetId || undefined,
        targetName: targetName || undefined,
        deepLinkUrl: deepLinkUrl || undefined,
        status: "pending",
        scheduledAt: admin.firestore.Timestamp.fromDate(scheduledDate),
        createdBy: adminUid,
        createdAt: now,
        updatedAt: now,
      };

      await notificationRef.set(notificationData);

      // Log admin action
      await db.collection("adminLogs").add({
        adminUid,
        action: "schedule_notification",
        details: {
          notificationId: notificationRef.id,
          title,
          targetType,
          targetId,
          targetName,
          scheduledAt,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `✅ [AdminNotification] Scheduled: ${notificationRef.id} for ${scheduledAt}`
      );

      res.status(200).json({
        success: true,
        data: {
          notificationId: notificationRef.id,
          scheduledAt,
          targetType,
          targetName,
        },
      } as ApiResponse<{
        notificationId: string;
        scheduledAt: string;
        targetType: string;
        targetName?: string;
      }>);
    } catch (error) {
      console.error("❌ [AdminNotification] Schedule error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
