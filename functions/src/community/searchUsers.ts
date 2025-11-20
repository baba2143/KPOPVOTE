/**
 * Search users by name or bias
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const searchUsers = functions.https.onRequest(async (req, res) => {
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
    const excludeFollowing = req.query.excludeFollowing === "true";

    const db = admin.firestore();
    let usersQuery:
      | admin.firestore.Query<admin.firestore.DocumentData>
      | admin.firestore.CollectionReference<admin.firestore.DocumentData> =
      db.collection("users")
        .orderBy("displayName")
        .limit(limit);

    // Filter by bias if provided
    if (biasId) {
      usersQuery = usersQuery.where("selectedIdols", "array-contains", biasId);
    }

    const usersSnapshot = await usersQuery.get();

    // Get following list if needed
    let followingIds: string[] = [];
    if (excludeFollowing) {
      const followsSnapshot = await db.collection("follows")
        .where("followerId", "==", currentUser.uid)
        .get();
      followingIds = followsSnapshot.docs.map((doc) => doc.data().followingId);
    }

    // Filter and format results
    const users = usersSnapshot.docs
      .map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          displayName: data.displayName || "Unknown",
          photoURL: data.photoURL || null,
          bio: data.bio || null,
          selectedIdols: data.selectedIdols || [],
          followersCount: data.followersCount || 0,
          followingCount: data.followingCount || 0,
          postsCount: data.postsCount || 0,
        };
      })
      .filter((user) => {
        // Exclude current user
        if (user.id === currentUser.uid) return false;

        // Exclude following users if requested
        if (excludeFollowing && followingIds.includes(user.id)) return false;

        // Filter by query (case-insensitive)
        if (query && !user.displayName.toLowerCase().includes(query.toLowerCase())) {
          return false;
        }

        return true;
      });

    res.status(200).json({
      success: true,
      data: {
        users,
        total: users.length,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Search users error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
