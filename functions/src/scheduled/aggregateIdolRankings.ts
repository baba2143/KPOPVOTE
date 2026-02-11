/**
 * Aggregate Idol Ranking Counts from Shards
 * Runs every minute to sync sharded ranking counts to parent documents
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { SCHEDULED_CONFIG } from "../utils/functionConfig";
import {
  syncIdolRankingCountsToParent,
  idolRankingShardsExist,
} from "../utils/shardedCounter";

/**
 * Scheduled function to aggregate idol ranking counts from shards
 * Runs every minute
 */
export const aggregateIdolRankings = functions
  .runWith(SCHEDULED_CONFIG)
  .pubsub.schedule("every 1 minutes")
  .onRun(async () => {
    const db = admin.firestore();

    try {
      // Get all idol rankings that have been updated recently (within last hour)
      // This is more efficient than processing all rankings
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

      const rankingsSnapshot = await db
        .collection("idolRankings")
        .where("lastUpdated", ">", admin.firestore.Timestamp.fromDate(oneHourAgo))
        .get();

      if (rankingsSnapshot.empty) {
        console.log("[aggregateIdolRankings] No recently updated rankings to aggregate");
        return null;
      }

      let aggregatedCount = 0;
      let skippedCount = 0;

      // Process each ranking
      const promises = rankingsSnapshot.docs.map(async (doc) => {
        const entityId = doc.id;

        // Check if shards exist for this ranking
        const hasShards = await idolRankingShardsExist(db, entityId);
        if (!hasShards) {
          skippedCount++;
          return; // Legacy ranking without shards
        }

        // Aggregate and sync
        const result = await syncIdolRankingCountsToParent(db, entityId);
        if (result) {
          aggregatedCount++;
        }
      });

      await Promise.all(promises);

      console.log(
        `[aggregateIdolRankings] Completed: aggregated=${aggregatedCount}, skipped=${skippedCount}`
      );

      return null;
    } catch (error) {
      console.error("[aggregateIdolRankings] Error:", error);
      throw error;
    }
  });

/**
 * Manual trigger for aggregating all idol rankings
 * Useful for initial sync or recovery scenarios
 */
export const aggregateIdolRankingsManual = functions
  .runWith(SCHEDULED_CONFIG)
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ success: false, error: "Method not allowed" });
      return;
    }

    try {
      // Admin authentication check
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({ success: false, error: "Unauthorized" });
        return;
      }

      const token = authHeader.split("Bearer ")[1];
      const decodedToken = await admin.auth().verifyIdToken(token);

      // Check if user is admin
      const userDoc = await admin.firestore().collection("users").doc(decodedToken.uid).get();
      if (!userDoc.exists || !userDoc.data()?.isAdmin) {
        res.status(403).json({ success: false, error: "Forbidden: Admin access required" });
        return;
      }

      const { entityId, aggregateAll } = req.body;

      const db = admin.firestore();

      if (aggregateAll) {
        // Aggregate all rankings with shards
        const rankingsSnapshot = await db.collection("idolRankings").get();

        let aggregatedCount = 0;
        let skippedCount = 0;

        const promises = rankingsSnapshot.docs.map(async (doc) => {
          const id = doc.id;
          const hasShards = await idolRankingShardsExist(db, id);
          if (!hasShards) {
            skippedCount++;
            return;
          }
          const result = await syncIdolRankingCountsToParent(db, id);
          if (result) {
            aggregatedCount++;
          }
        });

        await Promise.all(promises);

        res.status(200).json({
          success: true,
          data: {
            aggregated: aggregatedCount,
            skipped: skippedCount,
          },
        });
        return;
      }

      if (!entityId) {
        res.status(400).json({
          success: false,
          error: "entityId is required (or set aggregateAll: true)",
        });
        return;
      }

      // Check if shards exist
      const hasShards = await idolRankingShardsExist(db, entityId);
      if (!hasShards) {
        res.status(400).json({
          success: false,
          error: "Ranking does not have shards. Cannot aggregate.",
        });
        return;
      }

      // Aggregate and sync
      const result = await syncIdolRankingCountsToParent(db, entityId);

      if (result) {
        res.status(200).json({
          success: true,
          data: {
            entityId,
            weeklyVotes: result.weeklyVotes,
            totalVotes: result.totalVotes,
          },
        });
      } else {
        res.status(404).json({ success: false, error: "Ranking not found" });
      }
    } catch (error) {
      console.error("[aggregateIdolRankingsManual] Error:", error);
      res.status(500).json({ success: false, error: "Internal server error" });
    }
  });
