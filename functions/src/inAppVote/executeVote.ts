/**
 * Execute vote (user votes for a choice)
 * - ポイント消費機能付き
 * - 投票カウントは同期的に更新（即座に反映）
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { VoteExecuteRequest, ApiResponse } from "../types";
import { VOTE_WRITE_CONFIG } from "../utils/functionConfig";
import { applyRateLimit, VOTE_RATE_LIMIT } from "../middleware/rateLimit";
import { verifyAppCheck } from "../middleware/appCheck";
import { handleCors } from "../middleware/cors";
import { deductPointsWithUserData } from "../utils/rewardHelper";
import { shardsExist, incrementVoteShard } from "../utils/shardedCounter";

interface VoteExecuteRequestExtended extends VoteExecuteRequest {
  voteCount?: number; // 何票投票するか（デフォルト: 1）
}

export const executeVote = functions
  .runWith(VOTE_WRITE_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

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

      // 選択肢存在チェック（メモリ内）
      const choiceIndex = voteData.choices.findIndex((c: {choiceId: string}) => c.choiceId === choiceId);
      if (choiceIndex === -1) {
        res.status(400).json({ success: false, error: "Choice not found" } as ApiResponse<null>);
        return;
      }

      // 並列でデータ取得（パフォーマンス最適化）
      const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
      const userRef = db.collection("users").doc(uid);
      const dailyVoteHistoryRef = db.collection("dailyVoteHistory").doc(`${voteId}_${uid}_${today}`);

      const [userDoc, dailyVoteHistory, useShards] = await Promise.all([
        userRef.get(),
        dailyVoteHistoryRef.get(),
        shardsExist(db, voteId),
      ]);

      if (!userDoc.exists) {
        res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
        return;
      }

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

      // ポイント消費計算
      // pointsPerVote（restrictions内）があればそれを使用、なければrequiredPointsを使用
      const pointsPerVote = restrictions.pointsPerVote ?? voteData.requiredPoints ?? 0;
      const totalPointsRequired = voteCount * pointsPerVote;

      // ポイント消費（必要な場合のみ）
      // 軽量版deductPointsWithUserDataを使用（userDoc再取得を省略、100-150ms削減）
      let pointsDeducted = 0;
      if (totalPointsRequired > 0) {
        const userData = userDoc.data()!;
        const currentPoints = userData.points || 0;

        const deductResult = await deductPointsWithUserData(
          uid,
          totalPointsRequired,
          "in_app_vote",
          currentPoints,
          voteId,
          `投票: ${voteData.title}`
        );

        if (!deductResult.success) {
          res.status(400).json({
            success: false,
            error: deductResult.error || "ポイントが不足しています",
          } as ApiResponse<null>);
          return;
        }
        pointsDeducted = deductResult.pointsDeducted;
      }

      // 同期トランザクション: 履歴記録 + 投票カウント更新を同時に実行
      const batch = db.batch();

      // 投票履歴記録
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
        processed: true, // 同期更新のため即座にtrue
      });

      // 日次投票履歴更新（日次制限チェック用）
      batch.set(dailyVoteHistoryRef, {
        userId: uid,
        voteId,
        date: today,
        voteCount: admin.firestore.FieldValue.increment(voteCount),
        lastVotedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // シャード有無は既にPromise.allで取得済み

      if (useShards) {
        // シャードがある場合: バッチコミット後にシャードを更新
        await batch.commit();
        await incrementVoteShard(db, voteId, choiceId, voteCount);
      } else {
        // シャードがない場合: バッチ内で親ドキュメントも更新（1回のコミットで完了）
        // 選択肢の投票数を更新（既存データから計算）
        type Choice = {choiceId: string; voteCount?: number};
        const updatedChoices = voteData.choices.map((choice: Choice, idx: number) => {
          if (idx === choiceIndex) {
            return {
              ...choice,
              voteCount: (choice.voteCount || 0) + voteCount,
            };
          }
          return choice;
        });

        // 1回のupdateに統合（10-20ms削減）
        batch.update(voteRef, {
          totalVotes: admin.firestore.FieldValue.increment(voteCount),
          choices: updatedChoices,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await batch.commit();
      }

      // Calculate remaining votes after this vote
      const newDailyVoteCount = currentDailyVoteCount + voteCount;
      const userDailyRemaining = restrictions.dailyVoteLimitPerUser ?
        Math.max(0, restrictions.dailyVoteLimitPerUser - newDailyVoteCount) :
        null;

      console.log(
        `✅ [executeVote] Vote completed: user=${uid}, vote=${voteId}, ` +
        `choice=${choiceId}, count=${voteCount}, points=${pointsDeducted}, remaining=${userDailyRemaining}`
      );

      res.status(200).json({
        success: true,
        data: {
          status: "completed", // 投票カウントは同期的に更新済み
          voteId,
          choiceId,
          voteCount,
          totalPointsDeducted: pointsDeducted,
          premiumPointsDeducted: 0,
          regularPointsDeducted: pointsDeducted,
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
