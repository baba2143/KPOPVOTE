/**
 * Admin log service
 */

import { auth } from '../config/firebase';
import { AdminLog } from '../types/log';

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
 * Get admin logs
 * @param limit Maximum number of logs to retrieve (default: 50)
 * @returns List of admin logs
 */
export const getAdminLogs = async (limit: number = 50): Promise<AdminLog[]> => {
  try {
    const token = await getAuthToken();
    const url = new URL(`${FUNCTIONS_BASE_URL}/getAdminLogs`);
    url.searchParams.append('limit', limit.toString());

    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to get admin logs: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to get admin logs');
    }

    return data.data.logs;
  } catch (error) {
    console.error('Error getting admin logs:', error);
    throw error;
  }
};
