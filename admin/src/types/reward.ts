/**
 * Reward Settings Types
 * 報酬設定関連の型定義
 */

export type PointType = "premium" | "regular";

export interface RewardSetting {
  id: string;
  actionType: string;
  basePoints: number;
  description: string;
  isActive: boolean;
  updatedAt: Date;
}

export interface UpdateRewardSettingRequest {
  actionType: string;
  basePoints?: number;
  description?: string;
  isActive?: boolean;
}

export interface PointGrantRequest {
  uid: string;
  points: number;
  pointType: PointType;
  reason: string;
}

export interface PointGrantResponse {
  uid: string;
  pointsGranted: number;
  pointType: PointType;
  currentPremiumPoints: number;
  currentRegularPoints: number;
  reason: string;
}
