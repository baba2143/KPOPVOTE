/**
 * Get following users list
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const getFollowing = functions.https.onRequest(async (req, res) => {
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
    const userId = req.query.userId as string || currentUser.uid;
    const limit = parseInt(req.query.limit as string) || 20;
    const lastFollowId = req.query.lastFollowId as string | undefined;

    const db = admin.firestore();
    let query: admin.firestore.Query = db.collection("follows")
      .where("followerId", "==", userId)
      .orderBy("createdAt", "desc")
      .limit(limit + 1);

    if (lastFollowId) {
      const lastFollowDoc = await db.collection("follows").doc(lastFollowId).get();
      if (lastFollowDoc.exists) {
        query = query.startAfter(lastFollowDoc);
      }
    }

    const snapshot = await query.get();
    const hasMore = snapshot.size > limit;
    const follows = snapshot.docs.slice(0, limit);

    // Get user info for each following user
    const followingUsers = await Promise.all(
      follows.map(async (doc) => {
        const followData = doc.data();
        const userDoc = await db.collection("users").doc(followData.followingId).get();
        const userData = userDoc.exists ? userDoc.data() : null;

        // Check if current user is following this user
        let isFollowingBack = false;
        if (userId !== currentUser.uid) {
          const followBackDoc = await db.collection("follows")
            .doc(`${currentUser.uid}_${followData.followingId}`)
            .get();
          isFollowingBack = followBackDoc.exists;
        }

        return {
          followId: doc.id,
          userId: followData.followingId,
          displayName: userData?.displayName || null,
          photoURL: userData?.photoURL || null,
          followersCount: userData?.followersCount || 0,
          followingCount: userData?.followingCount || 0,
          postsCount: userData?.postsCount || 0,
          isFollowedByCurrentUser: isFollowingBack,
          followedAt: followData.createdAt?.toDate().toISOString() || null,
        };
      })
    );

    res.status(200).json({
      success: true,
      data: {
        users: followingUsers,
        hasMore,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Get following error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
