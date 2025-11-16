/**
 * Like/Unlike post (toggle)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const likePost = functions.https.onRequest(async (req, res) => {
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
      // Unlike: Remove like document and decrement count
      await likeRef.delete();
      await postRef.update({
        likesCount: admin.firestore.FieldValue.increment(-1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.status(200).json({
        success: true,
        data: {
          postId,
          action: "unliked",
          likesCount: (postData.likesCount || 1) - 1,
        },
      } as ApiResponse<unknown>);
    } else {
      // Like: Create like document and increment count
      await likeRef.set({
        userId: currentUser.uid,
        postId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await postRef.update({
        likesCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Create notification for post owner (if not self-like)
      if (postData.userId !== currentUser.uid) {
        const currentUserDoc = await db.collection("users").doc(currentUser.uid).get();
        const currentUserData = currentUserDoc.data();

        const notificationRef = db.collection("notifications").doc();
        await notificationRef.set({
          id: notificationRef.id,
          userId: postData.userId,
          type: "like",
          title: "New Like",
          body: `${currentUserData?.displayName || "Someone"} liked your post`,
          isRead: false,
          actionUserId: currentUser.uid,
          actionUserDisplayName: currentUserData?.displayName || null,
          actionUserPhotoURL: currentUserData?.photoURL || null,
          relatedPostId: postId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

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
