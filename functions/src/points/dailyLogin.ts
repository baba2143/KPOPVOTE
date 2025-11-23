/**
 * Daily Login Bonus API
 * デイリーログインボーナス（動的報酬設定対応）
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { ApiResponse, DailyLoginResponse, PointType } from "../types";
import { getRewardPoints } from "../utils/rewardHelper";

export const dailyLogin = functions.https.onRequest(async (req, res) => {
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

  await new Promise<void>((resolve, reject) => {
    verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  const currentUser = (req as AuthenticatedRequest).user;
  if (!currentUser) {
    res.status(401).json({ success: false, error: "Unauthorized" } as ApiResponse<null>);
    return;
  }

  try {
    const db = admin.firestore();
    const userRef = db.collection("users").doc(currentUser.uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
      return;
    }

    const userData = userDoc.data()!;
    const isPremium = userData.isPremium || false;
    const lastLoginDate = userData.lastLoginDate?.toDate();
    const currentLoginStreak = userData.loginStreak || 0;
    const now = new Date();

    // 今日の日付を取得（時刻を00:00:00にリセット）
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // 最終ログイン日を取得（時刻を00:00:00にリセット）
    let lastLogin: Date | null = null;
    if (lastLoginDate) {
      lastLogin = new Date(lastLoginDate.getFullYear(), lastLoginDate.getMonth(), lastLoginDate.getDate());
    }

    // 同じ日のログインかチェック
    if (lastLogin && lastLogin.getTime() === today.getTime()) {
      // 今日すでにログインボーナスを受け取っている
      res.status(200).json({
        success: true,
        data: {
          pointsGranted: 0,
          pointType: isPremium ? "premium" : "regular",
          loginStreak: currentLoginStreak,
          isFirstTimeToday: false,
          message: "今日のログインボーナスは受け取り済みです",
        } as DailyLoginResponse,
      } as ApiResponse<DailyLoginResponse>);
      return;
    }

    // 連続ログイン日数を計算
    let newStreak = 1;
    if (lastLogin) {
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);

      if (lastLogin.getTime() === yesterday.getTime()) {
        // 連続ログイン
        newStreak = currentLoginStreak + 1;
      } else {
        // 連続ログイン途切れる
        newStreak = 1;
      }
    }

    // ボーナスポイント計算（rewardSettingsから動的取得）
    const basePoints = await getRewardPoints("daily_login_base");
    let bonusPoints = 0;

    if (newStreak >= 30) {
      bonusPoints = await getRewardPoints("daily_login_streak_30");
    } else if (newStreak >= 14) {
      bonusPoints = await getRewardPoints("daily_login_streak_14");
    } else if (newStreak >= 7) {
      bonusPoints = await getRewardPoints("daily_login_streak_7");
    }

    const totalPoints = basePoints + bonusPoints;
    const pointType: PointType = isPremium ? "premium" : "regular";
    const pointFieldName = isPremium ? "premiumPoints" : "regularPoints";

    // ポイントフィールドの初期化（存在しない場合）
    if (userData[pointFieldName] === undefined) {
      await userRef.update({
        premiumPoints: 0,
        regularPoints: userData.points || 0, // 既存のpointsを青ポイントに移行
      });
    }

    // ポイント付与
    await userRef.update({
      [pointFieldName]: admin.firestore.FieldValue.increment(totalPoints),
      lastLoginDate: admin.firestore.FieldValue.serverTimestamp(),
      loginStreak: newStreak,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // トランザクション記録
    await db.collection("pointTransactions").add({
      userId: currentUser.uid,
      pointType,
      points: totalPoints,
      type: "daily_login",
      reason: newStreak > 1 ?
        `デイリーログインボーナス (${newStreak}日連続)` :
        "デイリーログインボーナス",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(
      `✅ Daily login bonus: ${currentUser.uid}, ${totalPoints}P (${pointType}), streak: ${newStreak}`,
    );

    res.status(200).json({
      success: true,
      data: {
        pointsGranted: totalPoints,
        pointType,
        loginStreak: newStreak,
        isFirstTimeToday: true,
        message: newStreak > 1 ?
          `${totalPoints}P獲得！${newStreak}日連続ログイン中🔥` :
          `${totalPoints}P獲得！`,
      } as DailyLoginResponse,
    } as ApiResponse<DailyLoginResponse>);
  } catch (error: unknown) {
    console.error("Daily login error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
