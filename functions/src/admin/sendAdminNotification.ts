/**
 * Send Admin Notification API
 * Allows administrators to send push notifications to users
 * Supports targeting: all users, by group bias, or by member bias
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  SendAdminNotificationRequest,
  AdminNotification,
} from "../types";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";
import { sendPushNotification } from "../utils/fcmHelper";
import { shouldSendNotificationCached } from "../utils/notificationHelper";

const db = admin.firestore();

/**
 * Get target users based on target type
 */
async function getTargetUserIds(
  targetType: "all" | "group" | "member",
  targetId?: string
): Promise<string[]> {
  const userIds: string[] = [];

  if (targetType === "all") {
    // Get all users
    const usersSnapshot = await db.collection("users").get();
    usersSnapshot.forEach((doc) => {
      userIds.push(doc.id);
    });
  } else if (targetType === "group" && targetId) {
    // Get users who have this group as bias
    const usersSnapshot = await db.collection("users").get();
    usersSnapshot.forEach((doc) => {
      const data = doc.data();
      const myBias = data.myBias || [];
      const hasGroupBias = myBias.some(
        (bias: { artistId: string }) => bias.artistId === targetId
      );
      if (hasGroupBias) {
        userIds.push(doc.id);
      }
    });
  } else if (targetType === "member" && targetId) {
    // Get users who have this member as bias
    const usersSnapshot = await db.collection("users").get();
    usersSnapshot.forEach((doc) => {
      const data = doc.data();
      const myBias = data.myBias || [];
      const hasMemberBias = myBias.some((bias: { memberIds: string[] }) =>
        bias.memberIds?.includes(targetId)
      );
      if (hasMemberBias) {
        userIds.push(doc.id);
      }
    });
  }

  return userIds;
}

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

/**
 * Send push notifications to target users
 */
async function sendNotificationsToUsers(
  userIds: string[],
  title: string,
  body: string,
  notificationId: string,
  deepLinkUrl?: string
): Promise<{ sentCount: number; failedCount: number }> {
  let sentCount = 0;
  let failedCount = 0;

  // Process in batches of 100
  const batchSize = 100;
  for (let i = 0; i < userIds.length; i += batchSize) {
    const batch = userIds.slice(i, i + batchSize);

    const promises = batch.map(async (userId) => {
      try {
        // Check if user has announcements enabled
        const shouldSend = await shouldSendNotificationCached(
          userId,
          "announcements"
        );
        if (!shouldSend) {
          console.log(
            `⏭️ [AdminNotification] Skipping user ${userId} (announcements disabled)`
          );
          return false;
        }

        // Send push notification
        const result = await sendPushNotification({
          userId,
          type: "system",
          title,
          body,
          data: {
            notificationId,
            ...(deepLinkUrl && { deepLinkUrl }),
          },
        });

        return result.success;
      } catch (error) {
        console.error(
          `❌ [AdminNotification] Failed to send to user ${userId}:`,
          error
        );
        return false;
      }
    });

    const results = await Promise.all(promises);
    results.forEach((success) => {
      if (success) {
        sentCount++;
      } else {
        failedCount++;
      }
    });
  }

  return { sentCount, failedCount };
}

export const sendAdminNotification = functions
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
      } = req.body as SendAdminNotificationRequest;

      // Validate required fields
      if (!title || !body || !targetType) {
        res.status(400).json({
          success: false,
          error: "Missing required fields: title, body, targetType",
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

      console.log(
        `📤 [AdminNotification] Starting send: targetType=${targetType}, targetId=${targetId}`
      );

      // Get target name
      const targetName = await getTargetName(targetType, targetId);

      // Create notification document
      const notificationRef = db.collection("adminNotifications").doc();
      const now = admin.firestore.FieldValue.serverTimestamp();

      const notificationData: Omit<AdminNotification, "id" | "createdAt" | "updatedAt"> & {
        id: string;
        createdAt: admin.firestore.FieldValue;
        updatedAt: admin.firestore.FieldValue;
      } = {
        id: notificationRef.id,
        title,
        body,
        targetType,
        targetId: targetId || undefined,
        targetName: targetName || undefined,
        deepLinkUrl: deepLinkUrl || undefined,
        status: "pending",
        createdBy: adminUid,
        createdAt: now,
        updatedAt: now,
      };

      await notificationRef.set(notificationData);

      // Get target users
      const userIds = await getTargetUserIds(targetType, targetId);
      console.log(`👥 [AdminNotification] Target users: ${userIds.length}`);

      if (userIds.length === 0) {
        await notificationRef.update({
          status: "sent",
          sentAt: now,
          sentCount: 0,
          failedCount: 0,
          updatedAt: now,
        });

        res.status(200).json({
          success: true,
          data: {
            notificationId: notificationRef.id,
            targetCount: 0,
            sentCount: 0,
            failedCount: 0,
          },
        } as ApiResponse<{
          notificationId: string;
          targetCount: number;
          sentCount: number;
          failedCount: number;
        }>);
        return;
      }

      // Send notifications
      const { sentCount, failedCount } = await sendNotificationsToUsers(
        userIds,
        title,
        body,
        notificationRef.id,
        deepLinkUrl
      );

      // Update notification status
      await notificationRef.update({
        status: failedCount > 0 && sentCount === 0 ? "failed" : "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        sentCount,
        failedCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Log admin action
      await db.collection("adminLogs").add({
        adminUid,
        action: "send_notification",
        details: {
          notificationId: notificationRef.id,
          title,
          targetType,
          targetId,
          targetName,
          targetCount: userIds.length,
          sentCount,
          failedCount,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `✅ [AdminNotification] Completed: sent=${sentCount}, failed=${failedCount}`
      );

      res.status(200).json({
        success: true,
        data: {
          notificationId: notificationRef.id,
          targetCount: userIds.length,
          sentCount,
          failedCount,
        },
      } as ApiResponse<{
        notificationId: string;
        targetCount: number;
        sentCount: number;
        failedCount: number;
      }>);
    } catch (error) {
      console.error("❌ [AdminNotification] Error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
