/**
 * Delete community post
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const deleteCommunityPost = functions.https.onRequest(async (req, res) => {
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

  await new Promise<void>((resolve, reject) => {
    verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  try {
    const postId = req.query.postId as string;
    const reason = req.query.reason as string | undefined;

    if (!postId) {
      res.status(400).json({ success: false, error: "postId is required" } as ApiResponse<null>);
      return;
    }

    const postRef = admin.firestore().collection("communityPosts").doc(postId);
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      res.status(404).json({ success: false, error: "Post not found" } as ApiResponse<null>);
      return;
    }

    // Record deletion
    await admin.firestore().collection("deletedPosts").add({
      postId,
      originalData: postDoc.data(),
      deletedBy: (req as AuthenticatedRequest).user?.uid,
      deleteReason: reason || "Admin deletion",
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Delete post
    await postRef.delete();

    res.status(200).json({ success: true, data: { postId, deleted: true, reason } } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Delete community post error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
