/**
 * Scheduled Function: Check Vote Deadlines
 * Runs every hour to send reminder notifications for votes ending soon:
 * - 24 hours before end
 * - 6 hours before end
 * - 1 hour before end
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendPushNotification } from "../utils/fcmHelper";
import { shouldSendNotificationCached } from "../utils/notificationHelper";

const db = admin.firestore();

// Reminder timing configuration (in hours)
const REMINDER_HOURS = [24, 6, 1];

/**
 * Check vote deadlines and send reminder notifications
 * Scheduled to run every hour
 */
export const checkVoteDeadlines = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const nowMs = now.toMillis();

    console.log(`🗳️ [Vote Deadline] Checking deadlines at ${now.toDate().toISOString()}`);

    try {
      // Get all active votes
      const activeVotesSnapshot = await db
        .collection("inAppVotes")
        .where("status", "==", "active")
        .get();

      if (activeVotesSnapshot.empty) {
        console.log("ℹ️ [Vote Deadline] No active votes found");
        return null;
      }

      let totalNotifications = 0;

      for (const voteDoc of activeVotesSnapshot.docs) {
        const voteData = voteDoc.data();
        const endDate = voteData.endDate?.toDate();

        if (!endDate) continue;

        const endMs = endDate.getTime();
        const hoursRemaining = (endMs - nowMs) / (1000 * 60 * 60);

        // Check each reminder threshold
        for (const reminderHours of REMINDER_HOURS) {
          // Check if we're within the reminder window (±30 minutes)
          const isInWindow =
            hoursRemaining > reminderHours - 0.5 &&
            hoursRemaining <= reminderHours + 0.5;

          if (isInWindow) {
            console.log(
              `⏰ [Vote Deadline] Vote ${voteDoc.id} ends in ~${Math.round(hoursRemaining)} hours`
            );

            // Send notifications to users who have voted or are interested
            const notified = await notifyVoteEnding(
              voteDoc.id,
              voteData.title,
              reminderHours
            );
            totalNotifications += notified;
          }
        }
      }

      console.log(`🗳️ [Vote Deadline] Sent ${totalNotifications} reminder notifications`);
      return null;
    } catch (error) {
      console.error("❌ [Vote Deadline] Error checking deadlines:", error);
      return null;
    }
  });

/**
 * Notify users about a vote ending soon
 */
async function notifyVoteEnding(
  voteId: string,
  voteTitle: string,
  hoursRemaining: number
): Promise<number> {
  let notifiedCount = 0;

  try {
    // 1. Get users who have voted on this vote
    const voteHistorySnapshot = await db
      .collection("voteHistory")
      .where("voteId", "==", voteId)
      .get();

    const votedUserIds = new Set<string>();
    voteHistorySnapshot.forEach((doc) => {
      votedUserIds.add(doc.data().userId);
    });

    // 2. Get users with biasIds (active voters who might be interested)
    const interestedUsersSnapshot = await db
      .collection("users")
      .where("biasIds", "!=", null)
      .limit(200)
      .get();

    // Combine user sets
    const userIdsToNotify = new Set<string>();

    // Add voted users
    votedUserIds.forEach((uid) => userIdsToNotify.add(uid));

    // Add interested users (limited)
    interestedUsersSnapshot.docs.slice(0, 100).forEach((doc) => {
      if (doc.data().biasIds?.length > 0) {
        userIdsToNotify.add(doc.id);
      }
    });

    // Create reminder message based on time remaining
    const timeText = getTimeRemainingText(hoursRemaining);
    const title = `投票終了まで${timeText}`;
    const body = `「${voteTitle}」の投票が${timeText}で終了します。まだの方はお急ぎください！`;

    // Send notifications
    for (const userId of userIdsToNotify) {
      // Check if already sent this reminder
      const sentKey = `${userId}_voteEnding_${voteId}_${hoursRemaining}h`;
      const alreadySent = await checkNotificationSent(sentKey);

      if (!alreadySent) {
        // Check notification settings
        const shouldNotify = await shouldSendNotificationCached(userId, "voteReminders");

        if (shouldNotify) {
          // Create notification in Firestore
          const notificationRef = db.collection("notifications").doc();
          await notificationRef.set({
            id: notificationRef.id,
            userId,
            type: "vote",
            title,
            body,
            isRead: false,
            relatedVoteId: voteId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Send push notification
          await sendPushNotification({
            userId,
            type: "vote",
            title,
            body,
            data: {
              voteId,
              notificationId: notificationRef.id,
            },
          });

          // Mark as sent
          await markNotificationSent(sentKey);
          notifiedCount++;
        } else {
          console.log(
            "[checkVoteDeadlines] Notification skipped: " +
            `user ${userId} has vote reminder notifications disabled`
          );
        }
      }
    }

    console.log(
      `📱 [Vote Deadline] Notified ${notifiedCount} users about "${voteTitle}" ending in ${hoursRemaining}h`
    );

    return notifiedCount;
  } catch (error) {
    console.error("❌ [Vote Deadline] Error notifying vote ending:", error);
    return 0;
  }
}

/**
 * Get human-readable time remaining text
 */
function getTimeRemainingText(hours: number): string {
  if (hours === 1) {
    return "あと1時間";
  } else if (hours === 6) {
    return "あと6時間";
  } else if (hours === 24) {
    return "あと24時間";
  } else {
    return `あと${hours}時間`;
  }
}

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
