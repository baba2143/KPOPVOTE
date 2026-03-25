/**
 * User management type definitions
 */

export type PointType = "premium" | "regular";

export interface UserListItem {
  uid: string;
  email: string;
  displayName: string | null;
  points: number;
  premiumPoints?: number; // マルチポイント対応
  regularPoints?: number; // マルチポイント対応
  isSuspended: boolean;
  createdAt: string;
}

export interface UserDetail {
  uid: string;
  email: string;
  displayName: string | null;
  points: number;
  premiumPoints?: number; // マルチポイント対応
  regularPoints?: number; // マルチポイント対応
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
  pointType: PointType; // 🆕 マルチポイント対応
  reason: string;
}

export interface GrantPointsResponse {
  uid: string;
  pointsGranted: number;
  pointType: PointType; // 🆕 マルチポイント対応
  currentPremiumPoints: number; // 🆕 マルチポイント対応
  currentRegularPoints: number; // 🆕 マルチポイント対応
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
