/**
 * Delete group master
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const deleteGroup = functions
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
      const { groupId } = req.body as { groupId: string };

      if (!groupId) {
        res.status(400).json({ success: false, error: "groupId is required" } as ApiResponse<null>);
        return;
      }

      // Check if any idols reference this group
      const idolsSnapshot = await admin
        .firestore()
        .collection("idolMasters")
        .where("groupId", "==", groupId)
        .limit(1)
        .get();

      if (!idolsSnapshot.empty) {
        res.status(400).json({
          success: false,
          error: "Cannot delete group with associated idols. Please reassign or delete the idols first.",
        } as ApiResponse<null>);
        return;
      }

      const groupRef = admin.firestore().collection("groupMasters").doc(groupId);
      const groupDoc = await groupRef.get();

      if (!groupDoc.exists) {
        res.status(404).json({ success: false, error: "Group not found" } as ApiResponse<null>);
        return;
      }

      await groupRef.delete();

      res.status(200).json({
        success: true,
        data: null,
      } as ApiResponse<null>);
    } catch (error: unknown) {
      console.error("Delete group error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
