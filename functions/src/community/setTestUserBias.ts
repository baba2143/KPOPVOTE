/**
 * Set Bias for Test User
 *
 * Sets the bias for the test4@kpopvote.com user
 *
 * Usage:
 *   curl -X POST https://us-central1-kpopvote-9de2b.cloudfunctions.net/setTestUserBias \
 *     -H "Content-Type: application/json" \
 *     -d '{"email": "test4@kpopvote.com", "selectedIdols": ["Mark"]}'
 */

import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

export const setTestUserBias = onRequest(
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

      const { email, selectedIdols } = req.body;

      if (!email || !selectedIdols || !Array.isArray(selectedIdols)) {
        res.status(400).json({
          error: "Missing required fields: email and selectedIdols (array)",
        });
        return;
      }

      logger.info(`Setting bias for ${email}: ${selectedIdols.join(", ")}`);

      const db = admin.firestore();

      // Find user by email
      const usersSnapshot = await db.collection("users")
        .where("email", "==", email)
        .limit(1)
        .get();

      if (usersSnapshot.empty) {
        res.status(404).json({ error: `User not found with email: ${email}` });
        return;
      }

      const userDoc = usersSnapshot.docs[0];
      const uid = userDoc.id;

      // Update bias collection
      await db.collection("bias").doc(uid).set({
        selectedIdols,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // Update users collection
      await db.collection("users").doc(uid).update({
        selectedIdols,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Successfully set bias for user ${uid} (${email})`);

      res.status(200).json({
        success: true,
        message: `Bias set successfully for ${email}`,
        data: {
          uid,
          email,
          selectedIdols,
        },
      });
    } catch (error) {
      logger.error("Error setting test user bias:", error);
      res.status(500).json({
        success: false,
        error: "Failed to set test user bias",
        details: error instanceof Error ? error.message : String(error),
      });
    }
  }
);
