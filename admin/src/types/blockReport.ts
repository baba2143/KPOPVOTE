/**
 * Block Report types
 * Apple App Store Guideline 1.2 compliance - User blocking auto-reports
 */

export interface BlockReport {
  reportId: string;
  reporterId: string;
  reportedUserId: string;
  type: 'user_block';
  reason: string;
  status: 'pending' | 'reviewed' | 'resolved';
  createdAt: string | null;
}

export interface BlockReportStats {
  totalReports: number;
  pendingReports: number;
  reviewedReports: number;
}
