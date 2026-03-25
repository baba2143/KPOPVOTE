/**
 * Vote management service
 * Communicates with Firebase Cloud Functions
 */

import { auth, storage } from '../config/firebase';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import imageCompression from 'browser-image-compression';
import {
  InAppVote,
  InAppVoteCreateRequest,
  InAppVoteUpdateRequest,
  ListVotesResponse,
  RankingResponse,
  ApiResponse,
} from '../types/vote';

// Use relative URL to proxy through Firebase Hosting (avoids CORS preflight issues)
const FUNCTIONS_BASE_URL = '/api';

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
 * Image compression options
 */
const imageCompressionOptions = {
  maxSizeMB: 1, // 最大1MBに圧縮
  maxWidthOrHeight: 1920, // 最大幅/高さ（フルHD）
  useWebWorker: true, // WebWorkerで非同期処理
};

/**
 * Compress image file if necessary
 * @param file Image file to compress
 * @returns Compressed file (or original if already small enough)
 */
const compressImage = async (file: File): Promise<File> => {
  // 元のファイルが1MB未満なら圧縮不要
  if (file.size <= 1 * 1024 * 1024) {
    console.log(`Image already small enough: ${(file.size / 1024 / 1024).toFixed(2)}MB`);
    return file;
  }

  console.log(`Compressing image: ${(file.size / 1024 / 1024).toFixed(2)}MB`);
  const compressedFile = await imageCompression(file, imageCompressionOptions);
  console.log(`Compressed to: ${(compressedFile.size / 1024 / 1024).toFixed(2)}MB`);

  return compressedFile;
};

/**
 * Upload vote cover image to Firebase Storage
 * @param file Image file to upload
 * @returns Download URL of uploaded image
 */
export const uploadVoteCoverImage = async (file: File): Promise<string> => {
  try {
    // Validate file type (before compression)
    const validTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (!validTypes.includes(file.type)) {
      throw new Error('Invalid file type. Only JPEG, PNG, and WebP are allowed.');
    }

    // Compress image if necessary
    const compressedFile = await compressImage(file);

    // Validate file size after compression (max 5MB)
    const maxSize = 5 * 1024 * 1024; // 5MB in bytes
    if (compressedFile.size > maxSize) {
      throw new Error('File size exceeds 5MB limit even after compression.');
    }

    // Create unique filename with timestamp
    const timestamp = Date.now();
    const filename = `${timestamp}_${compressedFile.name}`;
    const storageRef = ref(storage, `vote-covers/${filename}`);

    // Upload compressed file
    const snapshot = await uploadBytes(storageRef, compressedFile);

    // Get download URL
    const downloadURL = await getDownloadURL(snapshot.ref);

    return downloadURL;
  } catch (error) {
    console.error('Error uploading vote cover image:', error);
    throw error;
  }
};

/**
 * List all votes with optional status filter
 */
export const listVotes = async (
  status?: 'upcoming' | 'active' | 'ended' | 'draft'
): Promise<InAppVote[]> => {
  const token = await getAuthToken();
  const url = new URL(`${FUNCTIONS_BASE_URL}/listInAppVotes`, window.location.origin);

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
  const url = new URL(`${FUNCTIONS_BASE_URL}/getInAppVoteDetail`, window.location.origin);
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
    method: 'PATCH',
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
  const url = new URL(`${FUNCTIONS_BASE_URL}/deleteInAppVote`, window.location.origin);
  url.searchParams.append('voteId', voteId);

  const response = await fetch(url.toString(), {
    method: 'DELETE',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to delete vote: ${response.statusText}`);
  }

  const result: ApiResponse<{ voteId: string; deleted: boolean }> = await response.json();

  if (!result.success) {
    throw new Error(result.error || 'Failed to delete vote');
  }
};

/**
 * Get vote ranking
 */
export const getRanking = async (voteId: string): Promise<RankingResponse> => {
  const token = await getAuthToken();
  const url = new URL(`${FUNCTIONS_BASE_URL}/getRanking`, window.location.origin);
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
