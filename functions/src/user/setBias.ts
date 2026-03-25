/**
 * Set user bias (favorite members) endpoint
 * Also tracks bias history for same bias fan notifications
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { BiasSettings, ApiResponse } from "../types";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

/**
 * Request body for setBias endpoint
 */
interface SetBiasRequest {
  myBias: BiasSettings[];
}

/**
 * Extract all bias IDs from BiasSettings array
 * Returns Set of "group_{artistId}" and "member_{memberId}"
 */
function extractBiasIds(biasSettings: BiasSettings[]): Set<string> {
  const ids = new Set<string>();
  for (const bias of biasSettings) {
    // Add group-level bias
    ids.add(`group_${bias.artistId}`);
    // Add member-level biases
    for (const memberId of bias.memberIds) {
      ids.add(`member_${memberId}`);
    }
  }
  return ids;
}

/**
 * Create a map of bias ID to bias info for quick lookup
 */
function createBiasInfoMap(biasSettings: BiasSettings[]): Map<string, {
  biasId: string;
  biasType: "group" | "member";
  biasName: string;
  groupId?: string;
  groupName?: string;
}> {
  const map = new Map();
  for (const bias of biasSettings) {
    // Group-level
    map.set(`group_${bias.artistId}`, {
      biasId: bias.artistId,
      biasType: "group",
      biasName: bias.artistName,
    });
    // Member-level
    for (let i = 0; i < bias.memberIds.length; i++) {
      map.set(`member_${bias.memberIds[i]}`, {
        biasId: bias.memberIds[i],
        biasType: "member",
        biasName: bias.memberNames[i],
        groupId: bias.artistId,
        groupName: bias.artistName,
      });
    }
  }
  return map;
}

/**
 * Update biasUserHistory collection when biases are added or removed
 */
async function updateBiasUserHistory(
  db: admin.firestore.Firestore,
  userId: string,
  previousBias: BiasSettings[],
  newBias: BiasSettings[],
  isPrivate: boolean
): Promise<void> {
  const previousIds = extractBiasIds(previousBias);
  const newIds = extractBiasIds(newBias);
  const newBiasInfoMap = createBiasInfoMap(newBias);

  // Find added biases (in new but not in previous)
  const addedIds = [...newIds].filter((id) => !previousIds.has(id));

  // Find removed biases (in previous but not in new)
  const removedIds = [...previousIds].filter((id) => !newIds.has(id));

  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Add new biases to history
  for (const id of addedIds) {
    const biasInfo = newBiasInfoMap.get(id);
    if (!biasInfo) continue;

    const docRef = db
      .collection("biasUserHistory")
      .doc(id)
      .collection("users")
      .doc(userId);

    batch.set(docRef, {
      userId,
      biasId: biasInfo.biasId,
      biasType: biasInfo.biasType,
      biasName: biasInfo.biasName,
      groupId: biasInfo.groupId || null,
      groupName: biasInfo.groupName || null,
      addedAt: now,
      isPrivate,
    });
  }

  // Remove deleted biases from history
  for (const id of removedIds) {
    const docRef = db
      .collection("biasUserHistory")
      .doc(id)
      .collection("users")
      .doc(userId);

    batch.delete(docRef);
  }

  if (addedIds.length > 0 || removedIds.length > 0) {
    await batch.commit();
    console.log(
      `✅ [setBias] Updated biasUserHistory: added=${addedIds.length}, removed=${removedIds.length}`
    );
  }
}

export const setBias = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    // Only accept POST requests
    if (req.method !== "POST") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      } as ApiResponse<null>);
      return;
    }

    try {
      // Verify authentication token
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

      // Get request body
      const { myBias } = req.body as SetBiasRequest;

      // Validate myBias array
      if (!Array.isArray(myBias)) {
        res.status(400).json({
          success: false,
          error: "myBias must be an array",
        } as ApiResponse<null>);
        return;
      }

      // Validate each bias entry
      for (const bias of myBias) {
        if (
          !bias.artistId ||
          !bias.artistName ||
          !Array.isArray(bias.memberIds) ||
          !Array.isArray(bias.memberNames)
        ) {
          res.status(400).json({
            success: false,
            error:
              "Invalid bias format. Each bias must have artistId, artistName, memberIds, and memberNames",
          } as ApiResponse<null>);
          return;
        }
      }

      const db = admin.firestore();
      const userRef = db.collection("users").doc(uid);

      // Get current user data (previous bias and isPrivate)
      const userDoc = await userRef.get();
      const userData = userDoc.data();
      const previousBias: BiasSettings[] = userData?.myBias || [];
      const isPrivate: boolean = userData?.isPrivate || false;

      // Update biasUserHistory (fire-and-forget for performance)
      updateBiasUserHistory(db, uid, previousBias, myBias, isPrivate)
        .catch((err) => console.error("❌ [setBias] Error updating biasUserHistory:", err));

      // Update user's bias in Firestore
      await userRef.update({
        myBias,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Return success response
      res.status(200).json({
        success: true,
        data: { myBias },
      } as ApiResponse<{ myBias: BiasSettings[] }>);
    } catch (error: unknown) {
      console.error("Set bias error:", error);

      // Handle specific Firebase errors
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
