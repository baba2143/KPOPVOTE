/**
 * CSV utility functions
 */

import Papa from 'papaparse';

export interface ParseResult<T> {
  data: T[];
  errors: ParseError[];
}

export interface ParseError {
  line: number;
  data: Record<string, string>;
  error: string;
}

/**
 * Parse CSV file to typed array
 * @param file CSV file
 * @param requiredHeaders Required column headers
 * @param validator Row validation function
 * @returns Parsed data with errors
 */
export const parseCSV = <T>(
  file: File,
  requiredHeaders: string[],
  validator: (row: Record<string, string>, lineNumber: number) => { valid: boolean; error?: string; data?: T }
): Promise<ParseResult<T>> => {
  return new Promise((resolve) => {
    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: (results) => {
        const errors: ParseError[] = [];
        const data: T[] = [];

        // Validate headers
        const headers = results.meta.fields || [];
        const missingHeaders = requiredHeaders.filter((h) => !headers.includes(h));

        if (missingHeaders.length > 0) {
          errors.push({
            line: 0,
            data: {},
            error: `必須カラムが不足しています: ${missingHeaders.join(', ')}`,
          });
          resolve({ data: [], errors });
          return;
        }

        // Validate each row
        results.data.forEach((row: any, index: number) => {
          const lineNumber = index + 2; // +2 because of header line and 0-based index
          const validation = validator(row, lineNumber);

          if (!validation.valid) {
            errors.push({
              line: lineNumber,
              data: row,
              error: validation.error || '不明なエラー',
            });
          } else if (validation.data) {
            data.push(validation.data);
          }
        });

        resolve({ data, errors });
      },
      error: (error) => {
        resolve({
          data: [],
          errors: [{
            line: 0,
            data: {},
            error: `CSVパースエラー: ${error.message}`,
          }],
        });
      },
    });
  });
};

/**
 * Convert array to CSV blob
 * @param data Array of objects
 * @param headers Column headers
 * @returns CSV blob
 */
export const arrayToCSV = <T extends Record<string, any>>(
  data: T[],
  headers: string[]
): Blob => {
  const csv = Papa.unparse({
    fields: headers,
    data: data.map((item) => headers.map((header) => item[header] || '')),
  });

  return new Blob([csv], { type: 'text/csv;charset=utf-8;' });
};

/**
 * Download blob as file
 * @param blob Blob to download
 * @param filename Filename
 */
export const downloadBlob = (blob: Blob, filename: string): void => {
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);

  link.href = url;
  link.download = filename;
  link.style.display = 'none';

  document.body.appendChild(link);
  link.click();

  document.body.removeChild(link);
  URL.revokeObjectURL(url);
};

/**
 * Generate timestamped filename
 * @param prefix Filename prefix
 * @returns Filename with timestamp
 */
export const getTimestampedFilename = (prefix: string): string => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');

  return `${prefix}_${year}${month}${day}.csv`;
};
