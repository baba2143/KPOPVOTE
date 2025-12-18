/**
 * Block Report service
 * Apple App Store Guideline 1.2 compliance - User blocking auto-reports
 */

import { auth } from '../config/firebase';
import { BlockReport, BlockReportStats } from '../types/blockReport';

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

interface GetBlockReportsResponse {
  reports: BlockReport[];
  stats: BlockReportStats;
  count: number;
}

/**
 * Get Block reports
 * @param limit Maximum number of reports to retrieve
 * @param status Optional status filter
 * @returns List of block reports with stats
 */
export const getBlockReports = async (
  limit: number = 50,
  status?: 'pending' | 'reviewed' | 'resolved'
): Promise<GetBlockReportsResponse> => {
  try {
    const token = await getAuthToken();
    const url = new URL(`${FUNCTIONS_BASE_URL}/getBlockReports`, window.location.origin);
    url.searchParams.append('limit', limit.toString());
    if (status) {
      url.searchParams.append('status', status);
    }

    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch block reports: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to fetch block reports');
    }

    return data.data;
  } catch (error) {
    console.error('Error fetching block reports:', error);
    throw error;
  }
};
