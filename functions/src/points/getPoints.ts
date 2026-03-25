/**
 * Get user's current point balance
 * Endpoint: GET /api/getPoints
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

interface PointBalanceResponse {
  points: number;
  lastUpdated: string | null;
}

export const getPoints = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "GET") {
      res.status(405).json({ success: false, error: "Method not allowed. Use GET." } as ApiResponse<null>);
      return;
    }

    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({ success: false, error: "Unauthorized: No token provided" } as ApiResponse<null>);
        return;
      }

      const token = authHeader.split("Bearer ")[1];
      const decodedToken = await admin.auth().verifyIdToken(token);
      const uid = decodedToken.uid;

      const db = admin.firestore();
      const userDoc = await db.collection("users").doc(uid).get();

      if (!userDoc.exists) {
        res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
        return;
      }

      const userData = userDoc.data()!;

      const response: PointBalanceResponse = {
        points: userData.points || 0,
        lastUpdated: userData.updatedAt ? userData.updatedAt.toDate().toISOString() : null,
      };

      res.status(200).json({
        success: true,
        data: response,
      } as ApiResponse<PointBalanceResponse>);
    } catch (error: unknown) {
      console.error("Get points error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
