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
import {
  incrementIdolRankingShardInTransaction,
  idolRankingShardsExist,
} from "../utils/shardedCounter";

const DAILY_VOTE_LIMIT = 5;

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
  // Set CORS headers
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Firebase-AppCheck");
    res.set("Access-Control-Max-Age", "3600");

    // Handle CORS preflight
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

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

      // Check daily vote limit
      const dailyVotesRef = db.collection("idolRankingDailyVotes").doc(`${uid}_${today}`);
      const dailyVotesDoc = await dailyVotesRef.get();
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

      // シャードが存在するかチェック（後方互換性）
      const useShards = await idolRankingShardsExist(db, entityId);

      await db.runTransaction(async (transaction) => {
        const rankingDoc = await transaction.get(rankingRef);

        if (useShards) {
        // シャード化されたランキング: ランダムシャードに書き込み（分散書き込み）
          incrementIdolRankingShardInTransaction(transaction, db, entityId, 1);
          // 親ドキュメントは定期集計関数で更新されるため、ここでは更新しない
          // ただし、親ドキュメントが存在しない場合は作成する
          if (!rankingDoc.exists) {
            transaction.set(rankingRef, {
              entityId,
              entityType,
              name,
              groupName: groupName || null,
              imageUrl: imageUrl || null,
              weeklyVotes: 0, // 集計関数で更新される
              totalVotes: 0, // 集計関数で更新される
              previousRank: null,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        } else {
        // レガシーランキング: 直接親ドキュメントを更新（後方互換性）
          if (rankingDoc.exists) {
          // Update existing ranking
            transaction.update(rankingRef, {
              weeklyVotes: admin.firestore.FieldValue.increment(1),
              totalVotes: admin.firestore.FieldValue.increment(1),
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
          } else {
          // Create new ranking entry
            transaction.set(rankingRef, {
              entityId,
              entityType,
              name,
              groupName: groupName || null,
              imageUrl: imageUrl || null,
              weeklyVotes: 1,
              totalVotes: 1,
              previousRank: null,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }

        // Record individual vote
        const voteRecordRef = db.collection("idolRankingVotes").doc();
        transaction.set(voteRecordRef, {
          oderId: uid,
          entityId,
          entityType,
          name,
          groupName: groupName || null,
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

      // Get updated ranking data
      const updatedRanking = await rankingRef.get();
      const totalVotes = updatedRanking.data()?.totalVotes || 1;
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
