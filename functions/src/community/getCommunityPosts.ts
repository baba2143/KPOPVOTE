/**
 * Get community posts
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const getCommunityPosts = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "GET") {
    res.status(405).json({ success: false, error: "Method not allowed. Use GET." } as ApiResponse<null>);
    return;
  }

  await new Promise<void>((resolve, reject) => {
    verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  await new Promise<void>((resolve, reject) => {
    verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  try {
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 50;
    const isReported = req.query.isReported === "true";

    let query = admin
      .firestore()
      .collection("communityPosts")
      .orderBy("createdAt", "desc")
      .limit(limit);

    if (isReported) {
      query = query.where(
        "isReported",
        "==",
        true
      ) as admin.firestore.Query<admin.firestore.DocumentData>;
    }

    const snapshot = await query.get();

    const posts = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        postId: doc.id,
        userId: data.userId,
        content: data.content,
        imageUrls: data.imageUrls || [],
        likeCount: data.likeCount || 0,
        commentCount: data.commentCount || 0,
        isReported: data.isReported || false,
        reportCount: data.reportCount || 0,
        createdAt: data.createdAt?.toDate().toISOString() || null,
        updatedAt: data.updatedAt?.toDate().toISOString() || null,
      };
    });

    res.status(200).json({
      success: true,
      data: { posts, count: posts.length },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Get community posts error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
