/**
 * Get reported posts with report details
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyTokenAsync, verifyAdminAsync, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const getReportedPosts = functions
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

      // Batch fetch post data
      const postIds = Object.keys(reportsByPostId);
      const postDataMap = new Map<string, admin.firestore.DocumentData | null>();

      for (let i = 0; i < postIds.length; i += 100) {
        const batch = postIds.slice(i, i + 100);
        const refs = batch.map((id) => admin.firestore().collection("posts").doc(id));
        const docs = await admin.firestore().getAll(...refs);
        docs.forEach((doc, index) => {
          postDataMap.set(batch[index], doc.exists ? doc.data()! : null);
        });
      }

      // Map reported posts with post data
      const reportedPosts = postIds.map((postId) => {
        const postData = postDataMap.get(postId);
        return {
          postId,
          userId: postData?.userId || null,
          content: postData?.content?.text || "[削除済み]",
          reportCount: reportsByPostId[postId].count,
          createdAt: postData?.createdAt?.toDate().toISOString() || null,
          reports: reportsByPostId[postId].reports,
        };
      });

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
