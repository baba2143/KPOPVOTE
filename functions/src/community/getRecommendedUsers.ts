/**
 * Get recommended users based on shared biasIds
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const getRecommendedUsers = functions.https.onRequest(async (req, res) => {
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
    const limit = parseInt(req.query.limit as string) || 10;

    const db = admin.firestore();

    // Get current user's biasIds
    const currentUserDoc = await db.collection("users").doc(currentUser.uid).get();
    const currentUserData = currentUserDoc.data();
    const currentBiasIds = currentUserData?.biasIds || [];

    if (currentBiasIds.length === 0) {
      // No bias set, return empty
      res.status(200).json({
        success: true,
        data: {
          users: [],
        },
      } as ApiResponse<unknown>);
      return;
    }

    // Get users who already follow
    const followingSnapshot = await db.collection("follows")
      .where("followerId", "==", currentUser.uid)
      .get();
    const followingIds = followingSnapshot.docs.map((doc) => doc.data().followingId);

    // Query users with matching biasIds (limited to first biasId due to Firestore array-contains limitation)
    // In production, you may want to implement a more sophisticated recommendation algorithm
    const usersSnapshot = await db.collection("users")
      .where("biasIds", "array-contains", currentBiasIds[0])
      .limit(limit + followingIds.length + 1) // Get extra to filter out following users
      .get();

    // Filter and score users
    const recommendedUsers = usersSnapshot.docs
      .filter((doc) => {
        const userId = doc.id;
        // Exclude self and already following users
        return userId !== currentUser.uid && !followingIds.includes(userId);
      })
      .map((doc) => {
        const userData = doc.data();
        const userBiasIds = userData.biasIds || [];

        // Calculate match score (number of shared biasIds)
        const sharedBiasIds = currentBiasIds.filter((id: string) => userBiasIds.includes(id));
        const matchScore = sharedBiasIds.length;

        return {
          userId: doc.id,
          displayName: userData.displayName || null,
          photoURL: userData.photoURL || null,
          followersCount: userData.followersCount || 0,
          followingCount: userData.followingCount || 0,
          postsCount: userData.postsCount || 0,
          sharedBiasCount: matchScore,
          sharedBiasIds,
        };
      })
      .sort((a, b) => {
        // Sort by match score (desc), then by followers count (desc)
        if (b.sharedBiasCount !== a.sharedBiasCount) {
          return b.sharedBiasCount - a.sharedBiasCount;
        }
        return b.followersCount - a.followersCount;
      })
      .slice(0, limit);

    res.status(200).json({
      success: true,
      data: {
        users: recommendedUsers,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Get recommended users error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
