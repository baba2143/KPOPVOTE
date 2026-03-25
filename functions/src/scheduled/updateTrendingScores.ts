/**
 * Update Trending Scores for Collections
 * Runs every 15 minutes to pre-compute trending scores for efficient sorting
 *
 * Score formula: (saveCount * 3) + (likeCount * 2) + (viewCount * 1)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { SCHEDULED_CONFIG } from "../utils/functionConfig";

/**
 * Scheduled function to update trending scores for public collections
 * Runs every 15 minutes to keep trending list fresh without per-request computation
 */
export const updateTrendingScores = functions
  .runWith(SCHEDULED_CONFIG)
  .pubsub.schedule("every 15 minutes")
  .onRun(async () => {
    const db = admin.firestore();
    const startTime = Date.now();

    try {
      // Get collections from the last 30 days (covers all trending periods: 24h, 7d, 30d)
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

      const collectionsSnapshot = await db.collection("collections")
        .where("visibility", "==", "public")
        .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .get();

      if (collectionsSnapshot.empty) {
        console.log("[updateTrendingScores] No public collections to update");
        return null;
      }

      let updatedCount = 0;
      let skippedCount = 0;
      const batchSize = 500;
      let batch = db.batch();
      let batchCount = 0;

      for (const doc of collectionsSnapshot.docs) {
        const data = doc.data();

        // Calculate trending score
        const newScore = (
          (data.saveCount || 0) * 3 +
          (data.likeCount || 0) * 2 +
          (data.viewCount || 0) * 1
        );

        // Only update if score changed
        if (data.trendingScore !== newScore) {
          batch.update(doc.ref, {
            trendingScore: newScore,
            trendingScoreUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          batchCount++;
          updatedCount++;

          // Commit batch when reaching limit
          if (batchCount >= batchSize) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        } else {
          skippedCount++;
        }
      }

      // Commit remaining batch
      if (batchCount > 0) {
        await batch.commit();
      }

      const duration = Date.now() - startTime;
      console.log(
        `[updateTrendingScores] Completed in ${duration}ms: ` +
        `updated=${updatedCount}, skipped=${skippedCount}, total=${collectionsSnapshot.size}`
      );

      return null;
    } catch (error) {
      console.error("[updateTrendingScores] Error:", error);
      return null;
    }
  });
