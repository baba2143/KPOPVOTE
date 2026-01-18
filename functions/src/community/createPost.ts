/**
 * Create community post
 * Phase 1: ポイント報酬機能除外版
 * Phase 6: フォロワーへの通知機能追加
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { CreatePostRequest, ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { sendPushNotification } from "../utils/fcmHelper";
import { shouldSendNotificationCached } from "../utils/notificationHelper";

export const createPost = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

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
    const { type, content, biasIds } = req.body as CreatePostRequest;

    // Validation
    if (!type || !content || !biasIds) {
      res.status(400).json({ success: false, error: "type, content, and biasIds are required" } as ApiResponse<null>);
      return;
    }

    if (!["image", "my_votes", "goods_trade", "collection"].includes(type)) {
      res.status(400).json({ success: false, error: "Invalid post type" } as ApiResponse<null>);
      return;
    }

    if (!Array.isArray(biasIds) || biasIds.length === 0) {
      res.status(400).json({ success: false, error: "biasIds must be a non-empty array" } as ApiResponse<null>);
      return;
    }

    // Type-specific validation
    if (type === "collection") {
      if (!content.collectionId) {
        res.status(400).json({
          success: false,
          error: "collectionId required for collection posts",
        } as ApiResponse<null>);
        return;
      }
      if (!content.collectionTitle) {
        res.status(400).json({
          success: false,
          error: "collectionTitle required for collection posts",
        } as ApiResponse<null>);
        return;
      }
    }

    if (type === "image") {
      if (!content.images || content.images.length === 0) {
        res.status(400).json({ success: false, error: "images required for image posts" } as ApiResponse<null>);
        return;
      }
      if (content.images.length > 4) {
        res.status(400).json({ success: false, error: "Maximum 4 images allowed" } as ApiResponse<null>);
        return;
      }
    }

    if (type === "my_votes") {
      if (!content.myVotes || content.myVotes.length === 0) {
        res.status(400).json({ success: false, error: "myVotes required for my_votes posts" } as ApiResponse<null>);
        return;
      }
    }

    if (type === "goods_trade") {
      if (!content.goodsTrade) {
        res.status(400).json({
          success: false,
          error: "goodsTrade required for goods_trade posts",
        } as ApiResponse<null>);
        return;
      }
      const gt = content.goodsTrade;
      if (
        !gt.idolId ||
        !gt.goodsImageUrl ||
        !gt.goodsName ||
        !gt.tradeType ||
        !gt.goodsTags ||
        gt.goodsTags.length === 0
      ) {
        res.status(400).json({
          success: false,
          error: "goodsTrade requires: idolId, goodsImageUrl, goodsName, tradeType, and goodsTags",
        } as ApiResponse<null>);
        return;
      }
      if (!["want", "offer"].includes(gt.tradeType)) {
        res.status(400).json({
          success: false,
          error: "Invalid tradeType. Must be 'want' or 'offer'",
        } as ApiResponse<null>);
        return;
      }
    }

    const db = admin.firestore();
    const postRef = db.collection("posts").doc();

    const postData = {
      id: postRef.id,
      userId: currentUser.uid,
      type,
      content,
      biasIds,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      isReported: false,
      reportCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await postRef.set(postData);

    // Increment user's postsCount
    const userRef = db.collection("users").doc(currentUser.uid);
    await userRef.update({
      postsCount: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Get user info to include in response
    const userDoc = await userRef.get();
    const userData = userDoc.exists ? userDoc.data() : null;

    console.log(`✅ [createPost] Post created: user=${currentUser.uid}, post=${postRef.id}`);

    // Notify followers about the new post (async, don't block response)
    notifyFollowersAboutNewPost(
      currentUser.uid,
      userData?.displayName || "ユーザー",
      postRef.id,
      type
    ).catch((err) => console.error("❌ [createPost] Error notifying followers:", err));

    // Build user object for response
    const userObject = {
      uid: currentUser.uid,
      email: currentUser.email || "",
      displayName: userData?.displayName || null,
      photoURL: userData?.photoURL || null,
      points: userData?.points || 0,
      biasIds: userData?.biasIds || [],
      followingCount: userData?.followingCount || 0,
      followersCount: userData?.followersCount || 0,
      postsCount: (userData?.postsCount || 0) + 1, // Already incremented
      isPrivate: userData?.isPrivate || false,
      isSuspended: userData?.isSuspended || false,
      createdAt: userData?.createdAt?.toDate().toISOString() || new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    res.status(201).json({
      success: true,
      data: {
        ...postData,
        user: userObject,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Create post error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});

/**
 * Notify followers about a new post
 * Rate limited: only notify if user hasn't posted in the last 30 minutes
 */
async function notifyFollowersAboutNewPost(
  authorId: string,
  authorName: string,
  postId: string,
  postType: string
): Promise<void> {
  const db = admin.firestore();

  try {
    // Rate limit check: don't spam followers with too many notifications
    const rateLimitKey = `postNotify_${authorId}`;
    const rateLimitDoc = await db.collection("notificationsSent").doc(rateLimitKey).get();

    if (rateLimitDoc.exists) {
      const lastSent = rateLimitDoc.data()?.sentAt?.toDate();
      if (lastSent) {
        const minutesSinceLastNotify = (Date.now() - lastSent.getTime()) / (1000 * 60);
        if (minutesSinceLastNotify < 30) {
          console.log(
            `⏳ [createPost] Skipping follower notification (rate limited): ${authorId}`
          );
          return;
        }
      }
    }

    // Update rate limit timestamp
    await db.collection("notificationsSent").doc(rateLimitKey).set({
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Get followers
    const followersSnapshot = await db
      .collection("follows")
      .where("followingId", "==", authorId)
      .limit(100) // Limit to prevent excessive notifications
      .get();

    if (followersSnapshot.empty) {
      console.log(`ℹ️ [createPost] No followers to notify for user: ${authorId}`);
      return;
    }

    // Create post type label
    const postTypeLabels: Record<string, string> = {
      image: "画像",
      my_votes: "投票結果",
      goods_trade: "グッズ交換",
      collection: "コレクション",
    };
    const typeLabel = postTypeLabels[postType] || "投稿";

    let notifiedCount = 0;

    for (const followerDoc of followersSnapshot.docs) {
      const followerId = followerDoc.data().followerId;

      // Don't notify the author themselves
      if (followerId === authorId) continue;

      // Check notification settings
      const shouldNotify = await shouldSendNotificationCached(followerId, "newPosts");

      if (shouldNotify) {
        // Create notification
        const notificationRef = db.collection("notifications").doc();
        await notificationRef.set({
          id: notificationRef.id,
          userId: followerId,
          type: "system",
          title: `${authorName}さんが新しい${typeLabel}を投稿`,
          body: `${authorName}さんの新しい投稿をチェックしましょう！`,
          isRead: false,
          actionUserId: authorId,
          actionUserDisplayName: authorName,
          relatedPostId: postId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Send push notification
        await sendPushNotification({
          userId: followerId,
          type: "system",
          title: `${authorName}さんが新しい${typeLabel}を投稿`,
          body: `${authorName}さんの新しい投稿をチェックしましょう！`,
          data: {
            postId,
            userId: authorId,
            notificationId: notificationRef.id,
          },
        });

        notifiedCount++;
      } else {
        console.log(`[createPost] Notification skipped: user ${followerId} has new post notifications disabled`);
      }
    }

    console.log(
      `📱 [createPost] Notified ${notifiedCount} followers about new post by ${authorId}`
    );
  } catch (error) {
    console.error("❌ [createPost] Error in notifyFollowersAboutNewPost:", error);
  }
}
