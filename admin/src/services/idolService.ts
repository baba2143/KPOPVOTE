/**
 * Idol service
 */

import { auth, storage } from '../config/firebase';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { IdolMaster, IdolCreateRequest, IdolUpdateRequest } from '../types/idol';
import { parseCSV, arrayToCSV, downloadBlob, getTimestampedFilename, ParseError } from '../utils/csvUtils';

const FUNCTIONS_BASE_URL = 'https://us-central1-kpopvote-9de2b.cloudfunctions.net';

export interface ImportResult {
  success: boolean;
  created: number;
  updated: number;
  errors: ParseError[];
}

export interface ImportProgress {
  current: number;
  total: number;
  created: number;
  updated: number;
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

/**
 * Export idols to CSV
 * Downloads CSV file with all idols
 */
export const exportIdolsToCSV = async (): Promise<void> => {
  try {
    const idols = await listIdols();

    const csvData = idols.map((idol) => ({
      name: idol.name,
      groupName: idol.groupName,
    }));

    const blob = arrayToCSV(csvData, ['name', 'groupName']);
    const filename = getTimestampedFilename('idols');

    downloadBlob(blob, filename);
  } catch (error) {
    console.error('Error exporting idols to CSV:', error);
    throw error;
  }
};

/**
 * Process batch of idols in parallel
 * @param batch Batch of idol data to process
 * @param existingIdolMap Map of existing idols
 * @returns Created and updated counts
 */
const processBatch = async (
  batch: IdolCreateRequest[],
  existingIdolMap: Map<string, IdolMaster>
): Promise<{ created: number; updated: number; errors: ParseError[] }> => {
  let created = 0;
  let updated = 0;
  const errors: ParseError[] = [];

  const promises = batch.map(async (idolData, index) => {
    try {
      const key = `${idolData.name}_${idolData.groupName}`;
      const existingIdol = existingIdolMap.get(key);

      if (existingIdol) {
        // Update existing idol if imageUrl is different
        if (idolData.imageUrl && existingIdol.imageUrl !== idolData.imageUrl) {
          await updateIdol(existingIdol.idolId, {
            imageUrl: idolData.imageUrl,
          });
          return { type: 'updated' as const };
        }
        return { type: 'skipped' as const };
      } else {
        // Create new idol
        await createIdol(idolData);
        return { type: 'created' as const };
      }
    } catch (error: any) {
      return {
        type: 'error' as const,
        error: {
          line: index,
          error: error.message || '不明なエラー',
          data: {
            name: idolData.name,
            groupName: idolData.groupName,
            imageUrl: idolData.imageUrl || '',
          },
        },
      };
    }
  });

  const results = await Promise.all(promises);

  results.forEach((result) => {
    if (result.type === 'created') created++;
    else if (result.type === 'updated') updated++;
    else if (result.type === 'error') errors.push(result.error);
  });

  return { created, updated, errors };
};

/**
 * Import idols from CSV
 * @param file CSV file
 * @param onProgress Optional progress callback
 * @returns Import result with created/updated counts and errors
 */
export const importIdolsFromCSV = async (
  file: File,
  onProgress?: (progress: ImportProgress) => void
): Promise<ImportResult> => {
  try {
    // Validate file type
    if (!file.name.endsWith('.csv')) {
      throw new Error('CSVファイルを選択してください');
    }

    // Parse CSV - now including imageUrl
    const parseResult = await parseCSV<IdolCreateRequest>(
      file,
      ['name', 'groupName', 'imageUrl'],
      (row, lineNumber) => {
        // Validate name
        if (!row.name || row.name.trim().length === 0) {
          return {
            valid: false,
            error: 'アイドル名は必須です',
          };
        }
        if (row.name.length > 50) {
          return {
            valid: false,
            error: 'アイドル名は50文字以内で入力してください',
          };
        }

        // Validate groupName
        if (!row.groupName || row.groupName.trim().length === 0) {
          return {
            valid: false,
            error: 'グループ名は必須です',
          };
        }
        if (row.groupName.length > 50) {
          return {
            valid: false,
            error: 'グループ名は50文字以内で入力してください',
          };
        }

        // imageUrl is optional
        const imageUrl = row.imageUrl && row.imageUrl.trim().length > 0
          ? row.imageUrl.trim()
          : undefined;

        return {
          valid: true,
          data: {
            name: row.name.trim(),
            groupName: row.groupName.trim(),
            imageUrl,
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

    // Get existing idols to check for duplicates
    const existingIdols = await listIdols();
    const existingIdolMap = new Map(
      existingIdols.map((idol) => [`${idol.name}_${idol.groupName}`, idol])
    );

    let totalCreated = 0;
    let totalUpdated = 0;
    const allErrors: ParseError[] = [];

    // Process in batches of 5 for parallel processing
    const BATCH_SIZE = 5;
    const batches: IdolCreateRequest[][] = [];
    for (let i = 0; i < parseResult.data.length; i += BATCH_SIZE) {
      batches.push(parseResult.data.slice(i, i + BATCH_SIZE));
    }

    // Process each batch
    for (let i = 0; i < batches.length; i++) {
      const batch = batches[i];
      const { created, updated, errors } = await processBatch(batch, existingIdolMap);

      totalCreated += created;
      totalUpdated += updated;
      allErrors.push(...errors);

      // Report progress
      if (onProgress) {
        onProgress({
          current: Math.min((i + 1) * BATCH_SIZE, parseResult.data.length),
          total: parseResult.data.length,
          created: totalCreated,
          updated: totalUpdated,
        });
      }
    }

    return {
      success: allErrors.length === 0,
      created: totalCreated,
      updated: totalUpdated,
      errors: allErrors,
    };
  } catch (error) {
    console.error('Error importing idols from CSV:', error);
    throw error;
  }
};
