/**
 * Vote for idol ranking
 * Requires authentication, points are consumed per vote (1票 = 1P)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { VOTE_WRITE_CONFIG } from "../utils/functionConfig";
import { applyRateLimit, VOTE_RATE_LIMIT } from "../middleware/rateLimit";
import { verifyAppCheck } from "../middleware/appCheck";
import { idolRankingShardsExist } from "../utils/shardedCounter";
import { handleCors } from "../middleware/cors";
import { deductPoints } from "../utils/rewardHelper";

// アイドルランキング: 1票 = 1ポイント
const POINTS_PER_VOTE = 1;

export interface IdolRankingVoteRequest {
  entityId: string;
  entityType: "individual" | "group";
  name: string;
  groupName?: string;
  imageUrl?: string;
}

export interface IdolRankingVoteResponse {
  success: boolean;
  remainingVotes: number; // 残りポイント（投票可能数）
  totalVotes: number;
  pointsUsed: number; // 消費したポイント
  message: string;
}

export const idolRankingVote = functions
  .runWith(VOTE_WRITE_CONFIG)
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
      const appCheckToken = req.headers["x-firebase-appcheck"] as string | undefined;

      // 認証とAppCheckを並列実行（30-50ms削減）
      const [decodedToken, appCheckFailed] = await Promise.all([
        admin.auth().verifyIdToken(token),
        verifyAppCheck(appCheckToken, res),
      ]);

      if (appCheckFailed) {
        return; // Verification failed, response already sent
      }

      const uid = decodedToken.uid;

      // Rate limit check (30 requests/minute for vote endpoints)
      if (applyRateLimit(uid, res, VOTE_RATE_LIMIT)) {
        return; // Rate limited, response already sent
      }

      const { entityId, entityType, name, groupName, imageUrl } =
      req.body as IdolRankingVoteRequest;

      // Validation
      if (!entityId || !entityType || !name) {
        res.status(400).json({
          success: false,
          error: "entityId, entityType, and name are required",
        } as ApiResponse<null>);
        return;
      }

      if (!["individual", "group"].includes(entityType)) {
        res.status(400).json({
          success: false,
          error: "entityType must be 'individual' or 'group'",
        } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();

      // ポイント消費とシャード確認を並列実行（20-40ms削減）
      const [deductResult, useShards] = await Promise.all([
        deductPoints(
          uid,
          POINTS_PER_VOTE,
          "idol_ranking_vote",
          entityId,
          `アイドルランキング投票: ${name}`,
        ),
        idolRankingShardsExist(db, entityId),
      ]);

      if (!deductResult.success) {
        res.status(400).json({
          success: false,
          error: deductResult.error || "ポイントが不足しています",
        } as ApiResponse<null>);
        return;
      }

      // Transaction to update ranking and record vote
      const rankingRef = db.collection("idolRankings").doc(entityId);

      // Track totalVotes from transaction to avoid extra read
      let totalVotes = 0;

      await db.runTransaction(async (transaction) => {
        const rankingDoc = await transaction.get(rankingRef);

        // Calculate totalVotes within transaction to avoid post-transaction read
        const currentTotalVotes = rankingDoc.exists ?
          (rankingDoc.data()?.totalVotes || 0) : 0;
        totalVotes = currentTotalVotes + 1;

        // ランキングドキュメントの作成/更新（カウント更新はトリガーで処理）
        if (rankingDoc.exists) {
          transaction.update(rankingRef, {
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          // Create new ranking entry (counts will be incremented by trigger)
          transaction.set(rankingRef, {
            entityId,
            entityType,
            name,
            groupName: groupName || null,
            imageUrl: imageUrl || null,
            weeklyVotes: 0, // トリガーでインクリメントされる
            totalVotes: 0, // トリガーでインクリメントされる
            previousRank: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // Record individual vote with useShards flag for trigger optimization
        const voteRecordRef = db.collection("idolRankingVotes").doc();
        transaction.set(voteRecordRef, {
          userId: uid,
          entityId,
          entityType,
          name,
          groupName: groupName || null,
          useShards, // トリガーでシャードチェックを省略するためのフラグ
          pointsUsed: POINTS_PER_VOTE, // 消費したポイントを記録
          votedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // 残りポイント = 投票可能数
      const remainingVotes = deductResult.remainingPoints;

      console.log(
        `[idolRankingVote] Vote recorded: user=${uid}, entity=${entityId}, ` +
        `pointsUsed=${POINTS_PER_VOTE}, remainingPoints=${remainingVotes}`
      );

      res.status(200).json({
        success: true,
        data: {
          success: true,
          remainingVotes,
          totalVotes,
          pointsUsed: POINTS_PER_VOTE,
          message: `投票しました！残り${remainingVotes}P`,
        },
      } as ApiResponse<IdolRankingVoteResponse>);
    } catch (error: unknown) {
      console.error("Idol ranking vote error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
