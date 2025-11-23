/**
 * Reward Helper
 * ポイント報酬システムのヘルパー関数
 */

import * as admin from "firebase-admin";
import { PointType } from "../types";

/**
 * 報酬設定インターフェース
 */
export interface RewardSetting {
  id: string;
  actionType: string;
  basePoints: number;
  description: string;
  isActive: boolean;
  updatedAt: admin.firestore.Timestamp;
}

/**
 * アクションタイプごとの報酬ポイントを取得
 * rewardSettingsコレクションから動的に取得
 */
export async function getRewardPoints(actionType: string): Promise<number> {
  try {
    const db = admin.firestore();
    const settingDoc = await db.collection("rewardSettings").doc(actionType).get();

    if (!settingDoc.exists) {
      console.warn(`⚠️ [rewardHelper] Reward setting not found: ${actionType}, using default`);
      return getDefaultRewardPoints(actionType);
    }

    const settingData = settingDoc.data() as RewardSetting;

    if (!settingData.isActive) {
      console.log(`ℹ️ [rewardHelper] Reward is inactive: ${actionType}`);
      return 0;
    }

    return settingData.basePoints;
  } catch (error) {
    console.error(`❌ [rewardHelper] Error getting reward points for ${actionType}:`, error);
    return getDefaultRewardPoints(actionType);
  }
}

/**
 * デフォルトの報酬ポイント（rewardSettingsが存在しない場合のフォールバック）
 */
function getDefaultRewardPoints(actionType: string): number {
  const defaults: { [key: string]: number } = {
    task_completion: 50,
    daily_login_base: 10,
    daily_login_streak_7: 5,
    daily_login_streak_14: 10,
    daily_login_streak_30: 20,
    community_post: 5,
    community_like: 1,
    community_comment: 2,
  };

  return defaults[actionType] || 0;
}

/**
 * ユーザーに報酬ポイントを付与
 *
 * @param userId ユーザーID
 * @param actionType アクションタイプ
 * @param isPremium サブスク会員かどうか
 * @param relatedId 関連ID（投稿ID、タスクIDなど）
 * @returns 付与されたポイント数
 */
export async function grantRewardPoints(
  userId: string,
  actionType: string,
  isPremium: boolean,
  relatedId?: string,
): Promise<number> {
  try {
    // 報酬ポイント取得
    const points = await getRewardPoints(actionType);

    if (points === 0) {
      console.log(`ℹ️ [rewardHelper] No reward points for action: ${actionType}`);
      return 0;
    }

    // ポイントタイプ決定（サブスク会員=赤、非会員=青）
    const pointType: PointType = isPremium ? "premium" : "regular";
    const pointFieldName = isPremium ? "premiumPoints" : "regularPoints";

    const db = admin.firestore();
    const userRef = db.collection("users").doc(userId);

    // ユーザー存在確認
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      console.error(`❌ [rewardHelper] User not found: ${userId}`);
      return 0;
    }

    const userData = userDoc.data()!;

    // ポイントフィールドの初期化（存在しない場合）
    if (userData[pointFieldName] === undefined) {
      await userRef.update({
        premiumPoints: 0,
        regularPoints: userData.points || 0, // 既存のpointsを青ポイントに移行
      });
    }

    // ポイント付与
    await userRef.update({
      [pointFieldName]: admin.firestore.FieldValue.increment(points),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // トランザクション記録
    await db.collection("pointTransactions").add({
      userId,
      pointType,
      points,
      type: actionType,
      reason: getReasonText(actionType),
      relatedId: relatedId || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(
      `✅ [rewardHelper] Granted ${points}P (${pointType}) to user ${userId} for ${actionType}`,
    );

    return points;
  } catch (error) {
    console.error("❌ [rewardHelper] Error granting reward points:", error);
    return 0;
  }
}

/**
 * アクションタイプに応じた理由テキストを取得
 */
function getReasonText(actionType: string): string {
  const reasons: { [key: string]: string } = {
    task_completion: "タスク完了報酬",
    daily_login_base: "デイリーログインボーナス",
    daily_login_streak_7: "7日連続ログインボーナス",
    daily_login_streak_14: "14日連続ログインボーナス",
    daily_login_streak_30: "30日連続ログインボーナス",
    community_post: "投稿作成報酬",
    community_like: "いいね獲得報酬",
    community_comment: "コメント投稿報酬",
  };

  return reasons[actionType] || actionType;
}

/**
 * 初期報酬設定データをFirestoreに投入（セットアップ用）
 */
export async function seedRewardSettings(): Promise<void> {
  const db = admin.firestore();
  const batch = db.batch();

  const settings: Omit<RewardSetting, "id" | "updatedAt">[] = [
    {
      actionType: "task_completion",
      basePoints: 50,
      description: "外部投票タスク完了",
      isActive: true,
    },
    {
      actionType: "daily_login_base",
      basePoints: 10,
      description: "デイリーログイン基本報酬",
      isActive: true,
    },
    {
      actionType: "daily_login_streak_7",
      basePoints: 5,
      description: "7日連続ログインボーナス",
      isActive: true,
    },
    {
      actionType: "daily_login_streak_14",
      basePoints: 10,
      description: "14日連続ログインボーナス",
      isActive: true,
    },
    {
      actionType: "daily_login_streak_30",
      basePoints: 20,
      description: "30日連続ログインボーナス",
      isActive: true,
    },
    {
      actionType: "community_post",
      basePoints: 5,
      description: "投稿作成報酬",
      isActive: true,
    },
    {
      actionType: "community_like",
      basePoints: 1,
      description: "いいね獲得報酬",
      isActive: true,
    },
    {
      actionType: "community_comment",
      basePoints: 2,
      description: "コメント投稿報酬",
      isActive: true,
    },
  ];

  settings.forEach((setting) => {
    const docRef = db.collection("rewardSettings").doc(setting.actionType);
    batch.set(docRef, {
      ...setting,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();
  console.log("✅ [rewardHelper] Reward settings seeded successfully");
}
