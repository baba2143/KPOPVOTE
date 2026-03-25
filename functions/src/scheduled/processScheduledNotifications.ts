/**
 * Process Scheduled Admin Notifications
 * Runs every minute to check for pending notifications that need to be sent
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { AdminNotification } from "../types";
import { SCHEDULED_CONFIG } from "../utils/functionConfig";
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
    const usersSnapshot = await db.collection("users").get();
    usersSnapshot.forEach((doc) => {
      userIds.push(doc.id);
    });
  } else if (targetType === "group" && targetId) {
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

  const batchSize = 100;
  for (let i = 0; i < userIds.length; i += batchSize) {
    const batch = userIds.slice(i, i + batchSize);

    const promises = batch.map(async (userId) => {
      try {
        const shouldSend = await shouldSendNotificationCached(
          userId,
          "announcements"
        );
        if (!shouldSend) {
          return false;
        }

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
          `❌ [ScheduledNotification] Failed to send to user ${userId}:`,
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

/**
 * Process a single scheduled notification
 */
async function processNotification(
  notificationDoc: admin.firestore.QueryDocumentSnapshot
): Promise<void> {
  const notification = notificationDoc.data() as AdminNotification;
  const notificationRef = notificationDoc.ref;

  console.log(
    `📤 [ScheduledNotification] Processing: ${notification.id} (${notification.title})`
  );

  try {
    // Get target users
    const userIds = await getTargetUserIds(
      notification.targetType,
      notification.targetId
    );

    console.log(`👥 [ScheduledNotification] Target users: ${userIds.length}`);

    if (userIds.length === 0) {
      await notificationRef.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        sentCount: 0,
        failedCount: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    // Send notifications
    const { sentCount, failedCount } = await sendNotificationsToUsers(
      userIds,
      notification.title,
      notification.body,
      notification.id,
      notification.deepLinkUrl
    );

    // Update notification status
    await notificationRef.update({
      status: failedCount > 0 && sentCount === 0 ? "failed" : "sent",
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      sentCount,
      failedCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(
      `✅ [ScheduledNotification] Completed: ${notification.id} - sent=${sentCount}, failed=${failedCount}`
    );
  } catch (error) {
    console.error(
      `❌ [ScheduledNotification] Error processing ${notification.id}:`,
      error
    );

    // Mark as failed
    await notificationRef.update({
      status: "failed",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

/**
 * Scheduled function that runs every minute
 */
export const processScheduledNotifications = functions
  .runWith(SCHEDULED_CONFIG)
  .pubsub.schedule("* * * * *") // Every minute
  .timeZone("Asia/Tokyo")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    console.log(
      `🕐 [ScheduledNotification] Checking for pending notifications at ${now.toDate().toISOString()}`
    );

    try {
      // Find pending notifications that are due
      const pendingSnapshot = await db
        .collection("adminNotifications")
        .where("status", "==", "pending")
        .where("scheduledAt", "<=", now)
        .get();

      if (pendingSnapshot.empty) {
        console.log("ℹ️ [ScheduledNotification] No pending notifications to process");
        return null;
      }

      console.log(
        `📋 [ScheduledNotification] Found ${pendingSnapshot.size} notification(s) to process`
      );

      // Process each notification
      for (const doc of pendingSnapshot.docs) {
        await processNotification(doc);
      }

      console.log("✅ [ScheduledNotification] All pending notifications processed");
      return null;
    } catch (error) {
      console.error("❌ [ScheduledNotification] Error:", error);
      throw error;
    }
  });
