/**
 * Get User Profile
 *
 * Returns user profile information including posts, follow status, and statistics
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

interface UserProfile {
  id: string;
  displayName: string;
  photoURL: string | null;
  bio: string | null;
  selectedIdols: string[];
  followersCount: number;
  followingCount: number;
  postsCount: number;
  isFollowing: boolean;
  isFollowedBy: boolean;
  posts: unknown[];
}

export const getUserProfile = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "GET") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use GET.",
    } as ApiResponse<null>);
    return;
  }

  await new Promise<void>((resolve, reject) => {
    verifyToken(
      req as AuthenticatedRequest,
      res,
      (error?: unknown) => (error ? reject(error) : resolve())
    );
  });

  const currentUser = (req as AuthenticatedRequest).user;
  if (!currentUser) {
    res.status(401).json({
      success: false,
      error: "Unauthorized",
    } as ApiResponse<null>);
    return;
  }

  try {
    const userId = req.query.userId as string | undefined;

    if (!userId) {
      res.status(400).json({
        success: false,
        error: "userId is required",
      } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();

    // Get user data
    const userDoc = await db.collection("users").doc(userId).get();

    if (!userDoc.exists) {
      res.status(404).json({
        success: false,
        error: "User not found",
      } as ApiResponse<null>);
      return;
    }

    const userData = userDoc.data()!;

    // Check if current user is following this user
    const followingSnapshot = await db
      .collection("follows")
      .where("followerId", "==", currentUser.uid)
      .where("followingId", "==", userId)
      .limit(1)
      .get();
    const isFollowing = !followingSnapshot.empty;

    // Check if this user is following current user
    const followedBySnapshot = await db
      .collection("follows")
      .where("followerId", "==", userId)
      .where("followingId", "==", currentUser.uid)
      .limit(1)
      .get();
    const isFollowedBy = !followedBySnapshot.empty;

    // Get user's posts
    const postsSnapshot = await db
      .collection("posts")
      .where("userId", "==", userId)
      .orderBy("createdAt", "desc")
      .limit(20)
      .get();

    const posts = postsSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        userId: data.userId,
        user: {
          uid: userId,
          email: userData.email || "",
          displayName: userData.displayName || null,
          photoURL: userData.photoURL || null,
          points: userData.points || 0,
          biasIds: userData.selectedIdols || [],
          followingCount: userData.followingCount || 0,
          followersCount: userData.followersCount || 0,
          postsCount: userData.postsCount || 0,
          isPrivate: userData.isPrivate || false,
          isSuspended: userData.isSuspended || false,
          createdAt: userData.createdAt?.toDate().getTime() / 1000 || Date.now() / 1000,
          updatedAt: userData.updatedAt?.toDate().getTime() / 1000 || Date.now() / 1000,
        },
        type: data.type,
        content: data.content,
        biasIds: data.biasIds || [],
        likesCount: data.likesCount || 0,
        commentsCount: data.commentsCount || 0,
        sharesCount: data.sharesCount || 0,
        createdAt: data.createdAt?.toDate().toISOString() || null,
        updatedAt: data.updatedAt?.toDate().toISOString() || null,
      };
    });

    const profile: UserProfile = {
      id: userId,
      displayName: userData.displayName || "Unknown",
      photoURL: userData.photoURL || null,
      bio: userData.bio || null,
      selectedIdols: userData.selectedIdols || [],
      followersCount: userData.followersCount || 0,
      followingCount: userData.followingCount || 0,
      postsCount: userData.postsCount || 0,
      isFollowing,
      isFollowedBy,
      posts,
    };

    res.status(200).json({
      success: true,
      data: profile,
    } as ApiResponse<UserProfile>);
  } catch (error: unknown) {
    console.error("Get user profile error:", error);
    res.status(500).json({
      success: false,
      error: "Internal server error",
    } as ApiResponse<null>);
  }
});
