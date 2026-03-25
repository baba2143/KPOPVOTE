/**
 * Scheduled Function: Update Vote Statuses
 * Runs every minute to automatically update vote statuses:
 * - upcoming → active (when startDate is reached)
 * - active → ended (when endDate is reached)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendPushNotification } from "../utils/fcmHelper";
import { SCHEDULED_CONFIG } from "../utils/functionConfig";

const db = admin.firestore();

interface VoteStatusChange {
  voteId: string;
  title: string;
  oldStatus: string;
  newStatus: string;
}

/**
 * Update vote statuses based on current time
 * Scheduled to run every minute
 */
export const updateVoteStatuses = functions
  .runWith(SCHEDULED_CONFIG)
  .pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const changes: VoteStatusChange[] = [];

    console.log(`🗳️ [Vote Status] Checking vote statuses at ${now.toDate().toISOString()}`);

    try {
      // 1. Find votes that should become active (upcoming → active)
      const upcomingVotesSnapshot = await db
        .collection("inAppVotes")
        .where("status", "==", "upcoming")
        .where("startDate", "<=", now)
        .get();

      // 2. Find votes that should end (active → ended)
      const activeVotesSnapshot = await db
        .collection("inAppVotes")
        .where("status", "==", "active")
        .where("endDate", "<=", now)
        .get();

      // Process upcoming → active
      for (const doc of upcomingVotesSnapshot.docs) {
        const voteData = doc.data();
        await doc.ref.update({
          status: "active",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        changes.push({
          voteId: doc.id,
          title: voteData.title,
          oldStatus: "upcoming",
          newStatus: "active",
        });

        console.log(`✅ [Vote Status] Vote ${doc.id} (${voteData.title}): upcoming → active`);

        // Send notification to interested users (those with matching bias)
        await notifyVoteStarted(doc.id, voteData.title, voteData.choices);
      }

      // Process active → ended
      for (const doc of activeVotesSnapshot.docs) {
        const voteData = doc.data();
        await doc.ref.update({
          status: "ended",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        changes.push({
          voteId: doc.id,
          title: voteData.title,
          oldStatus: "active",
          newStatus: "ended",
        });

        console.log(`✅ [Vote Status] Vote ${doc.id} (${voteData.title}): active → ended`);
      }

      if (changes.length > 0) {
        console.log(`🗳️ [Vote Status] Updated ${changes.length} vote(s)`);
      }

      return null;
    } catch (error) {
      console.error("❌ [Vote Status] Error updating vote statuses:", error);
      return null;
    }
  });

/**
 * Notify users when a vote starts
 * Targets users who have participated in similar votes or have matching bias
 */
async function notifyVoteStarted(
  voteId: string,
  voteTitle: string,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  _choices: any[]
): Promise<void> {
  try {
    // Find users who might be interested (have biasIds - active voters)
    // Future enhancement: match choice labels with user biasIds for more targeted notifications
    const usersSnapshot = await db
      .collection("users")
      .where("biasIds", "!=", null)
      .limit(100) // Limit to prevent excessive notifications
      .get();

    let notifiedCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const userBiasIds: string[] = userData.biasIds || [];

      // Check if user has any bias that might match the vote choices
      // For now, notify all users with bias settings (they're active voters)
      if (userBiasIds.length > 0) {
        // Check if we already sent this notification (prevent duplicates)
        const sentKey = `${userDoc.id}_voteStarted_${voteId}`;
        const alreadySent = await checkNotificationSent(sentKey);

        if (!alreadySent) {
          // Create notification in Firestore
          const notificationRef = db.collection("notifications").doc();
          await notificationRef.set({
            id: notificationRef.id,
            userId: userDoc.id,
            type: "vote",
            title: "新しい投票が開始されました！",
            body: `「${voteTitle}」への投票が始まりました。今すぐ参加しましょう！`,
            isRead: false,
            relatedVoteId: voteId,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Send push notification
          await sendPushNotification({
            userId: userDoc.id,
            type: "vote",
            title: "新しい投票が開始されました！",
            body: `「${voteTitle}」への投票が始まりました。`,
            data: {
              voteId,
              notificationId: notificationRef.id,
            },
          });

          // Mark as sent
          await markNotificationSent(sentKey);
          notifiedCount++;
        }
      }
    }

    console.log(`📱 [Vote Status] Notified ${notifiedCount} users about vote start: ${voteTitle}`);
  } catch (error) {
    console.error("❌ [Vote Status] Error notifying vote start:", error);
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
