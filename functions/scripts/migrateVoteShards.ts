/**
 * Migration Script: Initialize Shards for Existing Votes and Idol Rankings
 *
 * This script creates shard subcollections for existing votes and idol rankings
 * that were created before the sharding system was introduced.
 *
 * Usage:
 *   npx ts-node scripts/migrateVoteShards.ts [--dry-run] [--votes-only] [--rankings-only]
 *
 * Options:
 *   --dry-run       Show what would be migrated without making changes
 *   --votes-only    Only migrate inAppVotes
 *   --rankings-only Only migrate idolRankings
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin
// Use service account or default credentials
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const NUM_SHARDS = 10;

interface MigrationStats {
  votesProcessed: number;
  votesShardsCreated: number;
  votesSkipped: number;
  rankingsProcessed: number;
  rankingsShardsCreated: number;
  rankingsSkipped: number;
  errors: string[];
}

const stats: MigrationStats = {
  votesProcessed: 0,
  votesShardsCreated: 0,
  votesSkipped: 0,
  rankingsProcessed: 0,
  rankingsShardsCreated: 0,
  rankingsSkipped: 0,
  errors: [],
};

/**
 * Check if shards exist for a vote
 */
async function voteHasShards(voteId: string): Promise<boolean> {
  const shardRef = db
    .collection("inAppVotes")
    .doc(voteId)
    .collection("shards")
    .doc("shard_0");
  const doc = await shardRef.get();
  return doc.exists;
}

/**
 * Check if shards exist for an idol ranking
 */
async function rankingHasShards(entityId: string): Promise<boolean> {
  const shardRef = db
    .collection("idolRankings")
    .doc(entityId)
    .collection("shards")
    .doc("shard_0");
  const doc = await shardRef.get();
  return doc.exists;
}

/**
 * Initialize shards for a vote with current vote counts
 */
async function initializeVoteShardsWithData(
  voteId: string,
  choices: Array<{ choiceId: string; voteCount: number }>,
  totalVotes: number,
  dryRun: boolean
): Promise<void> {
  if (dryRun) {
    console.log(`  [DRY-RUN] Would create shards for vote: ${voteId}`);
    console.log(`    - Choices: ${choices.map((c) => `${c.choiceId}:${c.voteCount}`).join(", ")}`);
    console.log(`    - Total: ${totalVotes}`);
    return;
  }

  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Put all existing votes in shard_0, others start at 0
  for (let i = 0; i < NUM_SHARDS; i++) {
    const shardRef = db
      .collection("inAppVotes")
      .doc(voteId)
      .collection("shards")
      .doc(`shard_${i}`);

    if (i === 0) {
      // First shard contains existing vote counts
      const choiceVotes: { [choiceId: string]: number } = {};
      for (const choice of choices) {
        choiceVotes[choice.choiceId] = choice.voteCount;
      }
      batch.set(shardRef, {
        choiceVotes,
        totalVotes,
        updatedAt: now,
      });
    } else {
      // Other shards start empty
      const choiceVotes: { [choiceId: string]: number } = {};
      for (const choice of choices) {
        choiceVotes[choice.choiceId] = 0;
      }
      batch.set(shardRef, {
        choiceVotes,
        totalVotes: 0,
        updatedAt: now,
      });
    }
  }

  await batch.commit();
  console.log(`  ✅ Created shards for vote: ${voteId}`);
}

/**
 * Initialize shards for an idol ranking with current vote counts
 */
async function initializeRankingShardsWithData(
  entityId: string,
  weeklyVotes: number,
  totalVotes: number,
  dryRun: boolean
): Promise<void> {
  if (dryRun) {
    console.log(`  [DRY-RUN] Would create shards for ranking: ${entityId}`);
    console.log(`    - Weekly: ${weeklyVotes}, Total: ${totalVotes}`);
    return;
  }

  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Put all existing votes in shard_0, others start at 0
  for (let i = 0; i < NUM_SHARDS; i++) {
    const shardRef = db
      .collection("idolRankings")
      .doc(entityId)
      .collection("shards")
      .doc(`shard_${i}`);

    if (i === 0) {
      // First shard contains existing vote counts
      batch.set(shardRef, {
        weeklyVotes,
        totalVotes,
        updatedAt: now,
      });
    } else {
      // Other shards start empty
      batch.set(shardRef, {
        weeklyVotes: 0,
        totalVotes: 0,
        updatedAt: now,
      });
    }
  }

  await batch.commit();
  console.log(`  ✅ Created shards for ranking: ${entityId}`);
}

/**
 * Migrate all existing votes
 */
