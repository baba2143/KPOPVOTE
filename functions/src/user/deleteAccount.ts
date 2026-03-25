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
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

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

export const deleteAccount = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

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

      // Build all queries (independent of each other)
      const biasQuery = db.collection("users").doc(uid).collection("bias");
      const postsQuery = db.collection("communityPosts").where("createdBy", "==", uid);
      const commentsQuery = db.collection("comments").where("authorId", "==", uid);
      const likesQuery = db.collection("likes").where("userId", "==", uid);
      const messagesSentQuery = db.collection("messages").where("senderId", "==", uid);
      const messagesReceivedQuery = db.collection("messages").where("recipientId", "==", uid);
      const followingQuery = db.collection("follows").where("followingUserId", "==", uid);
      const followersQuery = db.collection("follows").where("followerUserId", "==", uid);
      const notificationsQuery = db.collection("notifications").where("userId", "==", uid);
      const notificationsSentQuery = db.collection("notifications").where("fromUserId", "==", uid);
      const fcmTokensQuery = db.collection("fcmTokens").where("uid", "==", uid);
      const tasksQuery = db.collection("tasks").where("authorId", "==", uid);
      const collectionsQuery = db.collection("collections").where("createdBy", "==", uid);
      const collectionLikesQuery = db.collection("collectionLikes").where("userId", "==", uid);
      const pointTransactionsQuery = db.collection("pointTransactions").where("userId", "==", uid);
      const conversationsQuery = db.collection("conversations").where("participantIds", "array-contains", uid);
      const reportsQuery = db.collection("communityReports").where("reporterId", "==", uid);
      const dmReportsQuery = db.collection("dmReports").where("reporterId", "==", uid);

      // Chunk 1: Delete 5 collections in parallel
      const [bias, communityPosts, comments, likes, messagesSent] = await Promise.all([
        deleteDocumentsInBatches(db, biasQuery),
        deleteDocumentsInBatches(db, postsQuery),
        deleteDocumentsInBatches(db, commentsQuery),
        deleteDocumentsInBatches(db, likesQuery),
        deleteDocumentsInBatches(db, messagesSentQuery),
      ]);
      deletionLog.bias = bias;
      deletionLog.communityPosts = communityPosts;
      deletionLog.comments = comments;
      deletionLog.likes = likes;
      deletionLog.messagesSent = messagesSent;
      console.log(`  ✓ Chunk 1: bias(${bias}), posts(${communityPosts}), ` +
        `comments(${comments}), likes(${likes}), messagesSent(${messagesSent})`);

      // Chunk 2: Delete 5 more collections in parallel
      const [messagesReceived, following, followers, notifications, notificationsSent] = await Promise.all([
        deleteDocumentsInBatches(db, messagesReceivedQuery),
        deleteDocumentsInBatches(db, followingQuery),
        deleteDocumentsInBatches(db, followersQuery),
        deleteDocumentsInBatches(db, notificationsQuery),
        deleteDocumentsInBatches(db, notificationsSentQuery),
      ]);
      deletionLog.messagesReceived = messagesReceived;
      deletionLog.following = following;
      deletionLog.followers = followers;
      deletionLog.notifications = notifications;
      deletionLog.notificationsSent = notificationsSent;
      console.log(`  ✓ Chunk 2: messagesReceived(${messagesReceived}), ` +
        `following(${following}), followers(${followers}), ` +
        `notifications(${notifications}), notificationsSent(${notificationsSent})`);

      // Chunk 3: Delete 5 more collections in parallel
      const [fcmTokens, tasks, collections, collectionLikes, pointTransactions] = await Promise.all([
        deleteDocumentsInBatches(db, fcmTokensQuery),
        deleteDocumentsInBatches(db, tasksQuery),
        deleteDocumentsInBatches(db, collectionsQuery),
        deleteDocumentsInBatches(db, collectionLikesQuery),
        deleteDocumentsInBatches(db, pointTransactionsQuery),
      ]);
      deletionLog.fcmTokens = fcmTokens;
      deletionLog.tasks = tasks;
      deletionLog.collections = collections;
      deletionLog.collectionLikes = collectionLikes;
      deletionLog.pointTransactions = pointTransactions;
      console.log(`  ✓ Chunk 3: fcmTokens(${fcmTokens}), tasks(${tasks}), ` +
        `collections(${collections}), collectionLikes(${collectionLikes}), ` +
        `pointTransactions(${pointTransactions})`);

      // Chunk 4: Delete remaining 3 collections in parallel
      const [conversations, reports, dmReports] = await Promise.all([
        deleteDocumentsInBatches(db, conversationsQuery),
        deleteDocumentsInBatches(db, reportsQuery),
        deleteDocumentsInBatches(db, dmReportsQuery),
      ]);
      deletionLog.conversations = conversations;
      deletionLog.reports = reports;
      deletionLog.dmReports = dmReports;
      console.log(`  ✓ Chunk 4: conversations(${conversations}), reports(${reports}), dmReports(${dmReports})`);

      // Sequential: Delete user document (must complete before Auth deletion)
      await db.collection("users").doc(uid).delete();
      deletionLog.userDocument = 1;
      console.log("  ✓ Deleted user document");

      // Sequential: Delete Firebase Authentication user (depends on user document deletion)
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
