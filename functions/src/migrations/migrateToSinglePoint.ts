/**
 * Migration Script: Dual Points → Single Point System
 *
 * 概要:
 * - premiumPoints の値を points フィールドに移行
 * - regularPoints は破棄（マイグレーション決定による）
 * - premiumPoints, regularPoints フィールドは削除
 *
 * 実行方法:
 * 1. Firebase Admin SDK をセットアップ
 * 2. npx ts-node src/migrations/migrateToSinglePoint.ts
 *
 * 注意:
 * - 本番環境で実行する前に、必ずテスト環境で検証すること
 * - バックアップを取得してから実行すること
 */

import * as admin from "firebase-admin";

// Firebase Admin SDK の初期化（まだ初期化されていない場合）
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

interface MigrationStats {
  total: number;
  migrated: number;
  skipped: number;
  errors: number;
}

interface MigrationResult {
  success: boolean;
  stats: MigrationStats;
  errorDetails: Array<{userId: string; error: string}>;
}

/**
 * ユーザーのポイントを単一ポイント制に移行
 *
 * @param dryRun - true の場合、実際の更新は行わず、影響範囲のみを確認
 * @param batchSize - 一度に処理するドキュメント数
 */
export async function migrateToSinglePoint(
  dryRun: boolean = true,
  batchSize: number = 100
): Promise<MigrationResult> {
  console.log("\n🚀 Starting migration to single point system...");
  console.log(`📋 Mode: ${dryRun ? "DRY RUN (no actual changes)" : "LIVE MIGRATION"}`);
  console.log(`📦 Batch size: ${batchSize}\n`);

  const stats: MigrationStats = {
    total: 0,
    migrated: 0,
    skipped: 0,
    errors: 0,
  };

  const errorDetails: Array<{userId: string; error: string}> = [];

  try {
    // 全ユーザーを取得（premiumPoints または regularPoints を持つもの）
    const usersRef = db.collection("users");
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    let hasMore = true;

    while (hasMore) {
      let query = usersRef.orderBy(admin.firestore.FieldPath.documentId()).limit(batchSize);
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();

      if (snapshot.empty) {
        hasMore = false;
        break;
      }

      const batch = db.batch();
      let batchCount = 0;

      for (const doc of snapshot.docs) {
        stats.total++;
        const data = doc.data();
        const userId = doc.id;

        // premiumPoints または regularPoints が存在するか確認
        const hasPremiumPoints = "premiumPoints" in data;
        const hasRegularPoints = "regularPoints" in data;
        const hasPoints = "points" in data;

        if (!hasPremiumPoints && !hasRegularPoints) {
          // 既に移行済み、またはポイントなし
          stats.skipped++;
          console.log(`⏭️  [${userId}] Skipped: No dual points found`);
          continue;
        }

        try {
          const premiumPoints = (data.premiumPoints as number) || 0;
          const regularPoints = (data.regularPoints as number) || 0;
          const currentPoints = (data.points as number) || 0;

          // 移行ロジック: premiumPoints を points に移行（regularPoints は破棄）
          // すでに points がある場合は、premiumPoints を加算
          const newPoints = hasPoints ? currentPoints : premiumPoints;

          console.log(
            `📊 [${userId}] Premium: ${premiumPoints}P, Regular: ${regularPoints}P (破棄) → Points: ${newPoints}P`
          );

          if (!dryRun) {
            // 実際の更新
            batch.update(doc.ref, {
              points: newPoints,
              premiumPoints: admin.firestore.FieldValue.delete(),
              regularPoints: admin.firestore.FieldValue.delete(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              _migrationNote: "Migrated from dual points to single point system",
              _migratedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            batchCount++;
          }

          stats.migrated++;
        } catch (error) {
          stats.errors++;
          const errorMessage = error instanceof Error ? error.message : String(error);
          errorDetails.push({ userId, error: errorMessage });
          console.error(`❌ [${userId}] Error: ${errorMessage}`);
        }
      }

      // バッチをコミット
      if (!dryRun && batchCount > 0) {
        await batch.commit();
        console.log(`✅ Committed batch of ${batchCount} users`);
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];

      if (snapshot.docs.length < batchSize) {
        hasMore = false;
      }
    }

    // 結果サマリー
    console.log("\n📊 Migration Summary:");
    console.log("═══════════════════════════════════════");
    console.log(`Total users processed: ${stats.total}`);
    console.log(`Successfully migrated: ${stats.migrated}`);
    console.log(`Skipped (already migrated): ${stats.skipped}`);
    console.log(`Errors: ${stats.errors}`);
    console.log("═══════════════════════════════════════");

    if (dryRun) {
      console.log("\n⚠️  This was a DRY RUN. No actual changes were made.");
      console.log("Run with dryRun=false to apply changes.");
    } else {
      console.log("\n✅ Migration completed successfully!");
    }

    return {
      success: stats.errors === 0,
      stats,
      errorDetails,
    };
  } catch (error) {
    console.error("\n❌ Migration failed with critical error:", error);
    throw error;
  }
}

/**
 * ポイント履歴のマイグレーション（pointType フィールドを削除）
 */
export async function migratePointTransactions(
  dryRun: boolean = true,
  batchSize: number = 500
): Promise<MigrationResult> {
  console.log("\n🚀 Starting point transactions migration...");
  console.log(`📋 Mode: ${dryRun ? "DRY RUN" : "LIVE MIGRATION"}`);

  const stats: MigrationStats = {
    total: 0,
    migrated: 0,
    skipped: 0,
    errors: 0,
  };

  const errorDetails: Array<{userId: string; error: string}> = [];

  try {
    const transactionsRef = db.collectionGroup("pointTransactions");
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
    let hasMore = true;

    while (hasMore) {
      let query = transactionsRef.orderBy(admin.firestore.FieldPath.documentId()).limit(batchSize);
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();

      if (snapshot.empty) {
        hasMore = false;
        break;
      }

      const batch = db.batch();
      let batchCount = 0;

      for (const doc of snapshot.docs) {
        stats.total++;
        const data = doc.data();

        // pointType フィールドが存在するか確認
        if (!("pointType" in data)) {
          stats.skipped++;
          continue;
        }

        try {
          if (!dryRun) {
            batch.update(doc.ref, {
              pointType: admin.firestore.FieldValue.delete(),
            });
            batchCount++;
          }
          stats.migrated++;
        } catch (error) {
          stats.errors++;
          const errorMessage = error instanceof Error ? error.message : String(error);
          errorDetails.push({ userId: doc.ref.path, error: errorMessage });
        }
      }

      if (!dryRun && batchCount > 0) {
        await batch.commit();
        console.log(`✅ Committed batch of ${batchCount} transactions`);
      }

      lastDoc = snapshot.docs[snapshot.docs.length - 1];

      if (snapshot.docs.length < batchSize) {
        hasMore = false;
      }
    }

    console.log("\n📊 Point Transactions Migration Summary:");
    console.log(`Total: ${stats.total}, Migrated: ${stats.migrated}, ` +
      `Skipped: ${stats.skipped}, Errors: ${stats.errors}`);

    return {
      success: stats.errors === 0,
      stats,
      errorDetails,
    };
  } catch (error) {
    console.error("❌ Point transactions migration failed:", error);
    throw error;
  }
}

// CLI 実行用
if (require.main === module) {
  const args = process.argv.slice(2);
  const dryRun = !args.includes("--live");

  console.log("\n╔═══════════════════════════════════════════════════════════════╗");
  console.log("║     KPOPVOTE Points Migration: Dual → Single Point System     ║");
  console.log("╚═══════════════════════════════════════════════════════════════╝");

  if (!dryRun) {
    console.log("\n⚠️  WARNING: Running in LIVE mode. Changes will be permanent!");
    console.log("Press Ctrl+C within 5 seconds to abort...\n");

    setTimeout(async () => {
      try {
        await migrateToSinglePoint(false);
        await migratePointTransactions(false);
        process.exit(0);
      } catch {
        process.exit(1);
      }
    }, 5000);
  } else {
    console.log("\n📋 Running in DRY RUN mode (default)");
    console.log("Use --live flag to apply actual changes\n");

    migrateToSinglePoint(true)
      .then(() => migratePointTransactions(true))
      .then(() => process.exit(0))
      .catch(() => process.exit(1));
  }
}
