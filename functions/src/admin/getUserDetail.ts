/**
 * Get user detail
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const getUserDetail = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "GET") {
    res.status(405).json({ success: false, error: "Method not allowed. Use GET." } as ApiResponse<null>);
    return;
  }

  await new Promise<void>((resolve, reject) => {
    verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  await new Promise<void>((resolve, reject) => {
    verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  try {
    const uid = req.query.uid as string;

    if (!uid) {
      res.status(400).json({ success: false, error: "uid is required" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();

    // Get user document
    const userDoc = await db.collection("users").doc(uid).get();

    if (!userDoc.exists) {
      res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
      return;
    }

    const userData = userDoc.data()!;

    // Get task count
    const tasksSnapshot = await db
      .collection("users")
      .doc(uid)
      .collection("tasks")
      .count()
      .get();
    const taskCount = tasksSnapshot.data().count;

    // Get vote count
    const votesSnapshot = await db
      .collection("voteRecords")
      .where("userId", "==", uid)
      .count()
      .get();
    const voteCount = votesSnapshot.data().count;

    const userDetail = {
      uid,
      email: userData.email,
      displayName: userData.displayName || null,
      photoURL: userData.photoURL || null,
      myBias: userData.myBias || [],
      points: userData.points || 0,
      taskCount,
      voteCount,
      isSuspended: userData.isSuspended || false,
      suspendedUntil: userData.suspendedUntil?.toDate().toISOString() || null,
      suspendReason: userData.suspendReason || null,
      createdAt: userData.createdAt?.toDate().toISOString() || null,
      updatedAt: userData.updatedAt?.toDate().toISOString() || null,
    };

    res.status(200).json({
      success: true,
      data: userDetail,
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Get user detail error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
