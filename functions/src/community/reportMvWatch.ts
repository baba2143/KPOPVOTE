/**
 * Report MV watch endpoint
 * 新報酬設計: MV視聴報告報酬（dailyLimit: 3回/日）
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { applyRateLimit, GENERAL_RATE_LIMIT } from "../middleware/rateLimit";
import { COMMUNITY_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";
import { grantRewardPoints, checkDailyLimit } from "../utils/rewardHelper";

interface ReportMvWatchRequest {
  postId: string; // MV投稿のID
}

interface ReportMvWatchResponse {
  success: boolean;
  pointsGranted: number;
  dailyWatchCount: number;
  dailyLimit: number;
  alreadyReported: boolean;
}

export const reportMvWatch = functions
  .runWith(COMMUNITY_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "POST") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      } as ApiResponse<null>);
      return;
    }

    await new Promise<void>((resolve, reject) => {
      verifyToken(req as AuthenticatedRequest, res, (error?: unknown) =>
        error ? reject(error) : resolve()
      );
    });

    const currentUser = (req as AuthenticatedRequest).user;
    if (!currentUser) {
      res.status(401).json({
        success: false,
        error: "Unauthorized",
      } as ApiResponse<null>);
      return;
    }

    // Apply rate limiting
    if (applyRateLimit(currentUser.uid, res, GENERAL_RATE_LIMIT)) {
      return; // Rate limited, response already sent
    }

    try {
      const { postId } = req.body as ReportMvWatchRequest;

      // Validation
      if (!postId) {
        res.status(400).json({
          success: false,
          error: "postId is required",
        } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();

      // 投稿の存在確認とMV投稿かチェック
      const postDoc = await db.collection("posts").doc(postId).get();
      if (!postDoc.exists) {
        res.status(404).json({
          success: false,
          error: "Post not found",
        } as ApiResponse<null>);
        return;
      }

      const postData = postDoc.data();
      if (postData?.type !== "music_video") {
        res.status(400).json({
          success: false,
          error: "This post is not a music video",
        } as ApiResponse<null>);
        return;
      }

      // 自分の投稿には報告できない
      if (postData?.userId === currentUser.uid) {
        res.status(400).json({
          success: false,
          error: "Cannot report watching your own video",
        } as ApiResponse<null>);
        return;
      }

      // 同じ投稿への重複報告チェック（今日すでに報告済みか）
      const today = new Date().toISOString().split("T")[0];
      const watchReportId = `${currentUser.uid}_${postId}_${today}`;
      const existingReport = await db.collection("mvWatchReports").doc(watchReportId).get();

      if (existingReport.exists) {
        // デイリーリミット情報を取得して返す
        const { currentCount, limit } = await checkDailyLimit(currentUser.uid, "mv_watch");
        res.status(200).json({
          success: true,
          data: {
            success: false,
            pointsGranted: 0,
            dailyWatchCount: currentCount,
            dailyLimit: limit || 3,
            alreadyReported: true,
          } as ReportMvWatchResponse,
        } as ApiResponse<ReportMvWatchResponse>);
        return;
      }

      // デイリーリミットチェック
      const { canGrant, currentCount, limit } = await checkDailyLimit(
        currentUser.uid,
        "mv_watch"
      );

      if (!canGrant) {
        res.status(200).json({
          success: true,
          data: {
            success: false,
            pointsGranted: 0,
            dailyWatchCount: currentCount,
            dailyLimit: limit || 3,
            alreadyReported: false,
          } as ReportMvWatchResponse,
        } as ApiResponse<ReportMvWatchResponse>);
        return;
      }

      // 視聴報告を記録
      await db.collection("mvWatchReports").doc(watchReportId).set({
        id: watchReportId,
        userId: currentUser.uid,
        postId,
        postAuthorId: postData?.userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 投稿の視聴カウントをインクリメント
      await postDoc.ref.update({
        watchCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ポイント付与（単一ポイント制）
      const pointsGranted = await grantRewardPoints(
        currentUser.uid,
        "mv_watch",
        postId
      );

      console.log(
        `✅ [reportMvWatch] MV watch reported: user=${currentUser.uid}, post=${postId}, points=${pointsGranted}`
      );

      res.status(200).json({
        success: true,
        data: {
          success: true,
          pointsGranted,
          dailyWatchCount: currentCount + 1,
          dailyLimit: limit || 3,
          alreadyReported: false,
        } as ReportMvWatchResponse,
      } as ApiResponse<ReportMvWatchResponse>);
    } catch (error: unknown) {
      console.error("❌ [reportMvWatch] Error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
