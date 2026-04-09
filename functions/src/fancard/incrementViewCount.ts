/**
 * Increment FanCard view count endpoint
 * POST /incrementFanCardViewCount
 *
 * This is a public endpoint (no auth required) for tracking page views.
 * Rate limiting is handled to prevent abuse.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

// Simple in-memory rate limiting (per instance)
// In production, consider using Redis or Firestore for distributed rate limiting
const viewCache = new Map<string, number>();
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour

/**
 * Check if view should be counted (basic rate limiting)
 */
function shouldCountView(identifier: string): boolean {
  const now = Date.now();
  const lastView = viewCache.get(identifier);

  if (!lastView || now - lastView > RATE_LIMIT_WINDOW_MS) {
    viewCache.set(identifier, now);

    // Clean up old entries periodically
    if (viewCache.size > 10000) {
      const cutoff = now - RATE_LIMIT_WINDOW_MS;
      const keysToDelete: string[] = [];
      viewCache.forEach((time, key) => {
        if (time < cutoff) {
          keysToDelete.push(key);
        }
      });
      keysToDelete.forEach((key) => viewCache.delete(key));
    }

    return true;
  }

  return false;
}

export const incrementFanCardViewCount = functions
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
      const { odDisplayName } = req.body as { odDisplayName: string };

      if (!odDisplayName) {
        res.status(400).json({
          success: false,
          error: "odDisplayName is required",
        } as ApiResponse<null>);
        return;
      }

      const normalizedName = odDisplayName.toLowerCase();

      // Get client identifier for rate limiting
      const clientIp =
        req.headers["x-forwarded-for"]?.toString().split(",")[0] ||
        req.ip ||
        "unknown";
      const identifier = `${clientIp}:${normalizedName}`;

      // Check rate limit
      if (!shouldCountView(identifier)) {
        // Still return success but don't increment
        res.status(200).json({
          success: true,
          data: {
            counted: false,
            reason: "Rate limited",
          },
        } as ApiResponse<{ counted: boolean; reason?: string }>);
        return;
      }

      const db = admin.firestore();
      const docRef = db.collection("fanCards").doc(normalizedName);

      // Check if document exists
      const doc = await docRef.get();
      if (!doc.exists) {
        res.status(404).json({
          success: false,
          error: "FanCard not found",
        } as ApiResponse<null>);
        return;
      }

      // Check if FanCard is public
      if (!doc.data()?.isPublic) {
        res.status(404).json({
          success: false,
          error: "FanCard not found",
        } as ApiResponse<null>);
        return;
      }

      // Increment view count atomically
      await docRef.update({
        viewCount: admin.firestore.FieldValue.increment(1),
      });

      res.status(200).json({
        success: true,
        data: {
          counted: true,
        },
      } as ApiResponse<{ counted: boolean }>);
    } catch (error: unknown) {
      console.error("Increment view count error:", error);

      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
