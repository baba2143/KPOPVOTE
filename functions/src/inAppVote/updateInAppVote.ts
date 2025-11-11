/**
 * Update in-app vote
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { InAppVoteUpdateRequest, ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const updateInAppVote = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "PATCH");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "PATCH") {
    res.status(405).json({ success: false, error: "Method not allowed. Use PATCH." } as ApiResponse<null>);
    return;
  }

  await new Promise<void>((resolve, reject) => {
    verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  await new Promise<void>((resolve, reject) => {
    verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  try {
    const { voteId, title, description, startDate, endDate, requiredPoints } = req.body as InAppVoteUpdateRequest;

    if (!voteId) {
      res.status(400).json({ success: false, error: "voteId is required" } as ApiResponse<null>);
      return;
    }

    const voteRef = admin.firestore().collection("inAppVotes").doc(voteId);
    const voteDoc = await voteRef.get();

    if (!voteDoc.exists) {
      res.status(404).json({ success: false, error: "Vote not found" } as ApiResponse<null>);
      return;
    }

    const updateData: Record<string, unknown> = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (title) updateData.title = title.trim();
    if (description) updateData.description = description.trim();
    if (startDate) updateData.startDate = admin.firestore.Timestamp.fromDate(new Date(startDate));
    if (endDate) updateData.endDate = admin.firestore.Timestamp.fromDate(new Date(endDate));
    if (typeof requiredPoints === "number") updateData.requiredPoints = requiredPoints;

    await voteRef.update(updateData);

    res.status(200).json({ success: true, data: { voteId, ...updateData } } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Update in-app vote error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
