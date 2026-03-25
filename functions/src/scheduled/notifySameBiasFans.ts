/**
 * Scheduled Function: Notify Same Bias Fans
 * Runs daily at 20:00 JST (11:00 UTC) to notify users when
 * new fans with the same bias have joined.
 *
 * Conditions:
 * - 3+ new users added the same bias in the past 24 hours
 * - Notify up to top 3 biases with the most new users
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendPushNotification } from "../utils/fcmHelper";
import { shouldSendNotificationCached } from "../utils/notificationHelper";
import { SCHEDULED_CONFIG } from "../utils/functionConfig";

const db = admin.firestore();

// Minimum new users to trigger notification
const MIN_NEW_USERS_THRESHOLD = 3;
// Maximum number of notifications per user
const MAX_NOTIFICATIONS_PER_USER = 3;

interface BiasNewUsersInfo {
  biasDocId: string; // "group_xxx" or "member_xxx"
  biasId: string;
  biasType: "group" | "member";
  biasName: string;
  groupId?: string;
  groupName?: string;
  newUserCount: number;
  newUserIds: string[];
}

/**
 * Get all bias doc IDs that have new users in the past 24 hours
 */
async function getBiasesWithNewUsers(
  yesterday: admin.firestore.Timestamp
): Promise<Map<string, BiasNewUsersInfo>> {
  const biasMap = new Map<string, BiasNewUsersInfo>();

  // Get all biasUserHistory parent documents
  const biasHistoryRef = db.collection("biasUserHistory");
  const biasDocsSnapshot = await biasHistoryRef.listDocuments();

  for (const biasDocRef of biasDocsSnapshot) {
    const biasDocId = biasDocRef.id;

    // Query users added in the past 24 hours
    const newUsersSnapshot = await biasDocRef
      .collection("users")
      .where("addedAt", ">", yesterday)
      .get();

    if (newUsersSnapshot.size >= MIN_NEW_USERS_THRESHOLD) {
      // Get bias info from first user document
      const firstUserData = newUsersSnapshot.docs[0].data();

      biasMap.set(biasDocId, {
        biasDocId,
        biasId: firstUserData.biasId,
        biasType: firstUserData.biasType,
        biasName: firstUserData.biasName,
        groupId: firstUserData.groupId || undefined,
        groupName: firstUserData.groupName || undefined,
        newUserCount: newUsersSnapshot.size,
        newUserIds: newUsersSnapshot.docs.map((doc) => doc.id),
      });

      console.log(
        `📊 [SameBiasFans] ${biasDocId}: ${newUsersSnapshot.size} new users`
      );
    }
  }

  return biasMap;
}

/**
 * Get existing users for a bias (added before yesterday)
 */
async function getExistingUsers(
  biasDocId: string,
  yesterday: admin.firestore.Timestamp,
  newUserIds: string[]
): Promise<string[]> {
  const existingUsersSnapshot = await db
    .collection("biasUserHistory")
    .doc(biasDocId)
    .collection("users")
    .where("addedAt", "<=", yesterday)
    .get();

  // Filter out new users (just in case)
  const newUserSet = new Set(newUserIds);
  return existingUsersSnapshot.docs
    .map((doc) => doc.id)
    .filter((userId) => !newUserSet.has(userId));
}

/**
 * Get user's biases and find which ones have new fans
 */
async function getUserBiasesWithNewFans(
  userId: string,
  biasMap: Map<string, BiasNewUsersInfo>,
  yesterday: admin.firestore.Timestamp
): Promise<BiasNewUsersInfo[]> {
  // Get user's current biases from biasUserHistory
  const userBiases: BiasNewUsersInfo[] = [];

  for (const [biasDocId, biasInfo] of biasMap) {
    // Check if this user is an existing user for this bias (not a new user)
    const userDocRef = db
      .collection("biasUserHistory")
      .doc(biasDocId)
      .collection("users")
      .doc(userId);

    const userDoc = await userDocRef.get();
    if (!userDoc.exists) continue;

    const userData = userDoc.data();
    if (!userData) continue;

    // Check if user was added before yesterday (existing user)
    const addedAt = userData.addedAt?.toMillis() || 0;
    if (addedAt > yesterday.toMillis()) {
      // This user is a new user for this bias, skip
      continue;
    }

    userBiases.push(biasInfo);
  }

  // Sort by new user count (descending) and take top 3
  return userBiases
    .sort((a, b) => b.newUserCount - a.newUserCount)
    .slice(0, MAX_NOTIFICATIONS_PER_USER);
}

