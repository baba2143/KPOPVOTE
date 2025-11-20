/**
 * Create community post
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { CreatePostRequest, ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const createPost = functions.https.onRequest(async (req, res) => {
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
    const { type, content, biasIds } = req.body as CreatePostRequest;

    // Validation
    if (!type || !content || !biasIds) {
      res.status(400).json({ success: false, error: "type, content, and biasIds are required" } as ApiResponse<null>);
      return;
    }

    if (!["vote_share", "image", "my_votes", "goods_trade"].includes(type)) {
      res.status(400).json({ success: false, error: "Invalid post type" } as ApiResponse<null>);
      return;
    }

    if (!Array.isArray(biasIds) || biasIds.length === 0) {
      res.status(400).json({ success: false, error: "biasIds must be a non-empty array" } as ApiResponse<null>);
      return;
    }

    // Type-specific validation
    if (type === "vote_share") {
      if (!content.voteIds || !Array.isArray(content.voteIds) || content.voteIds.length === 0) {
        res.status(400).json({
          success: false,
          error: "voteIds must be a non-empty array for vote_share",
        } as ApiResponse<null>);
        return;
      }
      if (!content.voteSnapshots || !Array.isArray(content.voteSnapshots) || content.voteSnapshots.length === 0) {
        res.status(400).json({
          success: false,
          error: "voteSnapshots must be a non-empty array for vote_share",
        } as ApiResponse<null>);
        return;
      }
    }

    if (type === "image") {
      if (!content.images || content.images.length === 0) {
        res.status(400).json({ success: false, error: "images required for image posts" } as ApiResponse<null>);
        return;
      }
      if (content.images.length > 4) {
        res.status(400).json({ success: false, error: "Maximum 4 images allowed" } as ApiResponse<null>);
        return;
      }
    }

    if (type === "my_votes") {
      if (!content.myVotes || content.myVotes.length === 0) {
        res.status(400).json({ success: false, error: "myVotes required for my_votes posts" } as ApiResponse<null>);
        return;
      }
    }

    if (type === "goods_trade") {
      if (!content.goodsTrade) {
        res.status(400).json({
          success: false,
          error: "goodsTrade required for goods_trade posts",
        } as ApiResponse<null>);
        return;
      }
      const gt = content.goodsTrade;
      if (
        !gt.idolId ||
        !gt.goodsImageUrl ||
        !gt.goodsName ||
        !gt.tradeType ||
        !gt.goodsTags ||
        gt.goodsTags.length === 0
      ) {
        res.status(400).json({
          success: false,
          error: "goodsTrade requires: idolId, goodsImageUrl, goodsName, tradeType, and goodsTags",
        } as ApiResponse<null>);
        return;
      }
      if (!["want", "offer"].includes(gt.tradeType)) {
        res.status(400).json({
          success: false,
          error: "Invalid tradeType. Must be 'want' or 'offer'",
        } as ApiResponse<null>);
        return;
      }
    }

    const db = admin.firestore();
    const postRef = db.collection("posts").doc();

    const postData = {
      id: postRef.id,
      userId: currentUser.uid,
      type,
      content,
      biasIds,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      isReported: false,
      reportCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await postRef.set(postData);

    // Increment user's postsCount
    const userRef = db.collection("users").doc(currentUser.uid);
    await userRef.update({
      postsCount: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Get user info to include in response
    const userDoc = await userRef.get();
    const userData = userDoc.exists ? userDoc.data() : null;

    // Build user object for response
    const userObject = {
      uid: currentUser.uid,
      email: currentUser.email || "",
      displayName: userData?.displayName || null,
      photoURL: userData?.photoURL || null,
      points: userData?.points || 0,
      biasIds: userData?.biasIds || [],
      followingCount: userData?.followingCount || 0,
      followersCount: userData?.followersCount || 0,
      postsCount: (userData?.postsCount || 0) + 1, // Already incremented
      isPrivate: userData?.isPrivate || false,
      isSuspended: userData?.isSuspended || false,
      createdAt: userData?.createdAt?.toDate().toISOString() || new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    res.status(201).json({
      success: true,
      data: {
        ...postData,
        user: userObject,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Create post error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
