/**
 * Get reported posts with report details
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyTokenAsync, verifyAdminAsync, AuthenticatedRequest } from "../middleware/auth";

export const getReportedPosts = functions.https.onRequest(async (req, res) => {
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

  // Use async pattern to avoid Promise hanging when auth fails
  const tokenValid = await verifyTokenAsync(req as AuthenticatedRequest, res);
  if (!tokenValid) return;

  const isAdmin = await verifyAdminAsync(req as AuthenticatedRequest, res);
  if (!isAdmin) return;

  try {
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 50;

    // Get reports from communityReports collection (same pattern as DM reports)
    const reportsSnapshot = await admin
      .firestore()
      .collection("communityReports")
      .orderBy("reportedAt", "desc")
      .limit(limit)
      .get();

    // Group reports by postId
    const reportsByPostId: Record<string, { reports: unknown[]; count: number }> = {};

    reportsSnapshot.docs.forEach((reportDoc) => {
      const reportData = reportDoc.data();
      const postId = reportData.postId;

      if (!reportsByPostId[postId]) {
        reportsByPostId[postId] = { reports: [], count: 0 };
      }

      reportsByPostId[postId].reports.push({
        reportId: reportDoc.id,
        reporterId: reportData.reporterId,
        reason: reportData.reason,
        status: reportData.status || "pending",
        reportedAt: reportData.reportedAt?.toDate().toISOString() || null,
      });
      reportsByPostId[postId].count++;
    });

    // Get post data for each reported post
    const reportedPosts = await Promise.all(
      Object.keys(reportsByPostId).map(async (postId) => {
        const postDoc = await admin.firestore().collection("posts").doc(postId).get();
        const postData = postDoc.data();

        return {
          postId,
          userId: postData?.userId || null,
          content: postData?.content?.text || "[削除済み]",
          reportCount: reportsByPostId[postId].count,
          createdAt: postData?.createdAt?.toDate().toISOString() || null,
          reports: reportsByPostId[postId].reports,
        };
      })
    );

    // Sort by report count (descending)
    reportedPosts.sort((a, b) => b.reportCount - a.reportCount);

    res.status(200).json({
      success: true,
      data: { reportedPosts, count: reportedPosts.length },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Get reported posts error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
