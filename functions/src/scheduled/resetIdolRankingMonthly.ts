/**
 * Reset Idol Ranking Monthly Votes & Create Archive
 * Runs on the 1st of every month at 00:00 JST (last day of prev month 15:00 UTC)
 * Archives previous month's rankings and resets totalVotes to 0
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { SCHEDULED_CONFIG } from "../utils/functionConfig";
import {
  resetIdolRankingMonthlyVotes,
  idolRankingShardsExist,
} from "../utils/shardedCounter";
import { handleCors } from "../middleware/cors";

/**
 * Archive data structure for idol rankings
 */
interface IdolRankingArchiveEntry {
  entityId: string;
  entityType: "individual" | "group";
  name: string;
  groupName?: string;
  votes: number;
  rank: number;
}

interface IdolRankingArchive {
  archiveId: string;
  archiveType: "monthly";
  createdAt: admin.firestore.FieldValue | admin.firestore.Timestamp;
  year: number;
  month: number;
  rankings: {
    individual: IdolRankingArchiveEntry[];
    group: IdolRankingArchiveEntry[];
  };
}

/**
 * Get archive ID in YYYY-MM format
 */
function getArchiveId(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

/**
 * Get previous month's date
 * Called at 00:00 JST on the 1st, so we archive the just-ended month
 */
function getPreviousMonth(): Date {
  const now = new Date();
  // Create date for the previous month
  const prevMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  return prevMonth;
}

/**
 * Create archive of current rankings before reset
 */
async function createArchive(
  db: admin.firestore.Firestore
): Promise<{ archiveId: string; individualCount: number; groupCount: number }> {
  const prevMonth = getPreviousMonth();
  const archiveId = getArchiveId(prevMonth);

  console.log(`[resetIdolRankingMonthly] Creating archive: ${archiveId}`);

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
      rank: 0, // Will be set after sorting
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
  const archive: IdolRankingArchive = {
    archiveId,
    archiveType: "monthly",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    year: prevMonth.getFullYear(),
    month: prevMonth.getMonth() + 1,
    rankings: {
      individual: individualRankings,
      group: groupRankings,
    },
  };

  await db.collection("idolRankingArchives").doc(archiveId).set(archive);

  console.log(
    `[resetIdolRankingMonthly] Archive created: ${archiveId} ` +
      `(individual: ${individualRankings.length}, group: ${groupRankings.length})`
  );

  return {
    archiveId,
    individualCount: individualRankings.length,
    groupCount: groupRankings.length,
  };
}

/**
 * Scheduled function to reset monthly votes for all idol rankings
 * Runs on the 1st of every month at 00:00 JST
 *
 * Note: Since pubsub.schedule doesn't support 'L' (last day), we schedule for
 * the 1st at 00:00 JST. The archive will be for the previous month.
 */
export const resetIdolRankingMonthly = functions
  .runWith(SCHEDULED_CONFIG)
  .pubsub.schedule("0 15 1 * *")
  .timeZone("UTC")
  .onRun(async () => {
    const db = admin.firestore();
    const startTime = Date.now();

    console.log("[resetIdolRankingMonthly] Starting monthly reset...");

    try {
      // Step 1: Create archive before reset
      const archiveResult = await createArchive(db);

      // Step 2: Reset all idol rankings
      const rankingsSnapshot = await db.collection("idolRankings").get();

      if (rankingsSnapshot.empty) {
        console.log("[resetIdolRankingMonthly] No idol rankings found");
        return null;
      }

      let resetCount = 0;
      let errorCount = 0;

      // Process each ranking
      const promises = rankingsSnapshot.docs.map(async (doc) => {
        const entityId = doc.id;

        try {
          // Check if shards exist for this ranking
          const hasShards = await idolRankingShardsExist(db, entityId);

          if (hasShards) {
            // Reset shards' totalVotes (and weeklyVotes)
            await resetIdolRankingMonthlyVotes(db, entityId);
          }

          // Also reset parent document's totalVotes and weeklyVotes
          await doc.ref.update({
            weeklyVotes: 0,
            totalVotes: 0,
            lastMonthlyResetAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          resetCount++;
        } catch (error) {
          console.error(
            `[resetIdolRankingMonthly] Error resetting ${entityId}:`,
            error
          );
          errorCount++;
        }
      });

      await Promise.all(promises);

      const duration = Date.now() - startTime;
      console.log(
        `[resetIdolRankingMonthly] Completed: archive=${archiveResult.archiveId}, ` +
          `reset=${resetCount}, errors=${errorCount}, duration=${duration}ms`
      );

      return null;
    } catch (error) {
      console.error("[resetIdolRankingMonthly] Fatal error:", error);
      throw error;
    }
  });

/**
 * Manual trigger for monthly reset
 * Useful for testing or recovery scenarios
 */
export const resetIdolRankingMonthlyManual = functions
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

      const { skipArchive } = req.body;

      let archiveResult = null;

      // Step 1: Create archive (unless skipped)
      if (!skipArchive) {
        archiveResult = await createArchive(db);
      }

      // Step 2: Reset all idol rankings
      const rankingsSnapshot = await db.collection("idolRankings").get();

      let resetCount = 0;
      let errorCount = 0;

      const promises = rankingsSnapshot.docs.map(async (doc) => {
        const entityId = doc.id;

        try {
          const hasShards = await idolRankingShardsExist(db, entityId);

          if (hasShards) {
            await resetIdolRankingMonthlyVotes(db, entityId);
          }

          await doc.ref.update({
            weeklyVotes: 0,
            totalVotes: 0,
            lastMonthlyResetAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          resetCount++;
        } catch (error) {
          console.error(
            `[resetIdolRankingMonthlyManual] Error resetting ${entityId}:`,
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
          archiveId: archiveResult?.archiveId || null,
          individualCount: archiveResult?.individualCount || 0,
          groupCount: archiveResult?.groupCount || 0,
          resetCount,
          errorCount,
          duration: `${duration}ms`,
        },
      });
    } catch (error) {
      console.error("[resetIdolRankingMonthlyManual] Error:", error);
      res.status(500).json({ success: false, error: "Internal server error" });
    }
  });
