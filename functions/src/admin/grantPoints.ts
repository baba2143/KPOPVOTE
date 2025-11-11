/**
 * Grant points to user
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { PointGrantRequest, ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const grantPoints = functions.https.onRequest(async (req, res) => {
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
    const { uid, points, reason } = req.body as PointGrantRequest;

    if (!uid || typeof points !== "number" || !reason) {
      res.status(400).json({ success: false, error: "uid, points, and reason are required" } as ApiResponse<null>);
      return;
    }

    if (points === 0) {
      res.status(400).json({ success: false, error: "points must be non-zero" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
      return;
    }

    // Update points
    await userRef.update({
      points: admin.firestore.FieldValue.increment(points),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Record transaction
    await db.collection("pointTransactions").add({
      userId: uid,
      points,
      type: points > 0 ? "grant" : "deduct",
      reason,
      grantedBy: (req as AuthenticatedRequest).user?.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Get updated points
    const updatedDoc = await userRef.get();
    const currentPoints = updatedDoc.data()!.points || 0;

    res.status(200).json({
      success: true,
      data: { uid, pointsGranted: points, currentPoints, reason },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Grant points error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
