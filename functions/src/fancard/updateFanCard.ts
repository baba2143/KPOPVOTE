/**
 * Update FanCard endpoint
 * PUT /updateFanCard
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  ApiResponse,
  FanCardUpdateRequest,
  FanCardResponse,
  FanCardBlock,
  DEFAULT_FANCARD_THEME,
  FANCARD_LIMITS,
} from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

/**
 * Validate blocks array
 */
function validateBlocks(blocks: FanCardBlock[]): { valid: boolean; error?: string } {
  if (blocks.length > FANCARD_LIMITS.BLOCKS_MAX) {
    return {
      valid: false,
      error: `Maximum ${FANCARD_LIMITS.BLOCKS_MAX} blocks allowed`,
    };
  }

  for (const block of blocks) {
    // Validate block structure
    if (!block.id || !block.type || typeof block.order !== "number") {
      return {
        valid: false,
        error: "Invalid block structure: id, type, and order are required",
      };
    }

    // Validate block-specific data
    switch (block.type) {
    case "link":
      if (!block.data.title || !block.data.url) {
        return { valid: false, error: "Link block requires title and url" };
      }
      if (block.data.title.length > FANCARD_LIMITS.LINK_TITLE_MAX) {
        return {
          valid: false,
          error: `Link title must be at most ${FANCARD_LIMITS.LINK_TITLE_MAX} characters`,
        };
      }
      break;

    case "mvLink":
      if (!block.data.title || !block.data.youtubeUrl) {
        return { valid: false, error: "MV Link block requires title and youtubeUrl" };
      }
      // Basic YouTube URL validation
      if (
        !block.data.youtubeUrl.includes("youtube.com") &&
          !block.data.youtubeUrl.includes("youtu.be")
      ) {
        return { valid: false, error: "Invalid YouTube URL" };
      }
      break;

    case "sns":
      if (!block.data.platform || !block.data.url) {
        return { valid: false, error: "SNS block requires platform and url" };
      }
      break;

    case "text":
      if (typeof block.data.content !== "string") {
        return { valid: false, error: "Text block requires content" };
      }
      if (block.data.content.length > FANCARD_LIMITS.TEXT_CONTENT_MAX) {
        return {
          valid: false,
          error: `Text content must be at most ${FANCARD_LIMITS.TEXT_CONTENT_MAX} characters`,
        };
      }
      break;

    case "image":
      if (!block.data.imageUrl) {
        return { valid: false, error: "Image block requires imageUrl" };
      }
      break;

    case "bias":
      // Bias block is always valid if structure is correct
      break;

    default:
      return { valid: false, error: `Unknown block type: ${(block as any).type}` };
    }
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

export const updateFanCard = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS
    if (handleCors(req, res)) return;

    // Only accept PUT or PATCH
    if (req.method !== "PUT" && req.method !== "PATCH") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use PUT or PATCH.",
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
      const updateData = req.body as FanCardUpdateRequest;

      const db = admin.firestore();

      // Find user's FanCard
      const fanCardQuery = await db
        .collection("fanCards")
        .where("userId", "==", uid)
        .limit(1)
        .get();

      if (fanCardQuery.empty) {
        res.status(404).json({
          success: false,
          error: "FanCard not found. Create one first.",
        } as ApiResponse<null>);
        return;
      }

      const docRef = fanCardQuery.docs[0].ref;

      // Validate displayName if provided
      if (updateData.displayName !== undefined) {
        if (updateData.displayName.length > FANCARD_LIMITS.DISPLAY_NAME_MAX) {
          res.status(400).json({
            success: false,
            error: `Display name must be at most ${FANCARD_LIMITS.DISPLAY_NAME_MAX} characters`,
          } as ApiResponse<null>);
          return;
        }
      }

      // Validate bio if provided
      if (updateData.bio !== undefined) {
        if (updateData.bio.length > FANCARD_LIMITS.BIO_MAX) {
          res.status(400).json({
            success: false,
            error: `Bio must be at most ${FANCARD_LIMITS.BIO_MAX} characters`,
          } as ApiResponse<null>);
          return;
        }
      }

      // Validate blocks if provided
      if (updateData.blocks !== undefined) {
        const blocksValidation = validateBlocks(updateData.blocks);
        if (!blocksValidation.valid) {
          res.status(400).json({
            success: false,
            error: blocksValidation.error,
          } as ApiResponse<null>);
          return;
        }
      }

      // Build update object
      const updateFields: Record<string, any> = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (updateData.displayName !== undefined) {
        updateFields.displayName = updateData.displayName;
      }
      if (updateData.bio !== undefined) {
        updateFields.bio = updateData.bio;
      }
      if (updateData.profileImageUrl !== undefined) {
        updateFields.profileImageUrl = updateData.profileImageUrl;
      }
      if (updateData.headerImageUrl !== undefined) {
        updateFields.headerImageUrl = updateData.headerImageUrl;
      }
      if (updateData.theme !== undefined) {
        // Merge with existing theme
        const currentDoc = await docRef.get();
        const currentTheme = currentDoc.data()?.theme || DEFAULT_FANCARD_THEME;
        updateFields.theme = {
          ...currentTheme,
          ...updateData.theme,
        };
      }
      if (updateData.blocks !== undefined) {
        updateFields.blocks = updateData.blocks;
      }
      if (updateData.isPublic !== undefined) {
        updateFields.isPublic = updateData.isPublic;
      }

      // Update document
      await docRef.update(updateFields);

      // Fetch updated document
      const updatedDoc = await docRef.get();
      const fanCard = toFanCardResponse(updatedDoc);

      res.status(200).json({
        success: true,
        data: { fanCard },
      } as ApiResponse<{ fanCard: FanCardResponse }>);
    } catch (error: unknown) {
      console.error("Update FanCard error:", error);

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
