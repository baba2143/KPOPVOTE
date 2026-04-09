/**
 * Check odDisplayName availability endpoint
 * POST /checkOdDisplayName
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  FanCardCheckOdDisplayNameRequest,
  FanCardCheckOdDisplayNameResponse,
  FANCARD_LIMITS,
  OD_DISPLAY_NAME_REGEX,
  RESERVED_OD_DISPLAY_NAMES,
} from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

/**
 * Generate alternative suggestions for a taken username
 */
function generateSuggestions(baseName: string): string[] {
  const suggestions: string[] = [];
  const now = new Date();

  // Add random numbers
  suggestions.push(`${baseName}-${Math.floor(Math.random() * 1000)}`);
  suggestions.push(`${baseName}-${now.getFullYear()}`);
  suggestions.push(`${baseName}-fan`);
  suggestions.push(`${baseName}-oshi`);

  return suggestions.filter(
    (s) => s.length <= FANCARD_LIMITS.OD_DISPLAY_NAME_MAX
  );
}

export const checkOdDisplayName = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS
    if (handleCors(req, res)) return;

    // Only accept POST
    if (req.method !== "POST") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      } as ApiResponse<null>);
      return;
    }

    try {
      // Verify authentication
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          success: false,
          error: "Unauthorized: No token provided",
        } as ApiResponse<null>);
        return;
      }

      const token = authHeader.split("Bearer ")[1];
      await admin.auth().verifyIdToken(token);

      // Parse request body
      const { odDisplayName } = req.body as FanCardCheckOdDisplayNameRequest;

      if (!odDisplayName) {
        res.status(400).json({
          success: false,
          error: "odDisplayName is required",
        } as ApiResponse<null>);
        return;
      }

      const normalizedName = odDisplayName.toLowerCase();

      // Check length
      if (normalizedName.length < FANCARD_LIMITS.OD_DISPLAY_NAME_MIN) {
        res.status(200).json({
          success: true,
          data: {
            available: false,
            suggestion: `Name must be at least ${FANCARD_LIMITS.OD_DISPLAY_NAME_MIN} characters`,
          },
        } as ApiResponse<FanCardCheckOdDisplayNameResponse>);
        return;
      }

      if (normalizedName.length > FANCARD_LIMITS.OD_DISPLAY_NAME_MAX) {
        res.status(200).json({
          success: true,
          data: {
            available: false,
            suggestion: `Name must be at most ${FANCARD_LIMITS.OD_DISPLAY_NAME_MAX} characters`,
          },
        } as ApiResponse<FanCardCheckOdDisplayNameResponse>);
        return;
      }

      // Check format
      if (!OD_DISPLAY_NAME_REGEX.test(normalizedName)) {
        res.status(200).json({
          success: true,
          data: {
            available: false,
            suggestion: "Use only lowercase letters, numbers, and hyphens",
          },
        } as ApiResponse<FanCardCheckOdDisplayNameResponse>);
        return;
      }

      // Check reserved names
      if (RESERVED_OD_DISPLAY_NAMES.includes(normalizedName)) {
        const suggestions = generateSuggestions(normalizedName);
        res.status(200).json({
          success: true,
          data: {
            available: false,
            suggestion: suggestions[0],
          },
        } as ApiResponse<FanCardCheckOdDisplayNameResponse>);
        return;
      }

      // Check if name is already taken
      const db = admin.firestore();
      const existingDoc = await db.collection("fanCards").doc(normalizedName).get();

      if (existingDoc.exists) {
        const suggestions = generateSuggestions(normalizedName);

        // Find first available suggestion
        let availableSuggestion: string | undefined;
        for (const suggestion of suggestions) {
          const suggestionDoc = await db.collection("fanCards").doc(suggestion).get();
          if (!suggestionDoc.exists) {
            availableSuggestion = suggestion;
            break;
          }
        }

        res.status(200).json({
          success: true,
          data: {
            available: false,
            suggestion: availableSuggestion,
          },
        } as ApiResponse<FanCardCheckOdDisplayNameResponse>);
        return;
      }

      // Name is available
      res.status(200).json({
        success: true,
        data: {
          available: true,
        },
      } as ApiResponse<FanCardCheckOdDisplayNameResponse>);
    } catch (error: unknown) {
      console.error("Check odDisplayName error:", error);

      if (
        typeof error === "object" &&
        error !== null &&
        "code" in error &&
        error.code === "auth/id-token-expired"
      ) {
        res.status(401).json({
          success: false,
          error: "Token expired",
        } as ApiResponse<null>);
        return;
      }

      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