/**
 * Send notification to a user about new fans
 */
async function sendSameBiasFanNotification(
  userId: string,
  biasInfo: BiasNewUsersInfo
): Promise<boolean> {
  // Check notification settings
  const shouldNotify = await shouldSendNotificationCached(userId, "sameBiasFans");
  if (!shouldNotify) {
    return false;
  }

  const title = "仲間が増えました！🎉";
  const body = `あなたと同じ「${biasInfo.biasName}」を応援するユーザーが${biasInfo.newUserCount}人増えました`;

  // Create notification document
  const notificationRef = db.collection("notifications").doc();
  await notificationRef.set({
    id: notificationRef.id,
    userId,
    type: "sameBiasFans",
    title,
    body,
    isRead: false,
    relatedBiasId: biasInfo.biasId,
    relatedBiasType: biasInfo.biasType,
    relatedBiasName: biasInfo.biasName,
    newUserCount: biasInfo.newUserCount,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Send push notification
  await sendPushNotification({
    userId,
    type: "system", // Use "system" type for FCM compatibility
    title,
    body,
    data: {
      notificationId: notificationRef.id,
    },
  });

  return true;
}

/**
 * Main scheduled function
 */
export const notifySameBiasFans = functions
  .runWith(SCHEDULED_CONFIG)
  .pubsub.schedule("0 11 * * *") // 20:00 JST = 11:00 UTC
  .timeZone("Asia/Tokyo")
  .onRun(async () => {
    const startTime = Date.now();
    const now = admin.firestore.Timestamp.now();
    const yesterday = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - 24 * 60 * 60 * 1000
    );

    console.log(
      `🎉 [SameBiasFans] Starting notification check at ${now.toDate().toISOString()}`
    );

    try {
      // Step 1: Get all biases with 3+ new users
      const biasMap = await getBiasesWithNewUsers(yesterday);

      if (biasMap.size === 0) {
        console.log("ℹ️ [SameBiasFans] No biases with enough new users");
        return null;
      }

      console.log(
        `📊 [SameBiasFans] Found ${biasMap.size} biases with ${MIN_NEW_USERS_THRESHOLD}+ new users`
      );

      // Step 2: For each bias, get existing users and send notifications
      let totalNotificationsSent = 0;
      const processedUsers = new Set<string>();

      for (const [biasDocId, biasInfo] of biasMap) {
        // Get existing users for this bias
        const existingUsers = await getExistingUsers(
          biasDocId,
          yesterday,
          biasInfo.newUserIds
        );

        console.log(
          `📤 [SameBiasFans] Processing ${biasInfo.biasName}: ${existingUsers.length} existing users`
        );

        // Send notifications to each existing user (if not already processed)
        for (const userId of existingUsers) {
          // Track processed users to avoid duplicate work
          if (processedUsers.has(userId)) continue;
          processedUsers.add(userId);

          // Get this user's top biases with new fans
          const userBiases = await getUserBiasesWithNewFans(
            userId,
            biasMap,
            yesterday
          );

          // Send notifications for each bias (up to MAX_NOTIFICATIONS_PER_USER)
          for (const userBiasInfo of userBiases) {
            const sent = await sendSameBiasFanNotification(userId, userBiasInfo);
            if (sent) {
              totalNotificationsSent++;
            }
          }
        }
      }

      const duration = Date.now() - startTime;
      console.log(
        `✅ [SameBiasFans] Completed: ${totalNotificationsSent} notifications sent in ${duration}ms`
      );

      functions.logger.info("[PERF] notifySameBiasFans completed", {
        duration: `${duration}ms`,
        biasCount: biasMap.size,
        notificationsSent: totalNotificationsSent,
        usersProcessed: processedUsers.size,
      });

      return null;
    } catch (error) {
      console.error("❌ [SameBiasFans] Error:", error);
      throw error;
    }
  });
