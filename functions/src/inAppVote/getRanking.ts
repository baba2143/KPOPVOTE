/**
 * Get vote ranking (real-time results)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse, RankingResponse, RankingData } from "../types";

export const getRanking = functions.https.onRequest(async (req, res) => {
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
    await admin.auth().verifyIdToken(token);

    const voteId = req.query.voteId as string;

    if (!voteId) {
      res.status(400).json({ success: false, error: "voteId is required" } as ApiResponse<null>);
      return;
    }

    const voteDoc = await admin.firestore().collection("inAppVotes").doc(voteId).get();

    if (!voteDoc.exists) {
      res.status(404).json({ success: false, error: "Vote not found" } as ApiResponse<null>);
      return;
    }

    const voteData = voteDoc.data()!;
    const totalVotes = voteData.totalVotes || 0;

    const ranking: RankingData[] = voteData.choices
      .map((choice: {choiceId: string; label: string; voteCount: number}) => ({
        choiceId: choice.choiceId,
        label: choice.label,
        voteCount: choice.voteCount,
        percentage: totalVotes > 0 ? (choice.voteCount / totalVotes) * 100 : 0,
      }))
      .sort((a: RankingData, b: RankingData) => b.voteCount - a.voteCount);

    const response: RankingResponse = {
      voteId,
      title: voteData.title,
      totalVotes,
      ranking,
    };

    res.status(200).json({
      success: true,
      data: response,
    } as ApiResponse<RankingResponse>);
  } catch (error: unknown) {
    console.error("Get ranking error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
