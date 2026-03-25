/**
 * Get community statistics
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse, CommunityStats } from "../types";
import { verifyTokenAsync, verifyAdminAsync, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const getCommunityStats = functions
  .runWith(ADMIN_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "GET") {
      res.status(405).json({ success: false, error: "Method not allowed. Use GET." } as ApiResponse<null>);
      return;
    }

    // Use async pattern to avoid Promise hanging when auth fails
    const tokenValid = await verifyTokenAsync(req as AuthenticatedRequest, res);
    if (!tokenValid) return;

    const isAdmin = await verifyAdminAsync(req as AuthenticatedRequest, res);
    if (!isAdmin) return;

    try {
      const db = admin.firestore();

      // Get total posts count
      const postsSnapshot = await db.collection("posts").count().get();
      const totalPosts = postsSnapshot.data().count;

      // Get deleted posts count
      const deletedSnapshot = await db.collection("deletedPosts").count().get();
      const deletedPosts = deletedSnapshot.data().count;

      // Get reported posts count from communityReports collection
      const reportedSnapshot = await db.collection("communityReports").count().get();
      const reportedPosts = reportedSnapshot.data().count;

      // Get active users (users who posted in last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const recentPostsSnapshot = await db
        .collection("posts")
        .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .get();

      const activeUserIds = new Set(recentPostsSnapshot.docs.map((doc) => doc.data().userId));
      const activeUsers = activeUserIds.size;

      const stats: CommunityStats = {
        totalPosts,
        deletedPosts,
        reportedPosts,
        activeUsers,
      };

      res.status(200).json({
        success: true,
        data: stats,
      } as ApiResponse<CommunityStats>);
    } catch (error: unknown) {
      console.error("Get community stats error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
