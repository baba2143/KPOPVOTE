/**
 * Seed Reward Settings
 * rewardSettingsコレクションの初期データ投入
 * 新報酬設計: デイリーログイン廃止、アクション報酬重視
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

interface RewardSettingData {
  actionType: string;
  basePoints: number;
  description: string;
  isActive: boolean;
  dailyLimit?: number;
}

const defaultRewardSettings: RewardSettingData[] = [
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

  // コミュニティ系（低報酬） - する側
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
  {
    actionType: "daily_login",
    basePoints: 10,
    description: "デイリーログインボーナス（旧）（廃止）",
    isActive: false,
  },
  {
    actionType: "vote",
    basePoints: 1,
    description: "投票実行（旧）（廃止）",
    isActive: false,
  },
];

export const seedRewardSettings = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "POST") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      });
      return;
    }

    try {
      const db = admin.firestore();
      const batch = db.batch();
      const now = admin.firestore.FieldValue.serverTimestamp();

      let createdCount = 0;
      let updatedCount = 0;

      // 新報酬設計では既存の設定を上書きする
      const forceUpdate = req.query.force === "true";

      for (const setting of defaultRewardSettings) {
        const docRef = db.collection("rewardSettings").doc(setting.actionType);
        const doc = await docRef.get();

        if (doc.exists && !forceUpdate) {
          console.log(`⏭️  Skipped (already exists): ${setting.actionType}`);
        } else {
          const data: Record<string, unknown> = {
            ...setting,
            updatedAt: now,
          };

          if (!doc.exists) {
            data.createdAt = now;
            console.log(`✅ Created: ${setting.actionType}`);
            createdCount++;
          } else {
            console.log(`🔄 Updated: ${setting.actionType}`);
            updatedCount++;
          }

          batch.set(docRef, data, { merge: true });
        }
      }

      await batch.commit();

      console.log(
        `🎉 Seed completed: ${createdCount} created, ${updatedCount} updated`,
      );

      res.status(200).json({
        success: true,
        data: {
          created: createdCount,
          updated: updatedCount,
          total: defaultRewardSettings.length,
          message: "新報酬設計のrewardSettingsをシードしました",
        },
      });
    } catch (error: unknown) {
      console.error("❌ Seed error:", error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : "Internal server error",
      });
    }
  });
