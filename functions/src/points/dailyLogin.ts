/**
 * Daily Login Bonus API
 * デイリーログインボーナス（動的報酬設定対応）
 */

import * as functions from "firebase-functions";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const dailyLogin = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "POST") {
      res.status(405).json({ success: false, error: "Method not allowed. Use POST." } as ApiResponse<null>);
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
      // デイリーログインボーナスは廃止
      // 後方互換性のため、常に0ポイント・機能廃止メッセージを返す
      res.status(200).json({
        success: true,
        data: {
          pointsGranted: 0,
          loginStreak: 0,
          isFirstTimeToday: false,
          message: "デイリーログインボーナスは廃止されました。アクション報酬でポイントを獲得できます。",
        },
      } as ApiResponse<{
        pointsGranted: number;
        loginStreak: number;
        isFirstTimeToday: boolean;
        message: string;
      }>);
    } catch (error: unknown) {
      console.error("Daily login error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
