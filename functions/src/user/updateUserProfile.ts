/**
 * Update User Profile
 *
 * Updates user profile information (displayName, bio, biasIds)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

interface UpdateProfileRequest {
  displayName?: string;
  bio?: string;
  biasIds?: string[];
  photoURL?: string;
}

export const updateUserProfile = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, PUT");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST" && req.method !== "PUT") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use POST or PUT.",
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
    const { displayName, bio, biasIds, photoURL } = req.body as UpdateProfileRequest;

    // Validation
    if (displayName !== undefined) {
      if (typeof displayName !== "string" || displayName.trim().length === 0) {
        res.status(400).json({
          success: false,
          error: "displayName must be a non-empty string",
        } as ApiResponse<null>);
        return;
      }
      if (displayName.length > 30) {
        res.status(400).json({
          success: false,
          error: "displayName must be 30 characters or less",
        } as ApiResponse<null>);
        return;
      }
    }

    if (bio !== undefined && typeof bio !== "string") {
      res.status(400).json({
        success: false,
        error: "bio must be a string",
      } as ApiResponse<null>);
      return;
    }

    if (bio && bio.length > 150) {
      res.status(400).json({
        success: false,
        error: "bio must be 150 characters or less",
      } as ApiResponse<null>);
      return;
    }

    if (biasIds !== undefined && !Array.isArray(biasIds)) {
      res.status(400).json({
        success: false,
        error: "biasIds must be an array",
      } as ApiResponse<null>);
      return;
    }

    // Build update data
    const updateData: Record<string, unknown> = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (displayName !== undefined) {
      updateData.displayName = displayName.trim();
    }

    if (bio !== undefined) {
      updateData.bio = bio.trim();
    }

    if (biasIds !== undefined) {
      updateData.selectedIdols = biasIds;
    }

    if (photoURL !== undefined) {
      updateData.photoURL = photoURL;
    }

    // Update Firestore
    const db = admin.firestore();
    await db.collection("users").doc(currentUser.uid).update(updateData);

    // Get updated user data
    const userDoc = await db.collection("users").doc(currentUser.uid).get();
    const userData = userDoc.data()!;

    console.log(`✅ [updateUserProfile] Profile updated for user: ${currentUser.uid}`);

    res.status(200).json({
      success: true,
      data: {
        uid: currentUser.uid,
        email: userData.email,
        displayName: userData.displayName || null,
        photoURL: userData.photoURL || null,
        bio: userData.bio || null,
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
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Update user profile error:", error);
    res.status(500).json({
      success: false,
      error: "Internal server error",
    } as ApiResponse<null>);
  }
});
