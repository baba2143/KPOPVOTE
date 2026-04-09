/**
 * Create FanCard endpoint
 * POST /createFanCard
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  FanCardCreateRequest,
  FanCardCreateResponse,
  FanCardResponse,
  DEFAULT_FANCARD_THEME,
  FANCARD_LIMITS,
  OD_DISPLAY_NAME_REGEX,
  RESERVED_OD_DISPLAY_NAMES,
} from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

/**
 * Validate odDisplayName format and availability
 */
function validateOdDisplayName(name: string): { valid: boolean; error?: string } {
  // Check length
  if (name.length < FANCARD_LIMITS.OD_DISPLAY_NAME_MIN) {
    return {
      valid: false,
      error: `URL name must be at least ${FANCARD_LIMITS.OD_DISPLAY_NAME_MIN} characters`,
    };
  }
  if (name.length > FANCARD_LIMITS.OD_DISPLAY_NAME_MAX) {
    return {
      valid: false,
      error: `URL name must be at most ${FANCARD_LIMITS.OD_DISPLAY_NAME_MAX} characters`,
    };
  }

  // Check format (lowercase alphanumeric + hyphen)
  if (!OD_DISPLAY_NAME_REGEX.test(name)) {
    return {
      valid: false,
      error: "URL name must contain only lowercase letters, numbers, and hyphens",
    };
  }

  // Check reserved names
  if (RESERVED_OD_DISPLAY_NAMES.includes(name.toLowerCase())) {
    return {
      valid: false,
      error: "This URL name is reserved and cannot be used",
    };
  }

  return { valid: true };
}

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

export const createFanCard = functions
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
      const decodedToken = await admin.auth().verifyIdToken(token);
      const uid = decodedToken.uid;

      // Parse request body
      const {
        odDisplayName,
        displayName,
        bio,
        profileImageUrl,
        headerImageUrl,
        theme,
      } = req.body as FanCardCreateRequest;

      // Validate required fields
      if (!odDisplayName || !displayName) {
        res.status(400).json({
          success: false,
          error: "odDisplayName and displayName are required",
        } as ApiResponse<null>);
        return;
      }

      // Validate odDisplayName format
      const odValidation = validateOdDisplayName(odDisplayName.toLowerCase());
      if (!odValidation.valid) {
        res.status(400).json({
          success: false,
          error: odValidation.error,
        } as ApiResponse<null>);
        return;
      }

      // Validate displayName length
      if (displayName.length > FANCARD_LIMITS.DISPLAY_NAME_MAX) {
        res.status(400).json({
          success: false,
          error: `Display name must be at most ${FANCARD_LIMITS.DISPLAY_NAME_MAX} characters`,
        } as ApiResponse<null>);
        return;
      }

      // Validate bio length
      if (bio && bio.length > FANCARD_LIMITS.BIO_MAX) {
        res.status(400).json({
          success: false,
          error: `Bio must be at most ${FANCARD_LIMITS.BIO_MAX} characters`,
        } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();
      const normalizedOdDisplayName = odDisplayName.toLowerCase();

      // Check if user already has a FanCard
      const userFanCardQuery = await db
        .collection("fanCards")
        .where("userId", "==", uid)
        .limit(1)
        .get();

      if (!userFanCardQuery.empty) {
        res.status(409).json({
          success: false,
          error: "You already have a FanCard. Use update endpoint to modify it.",
        } as ApiResponse<null>);
        return;
      }

      // Check if odDisplayName is already taken
      const existingDoc = await db
        .collection("fanCards")
        .doc(normalizedOdDisplayName)
        .get();

      if (existingDoc.exists) {
        res.status(409).json({
          success: false,
          error: "This URL name is already taken. Please choose another.",
        } as ApiResponse<null>);
        return;
      }

      // Create FanCard document
      const now = admin.firestore.FieldValue.serverTimestamp();
      const fanCardData = {
        odDisplayName: normalizedOdDisplayName,
        userId: uid,
        displayName,
        bio: bio || "",
        profileImageUrl: profileImageUrl || "",
        headerImageUrl: headerImageUrl || "",
        theme: {
          ...DEFAULT_FANCARD_THEME,
          ...(theme || {}),
        },
        blocks: [],
        isPublic: false,
        viewCount: 0,
        createdAt: now,
        updatedAt: now,
      };

      // Save to Firestore
      const docRef = db.collection("fanCards").doc(normalizedOdDisplayName);
      await docRef.set(fanCardData);

      // Also store reference in user document
      await db.collection("users").doc(uid).update({
        fanCardId: normalizedOdDisplayName,
        updatedAt: now,
      });

      // Fetch the created document to return
      const createdDoc = await docRef.get();
      const fanCard = toFanCardResponse(createdDoc);

      res.status(201).json({
        success: true,
        data: { fanCard },
      } as ApiResponse<FanCardCreateResponse>);
    } catch (error: unknown) {
      console.error("Create FanCard error:", error);

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
