/**
 * Get in-app vote detail
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const getInAppVoteDetail = functions
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

      const voteId = req.query.voteId as string;

      if (!voteId) {
        res.status(400).json({
          success: false,
          error: "voteId is required",
        } as ApiResponse<null>);
        return;
      }

      const voteDoc = await admin
        .firestore()
        .collection("inAppVotes")
        .doc(voteId)
        .get();

      if (!voteDoc.exists) {
        res.status(404).json({
          success: false,
          error: "Vote not found",
        } as ApiResponse<null>);
        return;
      }

      const data = voteDoc.data()!;
      const now = new Date();
      const startDate = data.startDate.toDate();
      const endDate = data.endDate.toDate();

      // Calculate status dynamically based on current time
      // 下書きの場合はそのままdraftを維持
      let calculatedStatus: "upcoming" | "active" | "ended" | "draft" = "upcoming";
      if (data.isDraft || data.status === "draft") {
        calculatedStatus = "draft";
      } else {
        if (now >= startDate) {
          calculatedStatus = "active";
        }
        if (now >= endDate) {
          calculatedStatus = "ended";
        }
      }

      // Get user's daily vote count for this vote (if dailyVoteLimitPerUser is set)
      const restrictions = data.restrictions || {};
      let userDailyVotes = 0;
      let userDailyRemaining: number | null = null;

      if (restrictions.dailyVoteLimitPerUser) {
        const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
        const dailyVoteHistoryRef = admin.firestore()
          .collection("dailyVoteHistory")
          .doc(`${voteId}_${uid}_${today}`);
        const dailyVoteHistory = await dailyVoteHistoryRef.get();

        userDailyVotes = dailyVoteHistory.exists ?
          (dailyVoteHistory.data()!.voteCount || 0) : 0;
        userDailyRemaining = Math.max(0, restrictions.dailyVoteLimitPerUser - userDailyVotes);
      }

      console.log(
        `📊 [getInAppVoteDetail] userDailyVotes=${userDailyVotes}, ` +
      `userDailyRemaining=${userDailyRemaining}, ` +
      `dailyVoteLimitPerUser=${restrictions.dailyVoteLimitPerUser}`
      );

      res.status(200).json({
        success: true,
        data: {
          voteId: voteDoc.id,
          title: data.title,
          description: data.description,
          choices: data.choices,
          startDate: startDate.toISOString(),
          endDate: endDate.toISOString(),
          requiredPoints: data.requiredPoints,
          status: calculatedStatus,
          totalVotes: data.totalVotes,
          coverImageUrl: data.coverImageUrl || null,
          isFeatured: data.isFeatured || false,
          isDraft: data.isDraft || false,
          restrictions: data.restrictions || null,
          createdAt: data.createdAt?.toDate().toISOString() || null,
          updatedAt: data.updatedAt?.toDate().toISOString() || null,
          // User-specific daily vote info
          userDailyVotes,
          userDailyRemaining,
        },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("Get in-app vote detail error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
