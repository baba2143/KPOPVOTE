/**
 * Seed Reward Settings
 * rewardSettingsコレクションに初期データを投入するスクリプト
 *
 * 実行方法:
 * cd /Users/makotobaba/Desktop/KPOPVOTE
 * npx ts-node scripts/seedRewardSettings.ts
 */

import * as admin from "firebase-admin";

// Firebase Admin初期化
if (!admin.apps.length) {
  admin.initializeApp();
}

interface RewardSetting {
  actionType: string;
  basePoints: number;
  description: string;
  isActive: boolean;
}

async function seedRewardSettings(): Promise<void> {
  console.log("🌱 Seeding reward settings...\n");

  const db = admin.firestore();
  const batch = db.batch();

  const settings: RewardSetting[] = [
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

  let count = 0;

  for (const setting of settings) {
    const docRef = db.collection("rewardSettings").doc(setting.actionType);
    batch.set(docRef, {
      ...setting,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    count++;
    console.log(`✅ ${setting.actionType}: ${setting.basePoints}P - ${setting.description}`);
  }

  await batch.commit();

  console.log(`\n🎉 Successfully seeded ${count} reward settings!`);
  console.log("📊 Reward settings collection is ready for use.\n");

  // データ確認
  console.log("🔍 Verifying data...");
  const snapshot = await db.collection("rewardSettings").get();
  console.log(`Total documents in rewardSettings: ${snapshot.size}\n`);

  process.exit(0);
}

// スクリプト実行
seedRewardSettings().catch((error) => {
  console.error("❌ Error seeding reward settings:", error);
  process.exit(1);
});
