/**
 * Create community post
 * 新報酬設計: 投稿タイプ別ポイント報酬対応
 * Phase 6: フォロワーへの通知機能追加
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { CreatePostRequest, ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { applyRateLimit, GENERAL_RATE_LIMIT } from "../middleware/rateLimit";
import { sendPushNotification } from "../utils/fcmHelper";
import { shouldSendNotificationCached } from "../utils/notificationHelper";
import { COMMUNITY_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";
import { grantRewardPoints } from "../utils/rewardHelper";

// Validation constants
const MAX_TEXT_LENGTH = 5000;
const MAX_GOODS_NAME_LENGTH = 200;
const MAX_GOODS_DESCRIPTION_LENGTH = 2000;
const MAX_TAG_LENGTH = 50;
const MAX_TAGS_COUNT = 10;

export const createPost = functions
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
      const { type, content, biasIds } = req.body as CreatePostRequest;

      // Validation
      if (!type || !content || !biasIds) {
        res.status(400).json({ success: false, error: "type, content, and biasIds are required" } as ApiResponse<null>);
        return;
      }

      if (!["image", "my_votes", "goods_trade", "collection", "music_video"].includes(type)) {
        res.status(400).json({ success: false, error: "Invalid post type" } as ApiResponse<null>);
        return;
      }

      if (!Array.isArray(biasIds) || biasIds.length === 0) {
        res.status(400).json({ success: false, error: "biasIds must be a non-empty array" } as ApiResponse<null>);
        return;
      }

      // Text length validation
      if (content.text && content.text.length > MAX_TEXT_LENGTH) {
        res.status(400).json({
          success: false,
          error: `Text must be ${MAX_TEXT_LENGTH} characters or less`,
        } as ApiResponse<null>);
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
        // Validate goods name length
        if (gt.goodsName.length > MAX_GOODS_NAME_LENGTH) {
          res.status(400).json({
            success: false,
            error: `Goods name must be ${MAX_GOODS_NAME_LENGTH} characters or less`,
          } as ApiResponse<null>);
          return;
        }
        // Validate description length
        if (gt.description && gt.description.length > MAX_GOODS_DESCRIPTION_LENGTH) {
          res.status(400).json({
            success: false,
            error: `Description must be ${MAX_GOODS_DESCRIPTION_LENGTH} characters or less`,
          } as ApiResponse<null>);
          return;
        }
        // Validate tags
        if (gt.goodsTags.length > MAX_TAGS_COUNT) {
          res.status(400).json({
            success: false,
            error: `Maximum ${MAX_TAGS_COUNT} tags allowed`,
          } as ApiResponse<null>);
          return;
        }
        for (const tag of gt.goodsTags) {
          if (tag.length > MAX_TAG_LENGTH) {
            res.status(400).json({
              success: false,
              error: `Each tag must be ${MAX_TAG_LENGTH} characters or less`,
            } as ApiResponse<null>);
            return;
          }
        }
      }

      if (type === "music_video") {
        if (!content.musicVideo) {
          res.status(400).json({
            success: false,
            error: "musicVideo required for music_video posts",
          } as ApiResponse<null>);
          return;
        }
        const mv = content.musicVideo;
        if (!mv.youtubeVideoId || !mv.youtubeUrl || !mv.title || !mv.thumbnailUrl) {
          res.status(400).json({
            success: false,
            error: "musicVideo requires: youtubeVideoId, youtubeUrl, title, thumbnailUrl",
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

      // Increment user's postsCount and update latestPostAt for efficient activity queries
      const userRef = db.collection("users").doc(currentUser.uid);
      await userRef.update({
        postsCount: admin.firestore.FieldValue.increment(1),
        latestPostAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Get user info to include in response
      const userDoc = await userRef.get();
      const userData = userDoc.exists ? userDoc.data() : null;

      console.log(`✅ [createPost] Post created: user=${currentUser.uid}, post=${postRef.id}`);

      // 投稿タイプに応じたポイント報酬を付与（async, don't block response）
      grantPostRewardPoints(currentUser.uid, type, postRef.id)
        .catch((err) => console.error("❌ [createPost] Error granting reward points:", err));

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
      music_video: "MV",
    };
    const typeLabel = postTypeLabels[postType] || "投稿";

    // Check notification settings in parallel
    const followerIds = followersSnapshot.docs
      .map((doc) => doc.data().followerId)
      .filter((id) => id !== authorId); // Exclude author

    const notificationChecks = await Promise.all(
      followerIds.map((followerId) =>
        shouldSendNotificationCached(followerId, "newPosts")
          .then((shouldNotify) => ({ followerId, shouldNotify }))
      )
    );

    const eligibleFollowers = notificationChecks.filter((c) => c.shouldNotify);
    const skippedCount = notificationChecks.length - eligibleFollowers.length;

    if (skippedCount > 0) {
      console.log(`[createPost] Notification skipped for ${skippedCount} users (notifications disabled)`);
    }

    if (eligibleFollowers.length === 0) {
      console.log(`ℹ️ [createPost] No eligible followers to notify for user: ${authorId}`);
      return;
    }

    // Batch write notifications (N sequential → 1 batch)
    const batch = db.batch();
    const pushPromises: Promise<unknown>[] = [];
    const notificationRefs: admin.firestore.DocumentReference[] = [];

    for (const { followerId } of eligibleFollowers) {
      const notificationRef = db.collection("notifications").doc();
      notificationRefs.push(notificationRef);

      batch.set(notificationRef, {
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

      // Queue push notification (will run in parallel)
      pushPromises.push(
        sendPushNotification({
          userId: followerId,
          type: "system",
          title: `${authorName}さんが新しい${typeLabel}を投稿`,
          body: `${authorName}さんの新しい投稿をチェックしましょう！`,
          data: {
            postId,
            userId: authorId,
            notificationId: notificationRef.id,
          },
        })
      );
    }

    // Execute batch write and push notifications in parallel
    await Promise.all([
      batch.commit(),
      Promise.all(pushPromises),
    ]);

    const notifiedCount = eligibleFollowers.length;

    console.log(
      `📱 [createPost] Notified ${notifiedCount} followers about new post by ${authorId}`
    );
  } catch (error) {
    console.error("❌ [createPost] Error in notifyFollowersAboutNewPost:", error);
  }
}

/**
 * 投稿タイプに応じたポイント報酬を付与
 * 新報酬設計: タイプ別ポイント（単一ポイント制）
 * - music_video (MV): post_mv → 5P
 * - image (画像): post_image → 3P
 * - goods_trade (グッズ交換): post_goods_exchange → 5P
 * - collection (コレクション): collection_create → 10P（作成時）
 * - my_votes (投票結果): post_text → 2P（テキスト扱い）
 */
async function grantPostRewardPoints(
  userId: string,
  postType: string,
  postId: string
): Promise<void> {
  try {
    // 投稿タイプ → actionType マッピング
    const actionTypeMap: Record<string, string> = {
      music_video: "post_mv",
      image: "post_image",
      goods_trade: "post_goods_exchange",
      collection: "collection_create",
      my_votes: "post_text", // 投票結果投稿はテキスト扱い
    };

    const actionType = actionTypeMap[postType];
    if (!actionType) {
      console.warn(`⚠️ [createPost] Unknown post type for reward: ${postType}`);
      return;
    }

    // ポイント付与（単一ポイント制: isPremium不要）
    const pointsGranted = await grantRewardPoints(userId, actionType, postId);

    if (pointsGranted > 0) {
      console.log(
        `🎁 [createPost] Granted ${pointsGranted}P for ${actionType} to user ${userId}`
      );
    }
  } catch (error) {
    console.error("❌ [createPost] Error in grantPostRewardPoints:", error);
  }
}
