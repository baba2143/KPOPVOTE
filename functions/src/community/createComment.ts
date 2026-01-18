/**
 * Create comment on a post
 * Only followers of the post author can comment
 * Phase 1: ポイント報酬機能除外版
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { sendPushNotification } from "../utils/fcmHelper";
import { shouldSendNotificationCached } from "../utils/notificationHelper";

interface CreateCommentRequest {
  postId: string;
  text: string;
}

interface CreateCommentResponse {
  commentId: string;
  commentsCount: number;
}

export const createComment = functions.https.onRequest(async (req, res) => {
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
    const { postId, text } = req.body as CreateCommentRequest;

    // Validation
    if (!postId || !text) {
      res.status(400).json({ success: false, error: "postId and text are required" } as ApiResponse<null>);
      return;
    }

    if (text.trim().length === 0) {
      res.status(400).json({ success: false, error: "Comment text cannot be empty" } as ApiResponse<null>);
      return;
    }

    if (text.length > 500) {
      res.status(400).json({
        success: false,
        error: "Comment text must be 500 characters or less",
      } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();

    // Check if post exists
    const postDoc = await db.collection("posts").doc(postId).get();
    if (!postDoc.exists) {
      res.status(404).json({ success: false, error: "Post not found" } as ApiResponse<null>);
      return;
    }

    const postData = postDoc.data();
    if (!postData) {
      res.status(404).json({ success: false, error: "Post data not found" } as ApiResponse<null>);
      return;
    }

    const postAuthorId = postData.userId;

    // Check if current user follows the post author
    // (Skip check if commenting on own post)
    if (currentUser.uid !== postAuthorId) {
      const followerDoc = await db
        .collection("followers")
        .doc(postAuthorId)
        .collection("users")
        .doc(currentUser.uid)
        .get();

      if (!followerDoc.exists) {
        res.status(403).json({
          success: false,
          error: "You must follow the post author to comment",
        } as ApiResponse<null>);
        return;
      }
    }

    // Create comment
    const commentRef = db.collection("comments").doc();
    const now = admin.firestore.FieldValue.serverTimestamp();

    await commentRef.set({
      postId: postId,
      userId: currentUser.uid,
      text: text.trim(),
      createdAt: now,
      updatedAt: now,
    });

    // Update post's commentsCount
    await db.collection("posts").doc(postId).update({
      commentsCount: admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    });

    // Create notification for post author (if not commenting on own post)
    if (currentUser.uid !== postAuthorId) {
      // Check notification settings
      const shouldNotify = await shouldSendNotificationCached(postAuthorId, "comments");

      if (shouldNotify) {
        const currentUserDoc = await db.collection("users").doc(currentUser.uid).get();
        const currentUserData = currentUserDoc.data();

        const notificationRef = db.collection("notifications").doc();
        const notificationTitle = "コメントされました";
        const notificationBody = `${currentUserData?.displayName || "ユーザー"}さんがあなたの投稿にコメントしました`;

        await notificationRef.set({
          id: notificationRef.id,
          userId: postAuthorId,
          type: "comment",
          title: notificationTitle,
          body: notificationBody,
          isRead: false,
          actionUserId: currentUser.uid,
          actionUserDisplayName: currentUserData?.displayName || null,
          actionUserPhotoURL: currentUserData?.photoURL || null,
          relatedPostId: postId,
          relatedCommentId: commentRef.id,
          createdAt: now,
        });

        // Send push notification
        await sendPushNotification({
          userId: postAuthorId,
          type: "comment",
          title: notificationTitle,
          body: notificationBody,
          data: {
            notificationId: notificationRef.id,
            postId: postId,
            commentId: commentRef.id,
            userId: currentUser.uid,
          },
        });
      } else {
        console.log(`[createComment] Notification skipped: user ${postAuthorId} has comment notifications disabled`);
      }
    }

    console.log(`✅ [createComment] Comment created: user=${currentUser.uid}, post=${postId}, comment=${commentRef.id}`);

    // Handle @mentions in comment (async, don't block response)
    handleMentionsInComment(
      db,
      text.trim(),
      currentUser.uid,
      postAuthorId,
      postId,
      commentRef.id
    ).catch((err) => console.error("❌ [createComment] Error handling mentions:", err));

    // Get updated comments count
    const updatedPostDoc = await db.collection("posts").doc(postId).get();
    const updatedCommentsCount = updatedPostDoc.data()?.commentsCount || 1;

    res.status(201).json({
      success: true,
      data: {
        commentId: commentRef.id,
        commentsCount: updatedCommentsCount,
      },
    } as ApiResponse<CreateCommentResponse>);
  } catch (error) {
    console.error("Error creating comment:", error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Failed to create comment",
    } as ApiResponse<null>);
  }
});

/**
 * Extract @username mentions from text
 * @param text - Comment text to search for mentions
 * @returns Array of mentioned usernames (without @ symbol)
 */
