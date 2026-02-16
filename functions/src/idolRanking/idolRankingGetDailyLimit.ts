/**
 * Get daily vote limit status
 * Returns how many votes user has used today and remaining
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

// 投票上限撤廃: 実質無制限
const DAILY_VOTE_LIMIT = 999999;

export interface VoteDetail {
  entityId: string;
  entityType: "individual" | "group";
  name: string;
  groupName?: string;
  votedAt: string;
}

export interface DailyLimitResponse {
  votesUsed: number;
  maxVotes: number;
  remainingVotes: number;
  voteDetails: VoteDetail[];
  resetTime: string;
}

export const idolRankingGetDailyLimit = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "GET") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use GET.",
      } as ApiResponse<null>);
      return;
    }

    try {
    // Auth check
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
      const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD

      // Get today's vote count
      const dailyVotesRef = db.collection("idolRankingDailyVotes").doc(`${uid}_${today}`);
      const dailyVotesDoc = await dailyVotesRef.get();
      const votesUsed = dailyVotesDoc.exists ?
        (dailyVotesDoc.data()!.voteCount || 0) :
        0;

      // Get today's vote details
      const todayStart = new Date(today);
      const todayEnd = new Date(today);
      todayEnd.setDate(todayEnd.getDate() + 1);

      const votesSnapshot = await db
        .collection("idolRankingVotes")
        .where("oderId", "==", uid)
        .where("votedAt", ">=", todayStart)
        .where("votedAt", "<", todayEnd)
        .orderBy("votedAt", "desc")
        .get();

      const voteDetails: VoteDetail[] = votesSnapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          entityId: data.entityId,
          entityType: data.entityType,
          name: data.name,
          groupName: data.groupName || undefined,
          votedAt: data.votedAt?.toDate?.()?.toISOString() ??
          new Date().toISOString(),
        };
      });

      // Calculate reset time (midnight UTC next day)
      const resetDate = new Date(today);
      resetDate.setDate(resetDate.getDate() + 1);
      const resetTime = resetDate.toISOString();

      const response: DailyLimitResponse = {
        votesUsed,
        maxVotes: DAILY_VOTE_LIMIT,
        remainingVotes: Math.max(0, DAILY_VOTE_LIMIT - votesUsed),
        voteDetails,
        resetTime,
      };

      res.status(200).json({
        success: true,
        data: response,
      } as ApiResponse<DailyLimitResponse>);
    } catch (error: unknown) {
      console.error("Get daily limit error:", error);
      // Log detailed error information for debugging
      if (error instanceof Error) {
        console.error("Error name:", error.name);
        console.error("Error message:", error.message);
        console.error("Error stack:", error.stack);
      }
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
