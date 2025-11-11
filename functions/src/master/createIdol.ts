/**
 * Create idol master
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { IdolCreateRequest, ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const createIdol = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

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
    const { name, groupName, imageUrl } = req.body as IdolCreateRequest;

    if (!name || !groupName) {
      res.status(400).json({ success: false, error: "name and groupName are required" } as ApiResponse<null>);
      return;
    }

    const idolData = {
      name: name.trim(),
      groupName: groupName.trim(),
      imageUrl: imageUrl || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const idolRef = await admin.firestore().collection("idolMasters").add(idolData);

    res.status(201).json({
      success: true,
      data: { idolId: idolRef.id, ...idolData },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Create idol error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
