/**
 * Like/Unlike post (toggle)
 * 双方向報酬対応: する側(community_like)、される側(received_like)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { sendPushNotification } from "../utils/fcmHelper";
import { shouldSendNotificationCached } from "../utils/notificationHelper";
import { COMMUNITY_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";
import { grantRewardPoints } from "../utils/rewardHelper";

export const likePost = functions
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

    try {
      const { postId } = req.body;

      // Validation
      if (!postId) {
        res.status(400).json({ success: false, error: "postId is required" } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();
      const postRef = db.collection("posts").doc(postId);

      // Check if post exists
      const postDoc = await postRef.get();
      if (!postDoc.exists) {
        res.status(404).json({ success: false, error: "Post not found" } as ApiResponse<null>);
        return;
      }

      const postData = postDoc.data()!;
      const likeRef = postRef.collection("likes").doc(currentUser.uid);
      const likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // Unlike: Remove like document and decrement count in a single batch
        const batch = db.batch();
        batch.delete(likeRef);
        batch.update(postRef, {
          likesCount: admin.firestore.FieldValue.increment(-1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await batch.commit();

        res.status(200).json({
          success: true,
          data: {
            postId,
            action: "unliked",
            likesCount: (postData.likesCount || 1) - 1,
          },
        } as ApiResponse<unknown>);
      } else {
        // Like: Create like document and increment count in a single batch
        const batch = db.batch();
        batch.set(likeRef, {
          userId: currentUser.uid,
          postId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        batch.update(postRef, {
          likesCount: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await batch.commit();

        // Create notification for post owner (if not self-like)
        // Fire-and-forget: Don't block response for notification
        if (postData.userId !== currentUser.uid) {
          sendLikeNotification(db, currentUser.uid, postData.userId, postId)
            .catch((err) => console.error("❌ [likePost] Notification error:", err));
        }

        // ポイント付与（双方向報酬）- Fire-and-forget
        grantLikeRewardPoints(currentUser.uid, postData.userId, postId)
          .catch((err) => console.error("❌ [likePost] Reward points error:", err));

        console.log(`✅ [likePost] Post liked: user=${currentUser.uid}, post=${postId}`);

        res.status(200).json({
          success: true,
          data: {
            postId,
            action: "liked",
            likesCount: (postData.likesCount || 0) + 1,
          },
        } as ApiResponse<unknown>);
      }
    } catch (error: unknown) {
      console.error("Like post error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });

/**
 * Send like notification in background (fire-and-forget)
 */
async function sendLikeNotification(
  db: admin.firestore.Firestore,
  likerUserId: string,
  postAuthorId: string,
  postId: string
): Promise<void> {
  // Check notification settings
  const shouldNotify = await shouldSendNotificationCached(postAuthorId, "likes");

  if (!shouldNotify) {
    console.log(`[likePost] Notification skipped: user ${postAuthorId} has likes notifications disabled`);
    return;
  }

  const currentUserDoc = await db.collection("users").doc(likerUserId).get();
  const currentUserData = currentUserDoc.data();

  const notificationRef = db.collection("notifications").doc();
  const notificationTitle = "いいねされました";
  const notificationBody = `${currentUserData?.displayName || "ユーザー"}さんがあなたの投稿にいいねしました`;

  await notificationRef.set({
    id: notificationRef.id,
    userId: postAuthorId,
    type: "like",
    title: notificationTitle,
    body: notificationBody,
    isRead: false,
    actionUserId: likerUserId,
    actionUserDisplayName: currentUserData?.displayName || null,
    actionUserPhotoURL: currentUserData?.photoURL || null,
    relatedPostId: postId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Send push notification
  await sendPushNotification({
    userId: postAuthorId,
    type: "like",
    title: notificationTitle,
    body: notificationBody,
    data: {
      notificationId: notificationRef.id,
      postId: postId,
      userId: likerUserId,
    },
  });

  console.log(`📱 [likePost] Like notification sent to ${postAuthorId}`);
}

/**
 * いいね報酬を付与（双方向報酬）
 * する側: community_like → 1P（dailyLimit: 10回/日）
 * される側: received_like → 1P（dailyLimit: 50回/日）
 */
async function grantLikeRewardPoints(
  likerUserId: string,
  postAuthorId: string,
  postId: string
): Promise<void> {
  try {
    // する側へのポイント付与
    const likerPoints = await grantRewardPoints(
      likerUserId,
      "community_like",
      postId
    );

    if (likerPoints > 0) {
      console.log(
        `🎁 [likePost] Granted ${likerPoints}P for community_like to user ${likerUserId}`
      );
    }

    // される側へのポイント付与（自分の投稿へのいいねは除外）
    if (postAuthorId !== likerUserId) {
      const authorPoints = await grantRewardPoints(
        postAuthorId,
        "received_like",
        postId
      );

      if (authorPoints > 0) {
        console.log(
          `🎁 [likePost] Granted ${authorPoints}P for received_like to user ${postAuthorId}`
        );
      }
    }
  } catch (error) {
    console.error("❌ [likePost] Error in grantLikeRewardPoints:", error);
  }
}
