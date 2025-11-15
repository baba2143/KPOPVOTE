/**
 * Vote management types for admin panel
 */

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
  createdAt: string | null;
  updatedAt: string | null;
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
