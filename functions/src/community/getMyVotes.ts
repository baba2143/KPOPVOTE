/**
 * Get my votes history
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const getMyVotes = functions.https.onRequest(async (req, res) => {
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

  await new Promise<void>((resolve, reject) => {
    verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  const currentUser = (req as AuthenticatedRequest).user;
  if (!currentUser) {
    res.status(401).json({ success: false, error: "Unauthorized" } as ApiResponse<null>);
    return;
  }

  try {
    const status = req.query.status as string || "all"; // 'all', 'active', 'ended'
    const sort = req.query.sort as string || "date"; // 'date', 'points'
    const limit = parseInt(req.query.limit as string) || 20;
    const lastVoteHistoryId = req.query.lastVoteHistoryId as string | undefined;

    const db = admin.firestore();

    // Build base query
    let query: admin.firestore.Query = db.collection("voteHistory")
      .where("userId", "==", currentUser.uid);

    // Sort order
    if (sort === "points") {
      query = query.orderBy("pointsUsed", "desc");
    } else {
      query = query.orderBy("votedAt", "desc");
    }

    query = query.limit(limit + 1);

    if (lastVoteHistoryId) {
      const lastVoteHistoryDoc = await db.collection("voteHistory").doc(lastVoteHistoryId).get();
      if (lastVoteHistoryDoc.exists) {
        query = query.startAfter(lastVoteHistoryDoc);
      }
    }

    const snapshot = await query.get();
    const hasMore = snapshot.size > limit;
    const voteHistories = snapshot.docs.slice(0, limit);

    // Enrich with vote status
    const myVotesData = await Promise.all(
      voteHistories.map(async (doc) => {
        const historyData = doc.data();

        // Get current vote status
        const voteDoc = await db.collection("inAppVotes").doc(historyData.voteId).get();
        const voteData = voteDoc.exists ? voteDoc.data() : null;

        const voteStatus = voteData?.status || "ended";

        return {
          id: doc.id,
          ...historyData,
          votedAt: historyData.votedAt?.toDate().toISOString() || null,
          voteStatus,
          voteEndDate: voteData?.endDate?.toDate().toISOString() || null,
        };
      })
    );

    // Filter by status if needed
    let filteredVotes = myVotesData;
    if (status === "active") {
      filteredVotes = myVotesData.filter((vote) => vote.voteStatus === "active");
    } else if (status === "ended") {
      filteredVotes = myVotesData.filter((vote) => vote.voteStatus === "ended");
    }

    // Calculate summary stats
    const totalPointsUsed = filteredVotes.reduce(
      (sum, vote) => sum + ((vote as Record<string, unknown>).pointsUsed as number || 0),
      0
    );
    const totalVotes = filteredVotes.length;

    res.status(200).json({
      success: true,
      data: {
        voteHistory: filteredVotes,
        hasMore,
        summary: {
          totalVotes,
          totalPointsUsed,
        },
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Get my votes error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
