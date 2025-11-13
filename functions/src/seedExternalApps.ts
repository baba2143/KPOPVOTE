/**
 * Admin-only Cloud Function to seed External App Masters
 *
 * Usage:
 *   curl -X POST https://us-central1-kpopvote-9de2b.cloudfunctions.net/seedExternalApps \
 *     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
 *     -H "Content-Type: application/json"
 */

import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const STORAGE_BASE =
  "https://firebasestorage.googleapis.com/v0/b/kpopvote-9de2b.appspot.com/o/app-icons%2F";

const externalAppsData = [
  {
    appId: "idol-champ",
    appName: "IDOL CHAMP",
    appUrl: "https://www.idolchamp.com",
    iconUrl: `${STORAGE_BASE}idol_champ.png?alt=media`,
  },
  {
    appId: "mnet-plus",
    appName: "Mnet Plus",
    appUrl: "https://www.mnetplus.world",
    iconUrl: `${STORAGE_BASE}mnet_plus.png?alt=media`,
  },
  {
    appId: "mubeat",
    appName: "MUBEAT",
    appUrl: "https://www.mubeat.io",
    iconUrl: `${STORAGE_BASE}mubeat.png?alt=media`,
  },
];

export const seedExternalApps = onRequest(
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

      logger.info("Starting external app master seeding...");

      const db = admin.firestore();
      const results = [];

      for (const app of externalAppsData) {
        const { appId, ...appData } = app;

        // Check if app already exists
        const docRef = db.collection("externalAppMasters").doc(appId);
        const doc = await docRef.get();

        if (doc.exists) {
          logger.info(`External app "${app.appName}" (${appId}) already exists, skipping...`);
          results.push({
            appId,
            appName: app.appName,
            status: "skipped",
            reason: "already exists",
          });
        } else {
          await docRef.set({
            ...appData,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logger.info(`Created external app "${app.appName}" (${appId})`);
          results.push({
            appId,
            appName: app.appName,
            status: "created",
          });
        }
      }

      logger.info("External app master seeding completed successfully");

      res.status(200).json({
        success: true,
        message: "External app master seeding completed",
        totalApps: externalAppsData.length,
        results,
      });
    } catch (error) {
      logger.error("Error seeding external apps:", error);
      res.status(500).json({
        success: false,
        error: "Failed to seed external apps",
        details: error instanceof Error ? error.message : String(error),
      });
    }
  }
);
