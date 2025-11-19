/**
 * Get comments for a post
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

interface Comment {
  id: string;
  postId: string;
  userId: string;
  text: string;
  createdAt: Date;
  updatedAt: Date;
  user: {
    displayName: string | null;
    photoURL: string | null;
  };
}

interface GetCommentsResponse {
  comments: Comment[];
  hasMore: boolean;
}

export const getComments = functions.https.onRequest(async (req, res) => {
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
    const limit = parseInt(req.query.limit as string) || 20;
    const lastCommentId = req.query.lastCommentId as string | undefined;

    // Validation
    if (!postId) {
      res.status(400).json({ success: false, error: "postId is required" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();

    // Check if post exists
    const postDoc = await db.collection("posts").doc(postId).get();
    if (!postDoc.exists) {
      res.status(404).json({ success: false, error: "Post not found" } as ApiResponse<null>);
      return;
    }

    // Build query
    let query = db
      .collection("comments")
      .where("postId", "==", postId)
      .orderBy("createdAt", "desc")
      .limit(limit + 1); // Fetch one extra to check if there are more

    // Pagination: Start after lastCommentId
    if (lastCommentId) {
      const lastCommentDoc = await db.collection("comments").doc(lastCommentId).get();
      if (lastCommentDoc.exists) {
        query = query.startAfter(lastCommentDoc);
      }
    }

    const commentsSnapshot = await query.get();
    const hasMore = commentsSnapshot.size > limit;
    const commentsToReturn = hasMore ? commentsSnapshot.docs.slice(0, limit) : commentsSnapshot.docs;

    // Fetch user data for each comment
    const comments: Comment[] = await Promise.all(
      commentsToReturn.map(async (commentDoc) => {
        const commentData = commentDoc.data();
        const userId = commentData.userId;

        // Fetch user profile
        const userDoc = await db.collection("users").doc(userId).get();
        const userData = userDoc.data();

        return {
          id: commentDoc.id,
          postId: commentData.postId,
          userId: userId,
          text: commentData.text,
          createdAt: commentData.createdAt?.toDate() || new Date(),
          updatedAt: commentData.updatedAt?.toDate() || new Date(),
          user: {
            displayName: userData?.displayName || null,
            photoURL: userData?.photoURL || null,
          },
        };
      })
    );

    res.status(200).json({
      success: true,
      data: {
        comments,
        hasMore,
      },
    } as ApiResponse<GetCommentsResponse>);
  } catch (error) {
    console.error("Error getting comments:", error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Failed to get comments",
    } as ApiResponse<null>);
  }
});
