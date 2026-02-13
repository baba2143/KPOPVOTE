/**
 * Monthly Reset for Idol Ranking
 * Runs on the 1st of each month at 00:00 JST (previous day 15:00 UTC)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { resetMonthlyVotesInShards } from "../utils/shardedCounter";

// Run on the 1st of each month at 15:00 UTC (00:00 JST on 1st)
// Note: We use "0 15 1 * *" which means 15:00 UTC on the 1st day of each month
// This equals 00:00 JST on the 1st (since JST = UTC+9)
export const resetMonthlyIdolRanking = functions
  .runWith({ memory: "512MB", timeoutSeconds: 300, maxInstances: 1 })
  .pubsub.schedule("0 15 1 * *")
  .timeZone("UTC")
  .onRun(async (_context) => {
    console.log("Starting monthly idol ranking reset...");

    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    try {
      // Get all idol ranking votes
      const votesSnapshot = await db.collection("idolRankingVotes").get();

      if (votesSnapshot.empty) {
        console.log("No ranking votes found to reset.");
        return null;
      }

      // Get previous month for snapshot naming
      const today = new Date();
      const prevMonth = new Date(today.getFullYear(), today.getMonth() - 1, 1);
      const snapshotMonth = `${prevMonth.getFullYear()}-${String(prevMonth.getMonth() + 1).padStart(2, "0")}`;

      // Optional: Save monthly snapshot before reset
      const snapshotBatch = db.batch();

      // Create monthly snapshot collection for historical data
      const monthlySnapshotRef = db.collection("idolRankingMonthlySnapshots").doc(snapshotMonth);
      const snapshotData: {
        month: string;
        createdAt: admin.firestore.Timestamp;
        individualRankings: Array<{
          entityId: string;
          name: string;
          groupName: string | null;
          monthlyVotes: number;
          allTimeVotes: number;
        }>;
        groupRankings: Array<{
          entityId: string;
          name: string;
          monthlyVotes: number;
          allTimeVotes: number;
        }>;
      } = {
        month: snapshotMonth,
        createdAt: now,
        individualRankings: [],
        groupRankings: [],
      };

      // Collect snapshot data and prepare reset
      votesSnapshot.docs.forEach((doc) => {
        const data = doc.data();

        // Only include entries with monthly votes
        if (data.monthlyVotes > 0) {
          const snapshotEntry = {
            entityId: data.entityId,
            name: data.name,
            groupName: data.groupName || null,
            monthlyVotes: data.monthlyVotes,
            allTimeVotes: data.allTimeVotes,
          };

          if (data.rankingType === "individual") {
            snapshotData.individualRankings.push(snapshotEntry);
          } else {
            snapshotData.groupRankings.push({
              entityId: data.entityId,
              name: data.name,
              monthlyVotes: data.monthlyVotes,
              allTimeVotes: data.allTimeVotes,
            });
          }
        }
      });

      // Sort snapshots by monthly votes descending
      snapshotData.individualRankings.sort((a, b) => b.monthlyVotes - a.monthlyVotes);
      snapshotData.groupRankings.sort((a, b) => b.monthlyVotes - a.monthlyVotes);

      // Save snapshot
      snapshotBatch.set(monthlySnapshotRef, snapshotData);
      await snapshotBatch.commit();

      console.log(`Saved monthly snapshot for ${snapshotMonth}`);
      console.log(`Individual rankings: ${snapshotData.individualRankings.length}`);
      console.log(`Group rankings: ${snapshotData.groupRankings.length}`);

      // Reset monthly votes in batches (Firestore has 500 document limit per batch)
      const BATCH_SIZE = 500;
      let resetCount = 0;

      for (let i = 0; i < votesSnapshot.docs.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const chunk = votesSnapshot.docs.slice(i, i + BATCH_SIZE);

        chunk.forEach((doc) => {
          batch.update(doc.ref, {
            monthlyVotes: 0,
            lastMonthlyReset: now,
            updatedAt: now,
          });
          resetCount++;
        });

        await batch.commit();
      }

      console.log(`Monthly idol ranking reset completed. Reset ${resetCount} parent documents.`);

      // Also reset monthly votes in shard sub-documents
      let shardResetCount = 0;
      for (const doc of votesSnapshot.docs) {
        const shardsSnapshot = await doc.ref.collection("shards").limit(1).get();
        if (!shardsSnapshot.empty) {
          await resetMonthlyVotesInShards(db, doc.id);
          shardResetCount++;
        }
      }
      console.log(`Reset shards for ${shardResetCount} entities.`);

      return null;
    } catch (error) {
      console.error("Error resetting monthly idol ranking:", error);
      throw error;
    }
  });
