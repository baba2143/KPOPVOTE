/**
 * Get user's point transaction history
 * Endpoint: GET /api/getPointHistory?limit=20&offset=0
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

interface PointTransactionData {
  id: string;
  points: number;
  type: string;
  reason: string;
  createdAt: string;
}

interface GetPointHistoryResponse {
  transactions: PointTransactionData[];
  totalCount: number;
}

export const getPointHistory = functions
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

      // Parse query parameters
      const limitParam = req.query.limit as string;
      const offsetParam = req.query.offset as string;

      const limit = Math.min(parseInt(limitParam) || 20, 100); // Max 100
      const offset = parseInt(offsetParam) || 0;

      const db = admin.firestore();

      // Get transactions
      const transactionsSnapshot = await db
        .collection("pointTransactions")
        .where("userId", "==", uid)
        .orderBy("createdAt", "desc")
        .limit(limit)
        .offset(offset)
        .get();

      const transactions: PointTransactionData[] = transactionsSnapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          points: data.points,
          type: data.type,
          reason: data.reason,
          createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : new Date().toISOString(),
        };
      });

      // Use pagination result size to determine hasMore instead of separate count query
      // For total count, we return -1 to indicate "more available" or actual count if less than limit
      const hasMore = transactions.length === limit;
      const totalCount = hasMore ? -1 : offset + transactions.length;

      const response: GetPointHistoryResponse = {
        transactions,
        totalCount,
      };

      res.status(200).json({
        success: true,
        data: response,
      } as ApiResponse<GetPointHistoryResponse>);
    } catch (error: unknown) {
      console.error("Get point history error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
