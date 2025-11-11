/**
 * Suspend or restore user account
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { UserSuspendRequest, ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const suspendUser = functions.https.onRequest(async (req, res) => {
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
    const { uid, suspend, reason, suspendUntil } = req.body as UserSuspendRequest;

    if (!uid || typeof suspend !== "boolean") {
      res.status(400).json({ success: false, error: "uid and suspend are required" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
      return;
    }

    const updateData: Record<string, unknown> = {
      isSuspended: suspend,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (suspend) {
      updateData.suspendReason = reason || "Admin action";
      if (suspendUntil) {
        updateData.suspendedUntil = admin.firestore.Timestamp.fromDate(new Date(suspendUntil));
      } else {
        updateData.suspendedUntil = null; // Permanent suspension
      }

      // Disable Firebase Authentication
      await admin.auth().updateUser(uid, { disabled: true });
    } else {
      // Restore account
      updateData.suspendReason = null;
      updateData.suspendedUntil = null;

      // Re-enable Firebase Authentication
      await admin.auth().updateUser(uid, { disabled: false });
    }

    await userRef.update(updateData);

    // Record action
    await db.collection("adminActions").add({
      actionType: suspend ? "suspend" : "restore",
      targetUserId: uid,
      reason: reason || null,
      suspendedUntil: suspendUntil || null,
      performedBy: (req as AuthenticatedRequest).user?.uid,
      performedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).json({
      success: true,
      data: { uid, suspended: suspend, reason, suspendUntil },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Suspend user error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
