/**
 * Delete in-app vote
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const deleteInAppVote = functions
  .runWith(ADMIN_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

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
