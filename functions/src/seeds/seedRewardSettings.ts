/**
 * Seed Reward Settings
 * rewardSettingsコレクションの初期データ投入
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

interface RewardSettingData {
  actionType: string;
  basePoints: number;
  description: string;
  isActive: boolean;
}

const defaultRewardSettings: RewardSettingData[] = [
  {
    actionType: "daily_login",
    basePoints: 10,
    description: "デイリーログインボーナス",
    isActive: true,
  },
  {
    actionType: "task_completion",
    basePoints: 50,
    description: "タスク完了報酬",
    isActive: true,
  },
  {
    actionType: "community_post",
    basePoints: 5,
    description: "コミュニティ投稿",
    isActive: true,
  },
  {
    actionType: "community_like",
    basePoints: 1,
    description: "いいね獲得",
    isActive: true,
  },
  {
    actionType: "community_comment",
    basePoints: 2,
    description: "コメント投稿",
    isActive: true,
  },
  {
    actionType: "vote",
    basePoints: 1,
    description: "投票実行（1票あたり）",
    isActive: true,
  },
];

export const seedRewardSettings = functions.https.onRequest(async (req, res) => {
  // CORS設定
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

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
    let skippedCount = 0;

    for (const setting of defaultRewardSettings) {
      const docRef = db.collection("rewardSettings").doc(setting.actionType);
      const doc = await docRef.get();

      if (doc.exists) {
        console.log(`⏭️  Skipped (already exists): ${setting.actionType}`);
        skippedCount++;
      } else {
        batch.set(docRef, {
          ...setting,
          updatedAt: now,
          createdAt: now,
        });
        console.log(`✅ Created: ${setting.actionType}`);
        createdCount++;
      }
    }

    await batch.commit();

    console.log(
      `🎉 Seed completed: ${createdCount} created, ${skippedCount} skipped`,
    );

    res.status(200).json({
      success: true,
      data: {
        created: createdCount,
        skipped: skippedCount,
        total: defaultRewardSettings.length,
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
