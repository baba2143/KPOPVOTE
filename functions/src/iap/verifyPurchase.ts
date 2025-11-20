/**
 * Verify App Store purchase and grant points
 * Endpoint: POST /api/verifyPurchase
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";

interface VerifyPurchaseRequest {
  receiptData: string; // Base64-encoded App Store receipt
  productId: string;
  transactionId: string;
}

interface VerifyPurchaseResponse {
  success: boolean;
  pointsGranted: number;
  newBalance: number;
  transactionId: string;
}

// Product ID to points mapping (Normal versions)
const PRODUCT_POINTS: { [key: string]: number } = {
  "com.kpopvote.points.330": 300,
  "com.kpopvote.points.550": 550,
  "com.kpopvote.points.1100": 1200,
  "com.kpopvote.points.3300": 3800,
  "com.kpopvote.points.5500": 6500,
  // Promo versions (2x points)
  "com.kpopvote.points.330.promo": 600,
  "com.kpopvote.points.550.promo": 1100,
  "com.kpopvote.points.1100.promo": 2400,
  "com.kpopvote.points.3300.promo": 7600,
  "com.kpopvote.points.5500.promo": 13000,
};

export const verifyPurchase = functions.https.onRequest(async (req, res) => {
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

  try {
    // Authenticate user
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ success: false, error: "Unauthorized: No token provided" } as ApiResponse<null>);
      return;
    }

    const token = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = decodedToken.uid;

    // Parse request body
    const { receiptData, productId, transactionId } = req.body as VerifyPurchaseRequest;

    if (!receiptData || !productId || !transactionId) {
      res.status(400).json({ success: false, error: "Missing required fields" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();

    // Check if transaction already processed (prevent duplicates)
    const existingPurchase = await db
      .collection("purchases")
      .where("transactionId", "==", transactionId)
      .limit(1)
      .get();

    if (!existingPurchase.empty) {
      console.log(`Transaction ${transactionId} already processed`);
      res.status(400).json({
        success: false,
        error: "Transaction already processed",
      } as ApiResponse<null>);
      return;
    }

    // Verify receipt with App Store (Production & Sandbox)
    const isValidReceipt = await verifyReceiptWithAppStore(receiptData);

    if (!isValidReceipt) {
      console.error("Invalid receipt from App Store");
      res.status(400).json({
        success: false,
        error: "Invalid receipt",
      } as ApiResponse<null>);
      return;
    }

    // Get points for product
    const pointsToGrant = PRODUCT_POINTS[productId];
    if (!pointsToGrant) {
      res.status(400).json({
        success: false,
        error: "Invalid product ID",
      } as ApiResponse<null>);
      return;
    }

    // Use Firestore transaction for atomicity
    const result = await db.runTransaction(async (transaction) => {
      const userRef = db.collection("users").doc(uid);
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new Error("User not found");
      }

      const userData = userDoc.data()!;
      const currentPoints = userData.points || 0;
      const newBalance = currentPoints + pointsToGrant;

      // Update user points
      transaction.update(userRef, {
        points: newBalance,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Record purchase
      const purchaseRef = db.collection("purchases").doc();
      transaction.set(purchaseRef, {
        userId: uid,
        productId,
        transactionId,
        points: pointsToGrant,
        receiptData, // Store for potential reverification
        status: "completed",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Record point transaction
      const transactionRef = db.collection("pointTransactions").doc();
      transaction.set(transactionRef, {
        userId: uid,
        points: pointsToGrant,
        type: "purchase",
        reason: `ポイント購入 (${productId})`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { pointsGranted: pointsToGrant, newBalance };
    });

    console.log(`Points granted: ${result.pointsGranted} to user ${uid}`);

    const response: VerifyPurchaseResponse = {
      success: true,
      pointsGranted: result.pointsGranted,
      newBalance: result.newBalance,
      transactionId,
    };

    res.status(200).json({
      success: true,
      data: response,
    } as ApiResponse<VerifyPurchaseResponse>);
  } catch (error: unknown) {
    console.error("Verify purchase error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});

/**
 * Verify receipt with App Store
 * Uses both production and sandbox environments
 * @param {string} receiptData - Base64-encoded App Store receipt
 * @return {Promise<boolean>} True if receipt is valid
 */
async function verifyReceiptWithAppStore(receiptData: string): Promise<boolean> {
  // Note: In production, you should use a dedicated receipt verification library
  // or Apple's Server-to-Server notifications for robust verification

  // For now, we'll implement a basic verification structure
  // In real implementation, you would:
  // 1. POST receipt to https://buy.itunes.apple.com/verifyReceipt (production)
  // 2. If status 21007, retry with https://sandbox.itunes.apple.com/verifyReceipt
  // 3. Validate receipt response fields (bundle_id, product_id, transaction_id)

  try {
    // Production verification
    const productionUrl = "https://buy.itunes.apple.com/verifyReceipt";
    const productionResponse = await verifyReceiptWithUrl(productionUrl, receiptData);

    if (productionResponse.status === 0) {
      return true;
    }

    // If production returns 21007, try sandbox
    if (productionResponse.status === 21007) {
      const sandboxUrl = "https://sandbox.itunes.apple.com/verifyReceipt";
      const sandboxResponse = await verifyReceiptWithUrl(sandboxUrl, receiptData);
      return sandboxResponse.status === 0;
    }

    return false;
  } catch (error) {
    console.error("App Store receipt verification error:", error);
    return false;
  }
}

/**
 * Verify receipt with specific App Store URL
 * @param {string} url - App Store verification URL
 * @param {string} receiptData - Base64-encoded App Store receipt
 * @return {Promise<{status: number}>} Verification response from App Store
 */
async function verifyReceiptWithUrl(url: string, receiptData: string): Promise<{ status: number }> {
  const fetch = (await import("node-fetch")).default;

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      "receipt-data": receiptData,
      "password": functions.config().appstore?.shared_secret || "", // App Store shared secret
      "exclude-old-transactions": true,
    }),
  });

  return await response.json() as { status: number };
}
