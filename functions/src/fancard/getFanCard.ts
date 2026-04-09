/**
 * Get current user's FanCard endpoint
 * GET /getFanCard
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  FanCardGetResponse,
  FanCardResponse,
  DEFAULT_FANCARD_THEME,
} from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

/**
 * Convert Firestore document to API response format
 */
function toFanCardResponse(doc: FirebaseFirestore.DocumentSnapshot): FanCardResponse {
  const data = doc.data()!;
  return {
    odDisplayName: data.odDisplayName,
    userId: data.userId,
    displayName: data.displayName,
    bio: data.bio || "",
    profileImageUrl: data.profileImageUrl || "",
    headerImageUrl: data.headerImageUrl || "",
    theme: data.theme || DEFAULT_FANCARD_THEME,
    blocks: data.blocks || [],
    isPublic: data.isPublic || false,
    viewCount: data.viewCount || 0,
    createdAt: data.createdAt?.toDate?.().toISOString() || new Date().toISOString(),
    updatedAt: data.updatedAt?.toDate?.().toISOString() || new Date().toISOString(),
  };
}

export const getFanCard = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS
    if (handleCors(req, res)) return;

    // Only accept GET
    if (req.method !== "GET") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use GET.",
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
      const decodedToken = await admin.auth().verifyIdToken(token);
      const uid = decodedToken.uid;

      const db = admin.firestore();

      // Find FanCard by userId
      const fanCardQuery = await db
        .collection("fanCards")
        .where("userId", "==", uid)
        .limit(1)
        .get();

      if (fanCardQuery.empty) {
        res.status(200).json({
          success: true,
          data: {
            fanCard: null,
            hasFanCard: false,
          },
        } as ApiResponse<FanCardGetResponse>);
        return;
      }

      const fanCard = toFanCardResponse(fanCardQuery.docs[0]);

      res.status(200).json({
        success: true,
        data: {
          fanCard,
          hasFanCard: true,
        },
      } as ApiResponse<FanCardGetResponse>);
    } catch (error: unknown) {
      console.error("Get FanCard error:", error);

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
