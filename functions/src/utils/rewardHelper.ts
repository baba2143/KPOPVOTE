/**
 * Reward Helper
 * ポイント報酬システムのヘルパー関数
 * 新報酬設計（2024/02）: デイリーログイン廃止、アクション報酬重視
 */

import * as admin from "firebase-admin";

/**
 * 報酬設定インターフェース（dailyLimit対応）
 */
export interface RewardSetting {
  id: string;
  actionType: string;
  basePoints: number;
  description: string;
  isActive: boolean;
  dailyLimit?: number; // 1日あたりの回数制限（省略時は無制限）
  updatedAt: admin.firestore.Timestamp;
}

/**
 * デイリーカウントの取得キーを生成
 */
function getDailyCountKey(userId: string, actionType: string): string {
  const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
  return `${userId}_${actionType}_${today}`;
}

/**
 * アクションのデイリーカウントを取得
 */
async function getDailyActionCount(userId: string, actionType: string): Promise<number> {
  const db = admin.firestore();
  const key = getDailyCountKey(userId, actionType);
  const countDoc = await db.collection("dailyActionCounts").doc(key).get();

  if (!countDoc.exists) {
    return 0;
  }

  return countDoc.data()?.count || 0;
}

/**
 * アクションのデイリーカウントをインクリメント
 */
