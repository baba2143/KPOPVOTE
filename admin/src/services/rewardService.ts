/**
 * Reward Settings Service
 * 報酬設定管理サービス
 */

import { auth } from '../config/firebase';
import {
  RewardSetting,
  UpdateRewardSettingRequest,
  PointGrantRequest,
  PointGrantResponse,
} from '../types/reward';

// Use relative URL to proxy through Firebase Hosting (avoids CORS preflight issues)
const FUNCTIONS_BASE_URL = '/api';

/**
 * Get auth token
 */
const getAuthToken = async (): Promise<string> => {
  const user = auth.currentUser;
  if (!user) {
    throw new Error('Not authenticated');
  }
  return await user.getIdToken();
};

/**
 * Get all reward settings
 * 全報酬設定を取得
 */
export const getRewardSettings = async (): Promise<RewardSetting[]> => {
  try {
    const token = await getAuthToken();
    const response = await fetch(`${FUNCTIONS_BASE_URL}/getRewardSettings`, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to fetch reward settings');
    }

    const result = await response.json();
    return result.data.map((setting: any) => ({
      ...setting,
      updatedAt: new Date(setting.updatedAt),
    }));
  } catch (error) {
    console.error('❌ [getRewardSettings] Error:', error);
    throw error;
  }
};

/**
 * Update reward setting
 * 報酬設定を更新
 */
export const updateRewardSetting = async (
  request: UpdateRewardSettingRequest
): Promise<RewardSetting> => {
  try {
    const token = await getAuthToken();
    const response = await fetch(`${FUNCTIONS_BASE_URL}/updateRewardSetting`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to update reward setting');
    }

    const result = await response.json();
    return {
      ...result.data,
      updatedAt: new Date(result.data.updatedAt),
    };
  } catch (error) {
    console.error('❌ [updateRewardSetting] Error:', error);
    throw error;
  }
};

/**
 * Grant points to user (multi-point system)
 * ユーザーにポイント付与（マルチポイント対応）
 */
export const grantPoints = async (
  request: PointGrantRequest
): Promise<PointGrantResponse> => {
  try {
    const token = await getAuthToken();
    const response = await fetch(`${FUNCTIONS_BASE_URL}/grantPoints`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to grant points');
    }

    const result = await response.json();
    return result.data;
  } catch (error) {
    console.error('❌ [grantPoints] Error:', error);
    throw error;
  }
};
