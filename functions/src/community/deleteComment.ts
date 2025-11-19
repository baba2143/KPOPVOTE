/**
 * Delete a comment
 * Only the comment author or post author can delete a comment
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const deleteComment = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "DELETE");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "DELETE") {
    res.status(405).json({ success: false, error: "Method not allowed. Use DELETE." } as ApiResponse<null>);
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
    const commentId = req.query.commentId as string;

    // Validation
    if (!commentId) {
      res.status(400).json({ success: false, error: "commentId is required" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();

    // Get comment
    const commentDoc = await db.collection("comments").doc(commentId).get();
    if (!commentDoc.exists) {
      res.status(404).json({ success: false, error: "Comment not found" } as ApiResponse<null>);
      return;
    }

    const commentData = commentDoc.data();
    if (!commentData) {
      res.status(404).json({ success: false, error: "Comment data not found" } as ApiResponse<null>);
      return;
    }

    const commentAuthorId = commentData.userId;
    const postId = commentData.postId;

    // Get post to check post author
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

    // Authorization: Only comment author or post author can delete
    if (currentUser.uid !== commentAuthorId && currentUser.uid !== postAuthorId) {
      res.status(403).json({
        success: false,
        error: "You can only delete your own comments or comments on your posts",
      } as ApiResponse<null>);
      return;
    }

    // Delete comment
    await db.collection("comments").doc(commentId).delete();

    // Update post's commentsCount
    await db.collection("posts").doc(postId).update({
      commentsCount: admin.firestore.FieldValue.increment(-1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Delete associated notification (if exists)
    const notificationsQuery = await db
      .collection("notifications")
      .where("commentId", "==", commentId)
      .get();

    const batch = db.batch();
    notificationsQuery.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    res.status(200).json({
      success: true,
      data: null,
    } as ApiResponse<null>);
  } catch (error) {
    console.error("Error deleting comment:", error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Failed to delete comment",
    } as ApiResponse<null>);
  }
});
