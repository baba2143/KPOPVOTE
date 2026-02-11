/**
 * Vote management types for admin panel
 */

export interface VoteRestrictions {
  dailyVoteLimitPerUser?: number; // 1日の投票数制限（人/日）
  minVoteCount?: number; // 1回あたりの最小票数
  maxVoteCount?: number; // 1回あたりの最大票数
  premiumPointsPerVote?: number; // Premiumポイントコスト（票/P）
  regularPointsPerVote?: number; // Regularポイントコスト（票/P）
}

export interface InAppVote {
  voteId: string;
  title: string;
  description: string;
  choices: InAppVoteChoice[];
  startDate: string; // ISO 8601
  endDate: string; // ISO 8601
  requiredPoints: number;
  status: "upcoming" | "active" | "ended";
  totalVotes: number;
  coverImageUrl?: string;
  isFeatured?: boolean;
  restrictions?: VoteRestrictions; // 投票制限設定
  createdAt: string | null;
  updatedAt: string | null;
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

export interface InAppVoteCreateRequest {
  title: string;
  description: string;
  choices: (string | VoteChoiceInput)[]; // Array of choice labels or choice objects
  startDate: string; // ISO 8601
  endDate: string; // ISO 8601
  requiredPoints: number;
  coverImageUrl?: string;
  isFeatured?: boolean;
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
  restrictions?: VoteRestrictions; // 投票制限設定
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

export interface ListVotesResponse {
  votes: InAppVote[];
  count: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
