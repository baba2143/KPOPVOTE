/**
 * Follow user
 * 双方向報酬対応: する側(follow_user)、される側(received_follow)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FollowRequest, ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { applyRateLimit, GENERAL_RATE_LIMIT } from "../middleware/rateLimit";
import { sendPushNotification } from "../utils/fcmHelper";
import { shouldSendNotificationCached } from "../utils/notificationHelper";
import { COMMUNITY_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";
import { grantRewardPoints } from "../utils/rewardHelper";

export const followUser = functions
  .runWith(COMMUNITY_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "POST") {
      res.status(405).json({ success: false, error: "Method not allowed. Use POST." } as ApiResponse<null>);
      return;
    }

    await new Promise<void>((resolve, reject) => {
      verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
    });

    const currentUser = (req as AuthenticatedRequest).user;
    if (!currentUser) {
      res.status(401).json({ success: false, error: "Unauthorized" } as ApiResponse<null>);
      return;
    }

    // Apply rate limiting
    if (applyRateLimit(currentUser.uid, res, GENERAL_RATE_LIMIT)) {
      return; // Rate limited, response already sent
    }

    try {
      const { userId } = req.body as FollowRequest;

      // Validation
      if (!userId) {
        res.status(400).json({ success: false, error: "userId is required" } as ApiResponse<null>);
        return;
      }

      if (userId === currentUser.uid) {
        res.status(400).json({ success: false, error: "Cannot follow yourself" } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();

      // Check if user to follow exists
      const userToFollowDoc = await db.collection("users").doc(userId).get();
      if (!userToFollowDoc.exists) {
        res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
        return;
      }

      const followId = `${currentUser.uid}_${userId}`;
      const followRef = db.collection("follows").doc(followId);

      // Check if already following
      const existingFollow = await followRef.get();
      if (existingFollow.exists) {
        res.status(400).json({ success: false, error: "Already following this user" } as ApiResponse<null>);
        return;
      }

      // Create follow document
      const followData = {
        id: followId,
        followerId: currentUser.uid,
        followingId: userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await followRef.set(followData);

      // Increment counts using batch
      const batch = db.batch();

      const followerRef = db.collection("users").doc(currentUser.uid);
      batch.update(followerRef, {
        followingCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const followingRef = db.collection("users").doc(userId);
      batch.update(followingRef, {
        followersCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Create notification for followed user
      // Check notification settings
      const shouldNotify = await shouldSendNotificationCached(userId, "followers");

      if (shouldNotify) {
        const notificationRef = db.collection("notifications").doc();
        const currentUserDoc = await db.collection("users").doc(currentUser.uid).get();
        const currentUserData = currentUserDoc.data();

        const notificationTitle = "フォローされました";
        const notificationBody = `${currentUserData?.displayName || "ユーザー"}さんがあなたをフォローしました`;

        await notificationRef.set({
          id: notificationRef.id,
          userId: userId,
          type: "follow",
          title: notificationTitle,
          body: notificationBody,
          isRead: false,
          actionUserId: currentUser.uid,
          actionUserDisplayName: currentUserData?.displayName || null,
          actionUserPhotoURL: currentUserData?.photoURL || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Send push notification
        await sendPushNotification({
          userId: userId,
          type: "follow",
          title: notificationTitle,
          body: notificationBody,
          data: {
            notificationId: notificationRef.id,
            userId: currentUser.uid,
          },
        });
      } else {
        console.log(`[followUser] Notification skipped: user ${userId} has follower notifications disabled`);
      }

      // フォロー報酬を付与（双方向報酬）
      grantFollowRewardPoints(currentUser.uid, userId)
        .catch((err) => console.error("❌ [followUser] Error granting reward points:", err));

      res.status(201).json({
        success: true,
        data: {
          followId,
          followerId: currentUser.uid,
          followingId: userId,
          createdAt: new Date().toISOString(),
        },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("Follow user error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });

/**
 * フォロー報酬を付与（双方向報酬）
 * する側: follow_user → 3P（dailyLimit: 5回/日）
 * される側: received_follow → 2P（dailyLimit: 20回/日）
 */
async function grantFollowRewardPoints(
  followerId: string,
  followingId: string
): Promise<void> {
  try {
    // する側へのポイント付与（dailyLimitはrewardHelper内でチェック）
    const followerPoints = await grantRewardPoints(
      followerId,
      "follow_user",
      followingId
    );

    if (followerPoints > 0) {
      console.log(
        `🎁 [followUser] Granted ${followerPoints}P for follow_user to user ${followerId}`
      );
    }

    // される側へのポイント付与
    const followedPoints = await grantRewardPoints(
      followingId,
      "received_follow",
      followerId
    );

    if (followedPoints > 0) {
      console.log(
        `🎁 [followUser] Granted ${followedPoints}P for received_follow to user ${followingId}`
      );
    }
  } catch (error) {
    console.error("❌ [followUser] Error in grantFollowRewardPoints:", error);
  }
}
