/**
 * Get FanCard by odDisplayName (public endpoint)
 * GET /getFanCardByOdDisplayName?odDisplayName=xxx
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  FanCardPublicResponse,
  FanCardResponse,
  DEFAULT_FANCARD_THEME,
  BiasSettings,
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

export const getFanCardByOdDisplayName = functions
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
      const odDisplayName = req.query.odDisplayName as string;

      if (!odDisplayName) {
        res.status(400).json({
          success: false,
          error: "odDisplayName is required",
        } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();
      const normalizedName = odDisplayName.toLowerCase();

      // Get FanCard document
      const docRef = db.collection("fanCards").doc(normalizedName);
      const doc = await docRef.get();

      if (!doc.exists) {
        res.status(404).json({
          success: false,
          error: "FanCard not found",
        } as ApiResponse<null>);
        return;
      }

      const data = doc.data()!;

      // Check if FanCard is public
      if (!data.isPublic) {
        res.status(404).json({
          success: false,
          error: "FanCard not found",
        } as ApiResponse<null>);
        return;
      }

      const fanCard = toFanCardResponse(doc);

      // Fetch additional user data for public view
      let userDisplayName: string | undefined;
      let userPhotoURL: string | undefined;
      let myBias: BiasSettings[] | undefined;

      try {
        const userDoc = await db.collection("users").doc(data.userId).get();
        if (userDoc.exists) {
          const userData = userDoc.data()!;
          userDisplayName = userData.displayName;
          userPhotoURL = userData.photoURL;
          myBias = userData.myBias;
        }
      } catch (userError) {
        console.warn("Failed to fetch user data:", userError);
        // Continue without user data
      }

      res.status(200).json({
        success: true,
        data: {
          fanCard,
          userDisplayName,
          userPhotoURL,
          myBias,
        },
      } as ApiResponse<FanCardPublicResponse>);
    } catch (error: unknown) {
      console.error("Get FanCard by odDisplayName error:", error);

      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
