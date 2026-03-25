/**
 * Create external app master
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ExternalAppCreateRequest, ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const createExternalApp = functions
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
      const { appName, appUrl, iconUrl, defaultCoverImageUrl } = req.body as ExternalAppCreateRequest;

      if (!appName || !appUrl) {
        res.status(400).json({ success: false, error: "appName and appUrl are required" } as ApiResponse<null>);
        return;
      }

      const appData = {
        appName: appName.trim(),
        appUrl: appUrl.trim(),
        iconUrl: iconUrl || null,
        defaultCoverImageUrl: defaultCoverImageUrl || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const appRef = await admin.firestore().collection("externalAppMasters").add(appData);

      res.status(201).json({
        success: true,
        data: { appId: appRef.id, ...appData },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("Create external app error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