function extractMentions(text: string): string[] {
  const mentionPattern = /@(\w+)/g;
  const matches = text.matchAll(mentionPattern);
  return Array.from(matches, (m) => m[1]);
}

/**
 * Resolve usernames to user IDs
 * @param db - Firestore database instance
 * @param usernames - Array of usernames to resolve
 * @returns Array of user IDs
 */
async function resolveUsernames(
  db: admin.firestore.Firestore,
  usernames: string[]
): Promise<Map<string, { uid: string; displayName: string; photoURL: string | null }>> {
  const userMap = new Map<string, { uid: string; displayName: string; photoURL: string | null }>();

  if (usernames.length === 0) {
    return userMap;
  }

  // Firestore 'in' query supports max 10 items, so batch if needed
  const batchSize = 10;
  for (let i = 0; i < usernames.length; i += batchSize) {
    const batch = usernames.slice(i, i + batchSize);

    try {
      const userDocs = await db
        .collection("users")
        .where("displayName", "in", batch)
        .get();

      userDocs.forEach((doc) => {
        const data = doc.data();
        const displayName = data?.displayName;
        if (displayName) {
          userMap.set(displayName, {
            uid: doc.id,
            displayName: displayName,
            photoURL: data?.photoURL || null,
          });
        }
      });
    } catch (error) {
      console.error("[createComment] Error resolving usernames batch:", error);
    }
  }

  return userMap;
}

/**
 * Handle @mentions in comment and send notifications
 */
async function handleMentionsInComment(
  db: admin.firestore.Firestore,
  text: string,
  commentAuthorId: string,
  postAuthorId: string,
  postId: string,
  commentId: string
): Promise<void> {
  try {
    // Extract mentions from comment text
    const mentionedUsernames = extractMentions(text);

    if (mentionedUsernames.length === 0) {
      return;
    }

    console.log(`🔍 [createComment] Found ${mentionedUsernames.length} mentions: ${mentionedUsernames.join(", ")}`);

    // Resolve usernames to user IDs
    const userMap = await resolveUsernames(db, mentionedUsernames);

    if (userMap.size === 0) {
      console.log("ℹ️ [createComment] No valid users found for mentions");
      return;
    }

    // Get comment author info
    const authorDoc = await db.collection("users").doc(commentAuthorId).get();
    const authorData = authorDoc.data();
    const authorDisplayName = authorData?.displayName || "Someone";
    const authorPhotoURL = authorData?.photoURL || null;

    let notifiedCount = 0;

    // Send notification to each mentioned user
    for (const [username, userData] of userMap) {
      const mentionedUserId = userData.uid;

      // Skip if mentioning themselves
      if (mentionedUserId === commentAuthorId) {
        console.log(`[createComment] Skipping self-mention: ${username}`);
        continue;
      }

      // Skip if mentioning the post author (they already got comment notification)
      if (mentionedUserId === postAuthorId) {
        console.log(`[createComment] Skipping post author mention (already notified): ${username}`);
        continue;
      }

      // Check notification settings
      const shouldNotify = await shouldSendNotificationCached(mentionedUserId, "mentions");

      if (!shouldNotify) {
        console.log(
          "[createComment] Mention notification skipped: " +
          `user ${mentionedUserId} (${username}) has mention notifications disabled`
        );
        continue;
      }

      // Create notification
      const notificationRef = db.collection("notifications").doc();
      const notificationTitle = "メンションされました";
      const notificationBody = `${authorDisplayName}さんがコメントであなたをメンションしました`;

      await notificationRef.set({
        id: notificationRef.id,
        userId: mentionedUserId,
        type: "mention",
        title: notificationTitle,
        body: notificationBody,
        isRead: false,
        actionUserId: commentAuthorId,
        actionUserDisplayName: authorDisplayName,
        actionUserPhotoURL: authorPhotoURL,
        relatedPostId: postId,
        relatedCommentId: commentId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Send push notification
      await sendPushNotification({
        userId: mentionedUserId,
        type: "mention",
        title: notificationTitle,
        body: notificationBody,
        data: {
          notificationId: notificationRef.id,
          postId: postId,
          commentId: commentId,
          userId: commentAuthorId,
        },
      });

      notifiedCount++;
      console.log(`✅ [createComment] Sent mention notification to ${username} (${mentionedUserId})`);
    }

    console.log(`📱 [createComment] Sent ${notifiedCount} mention notifications`);
  } catch (error) {
    console.error("❌ [createComment] Error in handleMentionsInComment:", error);
  }
}
