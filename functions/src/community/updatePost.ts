/**
 * Update community post
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

interface UpdatePostRequest {
  postId: string;
  content?: Record<string, unknown>;
  biasIds?: string[];
}

export const updatePost = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use POST.",
    } as ApiResponse<null>);
    return;
  }

  await new Promise<void>((resolve, reject) => {
    verifyToken(
      req as AuthenticatedRequest,
      res,
      (error?: unknown) => error ? reject(error) : resolve(),
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
    const { postId, content, biasIds } = req.body as UpdatePostRequest;

    // Validation
    if (!postId) {
      res.status(400).json({
        success: false,
        error: "postId is required",
      } as ApiResponse<null>);
      return;
    }

    if (!content && !biasIds) {
      res.status(400).json({
        success: false,
        error: "At least one field (content or biasIds) must be provided",
      } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();
    const postRef = db.collection("posts").doc(postId);
    const postDoc = await postRef.get();

    // Check if post exists
    if (!postDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Post not found",
      } as ApiResponse<null>);
      return;
    }

    const postData = postDoc.data();

    // Check if current user is the post owner
    if (postData?.userId !== currentUser.uid) {
      res.status(403).json({
        success: false,
        error: "You can only edit your own posts",
      } as ApiResponse<null>);
      return;
    }

    // Build update data
    const updateData: Record<string, unknown> = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Update content if provided
    if (content) {
      const postType = postData?.type;

      // Type-specific validation
      if (postType === "vote_share") {
        if (content.voteId && !content.voteSnapshot) {
          res.status(400).json({
            success: false,
            error: "voteSnapshot required for vote_share",
          } as ApiResponse<null>);
          return;
        }
      }

      if (postType === "image") {
        if (content.images && Array.isArray(content.images)) {
          if (content.images.length === 0) {
            res.status(400).json({
              success: false,
              error: "At least one image required for image posts",
            } as ApiResponse<null>);
            return;
          }
          if (content.images.length > 4) {
            res.status(400).json({
              success: false,
              error: "Maximum 4 images allowed",
            } as ApiResponse<null>);
            return;
          }
        }
      }

      if (postType === "my_votes") {
        if (content.myVotes && Array.isArray(content.myVotes)) {
          if (content.myVotes.length === 0) {
            res.status(400).json({
              success: false,
              error: "At least one vote required for my_votes posts",
            } as ApiResponse<null>);
            return;
          }
        }
      }

      if (postType === "goods_trade") {
        if (content.goodsTrade) {
          const gt = content.goodsTrade as Record<string, unknown>;
          if (
            gt.idolId &&
            (!gt.goodsImageUrl ||
              !gt.goodsName ||
              !gt.tradeType ||
              !gt.goodsTags ||
              !Array.isArray(gt.goodsTags) ||
              gt.goodsTags.length === 0)
          ) {
            res.status(400).json({
              success: false,
              error: "goodsTrade requires: idolId, goodsImageUrl, goodsName, tradeType, and goodsTags",
            } as ApiResponse<null>);
            return;
          }
          if (gt.tradeType && !["want", "offer"].includes(gt.tradeType as string)) {
            res.status(400).json({
              success: false,
              error: "Invalid tradeType. Must be 'want' or 'offer'",
            } as ApiResponse<null>);
            return;
          }
        }
      }

      updateData.content = content;
    }

    // Update biasIds if provided
    if (biasIds) {
      if (!Array.isArray(biasIds) || biasIds.length === 0) {
        res.status(400).json({
          success: false,
          error: "biasIds must be a non-empty array",
        } as ApiResponse<null>);
        return;
      }
      updateData.biasIds = biasIds;
    }

    // Update the post
    await postRef.update(updateData);

    // Fetch updated post
    const updatedDoc = await postRef.get();
    const updatedData = updatedDoc.data();

    // Get user info
    const userRef = db.collection("users").doc(currentUser.uid);
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
      postsCount: userData?.postsCount || 0,
      isPrivate: userData?.isPrivate || false,
      isSuspended: userData?.isSuspended || false,
      createdAt: userData?.createdAt?.toDate().toISOString() || new Date().toISOString(),
      updatedAt: userData?.updatedAt?.toDate().toISOString() || new Date().toISOString(),
    };

    res.status(200).json({
      success: true,
      data: {
        ...updatedData,
        user: userObject,
        createdAt: updatedData?.createdAt?.toDate().toISOString() || new Date().toISOString(),
        updatedAt: updatedData?.updatedAt?.toDate().toISOString() || new Date().toISOString(),
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Update post error:", error);
    res.status(500).json({
      success: false,
      error: "Internal server error",
    } as ApiResponse<null>);
  }
});
