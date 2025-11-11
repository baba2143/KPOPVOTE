/**
 * Delete external app master
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const deleteExternalApp = functions.https.onRequest(async (req, res) => {
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
    const appId = req.query.appId as string;

    if (!appId) {
      res.status(400).json({ success: false, error: "appId is required" } as ApiResponse<null>);
      return;
    }

    const appRef = admin.firestore().collection("externalAppMasters").doc(appId);
    const appDoc = await appRef.get();

    if (!appDoc.exists) {
      res.status(404).json({ success: false, error: "App not found" } as ApiResponse<null>);
      return;
    }

    await appRef.delete();

    res.status(200).json({ success: true, data: { appId, deleted: true } } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Delete external app error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
