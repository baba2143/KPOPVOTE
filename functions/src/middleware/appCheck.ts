/**
 * App Check middleware for K-VOTE COLLECTOR
 * Verifies Firebase App Check tokens to protect against bots/scripts
 */

import * as admin from "firebase-admin";
import { Response } from "express";

export interface AppCheckResult {
  verified: boolean;
  error?: string;
}

/**
 * Verify App Check token for onRequest handlers
 * @param appCheckToken - The App Check token from X-Firebase-AppCheck header
 * @param res - Express response object
 * @returns true if verification failed (response already sent), false if verified successfully
 */
export async function verifyAppCheck(
  appCheckToken: string | undefined,
  res: Response
): Promise<boolean> {
  if (!appCheckToken) {
    res.status(401).json({
      success: false,
      error: "Missing App Check token",
    });
    return true; // Failed
  }

  try {
    await admin.appCheck().verifyToken(appCheckToken);
    return false; // Success
  } catch (error) {
    console.error("[AppCheck] Token verification failed:", error);
    res.status(401).json({
      success: false,
      error: "Invalid App Check token",
    });
    return true; // Failed
  }
}
