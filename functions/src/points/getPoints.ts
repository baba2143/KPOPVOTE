/**
 * Get user's current point balance
 * Endpoint: GET /api/getPoints
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";

interface MultiPointBalanceResponse {
  premiumPoints: number;
  regularPoints: number;
  eventPoints: number;
  giftPoints: number;
  isPremium: boolean;
  lastUpdated: string | null;
}

export const getPoints = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

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

      const response: MultiPointBalanceResponse = {
        premiumPoints: userData.premiumPoints || 0,
        regularPoints: userData.regularPoints || 0,
        eventPoints: userData.eventPoints || 0,
        giftPoints: userData.giftPoints || 0,
        isPremium: userData.isPremium || false,
        lastUpdated: userData.updatedAt ? userData.updatedAt.toDate().toISOString() : null,
      };

      res.status(200).json({
        success: true,
        data: response,
      } as ApiResponse<MultiPointBalanceResponse>);
    } catch (error: unknown) {
      console.error("Get points error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
