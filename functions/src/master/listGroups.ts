/**
 * List group masters
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const listGroups = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

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

      const query = admin.firestore().collection("groupMasters").orderBy("name", "asc");

      const snapshot = await query.get();

      const groups = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          groupId: doc.id,
          name: data.name,
          imageUrl: data.imageUrl,
          createdAt: data.createdAt?.toDate().toISOString() || null,
          updatedAt: data.updatedAt?.toDate().toISOString() || null,
        };
      });

      res.status(200).json({
        success: true,
        data: { groups, count: groups.length },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("List groups error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
