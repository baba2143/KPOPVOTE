/**
 * Convert Points API
 * サブスク解約時に赤ポイントを青ポイントに自動変換
 * 変換レート: 5:1 (赤5P → 青1P)
 */

import * as admin from "firebase-admin";
import { PointType } from "../types";

/**
 * ユーザーのサブスク解約時に自動呼び出しされる関数
 * 赤ポイントを青ポイントに変換（5:1レート）
 */
export async function convertPremiumToRegularPoints(userId: string): Promise<void> {
  const db = admin.firestore();
  const userRef = db.collection("users").doc(userId);

  try {
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      console.error(`❌ User not found for conversion: ${userId}`);
      return;
    }

    const userData = userDoc.data()!;
    const premiumPoints = userData.premiumPoints || 0;

    // 赤ポイントがない場合は変換不要
    if (premiumPoints === 0) {
      console.log(`ℹ️ No premium points to convert for user: ${userId}`);
      return;
    }

    // 変換レート: 5:1 (赤5P → 青1P)
    const conversionRate = 5;
    const convertedRegularPoints = Math.floor(premiumPoints / conversionRate);

    // 端数は切り捨て（例: 赤12P → 青2P、赤2Pは失効）
    const pointsLost = premiumPoints % conversionRate;

    // ポイント変換
    await userRef.update({
      premiumPoints: 0,
      regularPoints: admin.firestore.FieldValue.increment(convertedRegularPoints),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // トランザクション記録（赤ポイント減少）
    await db.collection("pointTransactions").add({
      userId,
      pointType: "premium" as PointType,
      points: -premiumPoints,
      type: "subscription_conversion",
      reason: `サブスク解約により赤ポイントを青ポイントに変換（変換レート ${conversionRate}:1）`,
      conversionRate,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // トランザクション記録（青ポイント増加）
    await db.collection("pointTransactions").add({
      userId,
      pointType: "regular" as PointType,
      points: convertedRegularPoints,
      type: "subscription_conversion",
      reason: `赤ポイント${premiumPoints}Pから変換（レート ${conversionRate}:1）`,
      conversionRate,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(
      `✅ Points converted for user ${userId}: ` +
        `${premiumPoints} premium points → ${convertedRegularPoints} regular points ` +
        `(lost ${pointsLost} premium points due to rounding)`
    );
  } catch (error) {
    console.error(`❌ Error converting points for user ${userId}:`, error);
    throw error;
  }
}

/**
 * 手動でのポイント変換をサポート（管理者用）
 * 通常はサブスク解約時に自動実行されるため、直接呼び出すことは少ない
 */
export async function manualConvertPoints(userId: string): Promise<{
  success: boolean;
  premiumPointsConverted: number;
  regularPointsGranted: number;
  conversionRate: number;
  message: string;
}> {
  try {
    const db = admin.firestore();
    const userRef = db.collection("users").doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return {
        success: false,
        premiumPointsConverted: 0,
        regularPointsGranted: 0,
        conversionRate: 5,
        message: "User not found",
      };
    }

    const userData = userDoc.data()!;
    const premiumPoints = userData.premiumPoints || 0;

    if (premiumPoints === 0) {
      return {
        success: false,
        premiumPointsConverted: 0,
        regularPointsGranted: 0,
        conversionRate: 5,
        message: "No premium points to convert",
      };
    }

    // 変換実行
    await convertPremiumToRegularPoints(userId);

    const conversionRate = 5;
    const convertedRegularPoints = Math.floor(premiumPoints / conversionRate);

    return {
      success: true,
      premiumPointsConverted: premiumPoints,
      regularPointsGranted: convertedRegularPoints,
      conversionRate,
      message: `Successfully converted ${premiumPoints} premium points to ${convertedRegularPoints} regular points`,
    };
  } catch (error) {
    console.error("Manual point conversion error:", error);
    return {
      success: false,
      premiumPointsConverted: 0,
      regularPointsGranted: 0,
      conversionRate: 5,
      message: "Conversion failed",
    };
  }
}
