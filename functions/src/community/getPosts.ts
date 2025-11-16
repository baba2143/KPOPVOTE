/**
 * Get posts list (bias timeline or following timeline)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const getPosts = functions.https.onRequest(async (req, res) => {
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

  const currentUser = (req as AuthenticatedRequest).user;
  if (!currentUser) {
    res.status(401).json({ success: false, error: "Unauthorized" } as ApiResponse<null>);
    return;
  }

  try {
    const type = req.query.type as string;
    const biasId = req.query.biasId as string | undefined;
    const limit = parseInt(req.query.limit as string) || 20;
    const lastPostId = req.query.lastPostId as string | undefined;

    if (!type || !["bias", "following"].includes(type)) {
      res.status(400).json({ success: false, error: "type must be 'bias' or 'following'" } as ApiResponse<null>);
      return;
    }

    if (type === "bias" && !biasId) {
      res.status(400).json({ success: false, error: "biasId is required for bias timeline" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();
    let query: admin.firestore.Query = db.collection("posts");

    if (type === "bias") {
      // Bias timeline: posts with matching biasId
      query = query.where("biasIds", "array-contains", biasId);
    } else {
      // Following timeline: posts from followed users
      const followingSnapshot = await db.collection("follows")
        .where("followerId", "==", currentUser.uid)
        .get();

      if (followingSnapshot.empty) {
        // No following users, return empty
        res.status(200).json({
          success: true,
          data: { posts: [], hasMore: false },
        } as ApiResponse<unknown>);
        return;
      }

      const followingIds = followingSnapshot.docs.map((doc) => doc.data().followingId);

      // Firestore 'in' query limited to 10 items
      if (followingIds.length > 10) {
        query = query.where("userId", "in", followingIds.slice(0, 10));
      } else {
        query = query.where("userId", "in", followingIds);
      }
    }

    // Add pagination
    query = query.orderBy("createdAt", "desc").limit(limit + 1);

    if (lastPostId) {
      const lastPostDoc = await db.collection("posts").doc(lastPostId).get();
      if (lastPostDoc.exists) {
        query = query.startAfter(lastPostDoc);
      }
    }

    const snapshot = await query.get();
    const hasMore = snapshot.size > limit;
    const posts = snapshot.docs.slice(0, limit);

    // Get user info for each post
    const postsData = await Promise.all(
      posts.map(async (doc) => {
        const data = doc.data();
        const userDoc = await db.collection("users").doc(data.userId).get();
        const userData = userDoc.exists ? userDoc.data() : null;

        // Check if current user liked this post
        const likeDoc = await db.collection("posts").doc(doc.id).collection("likes").doc(currentUser.uid).get();

        return {
          id: doc.id,
          ...data,
          createdAt: data.createdAt?.toDate().toISOString() || null,
          updatedAt: data.updatedAt?.toDate().toISOString() || null,
          isLikedByCurrentUser: likeDoc.exists,
          userDisplayName: userData?.displayName || null,
          userPhotoURL: userData?.photoURL || null,
        };
      })
    );

    res.status(200).json({
      success: true,
      data: {
        posts: postsData,
        hasMore,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Get posts error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
