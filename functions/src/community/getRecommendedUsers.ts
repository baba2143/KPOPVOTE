/**
 * Get recommended users based on shared bias
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { COMMUNITY_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const getRecommendedUsers = functions
  .runWith(COMMUNITY_CONFIG)
  .https.onRequest(async (req, res) => {
    const startTime = Date.now();

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
      const limit = parseInt(req.query.limit as string) || 10;

      const db = admin.firestore();

      // Get current user's selected idols
      console.log(`🔍 [DEBUG] Current user UID: ${currentUser.uid}`);
      const currentUserDoc = await db.collection("users").doc(currentUser.uid).get();
      const currentUserData = currentUserDoc.data();
      console.log(`🔍 [DEBUG] Current user data exists: ${currentUserDoc.exists}`);
      console.log("🔍 [DEBUG] Current user selectedIdols:", currentUserData?.selectedIdols);

      const selectedIdols = currentUserData?.selectedIdols || [];

      if (selectedIdols.length === 0) {
        console.log(`⚠️ [DEBUG] No selectedIdols found for user ${currentUser.uid}`);
        res.status(200).json({
          success: true,
          data: {
            users: [],
            total: 0,
          },
        } as ApiResponse<unknown>);
        return;
      }

      console.log(`✅ [DEBUG] Searching for users with bias: ${selectedIdols.join(", ")}`);

      // Get users already following
      const followsSnapshot = await db.collection("follows")
        .where("followerId", "==", currentUser.uid)
        .get();
      const followingIds = new Set(followsSnapshot.docs.map((doc) => doc.data().followingId));

      // Get users with shared bias (parallel queries with optimized limit)
      const recommendedUsersMap = new Map();

      // Calculate per-bias limit based on total needed (reduce over-fetching)
      const usersPerBias = Math.max(10, Math.ceil(limit * 3 / selectedIdols.length));

      console.log(`🔍 [DEBUG] Querying ${selectedIdols.length} biases in parallel (${usersPerBias} users each)`);

      // Execute all bias queries in parallel
      const userSnapshots = await Promise.all(
        selectedIdols.map((biasId: string) =>
          db.collection("users")
            .where("selectedIdols", "array-contains", biasId)
            .limit(usersPerBias)
            .get()
            .then((snapshot) => ({ biasId, snapshot }))
        )
      );

      // Process all results
      for (const { biasId, snapshot: usersSnapshot } of userSnapshots) {
        console.log(`🔍 [DEBUG] Found ${usersSnapshot.docs.length} users with bias "${biasId}"`);

        usersSnapshot.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
          const userId = doc.id;
          const data = doc.data();

          // Skip current user and already following
          if (userId === currentUser.uid || followingIds.has(userId)) {
            return;
          }

          const sharedIdols = (data.selectedIdols || []).filter((id: string) =>
            selectedIdols.includes(id)
          );

          // Add or update user with shared idols count
          const existingUser = recommendedUsersMap.get(userId);
          if (!existingUser || existingUser.sharedIdols.length < sharedIdols.length) {
            recommendedUsersMap.set(userId, {
              id: userId,
              displayName: data.displayName || "Unknown",
              photoURL: data.photoURL || null,
              bio: data.bio || null,
              selectedIdols: data.selectedIdols || [],
              sharedIdols,
              followersCount: data.followersCount || 0,
              followingCount: data.followingCount || 0,
              postsCount: data.postsCount || 0,
            });
          }
        });
      }

      // Convert to array and sort by shared idols count
      console.log(`📊 [DEBUG] Total users in map before sorting: ${recommendedUsersMap.size}`);
      const recommendedUsers = Array.from(recommendedUsersMap.values())
        .sort((a, b) => {
        // Sort by shared idols count (descending)
          if (b.sharedIdols.length !== a.sharedIdols.length) {
            return b.sharedIdols.length - a.sharedIdols.length;
          }
          // Then by followers count (descending)
          return b.followersCount - a.followersCount;
        })
        .slice(0, limit);

      console.log(`✅ [DEBUG] Returning ${recommendedUsers.length} recommended users`);
      recommendedUsers.forEach((user) => {
        console.log(`   - ${user.id}: ${user.displayName} (shared: ${user.sharedIdols.join(", ")})`);
      });

      const duration = Date.now() - startTime;
      functions.logger.info("[PERF] getRecommendedUsers completed", {
        duration: `${duration}ms`,
        itemCount: recommendedUsers.length,
      });

      res.status(200).json({
        success: true,
        data: {
          users: recommendedUsers,
          total: recommendedUsers.length,
        },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("Get recommended users error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
