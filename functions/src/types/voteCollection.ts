//
// voteCollection.ts
// K-VOTE COLLECTOR - Vote Collection Type Definitions
//

import { Timestamp } from "firebase-admin/firestore";

/**
 * Vote Collection - User-created collection of voting tasks
 */
export interface VoteCollection {
  // Basic Information
  collectionId: string;
  creatorId: string;
  creatorName: string;
  creatorAvatarUrl?: string;

  // Collection Content
  title: string; // Max 50 characters
  description: string; // Max 500 characters
  coverImage?: string;
  tags: string[]; // Max 10 tags

  // Included Tasks
  tasks: VoteTaskInCollection[]; // Max 50 tasks
  taskCount: number;

  // Visibility Settings
  visibility: CollectionVisibility;

  // Engagement Metrics
  likeCount: number;
  saveCount: number;
  viewCount: number;
  commentCount: number;

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

/**
 * Task within a Collection
 */
export interface VoteTaskInCollection {
  taskId: string;
  title: string;
  url: string;
  deadline: Timestamp;
  externalAppId?: string;
  externalAppName?: string;
  externalAppIconUrl?: string;
  coverImage?: string;
  orderIndex: number;
}

/**
 * Collection Visibility Options
 */
export type CollectionVisibility = "public" | "followers" | "private";

/**
 * User Collection Save Record
 */
export interface UserCollectionSave {
  userId: string;
  collectionId: string;
  savedAt: Timestamp;
  addedToTasks: boolean;
  addedTaskIds?: string[];
}

/**
 * Collection Like Record (Phase 2)
 */
export interface CollectionLike {
  userId: string;
  collectionId: string;
  likedAt: Timestamp;
}

/**
 * Collection Comment (Phase 2)
 */
export interface CollectionComment {
  commentId: string;
  collectionId: string;
  userId: string;
  userName: string;
  userAvatarUrl?: string;
  content: string; // Max 500 characters
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

/**
 * User Follow Record (Phase 2)
 */
export interface UserFollow {
  followerId: string;
  followingId: string;
  followedAt: Timestamp;
}

/**
 * API Request/Response Types
 */

// Create Collection Request
export interface CreateCollectionRequest {
  title: string;
  description: string;
  coverImage?: string;
  tags: string[];
  tasks: Array<{
    taskId: string;
    orderIndex: number;
  }>;
  visibility: CollectionVisibility;
}

// Update Collection Request
export interface UpdateCollectionRequest {
  title?: string;
  description?: string;
  coverImage?: string;
  tags?: string[];
  tasks?: Array<{
    taskId: string;
    orderIndex: number;
  }>;
  visibility?: CollectionVisibility;
}

// Get Collections Query Parameters
export interface GetCollectionsQuery {
  page?: number;
  limit?: number;
  sortBy?: "latest" | "popular" | "trending";
  tags?: string[];
  visibility?: CollectionVisibility;
}

// Search Collections Query Parameters
export interface SearchCollectionsQuery {
  q: string;
  page?: number;
  limit?: number;
  sortBy?: "relevance" | "latest" | "popular";
  tags?: string[];
}

// Get Trending Query Parameters
export interface GetTrendingQuery {
  limit?: number;
  period?: "24h" | "7d" | "30d";
}

// Add to Tasks Response
export interface AddToTasksResponse {
  success: boolean;
  data: {
    addedCount: number;
    skippedCount: number;
    totalCount: number;
    addedTaskIds: string[];
    message: string;
  };
}

// Collection Detail Response
export interface CollectionDetailResponse {
  success: boolean;
  data: {
    collection: VoteCollection;
    isSaved: boolean;
    isLiked: boolean;
    isOwner: boolean;
  };
}

// Pagination Info
export interface PaginationInfo {
  currentPage: number;
  totalPages: number;
  totalCount: number;
  hasNext: boolean;
}

// Collections List Response
export interface CollectionsListResponse {
  success: boolean;
  data: {
    collections: VoteCollection[];
    pagination: PaginationInfo;
  };
}
