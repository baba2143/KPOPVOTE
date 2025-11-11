/**
 * Get reported posts with report details
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

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

  await new Promise<void>((resolve, reject) => {
    verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  await new Promise<void>((resolve, reject) => {
    verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  try {
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 50;

    // Get reported posts
    const postsSnapshot = await admin
      .firestore()
      .collection("communityPosts")
      .where("isReported", "==", true)
      .orderBy("reportCount", "desc")
      .limit(limit)
      .get();

    const reportedPosts = await Promise.all(
      postsSnapshot.docs.map(async (postDoc) => {
        const postData = postDoc.data();

        // Get reports for this post
        const reportsSnapshot = await admin
          .firestore()
          .collection("communityReports")
          .where("postId", "==", postDoc.id)
          .orderBy("reportedAt", "desc")
          .limit(10)
          .get();

        const reports = reportsSnapshot.docs.map((reportDoc) => {
          const reportData = reportDoc.data();
          return {
            reportId: reportDoc.id,
            reporterId: reportData.reporterId,
            reason: reportData.reason,
            reportedAt: reportData.reportedAt?.toDate().toISOString() || null,
          };
        });

        return {
          postId: postDoc.id,
          userId: postData.userId,
          content: postData.content,
          reportCount: postData.reportCount || 0,
          createdAt: postData.createdAt?.toDate().toISOString() || null,
          reports,
        };
      })
    );

    res.status(200).json({
      success: true,
      data: { reportedPosts, count: reportedPosts.length },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Get reported posts error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
