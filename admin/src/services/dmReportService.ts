/**
 * DM Report service
 */

import { auth } from '../config/firebase';
import { DMReport, DMReportStats } from '../types/dmReport';

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

interface GetDMReportsResponse {
  reports: DMReport[];
  stats: DMReportStats;
  count: number;
}

/**
 * Get DM reports
 * @param limit Maximum number of reports to retrieve
 * @param status Optional status filter
 * @returns List of DM reports with stats
 */
export const getDMReports = async (
  limit: number = 50,
  status?: 'pending' | 'reviewed' | 'resolved'
): Promise<GetDMReportsResponse> => {
  try {
    const token = await getAuthToken();
    const url = new URL(`${FUNCTIONS_BASE_URL}/getDMReports`);
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
      throw new Error(`Failed to fetch DM reports: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to fetch DM reports');
    }

    return data.data;
  } catch (error) {
    console.error('Error fetching DM reports:', error);
    throw error;
  }
};
