/**
 * Execute vote (user votes for a choice)
 * Phase 1: ポイント機能除外版（投票数のみチェック）
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { VoteExecuteRequest, ApiResponse } from "../types";
import { VOTE_WRITE_CONFIG } from "../utils/functionConfig";
import { applyRateLimit, VOTE_RATE_LIMIT } from "../middleware/rateLimit";
import { verifyAppCheck } from "../middleware/appCheck";
// Note: Vote count updates are now handled asynchronously by processVoteCount trigger

interface VoteExecuteRequestExtended extends VoteExecuteRequest {
  voteCount?: number; // 何票投票するか（デフォルト: 1）
}

export const executeVote = functions
  .runWith(VOTE_WRITE_CONFIG)
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Firebase-AppCheck");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ success: false, error: "Method not allowed. Use POST." } as ApiResponse<null>);
      return;
    }

    try {
    // 認証チェック
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({ success: false, error: "Unauthorized: No token provided" } as ApiResponse<null>);
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

      const {
        voteId,
        choiceId,
        voteCount = 1, // デフォルト1票（後方互換性）
      } = req.body as VoteExecuteRequestExtended;

      // バリデーション
      if (!voteId || !choiceId) {
        res.status(400).json({ success: false, error: "voteId and choiceId are required" } as ApiResponse<null>);
        return;
      }

      if (voteCount < 1) {
        res.status(400).json({ success: false, error: "voteCount must be at least 1" } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();
      const voteRef = db.collection("inAppVotes").doc(voteId);
      const voteDoc = await voteRef.get();

      if (!voteDoc.exists) {
        res.status(404).json({ success: false, error: "Vote not found" } as ApiResponse<null>);
        return;
      }

      const voteData = voteDoc.data()!;

      // 動的にステータスを計算
      const now = new Date();
      const startDate = voteData.startDate.toDate();
      const endDate = voteData.endDate.toDate();

      let calculatedStatus: "upcoming" | "active" | "ended" = "upcoming";
      if (now >= startDate) {
        calculatedStatus = "active";
      }
      if (now >= endDate) {
        calculatedStatus = "ended";
      }

      // 投票がアクティブかチェック
      if (calculatedStatus !== "active") {
        const errorMsg = calculatedStatus === "upcoming" ?
          "投票はまだ開始されていません" :
          "投票は終了しました";
        res.status(400).json({ success: false, error: errorMsg } as ApiResponse<null>);
        return;
      }

      // 投票ごとの制限設定
      const restrictions = voteData.restrictions || {};

      // 最小/最大票数チェック
      if (restrictions.minVoteCount && voteCount < restrictions.minVoteCount) {
        res.status(400).json({
          success: false,
          error: `投票数は${restrictions.minVoteCount}票以上である必要があります`,
        } as ApiResponse<null>);
        return;
      }

      if (restrictions.maxVoteCount && voteCount > restrictions.maxVoteCount) {
        res.status(400).json({
          success: false,
          error: `投票数は${restrictions.maxVoteCount}票以下である必要があります`,
        } as ApiResponse<null>);
        return;
      }

      // ユーザー存在チェック
      const userRef = db.collection("users").doc(uid);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
        return;
      }

      // 選択肢存在チェック
      const choiceIndex = voteData.choices.findIndex((c: {choiceId: string}) => c.choiceId === choiceId);
      if (choiceIndex === -1) {
        res.status(400).json({ success: false, error: "Choice not found" } as ApiResponse<null>);
        return;
      }

      // 日次投票履歴取得（常に確認）
      const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
      const dailyVoteHistoryRef = db.collection("dailyVoteHistory").doc(`${voteId}_${uid}_${today}`);
      const dailyVoteHistory = await dailyVoteHistoryRef.get();
      const currentDailyVoteCount = dailyVoteHistory.exists ? (dailyVoteHistory.data()!.voteCount || 0) : 0;

      // 日次投票数制限チェック（設定時のみ適用）
      if (restrictions.dailyVoteLimitPerUser) {
        const newTotalVoteCount = currentDailyVoteCount + voteCount;

        if (newTotalVoteCount > restrictions.dailyVoteLimitPerUser) {
          res.status(400).json({
            success: false,
            error: `本日の投票上限に達しました（1日${restrictions.dailyVoteLimitPerUser}票まで）`,
          } as ApiResponse<null>);
          return;
        }
      }

      // 軽量トランザクション: 履歴記録のみ（投票カウントは非同期で処理）
      // processVoteCount トリガーが voteHistory 作成時にカウント更新を行う
      const batch = db.batch();

      // 投票履歴記録（これがトリガーとなり processVoteCount が実行される）
      const voteHistoryRef = db.collection("voteHistory").doc();
      batch.set(voteHistoryRef, {
        id: voteHistoryRef.id,
        userId: uid,
        voteId,
        voteTitle: voteData.title,
        voteCoverImageUrl: voteData.coverImageUrl || null,
        selectedChoiceId: choiceId,
        selectedChoiceLabel: voteData.choices[choiceIndex].label,
        voteCount,
        votedAt: admin.firestore.FieldValue.serverTimestamp(),
        processed: false, // processVoteCount がカウント更新後に true に設定
      });

      // 日次投票履歴更新（日次制限チェック用 - 即座に反映が必要）
      batch.set(dailyVoteHistoryRef, {
        userId: uid,
        voteId,
        date: today,
        voteCount: admin.firestore.FieldValue.increment(voteCount),
        lastVotedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      await batch.commit();

      // Calculate remaining votes after this vote
      const newDailyVoteCount = currentDailyVoteCount + voteCount;
      const userDailyRemaining = restrictions.dailyVoteLimitPerUser ?
        Math.max(0, restrictions.dailyVoteLimitPerUser - newDailyVoteCount) :
        null;

      console.log(
        `✅ [executeVote] Vote accepted (async): user=${uid}, vote=${voteId}, ` +
      `count=${voteCount}, remaining=${userDailyRemaining}`
      );

      res.status(200).json({
        success: true,
        data: {
          status: "accepted", // 投票は受理され、カウントは非同期で処理される
          voteId,
          choiceId,
          voteCount,
          totalPointsDeducted: 0,
          premiumPointsDeducted: 0,
          regularPointsDeducted: 0,
          // User's daily vote info after this vote
          userDailyVotes: newDailyVoteCount,
          userDailyRemaining,
        },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("❌ [executeVote] Error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
