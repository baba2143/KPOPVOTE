//
// getCollections.ts
// K-VOTE COLLECTOR - Get Collections List API
//

import { Request, Response } from "express";
import * as admin from "firebase-admin";
import {
  VoteCollectionResponse,
  GetCollectionsQuery,
  CollectionsListResponse,
} from "../../types/voteCollection";

/**
 * Convert Date to ISO8601 string without milliseconds
 * Swift's .iso8601 decoder doesn't support milliseconds
 * @param date Date to convert
 * @returns ISO8601 string without milliseconds (e.g. "2025-11-22T09:24:00Z")
 */
const toISOStringWithoutMillis = (date: Date): string => {
  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
};

/**
 * Get Collections List
 * GET /api/collections
 *
 * Query Parameters:
 * - page: number (default: 1)
 * - limit: number (default: 20, max: 50)
 * - sortBy: "latest" | "popular" | "trending" (default: "latest")
 * - tags: string[] (filter by tags)
 * - visibility: "public" | "followers" | "private"
 * @param {Request} req Express request
 * @param {Response} res Express response
 * @return {Promise<void>} Promise void
 */
export async function getCollections(
  req: Request,
  res: Response
): Promise<void> {
  try {
    // Parse query parameters
    const page = parseInt(req.query.page as string) || 1;
    const limit = Math.min(parseInt(req.query.limit as string) || 20, 50);

    const query: GetCollectionsQuery = {
      page,
      limit,
      sortBy:
        (req.query.sortBy as "latest" | "popular" | "trending") || "latest",
      tags: req.query.tags ?
        (Array.isArray(req.query.tags) ?
          req.query.tags as string[] : [req.query.tags as string]) :
        undefined,
      visibility:
        req.query.visibility as "public" | "followers" | "private" | undefined,
    };

    const db = admin.firestore();
    let collectionQuery = db.collection("collections").where("visibility", "==", "public");

    // Apply tag filter
    if (query.tags && query.tags.length > 0) {
      collectionQuery = collectionQuery.where("tags", "array-contains-any", query.tags);
    }

    // Apply sorting
    switch (query.sortBy) {
    case "popular":
      collectionQuery = collectionQuery.orderBy("saveCount", "desc");
      break;
    case "trending":
      // Trending = high engagement in recent period
      collectionQuery = collectionQuery.orderBy("viewCount", "desc");
      break;
    case "latest":
    default:
      collectionQuery = collectionQuery.orderBy("createdAt", "desc");
      break;
    }

    // Get total count for pagination
    const countSnapshot = await collectionQuery.count().get();
    const totalCount = countSnapshot.data().count;

    // Apply pagination
    const offset = (page - 1) * limit;
    const snapshot = await collectionQuery
      .offset(offset)
      .limit(limit)
      .get();

    const collections: VoteCollectionResponse[] = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        collectionId: doc.id,
        creatorId: data.creatorId,
        creatorName: data.creatorName,
        creatorAvatarUrl: data.creatorAvatarUrl,
        title: data.title,
        description: data.description,
        coverImage: data.coverImage,
        tags: data.tags || [],
        tasks: (data.tasks || []).map((task: any) => ({
          ...task,
          deadline: task.deadline?.toDate ? toISOStringWithoutMillis(task.deadline.toDate()) : task.deadline,
        })),
        taskCount: data.taskCount || 0,
        visibility: data.visibility || "public",
        likeCount: data.likeCount || 0,
        saveCount: data.saveCount || 0,
        viewCount: data.viewCount || 0,
        commentCount: data.commentCount || 0,
        createdAt: data.createdAt?.toDate ?
          toISOStringWithoutMillis(data.createdAt.toDate()) :
          toISOStringWithoutMillis(new Date()),
        updatedAt: data.updatedAt?.toDate ?
          toISOStringWithoutMillis(data.updatedAt.toDate()) :
          toISOStringWithoutMillis(new Date()),
      };
    });

    const response: CollectionsListResponse = {
      success: true,
      data: {
        collections,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(totalCount / limit),
          totalCount,
          hasNext: page * limit < totalCount,
        },
      },
    };

    res.status(200).json(response);
  } catch (error) {
    console.error("❌ [getCollections] Error:", error);
    res.status(500).json({
      success: false,
      error: "コレクションの取得に失敗しました",
    });
  }
}
