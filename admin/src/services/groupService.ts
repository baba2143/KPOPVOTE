/**
 * Group service
 */

import { auth, storage } from '../config/firebase';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import {
  GroupMaster,
  GroupCreateRequest,
  GroupUpdateRequest,
} from '../types/group';
import { parseCSV, arrayToCSV, downloadBlob, getTimestampedFilename, ParseError } from '../utils/csvUtils';

const FUNCTIONS_BASE_URL = 'https://us-central1-kpopvote-9de2b.cloudfunctions.net';

export interface ImportResult {
  success: boolean;
  created: number;
  updated: number;
  errors: ParseError[];
}

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
 * Upload group image to Firebase Storage
 * @param file Image file to upload
 * @returns Download URL of uploaded image
 */
export const uploadGroupImage = async (file: File): Promise<string> => {
  try {
    // Validate file type
    const validTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'];
    if (!validTypes.includes(file.type)) {
      throw new Error('Invalid file type. Only JPEG, PNG, WebP, and SVG are allowed.');
    }

    // Validate file size (max 10MB)
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
      throw new Error('File size exceeds 10MB limit.');
    }

    // Create unique filename with timestamp
    const timestamp = Date.now();
    const filename = `${timestamp}_${file.name}`;
    const storageRef = ref(storage, `groups/${filename}`);

    // Upload file
    const snapshot = await uploadBytes(storageRef, file);

    // Get download URL
    const downloadURL = await getDownloadURL(snapshot.ref);

    return downloadURL;
  } catch (error) {
    console.error('Error uploading group image:', error);
    throw error;
  }
};

/**
 * List groups
 * @returns List of groups
 */
export const listGroups = async (): Promise<GroupMaster[]> => {
  try {
    const token = await getAuthToken();
    const url = `${FUNCTIONS_BASE_URL}/listGroups`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch groups: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to fetch groups');
    }

    return data.data.groups;
  } catch (error) {
    console.error('Error fetching groups:', error);
    throw error;
  }
};

/**
 * Create group
 * @param group Group data to create
 * @returns Created group
 */
export const createGroup = async (
  group: GroupCreateRequest
): Promise<GroupMaster> => {
  try {
    const token = await getAuthToken();

    const response = await fetch(`${FUNCTIONS_BASE_URL}/createGroup`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(group),
    });

    if (!response.ok) {
      throw new Error(`Failed to create group: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to create group');
    }

    return data.data;
  } catch (error) {
    console.error('Error creating group:', error);
    throw error;
  }
};

/**
 * Update group
 * @param groupId Group ID
 * @param group Group data to update
 * @returns Updated group
 */
export const updateGroup = async (
  groupId: string,
  group: Omit<GroupUpdateRequest, 'groupId'>
): Promise<GroupMaster> => {
  try {
    const token = await getAuthToken();

    const response = await fetch(`${FUNCTIONS_BASE_URL}/updateGroup`, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ groupId, ...group }),
    });

    if (!response.ok) {
      throw new Error(`Failed to update group: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to update group');
    }

    return data.data;
  } catch (error) {
    console.error('Error updating group:', error);
    throw error;
  }
};

/**
 * Delete group
 * @param groupId Group ID
 */
export const deleteGroup = async (groupId: string): Promise<void> => {
  try {
    const token = await getAuthToken();

    const response = await fetch(`${FUNCTIONS_BASE_URL}/deleteGroup`, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ groupId }),
    });

    if (!response.ok) {
      throw new Error(`Failed to delete group: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to delete group');
    }
  } catch (error) {
    console.error('Error deleting group:', error);
    throw error;
  }
};

/**
 * Export groups to CSV
 * Downloads CSV file with all groups
 */
export const exportGroupsToCSV = async (): Promise<void> => {
  try {
    const groups = await listGroups();

    const csvData = groups.map((group) => ({
      name: group.name,
      imageUrl: group.imageUrl || '',
    }));

    const blob = arrayToCSV(csvData, ['name', 'imageUrl']);
    const filename = getTimestampedFilename('groups');

    downloadBlob(blob, filename);
  } catch (error) {
    console.error('Error exporting groups to CSV:', error);
    throw error;
  }
};

/**
 * Import groups from CSV
 * @param file CSV file
 * @returns Import result with created/updated counts and errors
 */
export const importGroupsFromCSV = async (file: File): Promise<ImportResult> => {
  try {
    // Validate file type
    if (!file.name.endsWith('.csv')) {
      throw new Error('CSVファイルを選択してください');
    }

    // Parse CSV
    const parseResult = await parseCSV<GroupCreateRequest>(
      file,
      ['name'],
      (row, lineNumber) => {
        // Validate name
        if (!row.name || row.name.trim().length === 0) {
          return {
            valid: false,
            error: 'グループ名は必須です',
          };
        }
        if (row.name.length > 100) {
          return {
            valid: false,
            error: 'グループ名は100文字以内で入力してください',
          };
        }

        // imageUrl is optional, validate if provided
        const imageUrl = row.imageUrl?.trim();
        if (imageUrl && imageUrl.length > 0) {
          try {
            new URL(imageUrl);
          } catch {
            return {
              valid: false,
              error: '有効なURL形式で入力してください（imageUrl）',
            };
          }
        }

        return {
          valid: true,
          data: {
            name: row.name.trim(),
            imageUrl: imageUrl && imageUrl.length > 0 ? imageUrl : undefined,
          },
        };
      }
    );

    // If there are errors, return immediately without creating/updating
    if (parseResult.errors.length > 0) {
      return {
        success: false,
        created: 0,
        updated: 0,
        errors: parseResult.errors,
      };
    }

    // Get existing groups to check for duplicates
    const existingGroups = await listGroups();
    const existingGroupMap = new Map(
      existingGroups.map((group) => [group.name.toLowerCase(), group])
    );

    let created = 0;
    let updated = 0;

    // Create or update groups
    for (const groupData of parseResult.data) {
      const key = groupData.name.toLowerCase();
      const existingGroup = existingGroupMap.get(key);

      if (existingGroup) {
        // Update existing group if imageUrl changed
        if (groupData.imageUrl !== existingGroup.imageUrl) {
          await updateGroup(existingGroup.groupId, { imageUrl: groupData.imageUrl });
        }
        updated++;
      } else {
        // Create new group
        await createGroup(groupData);
        created++;
      }
    }

    return {
      success: true,
      created,
      updated,
      errors: [],
    };
  } catch (error) {
    console.error('Error importing groups from CSV:', error);
    throw error;
  }
};
