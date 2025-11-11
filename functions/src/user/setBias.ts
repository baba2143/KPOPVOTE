/**
 * Set user bias (favorite members) endpoint
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { BiasSettings, ApiResponse } from "../types";

/**
 * Request body for setBias endpoint
 */
interface SetBiasRequest {
  myBias: BiasSettings[];
}

export const setBias = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Handle preflight request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

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

    // Update user's bias in Firestore
    await admin
      .firestore()
      .collection("users")
      .doc(uid)
      .update({
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
