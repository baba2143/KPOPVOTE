/**
 * Create group master
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { GroupCreateRequest, ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const createGroup = functions
  .runWith(ADMIN_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "POST") {
      res.status(405).json({ success: false, error: "Method not allowed. Use POST." } as ApiResponse<null>);
      return;
    }

    await new Promise<void>((resolve, reject) => {
      verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
    });

    await new Promise<void>((resolve, reject) => {
      verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
    });

    try {
      const { name, imageUrl } = req.body as GroupCreateRequest;

      if (!name) {
        res.status(400).json({ success: false, error: "name is required" } as ApiResponse<null>);
        return;
      }

      const groupData = {
        name: name.trim(),
        imageUrl: imageUrl || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const groupRef = await admin.firestore().collection("groupMasters").add(groupData);

      res.status(201).json({
        success: true,
        data: { groupId: groupRef.id, ...groupData },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("Create group error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