async function incrementDailyActionCount(userId: string, actionType: string): Promise<void> {
  const db = admin.firestore();
  const key = getDailyCountKey(userId, actionType);

  await db.collection("dailyActionCounts").doc(key).set(
    {
      userId,
      actionType,
      count: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

/**
 * アクションタイプごとの報酬設定を取得
 * rewardSettingsコレクションから動的に取得
 */
export async function getRewardSetting(actionType: string): Promise<RewardSetting | null> {
  try {
    const db = admin.firestore();
    const settingDoc = await db.collection("rewardSettings").doc(actionType).get();

    if (!settingDoc.exists) {
      console.warn(`⚠️ [rewardHelper] Reward setting not found: ${actionType}`);
      return null;
    }

    return settingDoc.data() as RewardSetting;
  } catch (error) {
    console.error(`❌ [rewardHelper] Error getting reward setting for ${actionType}:`, error);
    return null;
  }
}

/**
 * アクションタイプごとの報酬ポイントを取得
 * rewardSettingsコレクションから動的に取得
 */
export async function getRewardPoints(actionType: string): Promise<number> {
  try {
    const setting = await getRewardSetting(actionType);

    if (!setting) {
      return getDefaultRewardPoints(actionType);
    }

    if (!setting.isActive) {
      console.log(`ℹ️ [rewardHelper] Reward is inactive: ${actionType}`);
      return 0;
    }

    return setting.basePoints;
  } catch (error) {
    console.error(`❌ [rewardHelper] Error getting reward points for ${actionType}:`, error);
    return getDefaultRewardPoints(actionType);
  }
}

/**
 * デフォルトの報酬ポイント（新報酬設計対応）
 */
function getDefaultRewardPoints(actionType: string): number {
  const defaults: { [key: string]: number } = {
    // 投票系（高報酬）
    task_registration: 10,
    task_completion: 10,
    task_share: 5,

    // コンテンツ系（中報酬）
    post_mv: 5,
    mv_watch: 2,
    collection_create: 10,
    post_image: 3,
    post_goods_exchange: 5,

    // コミュニティ系（低報酬） - する側
    post_text: 2,
    community_like: 1,
    community_comment: 2,
    follow_user: 3,

    // コミュニティ系 - される側（双方向報酬）
    received_like: 1,
    received_comment: 1,
    received_follow: 2,

    // 特別報酬
    friend_invite: 50,

    // 後方互換性のため残す（廃止）
    community_post: 0, // 投稿タイプ別に分離したため
    daily_login_base: 0,
    daily_login_streak_7: 0,
    daily_login_streak_14: 0,
    daily_login_streak_30: 0,
  };

  return defaults[actionType] || 0;
}

/**
 * デフォルトのデイリーリミット（新報酬設計対応）
 */
function getDefaultDailyLimit(actionType: string): number | undefined {
  const limits: { [key: string]: number } = {
    // する側
    task_share: 3,
    mv_watch: 3,
    community_like: 10,
    community_comment: 10,
    follow_user: 5,

    // される側（双方向報酬）
    received_like: 50,
    received_comment: 30,
    received_follow: 20,
  };

  return limits[actionType];
}

/**
 * デイリーリミットをチェック
 * @returns true = 付与可能、false = リミット到達
 */
export async function checkDailyLimit(
  userId: string,
  actionType: string,
): Promise<{ canGrant: boolean; currentCount: number; limit: number | undefined }> {
  const setting = await getRewardSetting(actionType);
  const limit = setting?.dailyLimit ?? getDefaultDailyLimit(actionType);

  if (limit === undefined) {
    return { canGrant: true, currentCount: 0, limit: undefined };
  }

  const currentCount = await getDailyActionCount(userId, actionType);
  const canGrant = currentCount < limit;

  return { canGrant, currentCount, limit };
}

/**
 * ユーザーに報酬ポイントを付与（dailyLimit対応）
 * 単一ポイント制: isPremiumは廃止、統一されたpointsフィールドに付与
 *
 * @param userId ユーザーID
 * @param actionType アクションタイプ
 * @param relatedId 関連ID（投稿ID、タスクIDなど）
 * @returns 付与されたポイント数（リミット超過時は0）
 */
export async function grantRewardPoints(
  userId: string,
  actionType: string,
  relatedId?: string,
): Promise<number> {
  try {
    // デイリーリミットチェック
    const { canGrant, currentCount, limit } = await checkDailyLimit(userId, actionType);

    if (!canGrant) {
      console.log(
        `ℹ️ [rewardHelper] Daily limit reached for ${actionType}: ${currentCount}/${limit}`,
      );
      return 0;
    }

    // 報酬ポイント取得
    const points = await getRewardPoints(actionType);

    if (points === 0) {
      console.log(`ℹ️ [rewardHelper] No reward points for action: ${actionType}`);
      return 0;
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(userId);

    // ユーザー存在確認
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      console.error(`❌ [rewardHelper] User not found: ${userId}`);
      return 0;
    }

    // ポイント付与（単一フィールド）
    await userRef.update({
      points: admin.firestore.FieldValue.increment(points),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // トランザクション記録
    await db.collection("pointTransactions").add({
      userId,
      points,
      type: actionType,
      reason: getReasonText(actionType),
      relatedId: relatedId || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // デイリーカウントをインクリメント（リミットありの場合）
    if (limit !== undefined) {
      await incrementDailyActionCount(userId, actionType);
    }

    console.log(
      `✅ [rewardHelper] Granted ${points}P to user ${userId} for ${actionType}`,
    );

    return points;
  } catch (error) {
    console.error("❌ [rewardHelper] Error granting reward points:", error);
    return 0;
  }
}

/**
 * ポイント消費結果インターフェース
 */
export interface DeductPointsResult {
  success: boolean;
  pointsDeducted: number;
  remainingPoints: number;
  error?: string;
}

/**
 * ユーザーのポイントを消費する（投票などに使用）
 *
 * @param userId ユーザーID
 * @param points 消費するポイント数（正の数で指定）
 * @param actionType アクションタイプ（例: "idol_ranking_vote", "in_app_vote"）
 * @param relatedId 関連ID（投票先のentityIdなど）
 * @param reason 理由テキスト
 * @returns 消費結果
 */
export async function deductPoints(
  userId: string,
  points: number,
  actionType: string,
  relatedId?: string,
  reason?: string,
): Promise<DeductPointsResult> {
  try {
    if (points <= 0) {
      return {
        success: false,
        pointsDeducted: 0,
        remainingPoints: 0,
        error: "ポイント数は正の数である必要があります",
      };
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      return {
        success: false,
        pointsDeducted: 0,
        remainingPoints: 0,
        error: "ユーザーが見つかりません",
      };
    }

    const userData = userDoc.data()!;
    return deductPointsWithUserData(userId, points, actionType, userData.points || 0, relatedId, reason);
  } catch (error) {
    console.error("❌ [rewardHelper] Error deducting points:", error);
    return {
      success: false,
      pointsDeducted: 0,
      remainingPoints: 0,
      error: "ポイント消費中にエラーが発生しました",
    };
  }
}

/**
 * ユーザーのポイントを消費する（軽量版 - userDataを再取得しない）
 * executeVoteなど、既にuserDocを取得している場合に使用
 *
 * @param userId ユーザーID
 * @param points 消費するポイント数（正の数で指定）
 * @param actionType アクションタイプ
 * @param currentPoints 現在のポイント数（呼び出し元で取得済み）
 * @param relatedId 関連ID
 * @param reason 理由テキスト
 * @returns 消費結果
 */
export async function deductPointsWithUserData(
  userId: string,
  points: number,
  actionType: string,
  currentPoints: number,
  relatedId?: string,
  reason?: string,
): Promise<DeductPointsResult> {
  try {
    if (points <= 0) {
      return {
        success: false,
        pointsDeducted: 0,
        remainingPoints: 0,
        error: "ポイント数は正の数である必要があります",
      };
    }

    // ポイント残高チェック
    if (currentPoints < points) {
      return {
        success: false,
        pointsDeducted: 0,
        remainingPoints: currentPoints,
        error: `ポイントが不足しています（現在: ${currentPoints}P、必要: ${points}P）`,
      };
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(userId);

    // ポイント消費（負の値でインクリメント）
    await userRef.update({
      points: admin.firestore.FieldValue.increment(-points),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // トランザクション記録は非同期（fire-and-forget）で実行してレスポンスをブロックしない
    db.collection("pointTransactions").add({
      userId,
      points: -points,
      type: actionType,
      reason: reason || getDeductReasonText(actionType),
      relatedId: relatedId || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }).catch((err) => console.error("❌ [rewardHelper] Failed to record transaction:", err));

    const remainingPoints = currentPoints - points;

    console.log(
      `✅ [rewardHelper] Deducted ${points}P from user ${userId} for ${actionType}, remaining: ${remainingPoints}P`,
    );

    return {
      success: true,
      pointsDeducted: points,
      remainingPoints,
    };
  } catch (error) {
    console.error("❌ [rewardHelper] Error deducting points:", error);
    return {
      success: false,
      pointsDeducted: 0,
      remainingPoints: 0,
      error: "ポイント消費中にエラーが発生しました",
    };
  }
}

/**
 * ポイント消費アクションタイプに応じた理由テキストを取得
 */
function getDeductReasonText(actionType: string): string {
  const reasons: { [key: string]: string } = {
    idol_ranking_vote: "アイドルランキング投票",
    in_app_vote: "アプリ内投票",
  };

  return reasons[actionType] || `${actionType}によるポイント消費`;
}

/**
 * アクションタイプに応じた理由テキストを取得（新報酬設計対応）
 */
function getReasonText(actionType: string): string {
  const reasons: { [key: string]: string } = {
    // 投票系
    task_registration: "タスク登録報酬",
    task_completion: "タスク完了報酬",
    task_share: "タスク共有報酬",

    // コンテンツ系
    post_mv: "MV投稿報酬",
    mv_watch: "MV視聴報酬",
    collection_create: "コレクション作成報酬",
    post_image: "画像投稿報酬",
    post_goods_exchange: "グッズ交換投稿報酬",

    // コミュニティ系 - する側
    post_text: "テキスト投稿報酬",
    community_like: "いいね報酬",
    community_comment: "コメント報酬",
    follow_user: "フォロー報酬",

    // コミュニティ系 - される側（双方向報酬）
    received_like: "いいね獲得報酬",
    received_comment: "コメント獲得報酬",
    received_follow: "フォロワー獲得報酬",

    // 特別報酬
    friend_invite: "友達招待報酬",

    // 廃止（後方互換性）
    community_post: "投稿作成報酬",
    daily_login_base: "デイリーログインボーナス",
    daily_login_streak_7: "7日連続ログインボーナス",
    daily_login_streak_14: "14日連続ログインボーナス",
    daily_login_streak_30: "30日連続ログインボーナス",
  };

  return reasons[actionType] || actionType;
}

/**
 * 初期報酬設定データをFirestoreに投入（新報酬設計対応）
 */
export async function seedRewardSettings(): Promise<void> {
  const db = admin.firestore();
  const batch = db.batch();

  const settings: Omit<RewardSetting, "id" | "updatedAt">[] = [
    // 投票系（高報酬）
    {
      actionType: "task_registration",
      basePoints: 10,
      description: "投票タスク登録",
      isActive: true,
    },
    {
      actionType: "task_completion",
      basePoints: 10,
      description: "外部投票タスク完了",
      isActive: true,
    },
    {
      actionType: "task_share",
      basePoints: 5,
      description: "投票タスクをSNSで共有",
      isActive: true,
      dailyLimit: 3,
    },

    // コンテンツ系（中報酬）
    {
      actionType: "post_mv",
      basePoints: 5,
      description: "MV投稿",
      isActive: true,
    },
    {
      actionType: "mv_watch",
      basePoints: 2,
      description: "MV視聴報告",
      isActive: true,
      dailyLimit: 3,
    },
    {
      actionType: "collection_create",
      basePoints: 10,
      description: "コレクション作成",
      isActive: true,
    },
    {
      actionType: "post_image",
      basePoints: 3,
      description: "画像投稿",
      isActive: true,
    },
    {
      actionType: "post_goods_exchange",
      basePoints: 5,
      description: "グッズ交換投稿",
      isActive: true,
    },

    // コミュニティ系（低報酬）
    {
      actionType: "post_text",
      basePoints: 2,
      description: "テキスト投稿",
      isActive: true,
    },
    {
      actionType: "community_like",
      basePoints: 1,
      description: "いいね",
      isActive: true,
      dailyLimit: 10,
    },
    {
      actionType: "community_comment",
      basePoints: 2,
      description: "コメント",
      isActive: true,
      dailyLimit: 10,
    },
    {
      actionType: "follow_user",
      basePoints: 3,
      description: "フォロー",
      isActive: true,
      dailyLimit: 5,
    },

    // コミュニティ系 - される側（双方向報酬）
    {
      actionType: "received_like",
      basePoints: 1,
      description: "いいねされた",
      isActive: true,
      dailyLimit: 50,
    },
    {
      actionType: "received_comment",
      basePoints: 1,
      description: "コメントされた",
      isActive: true,
      dailyLimit: 30,
    },
    {
      actionType: "received_follow",
      basePoints: 2,
      description: "フォローされた",
      isActive: true,
      dailyLimit: 20,
    },

    // 特別報酬
    {
      actionType: "friend_invite",
      basePoints: 50,
      description: "友達招待（登録完了時）",
      isActive: true,
    },

    // 廃止（isActive: false）
    {
      actionType: "daily_login_base",
      basePoints: 10,
      description: "デイリーログイン基本報酬（廃止）",
      isActive: false,
    },
    {
      actionType: "daily_login_streak_7",
      basePoints: 5,
      description: "7日連続ログインボーナス（廃止）",
      isActive: false,
    },
    {
      actionType: "daily_login_streak_14",
      basePoints: 10,
      description: "14日連続ログインボーナス（廃止）",
      isActive: false,
    },
    {
      actionType: "daily_login_streak_30",
      basePoints: 20,
      description: "30日連続ログインボーナス（廃止）",
      isActive: false,
    },
    {
      actionType: "community_post",
      basePoints: 5,
      description: "投稿作成報酬（投稿タイプ別に移行済み）",
      isActive: false,
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
  console.log("✅ [rewardHelper] Reward settings seeded successfully (new reward design)");
}
