/**
 * Register FCM Token API
 * POST /registerFcmToken
 *
 * Registers a device's FCM token for push notifications
 */

import * as functions from "firebase-functions";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { registerFCMToken } from "../utils/fcmHelper";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

interface RegisterTokenRequest {
  token: string;
  deviceId: string;
  platform: "ios" | "android";
}

interface RegisterTokenResponse {
  registered: boolean;
  deviceId: string;
}

export const registerFcmToken = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

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
      const { token, deviceId, platform } = req.body as RegisterTokenRequest;

      // Validation
      if (!token || typeof token !== "string") {
        res.status(400).json({
          success: false,
          error: "token is required and must be a string",
        } as ApiResponse<null>);
        return;
      }

      if (!deviceId || typeof deviceId !== "string") {
        res.status(400).json({
          success: false,
          error: "deviceId is required and must be a string",
        } as ApiResponse<null>);
        return;
      }

      if (!platform || !["ios", "android"].includes(platform)) {
        res.status(400).json({
          success: false,
          error: "platform is required and must be 'ios' or 'android'",
        } as ApiResponse<null>);
        return;
      }

      // Register the token
      const success = await registerFCMToken(
        currentUser.uid,
        token,
        deviceId,
        platform
      );

      if (success) {
        console.log(
          `✅ [registerFcmToken] Token registered for user: ${currentUser.uid}`
        );
        res.status(200).json({
          success: true,
          data: {
            registered: true,
            deviceId,
          },
        } as ApiResponse<RegisterTokenResponse>);
      } else {
        res.status(500).json({
          success: false,
          error: "Failed to register FCM token",
        } as ApiResponse<null>);
      }
    } catch (error: unknown) {
      console.error("❌ [registerFcmToken] Error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
