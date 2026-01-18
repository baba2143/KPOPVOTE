/**
 * Scheduled Function: Check Task Deadlines
 * Runs every hour to send reminder notifications for personal tasks ending soon:
 * - 24 hours before deadline
 * - 6 hours before deadline
 * - 1 hour before deadline
 * - 30 minutes before deadline
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendPushNotification } from "../utils/fcmHelper";
import { shouldSendNotificationCached } from "../utils/notificationHelper";

const db = admin.firestore();

// Reminder timing configuration (in hours)
const REMINDER_HOURS = [24, 6, 1, 0.5];

// Notification window in hours (±30 minutes)
const NOTIFICATION_WINDOW_HOURS = 0.5;

/**
 * Check task deadlines and send reminder notifications
 * Uses Collection Group Query to scan all user tasks
 */
export const checkTaskDeadlines = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (_context) => {
    const now = admin.firestore.Timestamp.now();
    const nowMs = now.toMillis();

    // Check tasks with deadlines in the next 25 hours
    const maxFutureMs = nowMs + 25 * 60 * 60 * 1000;
    const maxFutureTimestamp = admin.firestore.Timestamp.fromMillis(maxFutureMs);

    console.log(`✅ [Task Deadline] Checking deadlines at ${now.toDate().toISOString()}`);

    try {
      // Collection Group Query で全ユーザーのタスクを取得
      const tasksSnapshot = await db
        .collectionGroup("tasks")
        .where("isCompleted", "==", false)
        .where("deadline", ">", now)
        .where("deadline", "<=", maxFutureTimestamp)
        .get();

      if (tasksSnapshot.empty) {
        console.log("✅ [Task Deadline] No upcoming task deadlines in the next 25 hours");
        return;
      }

      console.log(`✅ [Task Deadline] Found ${tasksSnapshot.size} upcoming task(s)`);

      let totalNotificationsSent = 0;

      // Process each task
      for (const taskDoc of tasksSnapshot.docs) {
        const task = taskDoc.data();
        const taskId = taskDoc.id;
        const taskRef = taskDoc.ref;

        // Extract userId from path: users/{userId}/tasks/{taskId}
        const userId = taskRef.parent.parent?.id;
        if (!userId) {
          console.warn(`⚠️ [Task Deadline] Could not extract userId from task path: ${taskRef.path}`);
          continue;
        }

        const deadline = task.deadline;
        if (!deadline) {
          console.warn(`⚠️ [Task Deadline] Task ${taskId} has no deadline field`);
          continue;
        }

        const deadlineMs = deadline.toMillis();
        const timeUntilDeadlineMs = deadlineMs - nowMs;
        const hoursUntilDeadline = timeUntilDeadlineMs / (1000 * 60 * 60);

        // Check if task is within any reminder window
        for (const reminderHours of REMINDER_HOURS) {
          const isInWindow =
            hoursUntilDeadline >= reminderHours - NOTIFICATION_WINDOW_HOURS &&
            hoursUntilDeadline <= reminderHours + NOTIFICATION_WINDOW_HOURS;

          if (isInWindow) {
            console.log(
              `⏰ [Task Deadline] Task "${task.title}" (${taskId}) deadline in ~${reminderHours} hours`
            );

            // Check if already notified
            const sentKey = `${userId}_taskDeadline_${taskId}_${reminderHours}h`;
            const alreadySent = await checkNotificationSent(sentKey);

            if (!alreadySent) {
              // Check notification settings (reuse voteReminders setting)
              const shouldNotify = await shouldSendNotificationCached(userId, "voteReminders");

              if (shouldNotify) {
                // Create notification in Firestore
                const notificationRef = db.collection("notifications").doc();
                const title = "タスク期限のお知らせ";
                // 1時間未満の場合は「XX分」、それ以外は「XX時間」と表示
                const timeText = reminderHours < 1 ?
                  `${reminderHours * 60}分` :
                  `${reminderHours}時間`;
                const body = `「${task.title}」の期限まで残り${timeText}です`;

                await notificationRef.set({
                  id: notificationRef.id,
                  userId,
                  type: "vote", // Use "vote" type for task deadline reminders
                  title,
                  body,
                  isRead: false,
                  relatedVoteId: taskId, // Store taskId in relatedVoteId field
                  createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                // Send push notification
                await sendPushNotification({
                  userId,
                  type: "vote",
                  title,
                  body,
                  data: {
                    voteId: taskId, // Store taskId as voteId for consistency
                    notificationId: notificationRef.id,
                  },
                });

                // Mark as sent
                await markNotificationSent(sentKey);
                totalNotificationsSent++;

                console.log(`📱 [Task Deadline] Notified user ${userId} about task "${task.title}" (${reminderHours}h)`);
              } else {
                console.log(
                  `⚠️ [Task Deadline] User ${userId} has task reminder notifications disabled`
                );
              }
            } else {
              console.log(`⚠️ [Task Deadline] Already notified for task ${taskId} at ${reminderHours}h`);
            }
          }
        }
      }

      console.log(`✅ [Task Deadline] Sent ${totalNotificationsSent} reminder notifications`);
    } catch (error) {
      console.error("❌ [Task Deadline] Error checking task deadlines:", error);
      throw error;
    }
  });

/**
 * Check if a notification has already been sent
 */
async function checkNotificationSent(sentKey: string): Promise<boolean> {
  const doc = await db.collection("notificationsSent").doc(sentKey).get();
  return doc.exists;
}

/**
 * Mark a notification as sent
 */
async function markNotificationSent(sentKey: string): Promise<void> {
  await db.collection("notificationsSent").doc(sentKey).set({
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
