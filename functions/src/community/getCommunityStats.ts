/**
 * Get community statistics
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse, CommunityStats } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const getCommunityStats = functions.https.onRequest(async (req, res) => {
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

  await new Promise<void>((resolve, reject) => {
    verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  try {
    const db = admin.firestore();

    // Get total posts count
    const postsSnapshot = await db.collection("communityPosts").count().get();
    const totalPosts = postsSnapshot.data().count;

    // Get deleted posts count
    const deletedSnapshot = await db.collection("deletedPosts").count().get();
    const deletedPosts = deletedSnapshot.data().count;

    // Get reported posts count
    const reportedSnapshot = await db
      .collection("communityPosts")
      .where("isReported", "==", true)
      .count()
      .get();
    const reportedPosts = reportedSnapshot.data().count;

    // Get active users (users who posted in last 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const recentPostsSnapshot = await db
      .collection("communityPosts")
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
