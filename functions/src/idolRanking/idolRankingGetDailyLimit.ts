/**
 * Get vote limit status (based on points balance)
 * Returns user's current points as voting power
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export interface VoteDetail {
  entityId: string;
  entityType: "individual" | "group";
  name: string;
  groupName?: string;
  pointsUsed: number;
  votedAt: string;
}

export interface DailyLimitResponse {
  votesUsed: number; // 今日使った票数（参考情報）
  maxVotes: number; // ポイント残高（実質的な上限）
  remainingVotes: number; // ポイント残高（投票可能数）
  voteDetails: VoteDetail[];
}

export const idolRankingGetDailyLimit = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "GET") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use GET.",
      } as ApiResponse<null>);
      return;
    }

    try {
    // Auth check
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          success: false,
          error: "Unauthorized: No token provided",
        } as ApiResponse<null>);
        return;
      }

      const token = authHeader.split("Bearer ")[1];
      const decodedToken = await admin.auth().verifyIdToken(token);
      const uid = decodedToken.uid;

      const db = admin.firestore();

      // ユーザーのポイント残高を取得
      const userDoc = await db.collection("users").doc(uid).get();
      const userData = userDoc.data();
      const currentPoints = userData?.points || 0;

      // 投票詳細クエリは削除（Firestoreインデックスの問題を回避）
      // ポイント残高のみを返す（これが投票可能数）
      const response: DailyLimitResponse = {
        votesUsed: 0, // 参考情報（詳細が必要な場合は別エンドポイントで）
        maxVotes: currentPoints, // ポイント残高が実質的な上限
        remainingVotes: currentPoints, // ポイント残高 = 投票可能数
        voteDetails: [], // 空配列（詳細が必要な場合は別エンドポイントで）
      };

      res.status(200).json({
        success: true,
        data: response,
      } as ApiResponse<DailyLimitResponse>);
    } catch (error: unknown) {
      console.error("Get daily limit error:", error);
      // Log detailed error information for debugging
      if (error instanceof Error) {
        console.error("Error name:", error.name);
        console.error("Error message:", error.message);
        console.error("Error stack:", error.stack);
      }
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
