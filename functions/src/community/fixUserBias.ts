/**
 * Fix User Bias Data
 *
 * Copies selectedIdols from bias collection to users collection
 * for all users that don't have it set
 *
 * Usage:
 *   curl -X POST https://us-central1-kpopvote-9de2b.cloudfunctions.net/fixUserBias \
 *     -H "Content-Type: application/json"
 */

import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export const fixUserBias = onRequest(
  {
    region: "us-central1",
    cors: true,
  },
  async (req, res) => {
    try {
      // CORS preflight
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      // Only allow POST
      if (req.method !== "POST") {
        res.status(405).json({ error: "Method not allowed" });
        return;
      }

      logger.info("Starting bias data fix...");

      const db = admin.firestore();
      const results = {
        updated: [] as Array<{ uid: string; selectedIdols: string[] }>,
        skipped: [] as Array<{ uid: string; reason: string }>,
      };

      // Get all users
      const usersSnapshot = await db.collection("users").get();
      logger.info(`Found ${usersSnapshot.docs.length} users to check`);

      for (const userDoc of usersSnapshot.docs) {
        const uid = userDoc.id;
        const userData = userDoc.data();

        // Skip if already has selectedIdols
        if (userData.selectedIdols && userData.selectedIdols.length > 0) {
          results.skipped.push({
            uid,
            reason: "Already has selectedIdols in users collection",
          });
          continue;
        }

        // Get from bias collection
        const biasDoc = await db.collection("bias").doc(uid).get();
        if (!biasDoc.exists) {
          results.skipped.push({
            uid,
            reason: "No bias document found",
          });
          continue;
        }

        const biasData = biasDoc.data();
        if (!biasData || !biasData.selectedIdols || biasData.selectedIdols.length === 0) {
          results.skipped.push({
            uid,
            reason: "No selectedIdols in bias collection",
          });
          continue;
        }

        // Copy selectedIdols to users collection
        await userDoc.ref.update({
          selectedIdols: biasData.selectedIdols,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        logger.info(`Updated user ${uid} with selectedIdols:`, biasData.selectedIdols);
        results.updated.push({
          uid,
          selectedIdols: biasData.selectedIdols,
        });
      }

      logger.info("Bias data fix completed successfully");

      res.status(200).json({
        success: true,
        message: "Bias data fix completed",
        results: {
          updated: results.updated,
          skipped: results.skipped,
          totalUpdated: results.updated.length,
          totalSkipped: results.skipped.length,
        },
      });
    } catch (error) {
      logger.error("Error fixing bias data:", error);
      res.status(500).json({
        success: false,
        error: "Failed to fix bias data",
        details: error instanceof Error ? error.message : String(error),
      });
    }
  }
);
