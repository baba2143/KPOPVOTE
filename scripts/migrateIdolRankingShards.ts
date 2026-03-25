/**
 * Migration Script: Create shard sub-documents for existing idolRankingVotes
 *
 * This script:
 * 1. Reads all existing idolRankingVotes documents
 * 2. For each, creates 10 shard sub-documents under /shards/
 * 3. shard_0 gets the current weeklyVotes and allTimeVotes
 * 4. shards 1-9 are initialized with 0
 * 5. Skips documents that already have shards
 *
 * Usage:
 *   # Set GOOGLE_APPLICATION_CREDENTIALS to your service account key
 *   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
 *   npx ts-node scripts/migrateIdolRankingShards.ts
 *
 * This is safe to run multiple times (idempotent) and can run while the app is live.
 */

import * as admin from "firebase-admin";

const NUM_SHARDS = 10;

async function main(): Promise<void> {
  // Initialize Firebase Admin
  admin.initializeApp();
  const db = admin.firestore();

  console.log("Starting idol ranking shards migration...");

  // Get all existing idol ranking vote documents
  const votesSnapshot = await db.collection("idolRankingVotes").get();

  if (votesSnapshot.empty) {
    console.log("No idol ranking votes found. Nothing to migrate.");
    return;
  }

  console.log(`Found ${votesSnapshot.docs.length} idol ranking vote documents.`);

  let migratedCount = 0;
  let skippedCount = 0;

  for (const doc of votesSnapshot.docs) {
    const voteDocId = doc.id;
    const data = doc.data();

    // Check if shards already exist
    const existingShards = await doc.ref.collection("shards").limit(1).get();
    if (!existingShards.empty) {
      console.log(`  Skipping ${voteDocId} - shards already exist`);
      skippedCount++;
      continue;
    }

    const currentWeeklyVotes = data.weeklyVotes || 0;
    const currentAllTimeVotes = data.allTimeVotes || 0;

    console.log(
      `  Migrating ${voteDocId}: weeklyVotes=${currentWeeklyVotes}, allTimeVotes=${currentAllTimeVotes}`
    );

    // Create shards in a batch
    const batch = db.batch();
    for (let i = 0; i < NUM_SHARDS; i++) {
      const shardRef = doc.ref.collection("shards").doc(`shard_${i}`);
      batch.set(shardRef, {
        // shard_0 gets the current counts, rest get 0
        weeklyVotes: i === 0 ? currentWeeklyVotes : 0,
        allTimeVotes: i === 0 ? currentAllTimeVotes : 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    migratedCount++;
  }

  console.log("");
  console.log("Migration complete!");
  console.log(`  Migrated: ${migratedCount}`);
  console.log(`  Skipped (already had shards): ${skippedCount}`);
  console.log(`  Total documents: ${votesSnapshot.docs.length}`);

  process.exit(0);
}

main().catch((error) => {
  console.error("Migration failed:", error);
  process.exit(1);
});