async function migrateVotes(dryRun: boolean): Promise<void> {
  console.log("\n📊 Migrating inAppVotes...\n");

  const votesSnapshot = await db.collection("inAppVotes").get();
  console.log(`Found ${votesSnapshot.size} votes to process\n`);

  for (const doc of votesSnapshot.docs) {
    stats.votesProcessed++;
    const voteId = doc.id;
    const data = doc.data();

    try {
      // Check if already has shards
      const hasShards = await voteHasShards(voteId);
      if (hasShards) {
        console.log(`  ⏭️  Vote ${voteId} already has shards, skipping`);
        stats.votesSkipped++;
        continue;
      }

      // Get current vote counts
      const choices = (data.choices || []).map((c: { choiceId: string; voteCount?: number }) => ({
        choiceId: c.choiceId,
        voteCount: c.voteCount || 0,
      }));
      const totalVotes = data.totalVotes || 0;

      // Initialize shards
      await initializeVoteShardsWithData(voteId, choices, totalVotes, dryRun);
      stats.votesShardsCreated++;
    } catch (error) {
      const errorMsg = `Error migrating vote ${voteId}: ${error}`;
      console.error(`  ❌ ${errorMsg}`);
      stats.errors.push(errorMsg);
    }
  }
}

/**
 * Migrate all existing idol rankings
 */
async function migrateRankings(dryRun: boolean): Promise<void> {
  console.log("\n🏆 Migrating idolRankings...\n");

  const rankingsSnapshot = await db.collection("idolRankings").get();
  console.log(`Found ${rankingsSnapshot.size} rankings to process\n`);

  for (const doc of rankingsSnapshot.docs) {
    stats.rankingsProcessed++;
    const entityId = doc.id;
    const data = doc.data();

    try {
      // Check if already has shards
      const hasShards = await rankingHasShards(entityId);
      if (hasShards) {
        console.log(`  ⏭️  Ranking ${entityId} already has shards, skipping`);
        stats.rankingsSkipped++;
        continue;
      }

      // Get current vote counts
      const weeklyVotes = data.weeklyVotes || 0;
      const totalVotes = data.totalVotes || 0;

      // Initialize shards
      await initializeRankingShardsWithData(entityId, weeklyVotes, totalVotes, dryRun);
      stats.rankingsShardsCreated++;
    } catch (error) {
      const errorMsg = `Error migrating ranking ${entityId}: ${error}`;
      console.error(`  ❌ ${errorMsg}`);
      stats.errors.push(errorMsg);
    }
  }
}

/**
 * Print migration summary
 */
function printSummary(dryRun: boolean): void {
  console.log("\n" + "=".repeat(50));
  console.log(dryRun ? "📋 DRY-RUN SUMMARY" : "📋 MIGRATION SUMMARY");
  console.log("=".repeat(50));

  console.log("\n📊 Votes:");
  console.log(`   Processed: ${stats.votesProcessed}`);
  console.log(`   Shards created: ${stats.votesShardsCreated}`);
  console.log(`   Skipped (already had shards): ${stats.votesSkipped}`);

  console.log("\n🏆 Rankings:");
  console.log(`   Processed: ${stats.rankingsProcessed}`);
  console.log(`   Shards created: ${stats.rankingsShardsCreated}`);
  console.log(`   Skipped (already had shards): ${stats.rankingsSkipped}`);

  if (stats.errors.length > 0) {
    console.log("\n❌ Errors:");
    for (const error of stats.errors) {
      console.log(`   - ${error}`);
    }
  }

  console.log("\n" + "=".repeat(50));

  if (dryRun) {
    console.log("\n💡 This was a dry run. Run without --dry-run to apply changes.\n");
  } else {
    console.log("\n✅ Migration completed!\n");
  }
}

/**
 * Main function
 */
async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const dryRun = args.includes("--dry-run");
  const votesOnly = args.includes("--votes-only");
  const rankingsOnly = args.includes("--rankings-only");

  console.log("\n" + "=".repeat(50));
  console.log("🚀 Vote Shards Migration Script");
  console.log("=".repeat(50));

  if (dryRun) {
    console.log("\n⚠️  DRY-RUN MODE: No changes will be made\n");
  }

  try {
    if (!rankingsOnly) {
      await migrateVotes(dryRun);
    }

    if (!votesOnly) {
      await migrateRankings(dryRun);
    }

    printSummary(dryRun);
  } catch (error) {
    console.error("\n❌ Fatal error:", error);
    process.exit(1);
  }
}

// Run the migration
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Unhandled error:", error);
    process.exit(1);
  });
