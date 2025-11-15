/**
 * Get in-app vote detail
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";

export const getInAppVoteDetail = functions.https.onRequest(async (req, res) => {
  // Set CORS headers for all requests
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Max-Age", "3600");

  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

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
    await admin.auth().verifyIdToken(token);

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

    res.status(200).json({
      success: true,
      data: {
        voteId: voteDoc.id,
        title: data.title,
        description: data.description,
        choices: data.choices,
        startDate: data.startDate.toDate().toISOString(),
        endDate: data.endDate.toDate().toISOString(),
        requiredPoints: data.requiredPoints,
        status: data.status,
        totalVotes: data.totalVotes,
        coverImageUrl: data.coverImageUrl || null,
        isFeatured: data.isFeatured || false,
        createdAt: data.createdAt?.toDate().toISOString() || null,
        updatedAt: data.updatedAt?.toDate().toISOString() || null,
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
