/**
 * Delete in-app vote
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const deleteInAppVote = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "DELETE");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "DELETE") {
    res.status(405).json({ success: false, error: "Method not allowed. Use DELETE." } as ApiResponse<null>);
    return;
  }

  await new Promise<void>((resolve, reject) => {
    verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  await new Promise<void>((resolve, reject) => {
    verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  try {
    const voteId = req.query.voteId as string;

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

    await voteRef.delete();

    res.status(200).json({ success: true, data: { voteId, deleted: true } } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Delete in-app vote error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
