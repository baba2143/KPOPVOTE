/**
 * Get followers list
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { COMMUNITY_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";
import { batchGetDocs } from "../utils/batchUtils";

export const getFollowers = functions
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
        .where("followingId", "==", userId)
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

      // Step 1: Collect all follower IDs
      const followerIds = follows.map((doc) => doc.data().followerId);

      // Step 2: Batch fetch all user documents
      const userDocs = await batchGetDocs(db, "users", followerIds);

      // Step 3: Batch fetch follow-back status
      const followBackIds = followerIds.map((id) => `${currentUser.uid}_${id}`);
      const followBackDocs = await batchGetDocs(db, "follows", followBackIds);

      // Step 4: Map results (no queries)
      const followers = follows.map((doc) => {
        const followData = doc.data();
        const userDoc = userDocs.get(followData.followerId);
        const userData = userDoc?.exists ? userDoc.data() : null;

        // Check if current user is following this follower back
        const followBackDoc = followBackDocs.get(`${currentUser.uid}_${followData.followerId}`);
        const isFollowingBack = followBackDoc?.exists || false;

        return {
          followId: doc.id,
          userId: followData.followerId,
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
      functions.logger.info("[PERF] getFollowers completed", {
        duration: `${duration}ms`,
        itemCount: followers.length,
      });

      res.status(200).json({
        success: true,
        data: {
          users: followers,
          hasMore,
        },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("Get followers error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
