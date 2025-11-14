/**
 * Community service
 */

import { auth } from '../config/firebase';
import { ReportedPost, CommunityStats } from '../types/community';

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
 * Get reported posts
 * @param limit Maximum number of posts to retrieve
 * @returns List of reported posts with report details
 */
export const getReportedPosts = async (limit: number = 50): Promise<ReportedPost[]> => {
  try {
    const token = await getAuthToken();
    const url = new URL(`${FUNCTIONS_BASE_URL}/getReportedPosts`);
    url.searchParams.append('limit', limit.toString());

    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch reported posts: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to fetch reported posts');
    }

    return data.data.reportedPosts;
  } catch (error) {
    console.error('Error fetching reported posts:', error);
    throw error;
  }
};

/**
 * Delete community post
 * @param postId Post ID to delete
 * @param reason Deletion reason
 */
export const deleteCommunityPost = async (
  postId: string,
  reason?: string
): Promise<void> => {
  try {
    const token = await getAuthToken();
    const url = new URL(`${FUNCTIONS_BASE_URL}/deleteCommunityPost`);
    url.searchParams.append('postId', postId);
    if (reason) {
      url.searchParams.append('reason', reason);
    }

    const response = await fetch(url.toString(), {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to delete post: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to delete post');
    }
  } catch (error) {
    console.error('Error deleting post:', error);
    throw error;
  }
};

/**
 * Get community statistics
 * @returns Community statistics
 */
export const getCommunityStats = async (): Promise<CommunityStats> => {
  try {
    const token = await getAuthToken();
    const url = `${FUNCTIONS_BASE_URL}/getCommunityStats`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch community stats: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to fetch community stats');
    }

    return data.data;
  } catch (error) {
    console.error('Error fetching community stats:', error);
    throw error;
  }
};
