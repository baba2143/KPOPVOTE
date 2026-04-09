/**
 * Delete FanCard endpoint
 * DELETE /deleteFanCard
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const deleteFanCard = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS
    if (handleCors(req, res)) return;

    // Only accept DELETE
    if (req.method !== "DELETE") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use DELETE.",
      } as ApiResponse<null>);
      return;
    }

    try {
      // Verify authentication
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          success: false,
          error: "Unauthorized: No token provided",
        } as ApiResponse<null>);
        return;
      }

      const token = authHeader.split("Bearer ")[1];
      const decodedToken = await admin.auth().verifyIdToken(token);
      const uid = decodedToken.uid;

      const db = admin.firestore();

      // Find user's FanCard
      const fanCardQuery = await db
        .collection("fanCards")
        .where("userId", "==", uid)
        .limit(1)
        .get();

      if (fanCardQuery.empty) {
        res.status(404).json({
          success: false,
          error: "FanCard not found",
        } as ApiResponse<null>);
        return;
      }

      const docRef = fanCardQuery.docs[0].ref;
      const odDisplayName = fanCardQuery.docs[0].id;

      // Delete the FanCard document
      await docRef.delete();

      // Remove reference from user document
      await db.collection("users").doc(uid).update({
        fanCardId: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ FanCard deleted: ${odDisplayName} by user ${uid}`);

      res.status(200).json({
        success: true,
        data: {
          deleted: true,
          odDisplayName,
        },
      } as ApiResponse<{ deleted: boolean; odDisplayName: string }>);
    } catch (error: unknown) {
      console.error("Delete FanCard error:", error);

      if (
        typeof error === "object" &&
        error !== null &&
        "code" in error &&
        error.code === "auth/id-token-expired"
      ) {
        res.status(401).json({
          success: false,
          error: "Token expired",
        } as ApiResponse<null>);
        return;
      }

      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
