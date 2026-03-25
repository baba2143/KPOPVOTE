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

// Use relative URL to proxy through Firebase Hosting (avoids CORS preflight issues)
const FUNCTIONS_BASE_URL = '/api';

export interface ImportResult {
  success: boolean;
  created: number;
  updated: number;
  errors: ParseError[];
}

export interface ReplaceProgress {
  phase: 'deleting' | 'importing';
  current: number;
  total: number;
  created: number;
}

export interface ReplaceResult {
  success: boolean;
  deleted: number;
  created: number;
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

/**
 * Delete all groups from Firestore
 * @param onProgress Optional callback for deletion progress
 * @returns Number of deleted groups
 */
const deleteAllGroups = async (
  onProgress?: (deleted: number, total: number) => void
): Promise<number> => {
  const groups = await listGroups();
  console.log(`[deleteAllGroups] 削除対象: ${groups.length}件`);

  if (groups.length === 0) {
    console.warn('[deleteAllGroups] 削除対象のグループが0件です');
    return 0;
  }

  // バッチで削除（503エラー対策: バッチサイズ縮小 + 遅延追加）
  const BATCH_SIZE = 10;
  let deletedCount = 0;

  for (let i = 0; i < groups.length; i += BATCH_SIZE) {
    const batch = groups.slice(i, i + BATCH_SIZE);

    // Promise.allSettledで個別エラーを追跡
    const results = await Promise.allSettled(
      batch.map(group => deleteGroup(group.groupId))
    );

    const succeeded = results.filter(r => r.status === 'fulfilled').length;
    const failed = results.filter(r => r.status === 'rejected');

    if (failed.length > 0) {
      console.warn(`[deleteAllGroups] バッチ内 ${failed.length}件の削除失敗`);
    }

    deletedCount += succeeded;
    onProgress?.(deletedCount, groups.length);

    // バッチ間に遅延を追加（Cloud Functions負荷軽減）
    if (i + BATCH_SIZE < groups.length) {
      await new Promise(resolve => setTimeout(resolve, 500));
    }
  }

  console.log(`[deleteAllGroups] 削除完了: ${deletedCount}件`);
  return deletedCount;
};

/**
 * Replace all groups with CSV data (delete all then import)
 * @param file CSV file
 * @param onProgress Optional progress callback
 * @returns Replace result with deleted/created counts and errors
 */
export const replaceGroupsFromCSV = async (
  file: File,
  onProgress?: (progress: ReplaceProgress) => void
): Promise<ReplaceResult> => {
  try {
    // Validate file type
    if (!file.name.endsWith('.csv')) {
      throw new Error('CSVファイルを選択してください');
    }

    // 1. 既存データ全削除
    onProgress?.({ phase: 'deleting', current: 0, total: 0, created: 0 });
    const deletedCount = await deleteAllGroups((deleted, total) => {
      onProgress?.({ phase: 'deleting', current: deleted, total: total, created: 0 });
    });

    // Firestore整合性確保のため待機
    console.log('[replaceGroupsFromCSV] Firestore整合性待機中...');
    await new Promise(resolve => setTimeout(resolve, 3000));

    // 削除検証（リトライ付き）
    let remainingGroups = await listGroups();
    let retryCount = 0;
    const MAX_RETRIES = 3;

    while (remainingGroups.length > 0 && retryCount < MAX_RETRIES) {
      console.warn(`[replaceGroupsFromCSV] 検証リトライ ${retryCount + 1}/${MAX_RETRIES}: ${remainingGroups.length}件残存`);
      await new Promise(resolve => setTimeout(resolve, 2000));
      remainingGroups = await listGroups();
      retryCount++;
    }

    if (remainingGroups.length > 0) {
      throw new Error(`削除が完了しませんでした。${remainingGroups.length}件が残っています。再度お試しください。`);
    }
    console.log('[replaceGroupsFromCSV] 削除検証OK: 全グループ削除完了');

    // 2. CSVパース
    const parseResult = await parseCSV<GroupCreateRequest>(
      file,
      ['name'],
      (row) => {
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

    // If there are errors, return immediately
    if (parseResult.errors.length > 0) {
      return {
        success: false,
        deleted: deletedCount,
        created: 0,
        errors: parseResult.errors,
      };
    }

    // 3. 新規インポート（全て新規作成）
    let totalCreated = 0;
    const allErrors: ParseError[] = [];

    const BATCH_SIZE = 5;
    for (let i = 0; i < parseResult.data.length; i += BATCH_SIZE) {
      const batch = parseResult.data.slice(i, i + BATCH_SIZE);
      const results = await Promise.all(
        batch.map(async (groupData, index) => {
          try {
            await createGroup(groupData);
            return { type: 'created' as const };
          } catch (error: any) {
            return {
              type: 'error' as const,
              error: {
                line: i + index + 2, // +2 for header and 1-based index
                error: error.message || '不明なエラー',
                data: {
                  name: groupData.name,
                  imageUrl: groupData.imageUrl || '',
                },
              },
            };
          }
        })
      );

      results.forEach((result) => {
        if (result.type === 'created') totalCreated++;
        else if (result.type === 'error') allErrors.push(result.error);
      });

      // Report progress
      onProgress?.({
        phase: 'importing',
        current: Math.min(i + BATCH_SIZE, parseResult.data.length),
        total: parseResult.data.length,
        created: totalCreated,
      });
    }

    return {
      success: allErrors.length === 0,
      deleted: deletedCount,
      created: totalCreated,
      errors: allErrors,
    };
  } catch (error) {
    console.error('Error replacing groups from CSV:', error);
    throw error;
  }
};
