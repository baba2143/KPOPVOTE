/**
 * Aggregate Vote Counts from Shards
 * Runs every minute to sync sharded vote counts to parent documents
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { SCHEDULED_CONFIG } from "../utils/functionConfig";
import { syncVoteCountsToParent, shardsExist } from "../utils/shardedCounter";

/**
 * Scheduled function to aggregate vote counts from shards
 * Runs every minute for active votes only
 */
export const aggregateVoteCounts = functions
  .runWith(SCHEDULED_CONFIG)
  .pubsub.schedule("every 1 minutes")
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();

    try {
      // Get all active votes (status = active or calculated as active)
      const votesSnapshot = await db
        .collection("inAppVotes")
        .where("endDate", ">", admin.firestore.Timestamp.fromDate(now))
        .get();

      if (votesSnapshot.empty) {
        console.log("[aggregateVoteCounts] No active votes to aggregate");
        return null;
      }

      let aggregatedCount = 0;
      let skippedCount = 0;

      // Process each active vote
      const promises = votesSnapshot.docs.map(async (doc) => {
        const voteId = doc.id;
        const voteData = doc.data();

        // Check if vote has started
        const startDate = voteData.startDate.toDate();
        if (now < startDate) {
          skippedCount++;
          return; // Vote hasn't started yet
        }

        // Check if shards exist for this vote
        const hasShards = await shardsExist(db, voteId);
        if (!hasShards) {
          skippedCount++;
          return; // Legacy vote without shards
        }

        // Aggregate and sync
        const result = await syncVoteCountsToParent(db, voteId);
        if (result) {
          aggregatedCount++;
        }
      });

      await Promise.all(promises);

      console.log(
        `[aggregateVoteCounts] Completed: aggregated=${aggregatedCount}, skipped=${skippedCount}`
      );

      return null;
    } catch (error) {
      console.error("[aggregateVoteCounts] Error:", error);
      throw error;
    }
  });

/**
 * Manual trigger for aggregating a specific vote
 * Useful for testing or immediate sync needs
 */
export const aggregateVoteCountsManual = functions
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

      // Check if user is admin (you may want to add proper admin check)
      const userDoc = await admin.firestore().collection("users").doc(decodedToken.uid).get();
      if (!userDoc.exists || !userDoc.data()?.isAdmin) {
        res.status(403).json({ success: false, error: "Forbidden: Admin access required" });
        return;
      }

      const { voteId } = req.body;

      if (!voteId) {
        res.status(400).json({ success: false, error: "voteId is required" });
        return;
      }

      const db = admin.firestore();

      // Check if shards exist
      const hasShards = await shardsExist(db, voteId);
      if (!hasShards) {
        res.status(400).json({
          success: false,
          error: "Vote does not have shards. Cannot aggregate.",
        });
        return;
      }

      // Aggregate and sync
      const result = await syncVoteCountsToParent(db, voteId);

      if (result) {
        res.status(200).json({
          success: true,
          data: {
            voteId,
            totalVotes: result.totalVotes,
            choiceVotes: result.choiceVotes,
          },
        });
      } else {
        res.status(404).json({ success: false, error: "Vote not found" });
      }
    } catch (error) {
      console.error("[aggregateVoteCountsManual] Error:", error);
      res.status(500).json({ success: false, error: "Internal server error" });
    }
  });
