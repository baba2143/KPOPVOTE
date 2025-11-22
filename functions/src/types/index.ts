/**
 * Type definitions for K-VOTE COLLECTOR
 */

// User related types
export interface UserProfile {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  myBias: BiasSettings[];
  createdAt: Date;
  updatedAt: Date;
}

export interface BiasSettings {
  artistId: string;
  artistName: string;
  memberIds: string[];
  memberNames: string[];
}

// Auth related types
export interface RegisterRequest {
  email: string;
  password: string;
  displayName?: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  uid: string;
  email: string;
  displayName?: string;
  token: string;
}

// Task related types
export interface Task {
  taskId: string;
  userId: string;
  title: string;
  url: string;
  deadline: Date;
  targetMembers: string[];
  externalAppId?: string;
  isCompleted: boolean;
  completedAt?: Date;
  coverImage?: string;
  coverImageSource?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface TaskRegisterRequest {
  title: string;
  url: string;
  deadline: string; // ISO 8601 format
  targetMembers?: string[];
  externalAppId?: string;
  coverImage?: string;
  coverImageSource?: string;
}

export interface TaskUpdateStatusRequest {
  taskId: string;
  isCompleted: boolean;
}

// API response types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

// Task response types
export interface TaskRegisterResponse {
  taskId: string;
  title: string;
  url: string;
  deadline: string;
  targetMembers: string[];
  externalAppId?: string | null;
  isCompleted: boolean;
  completedAt: null;
  coverImage: string | null;
  coverImageSource: string | null;
}

export interface TaskData {
  taskId: string;
  title: string;
  url: string;
  deadline: string;
  targetMembers: string[];
  externalAppId?: string | null;
  isCompleted: boolean;
  completedAt: string | null;
  coverImage: string | null;
  coverImageSource: string | null;
  createdAt: string | null;
  updatedAt: string | null;
}

export interface TasksResponse {
  tasks: TaskData[];
  count: number;
}

export interface TaskOGPResponse {
  taskId: string;
  ogpTitle: string | null;
  ogpImage: string | null;
}

export interface TaskStatusResponse {
  taskId: string;
  isCompleted: boolean;
  completedAt: string | null;
  updatedAt: string | null;
}

// Validation result
export interface ValidationResult {
  valid: boolean;
  error?: string;
}

// In-App Vote related types (Phase 0+)
export interface InAppVote {
  voteId: string;
  title: string;
  description: string;
  choices: InAppVoteChoice[];
  startDate: Date;
  endDate: Date;
  requiredPoints: number;
  status: "upcoming" | "active" | "ended";
  totalVotes: number;
  coverImageUrl?: string;
  isFeatured?: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface InAppVoteChoice {
  choiceId: string;
  label: string;
  voteCount: number;
}

export interface InAppVoteCreateRequest {
  title: string;
  description: string;
  choices: string[]; // Array of choice labels
  startDate: string; // ISO 8601
  endDate: string; // ISO 8601
  requiredPoints: number;
  coverImageUrl?: string;
  isFeatured?: boolean;
}

export interface InAppVoteUpdateRequest {
  voteId: string;
  title?: string;
  description?: string;
  startDate?: string;
  endDate?: string;
  requiredPoints?: number;
  coverImageUrl?: string;
  isFeatured?: boolean;
}

export interface VoteExecuteRequest {
  voteId: string;
  choiceId: string;
}

export interface RankingData {
  choiceId: string;
  label: string;
  voteCount: number;
  percentage: number;
}

export interface RankingResponse {
  voteId: string;
  title: string;
  totalVotes: number;
  ranking: RankingData[];
}

// Master Data related types (Phase 0+)
export interface IdolMaster {
  idolId: string;
  name: string;
  groupName: string;
  groupId?: string;
  imageUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface IdolCreateRequest {
  name: string;
  groupName: string;
  groupId?: string;
  imageUrl?: string;
}

export interface IdolUpdateRequest {
  idolId: string;
  name?: string;
  groupName?: string;
  groupId?: string;
  imageUrl?: string;
}

export interface ExternalAppMaster {
  appId: string;
  appName: string;
  appUrl: string;
  iconUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface ExternalAppCreateRequest {
  appName: string;
  appUrl: string;
  iconUrl?: string;
}

export interface ExternalAppUpdateRequest {
  appId: string;
  appName?: string;
  appUrl?: string;
  iconUrl?: string;
}

export interface GroupMaster {
  groupId: string;
  name: string;
  imageUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface GroupCreateRequest {
  name: string;
  imageUrl?: string;
}

export interface GroupUpdateRequest {
  groupId: string;
  name?: string;
  imageUrl?: string;
}

// Community related types (Phase 0+)
export interface CommunityPost {
  postId: string;
  userId: string;
  content: string;
  imageUrls?: string[];
  likeCount: number;
  commentCount: number;
  isReported: boolean;
  reportCount: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface CommunityReport {
  reportId: string;
  postId: string;
  reporterId: string;
  reason: string;
  reportedAt: Date;
}

export interface CommunityStats {
  totalPosts: number;
  deletedPosts: number;
  reportedPosts: number;
  activeUsers: number;
}

// User Management related types (Phase 0+)
export interface UserDetail extends UserProfile {
  points: number;
  taskCount: number;
  voteCount: number;
  isSuspended: boolean;
  suspendedUntil?: Date;
  suspendReason?: string;
}

export interface UserSearchRequest {
  query?: string; // email, displayName, uid
  limit?: number;
  offset?: number;
}

export interface PointGrantRequest {
  uid: string;
  points: number;
  reason: string;
}

export interface UserSuspendRequest {
  uid: string;
  suspend: boolean; // true to suspend, false to restore
  reason?: string;
  suspendUntil?: string; // ISO 8601
}

// Admin Auth related types (Phase 0+)
export interface AdminAuthRequest {
  uid: string;
}

export interface AdminAuthResponse {
  uid: string;
  isAdmin: boolean;
}

// Goods Trade related types
export interface GoodsTradeContent {
  idolId: string;
  idolName: string;
  groupName: string;
  goodsImageUrl: string;
  goodsTags: string[];
  goodsName: string;
  tradeType: "want" | "offer";
  condition?: "new" | "excellent" | "good" | "fair";
  description?: string;
  status: "available" | "reserved" | "completed";
}

// Community Post related types (Phase 1 - Week 2)
export interface PostContent {
  text?: string;
  images?: string[];
  voteIds?: string[];
  voteSnapshots?: InAppVote[];
  myVotes?: MyVoteItem[];
  goodsTrade?: GoodsTradeContent;
  collectionId?: string;
  collectionTitle?: string;
  collectionDescription?: string;
  collectionCoverImage?: string;
  collectionTaskCount?: number;
}

export interface MyVoteItem {
  id: string;
  voteId: string;
  title: string;
  selectedChoiceId?: string;
  selectedChoiceLabel?: string;
  pointsUsed: number;
  votedAt: Date;
}

export interface Post {
  id: string;
  userId: string;
  type: "image" | "my_votes" | "goods_trade" | "collection";
  content: PostContent;
  biasIds: string[];
  likesCount: number;
  commentsCount: number;
  sharesCount: number;
  isReported: boolean;
  reportCount: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreatePostRequest {
  type: "image" | "my_votes" | "goods_trade" | "collection";
  content: PostContent;
  biasIds: string[];
}

export interface GetPostsRequest {
  type: "bias" | "following";
  biasId?: string;
  limit?: number;
  lastPostId?: string;
}

// Follow related types (Phase 1 - Week 2)
export interface Follow {
  id: string;
  followerId: string;
  followingId: string;
  createdAt: Date;
}

export interface FollowRequest {
  userId: string; // User to follow/unfollow
}

// Notification related types (Phase 1 - Week 2)
export interface Notification {
  id: string;
  userId: string;
  type: "follow" | "like" | "comment" | "mention" | "vote" | "system";
  title: string;
  body: string;
  isRead: boolean;
  actionUserId?: string;
  actionUserDisplayName?: string;
  actionUserPhotoURL?: string;
  relatedPostId?: string;
  relatedVoteId?: string;
  relatedCommentId?: string;
  createdAt: Date;
}

export interface GetNotificationsRequest {
  unreadOnly?: boolean;
  limit?: number;
}

// Vote History related types (Phase 1 - Week 2)
export interface VoteHistory {
  id: string;
  userId: string;
  voteId: string;
  voteTitle: string;
  voteCoverImageUrl?: string;
  selectedChoiceId?: string;
  selectedChoiceLabel?: string;
  pointsUsed: number;
  votedAt: Date;
}

export interface GetMyVotesRequest {
  status: "all" | "active" | "ended";
  sort: "date" | "points";
}

export interface ShareMyVotesRequest {
  voteIds: string[];
  message?: string;
}
