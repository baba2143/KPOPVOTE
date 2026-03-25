/**
 * List external app masters
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const listExternalApps = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "GET") {
      res.status(405).json({ success: false, error: "Method not allowed. Use GET." } as ApiResponse<null>);
      return;
    }

    try {
    // No authentication required - external app masters are public configuration data
      const limit = req.query.limit ? parseInt(req.query.limit as string) : 100;

      const snapshot = await admin
        .firestore()
        .collection("externalAppMasters")
        .orderBy("appName", "asc")
        .limit(limit)
        .get();

      const apps = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          appId: doc.id,
          appName: data.appName,
          appUrl: data.appUrl,
          iconUrl: data.iconUrl,
          defaultCoverImageUrl: data.defaultCoverImageUrl || null,
          createdAt: data.createdAt?.toDate().toISOString() || null,
          updatedAt: data.updatedAt?.toDate().toISOString() || null,
        };
      });

      res.status(200).json({
        success: true,
        data: { apps, count: apps.length },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("List external apps error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
