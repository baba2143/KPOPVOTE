/**
 * Delete User Account
 *
 * Deletes all user data from Firestore and Firebase Auth
 * App Store Guideline 5.1.1(v) compliance
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

/**
 * Helper function to delete documents in batches
 * Firestore batch operations are limited to 500 operations
 */
async function deleteDocumentsInBatches(
  db: admin.firestore.Firestore,
  query: admin.firestore.Query
): Promise<number> {
  let deletedCount = 0;
  const batchSize = 100;

  let snapshot = await query.limit(batchSize).get();

  while (!snapshot.empty) {
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      deletedCount++;
    });
    await batch.commit();

    if (snapshot.size < batchSize) {
      break;
    }
    snapshot = await query.limit(batchSize).get();
  }

  return deletedCount;
}

export const deleteAccount = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "DELETE, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "DELETE") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use DELETE.",
    } as ApiResponse<null>);
    return;
  }

  // Verify authentication
  await new Promise<void>((resolve, reject) => {
    verifyToken(
      req as AuthenticatedRequest,
      res,
      (error?: unknown) => (error ? reject(error) : resolve())
    );
  });

  const currentUser = (req as AuthenticatedRequest).user;
  if (!currentUser) {
    res.status(401).json({
      success: false,
      error: "Unauthorized",
    } as ApiResponse<null>);
    return;
  }

  const uid = currentUser.uid;
  const db = admin.firestore();

  console.log(`🗑️ [deleteAccount] Starting account deletion for UID: ${uid}`);

  try {
    // Track deletion progress
    const deletionLog: Record<string, number> = {};

    // 1. Delete user's bias subcollection
    const biasQuery = db.collection("users").doc(uid).collection("bias");
    deletionLog.bias = await deleteDocumentsInBatches(db, biasQuery);
    console.log(`  ✓ Deleted ${deletionLog.bias} bias documents`);

    // 2. Delete community posts created by user
    const postsQuery = db.collection("communityPosts").where("createdBy", "==", uid);
    deletionLog.communityPosts = await deleteDocumentsInBatches(db, postsQuery);
    console.log(`  ✓ Deleted ${deletionLog.communityPosts} community posts`);

    // 3. Delete comments created by user
    const commentsQuery = db.collection("comments").where("authorId", "==", uid);
    deletionLog.comments = await deleteDocumentsInBatches(db, commentsQuery);
    console.log(`  ✓ Deleted ${deletionLog.comments} comments`);

    // 4. Delete likes by user
    const likesQuery = db.collection("likes").where("userId", "==", uid);
    deletionLog.likes = await deleteDocumentsInBatches(db, likesQuery);
    console.log(`  ✓ Deleted ${deletionLog.likes} likes`);

    // 5. Delete messages sent by user
    const messagesSentQuery = db.collection("messages").where("senderId", "==", uid);
    deletionLog.messagesSent = await deleteDocumentsInBatches(db, messagesSentQuery);
    console.log(`  ✓ Deleted ${deletionLog.messagesSent} messages sent`);

    // 6. Delete messages received by user
    const messagesReceivedQuery = db.collection("messages").where("recipientId", "==", uid);
    deletionLog.messagesReceived = await deleteDocumentsInBatches(db, messagesReceivedQuery);
    console.log(`  ✓ Deleted ${deletionLog.messagesReceived} messages received`);

    // 7. Delete follow relationships (following)
    const followingQuery = db.collection("follows").where("followingUserId", "==", uid);
    deletionLog.following = await deleteDocumentsInBatches(db, followingQuery);
    console.log(`  ✓ Deleted ${deletionLog.following} following relationships`);

    // 8. Delete follow relationships (followers)
    const followersQuery = db.collection("follows").where("followerUserId", "==", uid);
    deletionLog.followers = await deleteDocumentsInBatches(db, followersQuery);
    console.log(`  ✓ Deleted ${deletionLog.followers} follower relationships`);

    // 9. Delete notifications for user
    const notificationsQuery = db.collection("notifications").where("userId", "==", uid);
    deletionLog.notifications = await deleteDocumentsInBatches(db, notificationsQuery);
    console.log(`  ✓ Deleted ${deletionLog.notifications} notifications`);

    // 10. Delete notifications sent by user
    const notificationsSentQuery = db.collection("notifications").where("fromUserId", "==", uid);
    deletionLog.notificationsSent = await deleteDocumentsInBatches(db, notificationsSentQuery);
    console.log(`  ✓ Deleted ${deletionLog.notificationsSent} notifications sent`);

    // 11. Delete FCM tokens
    const fcmTokensQuery = db.collection("fcmTokens").where("uid", "==", uid);
    deletionLog.fcmTokens = await deleteDocumentsInBatches(db, fcmTokensQuery);
    console.log(`  ✓ Deleted ${deletionLog.fcmTokens} FCM tokens`);

    // 12. Delete tasks created by user
    const tasksQuery = db.collection("tasks").where("authorId", "==", uid);
    deletionLog.tasks = await deleteDocumentsInBatches(db, tasksQuery);
    console.log(`  ✓ Deleted ${deletionLog.tasks} tasks`);

    // 13. Delete collections created by user
    const collectionsQuery = db.collection("collections").where("createdBy", "==", uid);
    deletionLog.collections = await deleteDocumentsInBatches(db, collectionsQuery);
    console.log(`  ✓ Deleted ${deletionLog.collections} collections`);

    // 14. Delete collection likes by user
    const collectionLikesQuery = db.collection("collectionLikes").where("userId", "==", uid);
    deletionLog.collectionLikes = await deleteDocumentsInBatches(db, collectionLikesQuery);
    console.log(`  ✓ Deleted ${deletionLog.collectionLikes} collection likes`);

    // 15. Delete point transactions
    const pointTransactionsQuery = db.collection("pointTransactions").where("userId", "==", uid);
    deletionLog.pointTransactions = await deleteDocumentsInBatches(db, pointTransactionsQuery);
    console.log(`  ✓ Deleted ${deletionLog.pointTransactions} point transactions`);

    // 16. Delete user's conversations
    const conversationsQuery = db.collection("conversations").where("participantIds", "array-contains", uid);
    deletionLog.conversations = await deleteDocumentsInBatches(db, conversationsQuery);
    console.log(`  ✓ Deleted ${deletionLog.conversations} conversations`);

    // 17. Delete community reports filed by user
    const reportsQuery = db.collection("communityReports").where("reporterId", "==", uid);
    deletionLog.reports = await deleteDocumentsInBatches(db, reportsQuery);
    console.log(`  ✓ Deleted ${deletionLog.reports} community reports`);

    // 18. Delete DM reports filed by user
    const dmReportsQuery = db.collection("dmReports").where("reporterId", "==", uid);
    deletionLog.dmReports = await deleteDocumentsInBatches(db, dmReportsQuery);
    console.log(`  ✓ Deleted ${deletionLog.dmReports} DM reports`);

    // 19. Delete user document from 'users' collection
    await db.collection("users").doc(uid).delete();
    deletionLog.userDocument = 1;
    console.log("  ✓ Deleted user document");

    // 20. Delete Firebase Authentication user
    await admin.auth().deleteUser(uid);
    console.log("  ✓ Deleted Firebase Auth user");

    console.log(`✅ [deleteAccount] Account deletion completed for UID: ${uid}`);
    console.log("   Deletion summary:", JSON.stringify(deletionLog));

    res.status(200).json({
      success: true,
      data: {
        message: "Account deleted successfully",
        deletedItems: deletionLog,
      },
    } as ApiResponse<{ message: string; deletedItems: Record<string, number> }>);
  } catch (error: unknown) {
    console.error(`❌ [deleteAccount] Error deleting account for ${uid}:`, error);

    if (error instanceof Error) {
      if (error.message.includes("not found") || error.message.includes("NOT_FOUND")) {
        res.status(404).json({
          success: false,
          error: "User not found",
        } as ApiResponse<null>);
        return;
      }
    }

    res.status(500).json({
      success: false,
      error: "Failed to delete account. Please try again.",
    } as ApiResponse<null>);
  }
});
