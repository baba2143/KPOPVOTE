/**
 * Collection Report types
 */

export interface CollectionReport {
  reportId: string;
  collectionId: string;
  reporterId: string;
  reporterEmail: string;
  reason: string;
  comment: string;
  status: 'pending' | 'reviewed' | 'resolved';
  createdAt: string | null;
}

export interface CollectionReportStats {
  totalReports: number;
  pendingReports: number;
  reviewedReports: number;
}
