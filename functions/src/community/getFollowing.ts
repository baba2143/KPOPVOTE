/**
 * Get following users list
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { COMMUNITY_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";
import { batchGetDocs } from "../utils/batchUtils";

export const getFollowing = functions
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

      // Step 1: Collect all following user IDs
      const followingIds = follows.map((doc) => doc.data().followingId);

      // Step 2: Batch fetch all user documents
      const userDocs = await batchGetDocs(db, "users", followingIds);

      // Step 3: Batch fetch follow status (only when viewing other user's following list)
      let followDocs = new Map<string, admin.firestore.DocumentSnapshot>();
      if (userId !== currentUser.uid) {
        const followIds = followingIds.map((id) => `${currentUser.uid}_${id}`);
        followDocs = await batchGetDocs(db, "follows", followIds);
      }

      // Step 4: Map results (no queries)
      const followingUsers = follows.map((doc) => {
        const followData = doc.data();
        const userDoc = userDocs.get(followData.followingId);
        const userData = userDoc?.exists ? userDoc.data() : null;

        // Check if current user is following this user (only relevant for other user's list)
        let isFollowingBack = false;
        if (userId !== currentUser.uid) {
          const followDoc = followDocs.get(`${currentUser.uid}_${followData.followingId}`);
          isFollowingBack = followDoc?.exists || false;
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
      });

      const duration = Date.now() - startTime;
      functions.logger.info("[PERF] getFollowing completed", {
        duration: `${duration}ms`,
        itemCount: followingUsers.length,
      });

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
