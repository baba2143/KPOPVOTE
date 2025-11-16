/**
 * Delete post (owner or admin only)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const deletePost = functions.https.onRequest(async (req, res) => {
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
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      res.status(404).json({ success: false, error: "Post not found" } as ApiResponse<null>);
      return;
    }

    const postData = postDoc.data()!;

    // Check if user is admin
    const userDoc = await db.collection("users").doc(currentUser.uid).get();
    const isAdmin = userDoc.exists && userDoc.data()?.isAdmin === true;

    // Authorization: Owner or Admin only
    if (postData.userId !== currentUser.uid && !isAdmin) {
      res.status(403).json({
        success: false,
        error: "Forbidden: You can only delete your own posts",
      } as ApiResponse<null>);
      return;
    }

    // Delete post and subcollections
    const batch = db.batch();

    // Delete the post document
    batch.delete(postRef);

    // Delete all likes subcollection documents
    const likesSnapshot = await postRef.collection("likes").get();
    likesSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    // Decrement user's postsCount
    const userRef = db.collection("users").doc(postData.userId);
    await userRef.update({
      postsCount: admin.firestore.FieldValue.increment(-1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).json({
      success: true,
      data: {
        message: "Post deleted successfully",
        postId,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Delete post error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
