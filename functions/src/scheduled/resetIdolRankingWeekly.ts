/**
 * Reset Idol Ranking Weekly Votes
 * Runs every Monday at 00:00 JST (Sunday 15:00 UTC)
 * Resets weeklyVotes to 0 for all idol rankings
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { SCHEDULED_CONFIG } from "../utils/functionConfig";
import {
  resetIdolRankingWeeklyVotes,
  idolRankingShardsExist,
} from "../utils/shardedCounter";
import { handleCors } from "../middleware/cors";

/**
 * Scheduled function to reset weekly votes for all idol rankings
 * Runs every Monday at 00:00 JST (Sunday 15:00 UTC)
 */
export const resetIdolRankingWeekly = functions
  .runWith(SCHEDULED_CONFIG)
  .pubsub.schedule("0 15 * * 0")
  .timeZone("UTC")
  .onRun(async () => {
    const db = admin.firestore();
    const startTime = Date.now();

    console.log("[resetIdolRankingWeekly] Starting weekly reset...");

    try {
      // Get all idol rankings
      const rankingsSnapshot = await db.collection("idolRankings").get();

      if (rankingsSnapshot.empty) {
        console.log("[resetIdolRankingWeekly] No idol rankings found");
        return null;
      }

      let resetCount = 0;
      const skippedCount = 0;
      let errorCount = 0;

      // Process each ranking
      const promises = rankingsSnapshot.docs.map(async (doc) => {
        const entityId = doc.id;

        try {
          // Check if shards exist for this ranking
          const hasShards = await idolRankingShardsExist(db, entityId);

          if (hasShards) {
            // Reset shards' weeklyVotes
            await resetIdolRankingWeeklyVotes(db, entityId);
          }

          // Also reset parent document's weeklyVotes
          await doc.ref.update({
            weeklyVotes: 0,
            lastWeeklyResetAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          resetCount++;
        } catch (error) {
          console.error(
            `[resetIdolRankingWeekly] Error resetting ${entityId}:`,
            error
          );
          errorCount++;
        }
      });

      await Promise.all(promises);

      const duration = Date.now() - startTime;
      console.log(
        `[resetIdolRankingWeekly] Completed: reset=${resetCount}, ` +
          `skipped=${skippedCount}, errors=${errorCount}, duration=${duration}ms`
      );

      return null;
    } catch (error) {
      console.error("[resetIdolRankingWeekly] Fatal error:", error);
      throw error;
    }
  });

/**
 * Manual trigger for weekly reset
 * Useful for testing or recovery scenarios
 */
export const resetIdolRankingWeeklyManual = functions
  .runWith(SCHEDULED_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

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
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(decodedToken.uid)
        .get();
      if (!userDoc.exists || !userDoc.data()?.isAdmin) {
        res
          .status(403)
          .json({ success: false, error: "Forbidden: Admin access required" });
        return;
      }

      const db = admin.firestore();
      const startTime = Date.now();

      // Get all idol rankings
      const rankingsSnapshot = await db.collection("idolRankings").get();

      let resetCount = 0;
      let errorCount = 0;

      // Process each ranking
      const promises = rankingsSnapshot.docs.map(async (doc) => {
        const entityId = doc.id;

        try {
          const hasShards = await idolRankingShardsExist(db, entityId);

          if (hasShards) {
            await resetIdolRankingWeeklyVotes(db, entityId);
          }

          await doc.ref.update({
            weeklyVotes: 0,
            lastWeeklyResetAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          resetCount++;
        } catch (error) {
          console.error(
            `[resetIdolRankingWeeklyManual] Error resetting ${entityId}:`,
            error
          );
          errorCount++;
        }
      });

      await Promise.all(promises);

      const duration = Date.now() - startTime;

      res.status(200).json({
        success: true,
        data: {
          resetCount,
          errorCount,
          duration: `${duration}ms`,
        },
      });
    } catch (error) {
      console.error("[resetIdolRankingWeeklyManual] Error:", error);
      res.status(500).json({ success: false, error: "Internal server error" });
    }
  });
