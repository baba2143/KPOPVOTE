/**
 * Weekly Reset for Idol Ranking
 * Runs every Monday at 00:00 UTC (09:00 JST)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { resetWeeklyVotesInShards } from "../utils/shardedCounter";

// Run every Monday at 00:00 UTC (09:00 JST)
export const resetWeeklyIdolRanking = functions
  .runWith({ memory: "512MB", timeoutSeconds: 300, maxInstances: 1 })
  .pubsub.schedule("0 0 * * 1")
  .timeZone("UTC")
  .onRun(async (_context) => {
    console.log("Starting weekly idol ranking reset...");

    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    try {
      // Get all idol ranking votes
      const votesSnapshot = await db.collection("idolRankingVotes").get();

      if (votesSnapshot.empty) {
        console.log("No ranking votes found to reset.");
        return null;
      }

      // Optional: Save weekly snapshot before reset
      const snapshotDate = new Date().toISOString().split("T")[0];
      const snapshotBatch = db.batch();

      // Create weekly snapshot collection for historical data
      const weeklySnapshotRef = db.collection("idolRankingWeeklySnapshots").doc(snapshotDate);
      const snapshotData: {
        date: string;
        createdAt: admin.firestore.Timestamp;
        individualRankings: Array<{
          entityId: string;
          name: string;
          groupName: string | null;
          weeklyVotes: number;
          allTimeVotes: number;
        }>;
        groupRankings: Array<{
          entityId: string;
          name: string;
          weeklyVotes: number;
          allTimeVotes: number;
        }>;
      } = {
        date: snapshotDate,
        createdAt: now,
        individualRankings: [],
        groupRankings: [],
      };

      // Collect snapshot data and prepare reset
      votesSnapshot.docs.forEach((doc) => {
        const data = doc.data();

        // Only include entries with weekly votes
        if (data.weeklyVotes > 0) {
          const snapshotEntry = {
            entityId: data.entityId,
            name: data.name,
            groupName: data.groupName || null,
            weeklyVotes: data.weeklyVotes,
            allTimeVotes: data.allTimeVotes,
          };

          if (data.rankingType === "individual") {
            snapshotData.individualRankings.push(snapshotEntry);
          } else {
            snapshotData.groupRankings.push({
              entityId: data.entityId,
              name: data.name,
              weeklyVotes: data.weeklyVotes,
              allTimeVotes: data.allTimeVotes,
            });
          }
        }
      });

      // Sort snapshots by weekly votes descending
      snapshotData.individualRankings.sort((a, b) => b.weeklyVotes - a.weeklyVotes);
      snapshotData.groupRankings.sort((a, b) => b.weeklyVotes - a.weeklyVotes);

      // Save snapshot
      snapshotBatch.set(weeklySnapshotRef, snapshotData);
      await snapshotBatch.commit();

      console.log(`Saved weekly snapshot for ${snapshotDate}`);
      console.log(`Individual rankings: ${snapshotData.individualRankings.length}`);
      console.log(`Group rankings: ${snapshotData.groupRankings.length}`);

      // Reset weekly votes in batches (Firestore has 500 document limit per batch)
      const BATCH_SIZE = 500;
      let resetCount = 0;

      for (let i = 0; i < votesSnapshot.docs.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const chunk = votesSnapshot.docs.slice(i, i + BATCH_SIZE);

        chunk.forEach((doc) => {
          batch.update(doc.ref, {
            weeklyVotes: 0,
            lastWeeklyReset: now,
            updatedAt: now,
          });
          resetCount++;
        });

        await batch.commit();
      }

      console.log(`Weekly idol ranking reset completed. Reset ${resetCount} parent documents.`);

      // Also reset weekly votes in shard sub-documents
      let shardResetCount = 0;
      for (const doc of votesSnapshot.docs) {
        const shardsSnapshot = await doc.ref.collection("shards").limit(1).get();
        if (!shardsSnapshot.empty) {
          await resetWeeklyVotesInShards(db, doc.id);
          shardResetCount++;
        }
      }
      console.log(`Reset shards for ${shardResetCount} entities.`);

      return null;
    } catch (error) {
      console.error("Error resetting weekly idol ranking:", error);
      throw error;
    }
  });
