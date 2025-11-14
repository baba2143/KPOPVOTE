/**
 * Community types
 */

export interface CommunityReport {
  reportId: string;
  reporterId: string;
  reason: string;
  reportedAt: string | null;
}

export interface ReportedPost {
  postId: string;
  userId: string;
  content: string;
  reportCount: number;
  createdAt: string | null;
  reports: CommunityReport[];
}

export interface CommunityStats {
  totalPosts: number;
  deletedPosts: number;
  reportedPosts: number;
  activeUsers: number;
}
