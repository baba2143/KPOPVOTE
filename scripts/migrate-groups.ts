/**
 * データ移行スクリプト: groupName → Group Master
 *
 * 使用方法:
 *   npx ts-node scripts/migrate-groups.ts
 */

import * as admin from 'firebase-admin';
import * as path from 'path';

// Service Account Key のパスを指定
const serviceAccountPath = path.join(__dirname, '../functions/service-account-key.json');
const serviceAccount = require(serviceAccountPath);

// Firebase Admin の初期化
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

interface MigrationResult {
  groupsCreated: number;
  idolsUpdated: number;
  errors: Array<{ idol: string; error: string }>;
}

async function migrateGroupsToMaster(): Promise<MigrationResult> {
  const result: MigrationResult = {
    groupsCreated: 0,
    idolsUpdated: 0,
    errors: [],
  };

  try {
    console.log('🚀 データ移行を開始します...\n');

    // Step 1: 既存の idolMasters から重複なし groupName リストを取得
    console.log('Step 1: 既存のアイドルデータからグループ名を抽出中...');
    const idolsSnapshot = await db.collection('idolMasters').get();

    const groupNamesSet = new Set<string>();
    const idolsByGroupName = new Map<string, admin.firestore.DocumentSnapshot[]>();

    idolsSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      const groupName = data.groupName?.trim();

      if (groupName) {
        groupNamesSet.add(groupName);

        if (!idolsByGroupName.has(groupName)) {
          idolsByGroupName.set(groupName, []);
        }
        idolsByGroupName.get(groupName)!.push(doc);
      }
    });

    console.log(`  → ${groupNamesSet.size}個のユニークなグループ名を発見\n`);

    // Step 2: 各 groupName に対して groupMasters レコードを作成
    console.log('Step 2: グループマスターレコードを作成中...');
    const groupNameToIdMap = new Map<string, string>();

    for (const groupName of Array.from(groupNamesSet)) {
      try {
        // 既に存在するか確認
        const existingGroupSnapshot = await db
          .collection('groupMasters')
          .where('name', '==', groupName)
          .limit(1)
          .get();

        let groupId: string;

        if (!existingGroupSnapshot.empty) {
          // 既に存在する場合はそのIDを使用
          groupId = existingGroupSnapshot.docs[0].id;
          console.log(`  → グループ "${groupName}" は既に存在します (ID: ${groupId})`);
        } else {
          // 新規作成
          const groupRef = await db.collection('groupMasters').add({
            name: groupName,
            imageUrl: null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          groupId = groupRef.id;
          result.groupsCreated++;
          console.log(`  ✅ グループ "${groupName}" を作成しました (ID: ${groupId})`);
        }

        groupNameToIdMap.set(groupName, groupId);
      } catch (error) {
        console.error(`  ❌ グループ "${groupName}" の作成に失敗:`, error);
      }
    }

    console.log(`\n  → ${result.groupsCreated}個の新規グループを作成しました\n`);

    // Step 3: idolMasters の各レコードを更新（groupId フィールドを追加）
    console.log('Step 3: アイドルデータに groupId を追加中...');

    const batch = db.batch();
    let batchCount = 0;
    const BATCH_SIZE = 500; // Firestore の batch 制限

    for (const [groupName, idolDocs] of idolsByGroupName.entries()) {
      const groupId = groupNameToIdMap.get(groupName);

      if (!groupId) {
        console.error(`  ❌ グループID が見つかりません: ${groupName}`);
        continue;
      }

      for (const idolDoc of idolDocs) {
        const idolData = idolDoc.data();
        const idolName = idolData.name || '不明';

        try {
          batch.update(idolDoc.ref, {
            groupId: groupId,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          batchCount++;
          result.idolsUpdated++;

          // バッチサイズに達したらコミット
          if (batchCount >= BATCH_SIZE) {
            await batch.commit();
            console.log(`  → ${batchCount}件の更新をコミットしました`);
            batchCount = 0;
          }
        } catch (error: any) {
          result.errors.push({
            idol: idolName,
            error: error.message || '不明なエラー',
          });
          console.error(`  ❌ アイドル "${idolName}" の更新に失敗:`, error);
        }
      }
    }

    // 残りのバッチをコミット
    if (batchCount > 0) {
      await batch.commit();
      console.log(`  → 残り ${batchCount}件の更新をコミットしました`);
    }

    console.log(`\n  → ${result.idolsUpdated}件のアイドルデータを更新しました\n`);

    // 移行結果レポート
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 移行結果レポート');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`✅ 新規作成グループ数: ${result.groupsCreated}`);
    console.log(`✅ 更新アイドル数: ${result.idolsUpdated}`);
    console.log(`❌ エラー数: ${result.errors.length}`);

    if (result.errors.length > 0) {
      console.log('\nエラー詳細:');
      result.errors.forEach((err, index) => {
        console.log(`  ${index + 1}. アイドル: ${err.idol}, エラー: ${err.error}`);
      });
    }

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    console.log('✨ データ移行が完了しました！\n');

  } catch (error) {
    console.error('❌ 移行処理中にエラーが発生しました:', error);
    throw error;
  }

  return result;
}

// スクリプト実行
(async () => {
  try {
    await migrateGroupsToMaster();
    process.exit(0);
  } catch (error) {
    console.error('移行スクリプトの実行に失敗しました:', error);
    process.exit(1);
  }
})();
