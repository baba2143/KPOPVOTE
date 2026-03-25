/**
 * Get following users sorted by activity (latest post)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { COMMUNITY_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

interface UserActivity {
  id: string;
  displayName: string;
  photoURL: string | null;
  bio: string | null;
  selectedIdols: string[];
  followersCount: number;
  followingCount: number;
  postsCount: number;
  latestPostAt: string | null;
  hasNewPost: boolean; // Posted in last 24 hours
}

export const getFollowingActivity = functions
  .runWith(COMMUNITY_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

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
      const limit = parseInt(req.query.limit as string) || 20;

      const db = admin.firestore();

      // Get following users
      const followsSnapshot = await db.collection("follows")
        .where("followerId", "==", currentUser.uid)
        .get();

      if (followsSnapshot.empty) {
        res.status(200).json({
          success: true,
          data: {
            users: [],
            total: 0,
          },
        } as ApiResponse<unknown>);
        return;
      }

      const followingIds = followsSnapshot.docs.map((doc) => doc.data().followingId);

      // Get user data (includes latestPostAt if available)
      const now = new Date();
      const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

      // Batch fetch user data (N+1 → 1 query)
      // Users should have latestPostAt field updated when they create a post
      const userRefs = followingIds.map((id) => db.collection("users").doc(id));
      const userDocs = await db.getAll(...userRefs);
      const userDataMap = new Map(
        userDocs.filter((d) => d.exists).map((d) => [d.id, d.data()!])
      );

      // Check if we need to fetch latest posts (fallback for users without latestPostAt)
      const usersNeedingLatestPost = followingIds.filter((userId) => {
        const userData = userDataMap.get(userId);
        return userData && userData.latestPostAt === undefined;
      });

      // Only fetch latest posts for users who don't have latestPostAt field (legacy users)
      // This dramatically reduces queries from N → only legacy users count
      const latestPostMap = new Map<string, Date | null>();

      if (usersNeedingLatestPost.length > 0) {
        // Parallel fetch latest posts only for users without latestPostAt
        const latestPostPromises = usersNeedingLatestPost.map((userId) =>
          db.collection("posts")
            .where("userId", "==", userId)
            .orderBy("createdAt", "desc")
            .limit(1)
            .get()
        );
        const latestPostSnapshots = await Promise.all(latestPostPromises);

        usersNeedingLatestPost.forEach((userId, i) => {
          const snapshot = latestPostSnapshots[i];
          if (snapshot.empty) {
            latestPostMap.set(userId, null);
          } else {
            const latestPost = snapshot.docs[0].data();
            latestPostMap.set(userId, latestPost.createdAt?.toDate() || null);
          }
        });
      }

      // Build user activities using pre-fetched data
      const userActivities: UserActivity[] = [];
      for (const userId of followingIds) {
        const userData = userDataMap.get(userId);
        if (!userData) continue;

        // Use latestPostAt from user document if available, otherwise from fetched post
        let latestPostAt: Date | null = null;
        if (userData.latestPostAt) {
          const postAt = userData.latestPostAt;
          latestPostAt = postAt.toDate ? postAt.toDate() : new Date(postAt);
        } else {
          latestPostAt = latestPostMap.get(userId) || null;
        }

        const hasNewPost = latestPostAt ? latestPostAt >= oneDayAgo : false;

        userActivities.push({
          id: userId,
          displayName: userData.displayName || "Unknown",
          photoURL: userData.photoURL || null,
          bio: userData.bio || null,
          selectedIdols: userData.selectedIdols || [],
          followersCount: userData.followersCount || 0,
          followingCount: userData.followingCount || 0,
          postsCount: userData.postsCount || 0,
          latestPostAt: latestPostAt?.toISOString() || null,
          hasNewPost,
        });
      }

      // Sort by latest post (most recent first)
      userActivities.sort((a, b) => {
        if (!a.latestPostAt && !b.latestPostAt) return 0;
        if (!a.latestPostAt) return 1;
        if (!b.latestPostAt) return -1;
        return new Date(b.latestPostAt).getTime() - new Date(a.latestPostAt).getTime();
      });

      const users = userActivities.slice(0, limit);

      res.status(200).json({
        success: true,
        data: {
          users,
          total: users.length,
        },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("Get following activity error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
