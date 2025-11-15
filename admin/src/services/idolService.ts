/**
 * Idol service
 */

import { auth, storage } from '../config/firebase';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { IdolMaster, IdolCreateRequest, IdolUpdateRequest } from '../types/idol';

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
 * Upload image to Firebase Storage
 * @param file Image file to upload
 * @returns Download URL of uploaded image
 */
export const uploadIdolImage = async (file: File): Promise<string> => {
  try {
    // Validate file type
    const validTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (!validTypes.includes(file.type)) {
      throw new Error('Invalid file type. Only JPEG, PNG, and WebP are allowed.');
    }

    // Validate file size (max 5MB)
    const maxSize = 5 * 1024 * 1024; // 5MB in bytes
    if (file.size > maxSize) {
      throw new Error('File size exceeds 5MB limit.');
    }

    // Create unique filename with timestamp
    const timestamp = Date.now();
    const filename = `${timestamp}_${file.name}`;
    const storageRef = ref(storage, `idols/${filename}`);

    // Upload file
    const snapshot = await uploadBytes(storageRef, file);

    // Get download URL
    const downloadURL = await getDownloadURL(snapshot.ref);

    return downloadURL;
  } catch (error) {
    console.error('Error uploading image:', error);
    throw error;
  }
};

/**
 * List idols
 * @param groupName Optional filter by group name
 * @returns List of idols
 */
export const listIdols = async (groupName?: string): Promise<IdolMaster[]> => {
  try {
    const token = await getAuthToken();
    const url = new URL(`${FUNCTIONS_BASE_URL}/listIdols`);

    if (groupName) {
      url.searchParams.append('groupName', groupName);
    }

    const response = await fetch(url.toString(), {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch idols: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to fetch idols');
    }

    return data.data.idols;
  } catch (error) {
    console.error('Error fetching idols:', error);
    throw error;
  }
};

/**
 * Create idol
 * @param idol Idol data to create
 * @returns Created idol
 */
export const createIdol = async (idol: IdolCreateRequest): Promise<IdolMaster> => {
  try {
    const token = await getAuthToken();

    const response = await fetch(`${FUNCTIONS_BASE_URL}/createIdol`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(idol),
    });

    if (!response.ok) {
      throw new Error(`Failed to create idol: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to create idol');
    }

    return data.data;
  } catch (error) {
    console.error('Error creating idol:', error);
    throw error;
  }
};

/**
 * Update idol
 * @param idolId Idol ID
 * @param idol Idol data to update
 * @returns Updated idol
 */
export const updateIdol = async (
  idolId: string,
  idol: Omit<IdolUpdateRequest, 'idolId'>
): Promise<IdolMaster> => {
  try {
    const token = await getAuthToken();

    const response = await fetch(`${FUNCTIONS_BASE_URL}/updateIdol`, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ idolId, ...idol }),
    });

    if (!response.ok) {
      throw new Error(`Failed to update idol: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to update idol');
    }

    return data.data;
  } catch (error) {
    console.error('Error updating idol:', error);
    throw error;
  }
};

/**
 * Delete idol
 * @param idolId Idol ID
 */
export const deleteIdol = async (idolId: string): Promise<void> => {
  try {
    const token = await getAuthToken();

    const response = await fetch(`${FUNCTIONS_BASE_URL}/deleteIdol`, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ idolId }),
    });

    if (!response.ok) {
      throw new Error(`Failed to delete idol: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to delete idol');
    }
  } catch (error) {
    console.error('Error deleting idol:', error);
    throw error;
  }
};
