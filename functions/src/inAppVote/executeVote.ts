/**
 * Execute vote (user votes for a choice)
 * 複数ポイントシステム対応版
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { VoteExecuteRequest, ApiResponse, PointType } from "../types";

interface VoteExecuteRequestExtended extends VoteExecuteRequest {
  voteCount?: number; // 何票投票するか（デフォルト: 1）
  pointSelection?: "auto" | "premium" | "regular"; // ポイント選択モード（デフォルト: "auto"）
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
      pointSelection = "auto", // デフォルト自動選択
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

    if (!["auto", "premium", "regular"].includes(pointSelection)) {
      res.status(400).json({ success: false, error: "Invalid pointSelection" } as ApiResponse<null>);
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

    // 🆕 投票ごとの制限設定
    const restrictions = voteData.restrictions || {};

    // 🆕 最小/最大票数チェック
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

    // ユーザー情報取得
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
      return;
    }

    const userData = userDoc.data()!;
    const isPremium = userData.isPremium || false;

    // ポイントフィールドの初期化（存在しない場合）
    if (userData.premiumPoints === undefined || userData.regularPoints === undefined) {
      await userRef.update({
        premiumPoints: 0,
        regularPoints: userData.points || 0, // 既存のpointsを青ポイントに移行
      });
      // 再取得
      const updatedUserDoc = await userRef.get();
      Object.assign(userData, updatedUserDoc.data());
    }

    const premiumPoints = userData.premiumPoints || 0;
    const regularPoints = userData.regularPoints || 0;

    // 🆕 カスタムポイントコスト（restrictions設定優先、なければデフォルト）
    const premiumPointsPerVote = restrictions.premiumPointsPerVote !== undefined ?
      restrictions.premiumPointsPerVote :
      (voteData.requiredPoints || 1); // デフォルト: 1P/票

    const regularPointsPerVote = restrictions.regularPointsPerVote !== undefined ?
      restrictions.regularPointsPerVote :
      (isPremium ? (voteData.requiredPoints || 1) : (voteData.requiredPoints || 5)); // デフォルト: Premium 1P, Free 5P

    // 基本コスト計算
    const totalPremiumCost = premiumPointsPerVote * voteCount;
    const totalRegularCost = regularPointsPerVote * voteCount;

    // ポイント消費計算（カスタムレート対応）
    let premiumUsed = 0;
    let regularUsed = 0;

    if (pointSelection === "premium") {
      // 赤ポイントのみ使用
      premiumUsed = totalPremiumCost;

      if (premiumPoints < premiumUsed) {
        res.status(400).json({
          success: false,
          error: `赤ポイントが不足しています（必要: ${premiumUsed}P、保有: ${premiumPoints}P）`,
        } as ApiResponse<null>);
        return;
      }
    } else if (pointSelection === "regular") {
      // 青ポイントのみ使用
      regularUsed = totalRegularCost;

      if (regularPoints < regularUsed) {
        res.status(400).json({
          success: false,
          error: `青ポイントが不足しています（必要: ${regularUsed}P、保有: ${regularPoints}P）`,
        } as ApiResponse<null>);
        return;
      }
    } else {
      // 自動選択: 赤ポイント優先 → 足りなければ青ポイント
      premiumUsed = Math.min(totalPremiumCost, premiumPoints);
      const remainingVoteCount = voteCount - Math.floor(premiumUsed / premiumPointsPerVote);

      if (remainingVoteCount > 0) {
        // 残りの投票を青ポイントで賄う
        regularUsed = remainingVoteCount * regularPointsPerVote;

        if (regularPoints < regularUsed) {
          res.status(400).json({
            success: false,
            error: `ポイントが不足しています（赤: ${premiumPoints}P、青: ${regularPoints}P）`,
          } as ApiResponse<null>);
          return;
        }
      }
    }

    // 選択肢存在チェック
    const choiceIndex = voteData.choices.findIndex((c: {choiceId: string}) => c.choiceId === choiceId);
    if (choiceIndex === -1) {
      res.status(400).json({ success: false, error: "Choice not found" } as ApiResponse<null>);
      return;
    }

    // 重複投票チェック
    const voteRecordRef = db.collection("voteRecords").doc(`${voteId}_${uid}`);
    const voteRecord = await voteRecordRef.get();

    if (voteRecord.exists) {
      res.status(400).json({ success: false, error: "Already voted" } as ApiResponse<null>);
      return;
    }

    // 🆕 日次投票数制限チェック
    if (restrictions.dailyVoteLimitPerUser) {
      const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
      const dailyVoteHistoryRef = db.collection("dailyVoteHistory").doc(`${voteId}_${uid}_${today}`);
      const dailyVoteHistory = await dailyVoteHistoryRef.get();

      const currentDailyVoteCount = dailyVoteHistory.exists ? (dailyVoteHistory.data()!.voteCount || 0) : 0;
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
      // ポイント消費
      const updates: {[key: string]: admin.firestore.FieldValue} = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (premiumUsed > 0) {
        updates.premiumPoints = admin.firestore.FieldValue.increment(-premiumUsed);
      }
      if (regularUsed > 0) {
        updates.regularPoints = admin.firestore.FieldValue.increment(-regularUsed);
      }

      transaction.update(userRef, updates);

      // 選択肢の投票数更新
      const choices = voteData.choices;
      choices[choiceIndex].voteCount += voteCount; // 複数票対応
      transaction.update(voteRef, {
        choices,
        totalVotes: admin.firestore.FieldValue.increment(voteCount),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 投票記録
      transaction.set(voteRecordRef, {
        voteId,
        userId: uid,
        choiceId,
        voteCount, // 🆕 投票数記録
        premiumPointsUsed: premiumUsed, // 🆕 赤ポイント使用量
        regularPointsUsed: regularUsed, // 🆕 青ポイント使用量
        votedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

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
        voteCount, // 🆕 投票数
        pointsUsed: premiumUsed + regularUsed, // 合計消費ポイント
        premiumPointsUsed: premiumUsed, // 🆕
        regularPointsUsed: regularUsed, // 🆕
        votedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // ポイントトランザクション記録（赤ポイント）
      if (premiumUsed > 0) {
        const premiumTxnRef = db.collection("pointTransactions").doc();
        transaction.set(premiumTxnRef, {
          userId: uid,
          pointType: "premium" as PointType,
          points: -premiumUsed,
          type: "vote",
          reason: `投票: ${voteData.title}`,
          relatedId: voteId,
          voteCount,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // ポイントトランザクション記録（青ポイント）
      if (regularUsed > 0) {
        const regularTxnRef = db.collection("pointTransactions").doc();
        transaction.set(regularTxnRef, {
          userId: uid,
          pointType: "regular" as PointType,
          points: -regularUsed,
          type: "vote",
          reason: `投票: ${voteData.title}`,
          relatedId: voteId,
          voteCount,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // 🆕 日次投票履歴更新（dailyVoteLimitPerUser設定時のみ）
      if (restrictions.dailyVoteLimitPerUser) {
        const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
        const dailyVoteHistoryRef = db.collection("dailyVoteHistory").doc(`${voteId}_${uid}_${today}`);
        transaction.set(dailyVoteHistoryRef, {
          userId: uid,
          voteId,
          date: today,
          voteCount: admin.firestore.FieldValue.increment(voteCount),
          lastVotedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true }); // merge: true で既存ドキュメントがあれば更新、なければ作成
      }
    });

    console.log(
      `✅ [executeVote] Vote completed: user=${uid}, vote=${voteId}, ` +
        `count=${voteCount}, premium=${premiumUsed}P, regular=${regularUsed}P`,
    );

    res.status(200).json({
      success: true,
      data: {
        voteId,
        choiceId,
        voteCount,
        premiumPointsDeducted: premiumUsed,
        regularPointsDeducted: regularUsed,
        totalPointsDeducted: premiumUsed + regularUsed,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("❌ [executeVote] Error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
