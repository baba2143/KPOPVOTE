/**
 * User management type definitions
 */

export interface UserListItem {
  uid: string;
  email: string;
  displayName: string | null;
  points: number;
  isSuspended: boolean;
  createdAt: string;
}

export interface UserDetail {
  uid: string;
  email: string;
  displayName: string | null;
  points: number;
  isSuspended: boolean;
  createdAt: string;
  taskCount: number;
  voteCount: number;
  suspendReason?: string;
  suspendUntil?: string;
}

export interface GrantPointsRequest {
  uid: string;
  points: number;
  reason: string;
}

export interface GrantPointsResponse {
  uid: string;
  pointsGranted: number;
  currentPoints: number;
  reason: string;
}

export interface SuspendUserRequest {
  uid: string;
  suspend: boolean;
  reason?: string;
  suspendUntil?: string;
}

export interface SuspendUserResponse {
  uid: string;
  suspended: boolean;
  reason?: string;
  suspendUntil?: string;
}
