/**
 * Aggregate Idol Ranking Votes from Shards
 * Runs every 1 minute to update parent documents with aggregated shard counts.
 *
 * This keeps the parent idolRankingVotes/{id} documents up-to-date
 * so that ranking queries (getRanking) can read directly from parent docs
 * without needing to aggregate shards on every read.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { getAggregatedCounts } from "../utils/shardedCounter";

export const aggregateIdolRankings = functions
  .runWith({ memory: "512MB", timeoutSeconds: 120, maxInstances: 1 })
  .pubsub.schedule("every 1 minutes")
  .onRun(async (_context) => {
    const db = admin.firestore();
    console.log("[aggregateIdolRankings] Starting aggregation...");

    try {
      // Get all idol ranking vote documents
      const votesSnapshot = await db.collection("idolRankingVotes").get();

      if (votesSnapshot.empty) {
        return null;
      }

      const BATCH_SIZE = 500;
      let updateCount = 0;
      const docs = votesSnapshot.docs;

      for (let i = 0; i < docs.length; i += BATCH_SIZE) {
        const batch = db.batch();
        const chunk = docs.slice(i, i + BATCH_SIZE);

        for (const doc of chunk) {
          const voteDocId = doc.id;

          // Check if this entity has shards
          const shardsSnapshot = await doc.ref.collection("shards").limit(1).get();
          if (shardsSnapshot.empty) {
            // No shards yet - skip (legacy data not yet migrated)
            continue;
          }

          // Aggregate shard counts
          const aggregated = await getAggregatedCounts(db, voteDocId);
          console.log(`[aggregateIdolRankings] Processing ${voteDocId}, weeklyVotes=${aggregated.weeklyVotes}, allTimeVotes=${aggregated.allTimeVotes}`);

          // Update parent document with aggregated totals
          batch.update(doc.ref, {
            weeklyVotes: aggregated.weeklyVotes,
            allTimeVotes: aggregated.allTimeVotes,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          updateCount++;
        }

        if (updateCount > 0) {
          await batch.commit();
        }
      }

      if (updateCount > 0) {
        console.log(`Aggregated idol rankings: updated ${updateCount} documents.`);
      }

      return null;
    } catch (error) {
      console.error("Error aggregating idol rankings:", error);
      throw error;
    }
  });
