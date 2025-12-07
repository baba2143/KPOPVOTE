/**
 * DM Report types
 */

export interface DMReport {
  reportId: string;
  conversationId: string;
  messageId?: string;
  reporterId: string;
  reporteeId: string;
  reportType: 'message' | 'user';
  reason: string;
  messageContent?: string;
  status: 'pending' | 'reviewed' | 'resolved';
  createdAt: string | null;
}

export interface DMReportStats {
  totalReports: number;
  pendingReports: number;
  reviewedReports: number;
}
