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

    // Decode Base64
    const imageBuffer = Buffer.from(imageData, "base64");

    // Generate unique filename
    const timestamp = Date.now();
    const filename = `${timestamp}.jpg`;
    const filepath = `goods/${currentUser.uid}/${filename}`;

    // Upload to Firebase Storage
    const bucket = admin.storage().bucket();
    const file = bucket.file(filepath);

    await file.save(imageBuffer, {
      metadata: {
        contentType: "image/jpeg",
      },
      public: true,
    });

    // Make file publicly accessible
    await file.makePublic();

    // Get public URL
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${filepath}`;

    console.log(`✅ Image uploaded: ${publicUrl}`);

    res.status(200).json({
      success: true,
      data: {
        imageUrl: publicUrl,
      },
    } as ApiResponse<{ imageUrl: string }>);
  } catch (error: unknown) {
    console.error("Upload goods image error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
