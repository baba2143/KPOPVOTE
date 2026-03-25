/**
 * Manual Monthly Reset Script
 * Archives February rankings and resets for March
 *
 * Usage: npx ts-node scripts/manualMonthlyReset.ts
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin with Application Default Credentials
admin.initializeApp({
  projectId: "kpopvote-9de2b",
});

const db = admin.firestore();

interface IdolRankingArchiveEntry {
  entityId: string;
  entityType: "individual" | "group";
  name: string;
  groupName?: string;
  votes: number;
  rank: number;
}

async function createArchive(): Promise<{ archiveId: string; individualCount: number; groupCount: number }> {
  // Archive for February 2026
  const archiveId = "2026-02";

  console.log(`📦 Creating archive: ${archiveId}`);

  // Get all idol rankings sorted by totalVotes
  const rankingsSnapshot = await db
    .collection("idolRankings")
    .orderBy("totalVotes", "desc")
    .get();

  const individualRankings: IdolRankingArchiveEntry[] = [];
  const groupRankings: IdolRankingArchiveEntry[] = [];

  rankingsSnapshot.docs.forEach((doc) => {
    const data = doc.data();
    const entry: IdolRankingArchiveEntry = {
      entityId: doc.id,
      entityType: data.entityType || "individual",
      name: data.name || "",
      groupName: data.groupName,
      votes: data.totalVotes || 0,
      rank: 0,
    };

    if (entry.entityType === "group") {
      groupRankings.push(entry);
    } else {
      individualRankings.push(entry);
    }
  });

  // Sort and assign ranks
  individualRankings.sort((a, b) => b.votes - a.votes);
  groupRankings.sort((a, b) => b.votes - a.votes);

  individualRankings.forEach((entry, index) => {
    entry.rank = index + 1;
  });
  groupRankings.forEach((entry, index) => {
    entry.rank = index + 1;
  });

  // Save archive
  const archive = {
    archiveId,
    archiveType: "monthly",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    year: 2026,
    month: 2,
    rankings: {
      individual: individualRankings,
      group: groupRankings,
    },
  };

  await db.collection("idolRankingArchives").doc(archiveId).set(archive);

  console.log(`✅ Archive created: ${archiveId}`);
  console.log(`   - Individual: ${individualRankings.length} entries`);
  console.log(`   - Group: ${groupRankings.length} entries`);

  // Show top 5 individual
  console.log("\n📊 Top 5 Individual (February):");
  individualRankings.slice(0, 5).forEach((entry) => {
    console.log(`   ${entry.rank}. ${entry.name} - ${entry.votes} votes`);
  });

  return {
    archiveId,
    individualCount: individualRankings.length,
    groupCount: groupRankings.length,
  };
}

async function resetAllRankings(): Promise<{ resetCount: number; errorCount: number }> {
  console.log("\n🔄 Resetting all rankings for March...");

  const rankingsSnapshot = await db.collection("idolRankings").get();

  let resetCount = 0;
  let errorCount = 0;

  for (const doc of rankingsSnapshot.docs) {
    const entityId = doc.id;

    try {
      // Reset shards
      const shardsSnapshot = await db
        .collection("idolRankings")
        .doc(entityId)
        .collection("shards")
        .get();

      if (!shardsSnapshot.empty) {
        const batch = db.batch();
        shardsSnapshot.docs.forEach((shardDoc) => {
          batch.update(shardDoc.ref, {
            weeklyVotes: 0,
            totalVotes: 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
        await batch.commit();
      }

      // Reset parent document
      await doc.ref.update({
        weeklyVotes: 0,
        totalVotes: 0,
        lastMonthlyResetAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      resetCount++;
    } catch (error) {
      console.error(`❌ Error resetting ${entityId}:`, error);
      errorCount++;
    }
  }

  console.log(`✅ Reset complete: ${resetCount} rankings reset, ${errorCount} errors`);

  return { resetCount, errorCount };
}

async function main() {
  console.log("=".repeat(50));
  console.log("🚀 Manual Monthly Reset - February → March 2026");
  console.log("=".repeat(50));

  try {
    // Step 1: Create archive
    const archiveResult = await createArchive();

    // Step 2: Reset all rankings
    const resetResult = await resetAllRankings();

    console.log("\n" + "=".repeat(50));
    console.log("✅ COMPLETE!");
    console.log("=".repeat(50));
    console.log(`Archive: ${archiveResult.archiveId}`);
    console.log(`Reset: ${resetResult.resetCount} rankings`);
    console.log("\n3月のランキングがスタートしました！");

  } catch (error) {
    console.error("❌ Fatal error:", error);
    process.exit(1);
  }

  process.exit(0);
}

main();
