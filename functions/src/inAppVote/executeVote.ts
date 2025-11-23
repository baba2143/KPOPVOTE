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

    // 会員倍率（Premium: 1倍、Free: 5倍）
    const memberMultiplier = isPremium ? 1 : 5;

    // requiredPoints: 投票ごとの基本コスト
    const requiredPoints = voteData.requiredPoints || 0;

    // 基本コスト計算（会員倍率適用前）
    const baseCostPerVote = requiredPoints;
    const totalBaseCost = baseCostPerVote * voteCount;

    // ポイント消費計算
    let premiumUsed = 0;
    let regularUsed = 0;

    if (pointSelection === "premium") {
      // 赤ポイントのみ使用
      premiumUsed = totalBaseCost;

      if (premiumPoints < premiumUsed) {
        res.status(400).json({
          success: false,
          error: `赤ポイントが不足しています（必要: ${premiumUsed}P、保有: ${premiumPoints}P）`,
        } as ApiResponse<null>);
        return;
      }
    } else if (pointSelection === "regular") {
      // 青ポイントのみ使用（会員倍率適用）
      regularUsed = totalBaseCost * memberMultiplier;

      if (regularPoints < regularUsed) {
        res.status(400).json({
          success: false,
          error: `青ポイントが不足しています（必要: ${regularUsed}P、保有: ${regularPoints}P）`,
        } as ApiResponse<null>);
        return;
      }
    } else {
      // 自動選択: 赤ポイント優先 → 足りなければ青ポイント
      premiumUsed = Math.min(totalBaseCost, premiumPoints);
      const remainingBaseCost = totalBaseCost - premiumUsed;

      if (remainingBaseCost > 0) {
        // 残りのコストを青ポイントで賄う（会員倍率適用）
        regularUsed = remainingBaseCost * memberMultiplier;

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
