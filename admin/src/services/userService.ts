/**
 * User management service
 */

import { auth } from '../config/firebase';
import {
  UserListItem,
  UserDetail,
  GrantPointsRequest,
  GrantPointsResponse,
  SuspendUserRequest,
  SuspendUserResponse,
} from '../types/user';

const FUNCTIONS_BASE_URL = 'https://us-central1-kpopvote-9de2b.cloudfunctions.net';

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
 * Search users
 * @param query Email or display name to search (prefix match)
 * @param limit Maximum number of results (default: 50)
 * @returns List of users
 */
export const searchUsers = async (query?: string, limit: number = 50): Promise<UserListItem[]> => {
  try {
    const token = await getAuthToken();
    const url = new URL(`${FUNCTIONS_BASE_URL}/searchUsers`);

    if (query) {
      url.searchParams.append('query', query);
    }
    url.searchParams.append('limit', limit.toString());

    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to search users: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to search users');
    }

    return data.data.users;
  } catch (error) {
    console.error('Error searching users:', error);
    throw error;
  }
};

/**
 * Get user detail
 * @param uid User ID
 * @returns User detail information
 */
export const getUserDetail = async (uid: string): Promise<UserDetail> => {
  try {
    const token = await getAuthToken();
    const url = new URL(`${FUNCTIONS_BASE_URL}/getUserDetail`);
    url.searchParams.append('uid', uid);

    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to get user detail: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to get user detail');
    }

    return data.data;
  } catch (error) {
    console.error('Error getting user detail:', error);
    throw error;
  }
};

/**
 * Grant points to user
 * @param request Grant points request
 * @returns Grant points response
 */
export const grantPoints = async (request: GrantPointsRequest): Promise<GrantPointsResponse> => {
  try {
    const token = await getAuthToken();

    const response = await fetch(`${FUNCTIONS_BASE_URL}/grantPoints`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      throw new Error(`Failed to grant points: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to grant points');
    }

    return data.data;
  } catch (error) {
    console.error('Error granting points:', error);
    throw error;
  }
};

/**
 * Suspend or restore user
 * @param request Suspend user request
 * @returns Suspend user response
 */
export const suspendUser = async (request: SuspendUserRequest): Promise<SuspendUserResponse> => {
  try {
    const token = await getAuthToken();

    const response = await fetch(`${FUNCTIONS_BASE_URL}/suspendUser`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      throw new Error(`Failed to suspend user: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to suspend user');
    }

    return data.data;
  } catch (error) {
    console.error('Error suspending user:', error);
    throw error;
  }
};
