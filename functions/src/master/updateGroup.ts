/**
 * Update group master
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { GroupUpdateRequest, ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const updateGroup = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "PATCH");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "PATCH") {
    res.status(405).json({ success: false, error: "Method not allowed. Use PATCH." } as ApiResponse<null>);
    return;
  }

  await new Promise<void>((resolve, reject) => {
    verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  await new Promise<void>((resolve, reject) => {
    verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  try {
    const { groupId, name, imageUrl } = req.body as GroupUpdateRequest;

    if (!groupId) {
      res.status(400).json({ success: false, error: "groupId is required" } as ApiResponse<null>);
      return;
    }

    const groupRef = admin.firestore().collection("groupMasters").doc(groupId);
    const groupDoc = await groupRef.get();

    if (!groupDoc.exists) {
      res.status(404).json({ success: false, error: "Group not found" } as ApiResponse<null>);
      return;
    }

    const updateData: { [key: string]: unknown } = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (name !== undefined) {
      updateData.name = name.trim();
    }
    if (imageUrl !== undefined) {
      updateData.imageUrl = imageUrl || null;
    }

    await groupRef.update(updateData);

    const updatedDoc = await groupRef.get();
    const updatedData = updatedDoc.data();

    res.status(200).json({
      success: true,
      data: {
        groupId: groupId,
        name: updatedData?.name,
        imageUrl: updatedData?.imageUrl,
        createdAt: updatedData?.createdAt?.toDate().toISOString() || null,
        updatedAt: updatedData?.updatedAt?.toDate().toISOString() || null,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Update group error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
