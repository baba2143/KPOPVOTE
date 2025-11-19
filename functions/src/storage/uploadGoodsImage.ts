/**
 * Upload goods image to Firebase Storage
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { ApiResponse } from "../types";

export const uploadGoodsImage = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({ success: false, error: "Method not allowed. Use POST." } as ApiResponse<null>);
    return;
  }

  await new Promise<void>((resolve, reject) => {
    verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  const currentUser = (req as AuthenticatedRequest).user;
  if (!currentUser) {
    res.status(401).json({ success: false, error: "Unauthorized" } as ApiResponse<null>);
    return;
  }

  try {
    const { imageData } = req.body;

    if (!imageData) {
      res.status(400).json({ success: false, error: "imageData is required" } as ApiResponse<null>);
      return;
    }

    console.log(`📤 [uploadGoodsImage] Starting upload for user: ${currentUser.uid}`);
    console.log(`📤 [uploadGoodsImage] Image data length: ${imageData.length} characters`);

    // Decode Base64
    const imageBuffer = Buffer.from(imageData, "base64");
    console.log(`📤 [uploadGoodsImage] Image buffer size: ${imageBuffer.length} bytes`);

    // Generate unique filename
    const timestamp = Date.now();
    const filename = `${timestamp}.jpg`;
    const filepath = `goods/${currentUser.uid}/${filename}`;

    console.log(`📤 [uploadGoodsImage] Target path: ${filepath}`);

    // Upload to Firebase Storage
    const bucket = admin.storage().bucket();
    const file = bucket.file(filepath);

    console.log(`📤 [uploadGoodsImage] Saving to bucket: ${bucket.name}`);

    // Save file without public option (deprecated)
    await file.save(imageBuffer, {
      metadata: {
        contentType: "image/jpeg",
      },
    });

    console.log("✅ [uploadGoodsImage] File saved successfully");

    // Try to make file publicly accessible
    try {
      await file.makePublic();
      console.log("✅ [uploadGoodsImage] File made public");
    } catch (publicError) {
      console.warn("⚠️ [uploadGoodsImage] Could not make file public (may already be public):", publicError);
      // Continue even if makePublic fails - file might still be accessible
    }

    // Get public URL - use Firebase Storage URL format
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${filepath}`;

    console.log(`✅ [uploadGoodsImage] Image uploaded successfully: ${publicUrl}`);

    res.status(200).json({
      success: true,
      data: {
        imageUrl: publicUrl,
      },
    } as ApiResponse<{ imageUrl: string }>);
  } catch (error: unknown) {
    console.error("❌ [uploadGoodsImage] Upload error:", error);
    if (error instanceof Error) {
      console.error("❌ [uploadGoodsImage] Error message:", error.message);
      console.error("❌ [uploadGoodsImage] Error stack:", error.stack);
    }
    res.status(500).json({
      success: false,
      error: "Internal server error",
      details: error instanceof Error ? error.message : String(error),
    } as ApiResponse<null>);
  }
});
