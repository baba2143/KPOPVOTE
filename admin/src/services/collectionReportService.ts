/**
 * Collection Report service
 */

import { auth } from '../config/firebase';
import { CollectionReport, CollectionReportStats } from '../types/collectionReport';

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

interface GetCollectionReportsResponse {
  reports: CollectionReport[];
  stats: CollectionReportStats;
  count: number;
}

/**
 * Get Collection reports
 * @param limit Maximum number of reports to retrieve
 * @param status Optional status filter
 * @returns List of Collection reports with stats
 */
export const getCollectionReports = async (
  limit: number = 50,
  status?: 'pending' | 'reviewed' | 'resolved'
): Promise<GetCollectionReportsResponse> => {
  try {
    const token = await getAuthToken();
    const url = new URL(`${FUNCTIONS_BASE_URL}/getCollectionReports`, window.location.origin);
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
      throw new Error(`Failed to fetch collection reports: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to fetch collection reports');
    }

    return data.data;
  } catch (error) {
    console.error('Error fetching collection reports:', error);
    throw error;
  }
};
