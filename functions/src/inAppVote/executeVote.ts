/**
 * Execute vote (user votes for a choice)
 * Phase 1: ポイント機能除外版（投票数のみチェック）
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { VoteExecuteRequest, ApiResponse } from "../types";

interface VoteExecuteRequestExtended extends VoteExecuteRequest {
  voteCount?: number; // 何票投票するか（デフォルト: 1）
}

export const executeVote = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

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

    // 投票がアクティブかチェック
    if (voteData.status !== "active") {
      res.status(400).json({ success: false, error: "Vote is not active" } as ApiResponse<null>);
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

    // 投票記録参照
    const voteRecordRef = db.collection("voteRecords").doc(`${voteId}_${uid}`);

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
          error: `1日の投票数制限に達しました（制限: ${restrictions.dailyVoteLimitPerUser}票/日、現在: ${currentDailyVoteCount}票）`,
        } as ApiResponse<null>);
        return;
      }
    }

    // トランザクション実行
    await db.runTransaction(async (transaction) => {
      // 選択肢の投票数更新
      const choices = voteData.choices;
      choices[choiceIndex].voteCount += voteCount;
      transaction.update(voteRef, {
        choices,
        totalVotes: admin.firestore.FieldValue.increment(voteCount),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 投票記録（累積更新 - 同一投票への複数回投票を許可）
      transaction.set(voteRecordRef, {
        voteId,
        userId: uid,
        lastChoiceId: choiceId, // 最後に選択した選択肢
        totalVoteCount: admin.firestore.FieldValue.increment(voteCount), // 累積投票数
        lastVotedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // 投票履歴記録
      const voteHistoryRef = db.collection("voteHistory").doc();
      transaction.set(voteHistoryRef, {
        id: voteHistoryRef.id,
        userId: uid,
        voteId,
        voteTitle: voteData.title,
        voteCoverImageUrl: voteData.coverImageUrl || null,
        selectedChoiceId: choiceId,
        selectedChoiceLabel: choices[choiceIndex].label,
        voteCount,
        votedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 日次投票履歴更新（常に記録 - 日付が変わればリセット）
      transaction.set(dailyVoteHistoryRef, {
        userId: uid,
        voteId,
        date: today,
        voteCount: admin.firestore.FieldValue.increment(voteCount),
        lastVotedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });

    console.log(
      `✅ [executeVote] Vote completed: user=${uid}, vote=${voteId}, count=${voteCount}`,
    );

    res.status(200).json({
      success: true,
      data: {
        voteId,
        choiceId,
        voteCount,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("❌ [executeVote] Error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
