/**
 * Get post detail
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const getPost = functions.https.onRequest(async (req, res) => {
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

  const currentUser = (req as AuthenticatedRequest).user;
  if (!currentUser) {
    res.status(401).json({ success: false, error: "Unauthorized" } as ApiResponse<null>);
    return;
  }

  try {
    const postId = req.query.postId as string;

    if (!postId) {
      res.status(400).json({ success: false, error: "postId is required" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();
    const postDoc = await db.collection("posts").doc(postId).get();

    if (!postDoc.exists) {
      res.status(404).json({ success: false, error: "Post not found" } as ApiResponse<null>);
      return;
    }

    const postData = postDoc.data()!;

    // Get user info
    const userDoc = await db.collection("users").doc(postData.userId).get();
    const userData = userDoc.exists ? userDoc.data() : null;

    // Check if current user liked this post
    const likeDoc = await db.collection("posts").doc(postId).collection("likes").doc(currentUser.uid).get();
    const isLikedByCurrentUser = likeDoc.exists;

    // Build user object
    const userObject = {
      uid: postData.userId,
      email: userData?.email || "",
      displayName: userData?.displayName || null,
      photoURL: userData?.photoURL || null,
      points: userData?.points || 0,
      biasIds: userData?.biasIds || [],
      followingCount: userData?.followingCount || 0,
      followersCount: userData?.followersCount || 0,
      postsCount: userData?.postsCount || 0,
      isPrivate: userData?.isPrivate || false,
      isSuspended: userData?.isSuspended || false,
      createdAt: userData?.createdAt?.toDate().toISOString() || new Date().toISOString(),
      updatedAt: userData?.updatedAt?.toDate().toISOString() || new Date().toISOString(),
    };

    const post = {
      id: postDoc.id,
      ...postData,
      user: userObject,
      createdAt: postData.createdAt?.toDate().toISOString() || null,
      updatedAt: postData.updatedAt?.toDate().toISOString() || null,
      isLikedByCurrentUser,
      userDisplayName: userData?.displayName || null,
      userPhotoURL: userData?.photoURL || null,
    };

    res.status(200).json({
      success: true,
      data: post,
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Get post error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
