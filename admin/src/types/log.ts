/**
 * Admin log type definitions
 */

export interface AdminActionLog {
  id: string;
  type: 'admin_action';
  actionType: 'suspend' | 'restore';
  targetUserId: string;
  targetUserEmail: string;
  reason: string | null;
  suspendedUntil: string | null;
  performedBy: string | null;
  performerEmail: string;
  performedAt: string | null;
}

export interface PointTransactionLog {
  id: string;
  type: 'point_transaction';
  userId: string;
  targetUserEmail: string;
  points: number;
  transactionType: 'grant' | 'deduct';
  reason: string;
  grantedBy: string | null;
  granterEmail: string;
  createdAt: string | null;
}

export type AdminLog = AdminActionLog | PointTransactionLog;
