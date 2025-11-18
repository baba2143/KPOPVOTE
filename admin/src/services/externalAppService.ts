/**
 * External App service
 */

import { auth, storage } from '../config/firebase';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import {
  ExternalAppMaster,
  ExternalAppCreateRequest,
  ExternalAppUpdateRequest,
} from '../types/externalApp';
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
 * Upload icon image to Firebase Storage
 * @param file Image file to upload
 * @returns Download URL of uploaded image
 */
export const uploadAppIcon = async (file: File): Promise<string> => {
  try {
    // Validate file type
    const validTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'];
    if (!validTypes.includes(file.type)) {
      throw new Error('Invalid file type. Only JPEG, PNG, WebP, and SVG are allowed.');
    }

    // Validate file size (max 10MB for cover images)
    const maxSize = 10 * 1024 * 1024; // 10MB in bytes
    if (file.size > maxSize) {
      throw new Error('File size exceeds 10MB limit.');
    }

    // Create unique filename with timestamp
    const timestamp = Date.now();
    const filename = `${timestamp}_${file.name}`;
    const storageRef = ref(storage, `external_apps/${filename}`);

    // Upload file
    const snapshot = await uploadBytes(storageRef, file);

    // Get download URL
    const downloadURL = await getDownloadURL(snapshot.ref);

    return downloadURL;
  } catch (error) {
    console.error('Error uploading icon:', error);
    throw error;
  }
};

/**
 * List external apps
 * @returns List of external apps
 */
export const listExternalApps = async (): Promise<ExternalAppMaster[]> => {
  try {
    const token = await getAuthToken();
    const url = `${FUNCTIONS_BASE_URL}/listExternalApps`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch external apps: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to fetch external apps');
    }

    return data.data.apps;
  } catch (error) {
    console.error('Error fetching external apps:', error);
    throw error;
  }
};

/**
 * Create external app
 * @param app External app data to create
 * @returns Created external app
 */
export const createExternalApp = async (
  app: ExternalAppCreateRequest
): Promise<ExternalAppMaster> => {
  try {
    const token = await getAuthToken();

    const response = await fetch(`${FUNCTIONS_BASE_URL}/createExternalApp`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(app),
    });

    if (!response.ok) {
      throw new Error(`Failed to create external app: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to create external app');
    }

    return data.data;
  } catch (error) {
    console.error('Error creating external app:', error);
    throw error;
  }
};

/**
 * Update external app
 * @param appId External app ID
 * @param app External app data to update
 * @returns Updated external app
 */
export const updateExternalApp = async (
  appId: string,
  app: ExternalAppUpdateRequest
): Promise<ExternalAppMaster> => {
  try {
    const token = await getAuthToken();

    const response = await fetch(`${FUNCTIONS_BASE_URL}/updateExternalApp`, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ appId, ...app }),
    });

    if (!response.ok) {
      throw new Error(`Failed to update external app: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to update external app');
    }

    return data.data;
  } catch (error) {
    console.error('Error updating external app:', error);
    throw error;
  }
};

/**
 * Delete external app
 * @param appId External app ID
 */
export const deleteExternalApp = async (appId: string): Promise<void> => {
  try {
    const token = await getAuthToken();

    const response = await fetch(`${FUNCTIONS_BASE_URL}/deleteExternalApp`, {
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ appId }),
    });

    if (!response.ok) {
      throw new Error(`Failed to delete external app: ${response.statusText}`);
    }

    const data = await response.json();

    if (!data.success) {
      throw new Error(data.error || 'Failed to delete external app');
    }
  } catch (error) {
    console.error('Error deleting external app:', error);
    throw error;
  }
};

/**
 * Export external apps to CSV
 * Downloads CSV file with all external apps
 */
export const exportExternalAppsToCSV = async (): Promise<void> => {
  try {
    const apps = await listExternalApps();

    const csvData = apps.map((app) => ({
      appName: app.appName,
      appUrl: app.appUrl || '',
    }));

    const blob = arrayToCSV(csvData, ['appName', 'appUrl']);
    const filename = getTimestampedFilename('external_apps');

    downloadBlob(blob, filename);
  } catch (error) {
    console.error('Error exporting external apps to CSV:', error);
    throw error;
  }
};

/**
 * Import external apps from CSV
 * @param file CSV file
 * @returns Import result with created/updated counts and errors
 */
export const importExternalAppsFromCSV = async (file: File): Promise<ImportResult> => {
  try {
    // Validate file type
    if (!file.name.endsWith('.csv')) {
      throw new Error('CSVファイルを選択してください');
    }

    // Parse CSV
    const parseResult = await parseCSV<ExternalAppCreateRequest>(
      file,
      ['appName', 'appUrl'],
      (row, lineNumber) => {
        // Validate appName
        if (!row.appName || row.appName.trim().length === 0) {
          return {
            valid: false,
            error: 'アプリ名は必須です',
          };
        }
        if (row.appName.length > 100) {
          return {
            valid: false,
            error: 'アプリ名は100文字以内で入力してください',
          };
        }

        // Validate appUrl (optional but must be valid if provided)
        const appUrl = row.appUrl?.trim();
        if (appUrl && appUrl.length > 0) {
          try {
            new URL(appUrl);
          } catch {
            return {
              valid: false,
              error: '有効なURL形式で入力してください',
            };
          }
        }

        return {
          valid: true,
          data: {
            appName: row.appName.trim(),
            appUrl: appUrl && appUrl.length > 0 ? appUrl : undefined,
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

    // Get existing apps to check for duplicates
    const existingApps = await listExternalApps();
    const existingAppMap = new Map(
      existingApps.map((app) => [app.appName.toLowerCase(), app])
    );

    let created = 0;
    let updated = 0;

    // Create or update external apps
    for (const appData of parseResult.data) {
      const key = appData.appName.toLowerCase();
      const existingApp = existingAppMap.get(key);

      if (existingApp) {
        // Update existing app if URL changed
        if (appData.appUrl !== existingApp.appUrl) {
          await updateExternalApp(existingApp.appId, { appUrl: appData.appUrl });
        }
        updated++;
      } else {
        // Create new external app
        await createExternalApp(appData);
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
    console.error('Error importing external apps from CSV:', error);
    throw error;
  }
};
