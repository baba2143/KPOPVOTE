/**
 * Share task endpoint
 * 新報酬設計: タスク共有報酬（dailyLimit: 3回/日）
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { applyRateLimit, GENERAL_RATE_LIMIT } from "../middleware/rateLimit";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";
import { grantRewardPoints, checkDailyLimit } from "../utils/rewardHelper";

interface ShareTaskRequest {
  taskId: string;
  platform: "twitter" | "instagram" | "line" | "other";
}

interface ShareTaskResponse {
  success: boolean;
  pointsGranted: number;
  dailyShareCount: number;
  dailyLimit: number;
}

export const shareTask = functions
  .runWith(STANDARD_CONFIG)
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
      const { taskId, platform } = req.body as ShareTaskRequest;

      // Validation
      if (!taskId) {
        res.status(400).json({
          success: false,
          error: "taskId is required",
        } as ApiResponse<null>);
        return;
      }

      if (!platform || !["twitter", "instagram", "line", "other"].includes(platform)) {
        res.status(400).json({
          success: false,
          error: "Invalid platform. Must be twitter, instagram, line, or other",
        } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();

      // タスクの存在確認（ユーザーのサブコレクションから取得）
      const taskDoc = await db
        .collection("users")
        .doc(currentUser.uid)
        .collection("tasks")
        .doc(taskId)
        .get();

      if (!taskDoc.exists) {
        res.status(404).json({
          success: false,
          error: "Task not found",
        } as ApiResponse<null>);
        return;
      }

      // サブコレクションなので所有権チェックは不要
      // (自分のサブコレクションからしか取得できないため)

      // デイリーリミットチェック
      const { canGrant, currentCount, limit } = await checkDailyLimit(
        currentUser.uid,
        "task_share"
      );

      if (!canGrant) {
        res.status(200).json({
          success: true,
          data: {
            success: false,
            pointsGranted: 0,
            dailyShareCount: currentCount,
            dailyLimit: limit || 3,
          } as ShareTaskResponse,
        } as ApiResponse<ShareTaskResponse>);
        return;
      }

      // 共有記録を保存
      const shareRef = db.collection("taskShares").doc();
      await shareRef.set({
        id: shareRef.id,
        taskId,
        userId: currentUser.uid,
        platform,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // タスクの共有カウントをインクリメント
      await taskDoc.ref.update({
        sharesCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ポイント付与（単一ポイント制、dailyLimitはrewardHelper内でチェック済み）
      const pointsGranted = await grantRewardPoints(
        currentUser.uid,
        "task_share",
        taskId
      );

      console.log(
        `✅ [shareTask] Task shared: user=${currentUser.uid}, ` +
        `task=${taskId}, platform=${platform}, points=${pointsGranted}`
      );

      res.status(200).json({
        success: true,
        data: {
          success: true,
          pointsGranted,
          dailyShareCount: currentCount + 1,
          dailyLimit: limit || 3,
        } as ShareTaskResponse,
      } as ApiResponse<ShareTaskResponse>);
    } catch (error: unknown) {
      console.error("❌ [shareTask] Error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
