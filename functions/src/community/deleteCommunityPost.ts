/**
 * Delete community post
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyTokenAsync, verifyAdminAsync, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const deleteCommunityPost = functions
  .runWith(ADMIN_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "DELETE") {
      res.status(405).json({ success: false, error: "Method not allowed. Use DELETE." } as ApiResponse<null>);
      return;
    }

    const tokenValid = await verifyTokenAsync(req as AuthenticatedRequest, res);
    if (!tokenValid) return;

    const isAdmin = await verifyAdminAsync(req as AuthenticatedRequest, res);
    if (!isAdmin) return;

    try {
      const postId = req.query.postId as string;
      const reason = req.query.reason as string | undefined;

      if (!postId) {
        res.status(400).json({ success: false, error: "postId is required" } as ApiResponse<null>);
        return;
      }

      const postRef = admin.firestore().collection("posts").doc(postId);
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
