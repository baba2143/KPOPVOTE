/**
 * Follow user
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FollowRequest, ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const followUser = functions.https.onRequest(async (req, res) => {
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
      res.status(400).json({ success: false, error: "Cannot follow yourself" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();

    // Check if user to follow exists
    const userToFollowDoc = await db.collection("users").doc(userId).get();
    if (!userToFollowDoc.exists) {
      res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
      return;
    }

    const followId = `${currentUser.uid}_${userId}`;
    const followRef = db.collection("follows").doc(followId);

    // Check if already following
    const existingFollow = await followRef.get();
    if (existingFollow.exists) {
      res.status(400).json({ success: false, error: "Already following this user" } as ApiResponse<null>);
      return;
    }

    // Create follow document
    const followData = {
      id: followId,
      followerId: currentUser.uid,
      followingId: userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await followRef.set(followData);

    // Increment counts using batch
    const batch = db.batch();

    const followerRef = db.collection("users").doc(currentUser.uid);
    batch.update(followerRef, {
      followingCount: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const followingRef = db.collection("users").doc(userId);
    batch.update(followingRef, {
      followersCount: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Create notification for followed user
    const notificationRef = db.collection("notifications").doc();
    const currentUserDoc = await db.collection("users").doc(currentUser.uid).get();
    const currentUserData = currentUserDoc.data();

    await notificationRef.set({
      id: notificationRef.id,
      userId: userId,
      type: "follow",
      title: "New Follower",
      body: `${currentUserData?.displayName || "Someone"} started following you`,
      isRead: false,
      actionUserId: currentUser.uid,
      actionUserDisplayName: currentUserData?.displayName || null,
      actionUserPhotoURL: currentUserData?.photoURL || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({
      success: true,
      data: {
        followId,
        followerId: currentUser.uid,
        followingId: userId,
        createdAt: new Date().toISOString(),
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Follow user error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
