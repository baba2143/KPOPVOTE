//
// searchCollections.ts
// K-VOTE COLLECTOR - Search Collections API
//

import { Request, Response } from "express";
import * as admin from "firebase-admin";
import {
  VoteCollectionResponse,
  SearchCollectionsQuery,
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
 * Search Collections
 * GET /api/collections/search
 *
 * Query Parameters:
 * - q: string (search query, required)
 * - page: number (default: 1)
 * - limit: number (default: 20, max: 50)
 * - sortBy: "relevance" | "latest" | "popular" (default: "relevance")
 * - tags: string[] (filter by tags)
 */
export async function searchCollections(
  req: Request,
  res: Response
): Promise<void> {
  try {
    const searchQuery = req.query.q as string;

    if (!searchQuery || searchQuery.trim().length === 0) {
      res.status(400).json({
        success: false,
        error: "検索クエリが必要です",
      });
      return;
    }

    // Parse query parameters
    const page = parseInt(req.query.page as string) || 1;
    const limit = Math.min(parseInt(req.query.limit as string) || 20, 50);

    const query: SearchCollectionsQuery = {
      q: searchQuery.trim(),
      page,
      limit,
      sortBy:
        (req.query.sortBy as "relevance" | "latest" | "popular") || "relevance",
      tags: req.query.tags ?
        (Array.isArray(req.query.tags) ?
          req.query.tags as string[] : [req.query.tags as string]) :
        undefined,
    };

    const db = admin.firestore();

    // Firestore doesn't support full-text search natively
    // Simple implementation using title/description matching
    // In production, consider using Algolia or Elasticsearch

    let collectionQuery = db.collection("collections")
      .where("visibility", "==", "public");

    // Apply tag filter if provided
    if (query.tags && query.tags.length > 0) {
      collectionQuery =
        collectionQuery.where("tags", "array-contains-any", query.tags);
    }

    // Get all matching visibility collections
    const snapshot = await collectionQuery.get();

    // Filter by search query in title and description
    const searchLower = query.q.toLowerCase();
    const filteredCollections: VoteCollectionResponse[] = snapshot.docs
      .map((doc) => {
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
      })
      .filter((collection) => {
        const titleMatch = collection.title.toLowerCase().includes(searchLower);
        const descMatch = collection.description.toLowerCase().includes(searchLower);
        const tagMatch =
          collection.tags.some((tag: string) => tag.toLowerCase().includes(searchLower));
        return titleMatch || descMatch || tagMatch;
      });

    // Apply sorting
    switch (query.sortBy) {
    case "popular":
      filteredCollections.sort((a, b) => b.saveCount - a.saveCount);
      break;
    case "latest":
      filteredCollections.sort((a, b) => {
        return b.createdAt.localeCompare(a.createdAt);
      });
      break;
    case "relevance":
    default:
      // Simple relevance: title match > description match > tag match
      filteredCollections.sort((a, b) => {
        const aScore = (
          (a.title.toLowerCase().includes(searchLower) ? 3 : 0) +
            (a.description.toLowerCase().includes(searchLower) ? 2 : 0) +
            (a.tags.some((tag: string) => tag.toLowerCase().includes(searchLower)) ? 1 : 0)
        );
        const bScore = (
          (b.title.toLowerCase().includes(searchLower) ? 3 : 0) +
            (b.description.toLowerCase().includes(searchLower) ? 2 : 0) +
            (b.tags.some((tag: string) => tag.toLowerCase().includes(searchLower)) ? 1 : 0)
        );
        return bScore - aScore;
      });
      break;
    }

    const totalCount = filteredCollections.length;

    // Apply pagination
    const offset = (page - 1) * limit;
    const paginatedCollections = filteredCollections.slice(offset, offset + limit);

    const response: CollectionsListResponse = {
      success: true,
      data: {
        collections: paginatedCollections,
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
    console.error("❌ [searchCollections] Error:", error);
    res.status(500).json({
      success: false,
      error: "コレクションの検索に失敗しました",
    });
  }
}
