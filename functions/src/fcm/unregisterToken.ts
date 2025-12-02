/**
 * Unregister FCM Token API
 * POST /unregisterFcmToken
 *
 * Unregisters a device's FCM token (on logout or device removal)
 */

import * as functions from "firebase-functions";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { unregisterFCMToken } from "../utils/fcmHelper";

interface UnregisterTokenRequest {
  deviceId: string;
}

interface UnregisterTokenResponse {
  unregistered: boolean;
  deviceId: string;
}

export const unregisterFcmToken = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use POST.",
    } as ApiResponse<null>);
    return;
  }

  // Verify authentication
  await new Promise<void>((resolve, reject) => {
    verifyToken(req as AuthenticatedRequest, res, (error?: unknown) =>
      error ? reject(error) : resolve()
    );
  });

  const currentUser = (req as AuthenticatedRequest).user;
  if (!currentUser) {
    res.status(401).json({
      success: false,
      error: "Unauthorized",
    } as ApiResponse<null>);
    return;
  }

  try {
    const { deviceId } = req.body as UnregisterTokenRequest;

    // Validation
    if (!deviceId || typeof deviceId !== "string") {
      res.status(400).json({
        success: false,
        error: "deviceId is required and must be a string",
      } as ApiResponse<null>);
      return;
    }

    // Unregister the token
    const success = await unregisterFCMToken(currentUser.uid, deviceId);

    if (success) {
      console.log(
        `✅ [unregisterFcmToken] Token unregistered for user: ${currentUser.uid}, device: ${deviceId}`
      );
      res.status(200).json({
        success: true,
        data: {
          unregistered: true,
          deviceId,
        },
      } as ApiResponse<UnregisterTokenResponse>);
    } else {
      res.status(500).json({
        success: false,
        error: "Failed to unregister FCM token",
      } as ApiResponse<null>);
    }
  } catch (error: unknown) {
    console.error("❌ [unregisterFcmToken] Error:", error);
    res.status(500).json({
      success: false,
      error: "Internal server error",
    } as ApiResponse<null>);
  }
});
