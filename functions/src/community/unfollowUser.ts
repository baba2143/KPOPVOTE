/**
 * Unfollow user
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FollowRequest, ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const unfollowUser = functions.https.onRequest(async (req, res) => {
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

  const currentUser = (req as AuthenticatedRequest).user;
  if (!currentUser) {
    res.status(401).json({ success: false, error: "Unauthorized" } as ApiResponse<null>);
    return;
  }

  try {
    const { userId } = req.body as FollowRequest;

    // Validation
    if (!userId) {
      res.status(400).json({ success: false, error: "userId is required" } as ApiResponse<null>);
      return;
    }

    if (userId === currentUser.uid) {
      res.status(400).json({ success: false, error: "Cannot unfollow yourself" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();
    const followId = `${currentUser.uid}_${userId}`;
    const followRef = db.collection("follows").doc(followId);

    // Check if follow relationship exists
    const existingFollow = await followRef.get();
    if (!existingFollow.exists) {
      res.status(404).json({ success: false, error: "Not following this user" } as ApiResponse<null>);
      return;
    }

    // Delete follow document
    await followRef.delete();

    // Decrement counts using batch
    const batch = db.batch();

    const followerRef = db.collection("users").doc(currentUser.uid);
    batch.update(followerRef, {
      followingCount: admin.firestore.FieldValue.increment(-1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const followingRef = db.collection("users").doc(userId);
    batch.update(followingRef, {
      followersCount: admin.firestore.FieldValue.increment(-1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    res.status(200).json({
      success: true,
      data: {
        message: "Successfully unfollowed user",
        followerId: currentUser.uid,
        followingId: userId,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Unfollow user error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
