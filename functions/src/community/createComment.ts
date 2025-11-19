/**
 * Create comment on a post
 * Only followers of the post author can comment
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

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
      await db.collection("notifications").add({
        userId: postAuthorId,
        type: "comment",
        postId: postId,
        commentId: commentRef.id,
        fromUserId: currentUser.uid,
        read: false,
        createdAt: now,
      });
    }

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
