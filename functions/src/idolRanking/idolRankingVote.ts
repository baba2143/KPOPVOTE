/**
 * Vote for idol ranking
 * Requires authentication, 5 votes per day limit
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { VOTE_WRITE_CONFIG } from "../utils/functionConfig";
import { applyRateLimit, VOTE_RATE_LIMIT } from "../middleware/rateLimit";
import { verifyAppCheck } from "../middleware/appCheck";
import { idolRankingShardsExist } from "../utils/shardedCounter";
import { handleCors } from "../middleware/cors";

// 投票上限撤廃: 実質無制限（将来的に復活させる可能性を考慮してコード構造は維持）
const DAILY_VOTE_LIMIT = 999999;

export interface IdolRankingVoteRequest {
  entityId: string;
  entityType: "individual" | "group";
  name: string;
  groupName?: string;
  imageUrl?: string;
}

export interface IdolRankingVoteResponse {
  success: boolean;
  remainingVotes: number;
  totalVotes: number;
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
      const decodedToken = await admin.auth().verifyIdToken(token);
      const uid = decodedToken.uid;

      // App Check verification
      const appCheckToken = req.headers["x-firebase-appcheck"] as string | undefined;
      if (await verifyAppCheck(appCheckToken, res)) {
        return; // Verification failed, response already sent
      }

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
      const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD

      // Check daily vote limit and shard existence in parallel (optimization)
      const dailyVotesRef = db.collection("idolRankingDailyVotes").doc(`${uid}_${today}`);
      const [dailyVotesDoc, useShards] = await Promise.all([
        dailyVotesRef.get(),
        idolRankingShardsExist(db, entityId),
      ]);

      const currentVoteCount = dailyVotesDoc.exists ?
        (dailyVotesDoc.data()!.voteCount || 0) :
        0;

      if (currentVoteCount >= DAILY_VOTE_LIMIT) {
        res.status(400).json({
          success: false,
          error: `Daily vote limit reached (${DAILY_VOTE_LIMIT} votes per day)`,
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
          votedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update daily vote count
        transaction.set(
          dailyVotesRef,
          {
            userId: uid,
            date: today,
            voteCount: admin.firestore.FieldValue.increment(1),
            lastVotedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      });

      const remainingVotes = DAILY_VOTE_LIMIT - (currentVoteCount + 1);

      console.log(
        `[idolRankingVote] Vote recorded: user=${uid}, entity=${entityId}, remaining=${remainingVotes}`
      );

      res.status(200).json({
        success: true,
        data: {
          success: true,
          remainingVotes,
          totalVotes,
          message: `Vote recorded. ${remainingVotes} votes remaining today.`,
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
