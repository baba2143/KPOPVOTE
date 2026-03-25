/**
 * Delete idol master
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const deleteIdol = functions
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
    // Support both body and query parameter for flexibility
      const idolId = req.body?.idolId || req.query.idolId as string;

      if (!idolId) {
        res.status(400).json({ success: false, error: "idolId is required" } as ApiResponse<null>);
        return;
      }

      const idolRef = admin.firestore().collection("idolMasters").doc(idolId);
      const idolDoc = await idolRef.get();

      if (!idolDoc.exists) {
        res.status(404).json({ success: false, error: "Idol not found" } as ApiResponse<null>);
        return;
      }

      await idolRef.delete();

      res.status(200).json({ success: true, data: { idolId, deleted: true } } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("Delete idol error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
