/**
 * Search posts by text content
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const searchPosts = functions.https.onRequest(async (req, res) => {
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
    const query = (req.query.query as string) || "";
    const biasId = req.query.biasId as string | undefined;
    const limit = parseInt(req.query.limit as string) || 20;

    if (!query.trim()) {
      res.status(400).json({ success: false, error: "Query is required" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();
    let postsQuery:
      | admin.firestore.Query<admin.firestore.DocumentData>
      | admin.firestore.CollectionReference<admin.firestore.DocumentData> =
      db.collection("posts")
        .orderBy("createdAt", "desc")
        .limit(100); // Get more initially for filtering

    // Filter by bias if provided
    if (biasId) {
      postsQuery = postsQuery.where("biasId", "==", biasId);
    }

    const postsSnapshot = await postsQuery.get();

    // Get user data for each post
    const userIds = [...new Set(postsSnapshot.docs.map((doc) => doc.data().userId))];
    const usersSnapshot = await Promise.all(
      userIds.map((userId) => db.collection("users").doc(userId).get())
    );
    const usersMap = new Map(
      usersSnapshot.map((doc) => [
        doc.id,
        {
          displayName: doc.data()?.displayName || "Unknown",
          photoURL: doc.data()?.photoURL || null,
        },
      ])
    );

    // Get current user's likes
    const likesSnapshot = await db.collection("posts")
      .where(admin.firestore.FieldPath.documentId(), "in", postsSnapshot.docs.map((d) => d.id).slice(0, 10))
      .get();

    const likedPostIds = new Set<string>();
    for (const postDoc of likesSnapshot.docs) {
      const likeDoc = await postDoc.ref.collection("likes").doc(currentUser.uid).get();
      if (likeDoc.exists) {
        likedPostIds.add(postDoc.id);
      }
    }

    // Filter and format posts
    const queryLower = query.toLowerCase();
    const posts = postsSnapshot.docs
      .map((doc) => {
        const data = doc.data();
        const userData = usersMap.get(data.userId);

        return {
          id: doc.id,
          userId: data.userId,
          userName: userData?.displayName || "Unknown",
          userPhotoURL: userData?.photoURL || null,
          type: data.type || "text",
          content: data.content || "",
          imageUrls: data.imageUrls || [],
          videoUrls: data.videoUrls || [],
          biasId: data.biasId || null,
          biasName: data.biasName || null,
          likesCount: data.likesCount || 0,
          commentsCount: data.commentsCount || 0,
          isLiked: likedPostIds.has(doc.id),
          createdAt: data.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
          updatedAt: data.updatedAt?.toDate?.()?.toISOString() || null,
        };
      })
      .filter((post) => {
        // Filter by text content (case-insensitive)
        return post.content.toLowerCase().includes(queryLower) ||
               (post.biasName && post.biasName.toLowerCase().includes(queryLower));
      })
      .slice(0, limit);

    res.status(200).json({
      success: true,
      data: {
        posts,
        total: posts.length,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Search posts error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
