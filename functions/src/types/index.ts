/**
 * Type definitions for K-VOTE COLLECTOR
 */

// FanCard types
export * from "./fancard";

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

export interface TaskUpdateRequest {
  taskId: string;
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

export interface TaskUpdateResponse {
  taskId: string;
  title: string;
  url: string;
  deadline: string;
  targetMembers: string[];
  externalAppId: string | null;
  coverImage: string | null;
  coverImageSource: string | null;
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
  restrictions?: VoteRestrictions; // 投票制限設定
  createdAt: Date;
  updatedAt: Date;
}

export interface InAppVoteChoice {
  choiceId: string;
  label: string;
  voteCount: number;
  idolId?: string;
  imageUrl?: string;
  groupName?: string;
  groupId?: string;
}

export interface VoteChoiceInput {
  label: string;
  idolId?: string;
  imageUrl?: string;
  groupName?: string;
  groupId?: string;
}

export interface VoteRestrictions {
  dailyVoteLimitPerUser?: number; // 1日の投票数制限（人/日）
  minVoteCount?: number; // 1回あたりの最小票数
  maxVoteCount?: number; // 1回あたりの最大票数
  pointsPerVote?: number; // ポイントコスト（票/P） 1P = 1票
}

export interface InAppVoteCreateRequest {
  title: string;
  description: string;
  choices: (string | VoteChoiceInput)[]; // Array of choice labels or choice objects (backward compatible)
  startDate: string; // ISO 8601
  endDate: string; // ISO 8601
  requiredPoints: number;
  coverImageUrl?: string;
  isFeatured?: boolean;
  isDraft?: boolean; // 下書きフラグ
  restrictions?: VoteRestrictions; // 投票制限設定
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
  isDraft?: boolean; // 下書きフラグ
  choices?: (string | VoteChoiceInput)[]; // 下書き時のみ選択肢更新可能
  restrictions?: VoteRestrictions; // 投票制限設定
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
  defaultCoverImageUrl?: string;
}

export interface ExternalAppUpdateRequest {
  appId: string;
  appName?: string;
  appUrl?: string;
  iconUrl?: string;
  defaultCoverImageUrl?: string;
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

// Music Video related types
export interface MusicVideoContent {
  youtubeVideoId: string;
  youtubeUrl: string;
  title: string;
  thumbnailUrl: string;
  channelName?: string;
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
  musicVideo?: MusicVideoContent;
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
  type: "image" | "my_votes" | "goods_trade" | "collection" | "music_video";
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
  type: "image" | "my_votes" | "goods_trade" | "collection" | "music_video";
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
  type: "follow" | "like" | "comment" | "mention" | "vote" | "system" | "dm";
  title: string;
  body: string;
  isRead: boolean;
  actionUserId?: string;
  actionUserDisplayName?: string;
  actionUserPhotoURL?: string;
  relatedPostId?: string;
  relatedVoteId?: string;
  relatedCommentId?: string;
  relatedConversationId?: string;
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

// Point System related types (Phase 1 - Week 1)
// PointType removed - unified to single points system

export interface PointBalance {
  points: number;
  lastUpdated: string | null;
}

export interface PointTransaction {
  id: string;
  userId: string;
  points: number; // Positive for earning, negative for spending
  type:
    | "task_completion"
    | "task_share"
    | "post_mv"
    | "mv_watch"
    | "collection_create"
    | "post_image"
    | "post_goods_exchange"
    | "post_text"
    | "community_like"
    | "community_comment"
    | "follow_user"
    | "friend_invite"
    | "vote"
    | "purchase"
    | "grant"
    | "deduct"
    | "campaign_bonus"
    | "coupon";
  relatedId?: string; // Post ID, Vote ID, Task ID, etc.
  voteCount?: number; // For vote transactions
  reason?: string;
  createdAt: Date;
}

export interface VoteExecuteRequestWithPoints extends VoteExecuteRequest {
  voteCount: number; // Number of votes to cast
}

// Notification Settings related types
export interface UserNotificationSettings {
  userId: string;
  pushEnabled: boolean; // Master switch
  likes: boolean; // Like notifications
  comments: boolean; // Comment notifications
  mentions: boolean; // Mention notifications
  followers: boolean; // Follow notifications
  newPosts: boolean; // New post notifications
  voteReminders: boolean; // Vote reminder notifications
  calendarReminders: boolean; // Calendar reminder notifications
  announcements: boolean; // System announcements
  directMessages: boolean; // Direct message notifications
  sameBiasFans: boolean; // Same bias fans increase notifications
  createdAt: Date;
  updatedAt: Date;
}

// Bias User History related types (for same bias fan notifications)
export interface BiasUserHistory {
  userId: string;
  biasId: string;
  biasType: "group" | "member";
  biasName: string;
  groupId?: string;
  groupName?: string;
  addedAt: Date;
  isPrivate: boolean;
}

// Admin Notification related types
export type AdminNotificationStatus = "pending" | "sent" | "cancelled" | "failed";
export type AdminNotificationTarget = "all" | "group" | "member";

export interface AdminNotification {
  id: string;
  title: string;
  body: string;
  targetType: AdminNotificationTarget;
  targetId?: string; // groupId or memberId (null for "all")
  targetName?: string; // グループ名/メンバー名
  deepLinkUrl?: string; // 遷移先URL
  status: AdminNotificationStatus;
  scheduledAt?: Date; // 予約配信日時（即時配信の場合はnull）
  sentAt?: Date; // 実際の配信日時
  sentCount?: number; // 配信成功数
  failedCount?: number; // 配信失敗数
  createdBy: string; // 管理者UID
  createdAt: Date;
  updatedAt: Date;
}

export interface SendAdminNotificationRequest {
  title: string;
  body: string;
  targetType: AdminNotificationTarget;
  targetId?: string;
  deepLinkUrl?: string;
}

export interface ScheduleAdminNotificationRequest extends SendAdminNotificationRequest {
  scheduledAt: string; // ISO 8601 format
}
