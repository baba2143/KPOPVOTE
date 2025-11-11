/**
 * Vote management service
 * Communicates with Firebase Cloud Functions
 */

import { auth } from '../config/firebase';
import {
  InAppVote,
  InAppVoteCreateRequest,
  InAppVoteUpdateRequest,
  ListVotesResponse,
  RankingResponse,
  ApiResponse,
} from '../types/vote';

const FUNCTIONS_BASE_URL =
  'https://us-central1-kpopvote-9de2b.cloudfunctions.net';

/**
 * Get authentication token
 */
const getAuthToken = async (): Promise<string> => {
  const user = auth.currentUser;
  if (!user) {
    throw new Error('User not authenticated');
  }
  return await user.getIdToken();
};

/**
 * List all votes with optional status filter
 */
export const listVotes = async (
  status?: 'upcoming' | 'active' | 'ended'
): Promise<InAppVote[]> => {
  const token = await getAuthToken();
  const url = new URL(`${FUNCTIONS_BASE_URL}/listInAppVotes`);

  if (status) {
    url.searchParams.append('status', status);
  }

  const response = await fetch(url.toString(), {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch votes: ${response.statusText}`);
  }

  const result: ApiResponse<ListVotesResponse> = await response.json();

  if (!result.success || !result.data) {
    throw new Error(result.error || 'Failed to fetch votes');
  }

  return result.data.votes;
};

/**
 * Get vote detail by voteId
 */
export const getVoteDetail = async (voteId: string): Promise<InAppVote> => {
  const token = await getAuthToken();
  const url = new URL(`${FUNCTIONS_BASE_URL}/getInAppVoteDetail`);
  url.searchParams.append('voteId', voteId);

  const response = await fetch(url.toString(), {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch vote detail: ${response.statusText}`);
  }

  const result: ApiResponse<InAppVote> = await response.json();

  if (!result.success || !result.data) {
    throw new Error(result.error || 'Failed to fetch vote detail');
  }

  return result.data;
};

/**
 * Create new vote
 */
export const createVote = async (
  data: InAppVoteCreateRequest
): Promise<InAppVote> => {
  const token = await getAuthToken();

  const response = await fetch(`${FUNCTIONS_BASE_URL}/createInAppVote`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    throw new Error(`Failed to create vote: ${response.statusText}`);
  }

  const result: ApiResponse<InAppVote> = await response.json();

  if (!result.success || !result.data) {
    throw new Error(result.error || 'Failed to create vote');
  }

  return result.data;
};

/**
 * Update existing vote
 */
export const updateVote = async (
  data: InAppVoteUpdateRequest
): Promise<InAppVote> => {
  const token = await getAuthToken();

  const response = await fetch(`${FUNCTIONS_BASE_URL}/updateInAppVote`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    throw new Error(`Failed to update vote: ${response.statusText}`);
  }

  const result: ApiResponse<InAppVote> = await response.json();

  if (!result.success || !result.data) {
    throw new Error(result.error || 'Failed to update vote');
  }

  return result.data;
};

/**
 * Delete vote
 */
export const deleteVote = async (voteId: string): Promise<void> => {
  const token = await getAuthToken();

  const response = await fetch(`${FUNCTIONS_BASE_URL}/deleteInAppVote`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ voteId }),
  });

  if (!response.ok) {
    throw new Error(`Failed to delete vote: ${response.statusText}`);
  }

  const result: ApiResponse<{ message: string }> = await response.json();

  if (!result.success) {
    throw new Error(result.error || 'Failed to delete vote');
  }
};

/**
 * Get vote ranking
 */
export const getRanking = async (voteId: string): Promise<RankingResponse> => {
  const token = await getAuthToken();
  const url = new URL(`${FUNCTIONS_BASE_URL}/getRanking`);
  url.searchParams.append('voteId', voteId);

  const response = await fetch(url.toString(), {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch ranking: ${response.statusText}`);
  }

  const result: ApiResponse<RankingResponse> = await response.json();

  if (!result.success || !result.data) {
    throw new Error(result.error || 'Failed to fetch ranking');
  }

  return result.data;
};
