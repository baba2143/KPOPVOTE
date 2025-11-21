//
// verifySubscription.ts
// K-VOTE COLLECTOR - Auto-Renewable Subscription Verification
//

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import fetch from "node-fetch";

// Type definition for receipt info
interface ReceiptInfo {
  product_id: string;
  expires_date_ms: string;
  transaction_id: string;
  original_transaction_id: string;
  purchase_date_ms: string;
}

// Subscription Product ID (monthly only)
const SUBSCRIPTION_PRODUCT_ID = "com.kpopvote.premium.monthly";

// Point rewards
const FIRST_MONTH_POINTS = 1200; // Initial subscription
const MONTHLY_POINTS = 600; // Monthly renewal

/**
 * Verify Auto-Renewable Subscription Purchase
 * Validates subscription receipt with App Store and updates user's premium status
 */
export const verifySubscription = functions.https.onCall(
  async (data, context) => {
    // Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です",
      );
    }

    const userId = context.auth.uid;
    const { receiptData, productId, transactionId } = data;

    // Validate required fields
    if (!receiptData || !productId || !transactionId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "必須パラメータが不足しています",
      );
    }

    // Validate product ID
    if (productId !== SUBSCRIPTION_PRODUCT_ID) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "無効な商品IDです",
      );
    }

    console.log(
      `📱 [verifySubscription] User: ${userId}, Product: ${productId}`,
    );

    try {
      // Check if transaction already processed
      const existingPurchase = await admin
        .firestore()
        .collection("subscriptions")
        .where("userId", "==", userId)
        .where("transactionId", "==", transactionId)
        .limit(1)
        .get();

      if (!existingPurchase.empty) {
        console.log(
          `⚠️ [verifySubscription] Transaction already processed: ${transactionId}`,
        );
        throw new functions.https.HttpsError(
          "already-exists",
          "この購入は既に処理されています",
        );
      }

      // Verify receipt with App Store
      const receiptValid = await verifyReceiptWithAppStore(receiptData);
      if (!receiptValid) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "レシート検証に失敗しました",
        );
      }

      console.log("✅ [verifySubscription] Receipt verified successfully");

      // Get subscription expiration date from receipt
      const expirationDate = await getSubscriptionExpiration(
        receiptData,
        productId,
      );

      // Check if this is first-time subscription or renewal
      const existingSubSnapshot = await admin
        .firestore()
        .collection("subscriptions")
        .where("userId", "==", userId)
        .where("productId", "==", productId)
        .limit(1)
        .get();

      const isFirstMonth = existingSubSnapshot.empty;
      const points = isFirstMonth ? FIRST_MONTH_POINTS : MONTHLY_POINTS;

      console.log(
        `💰 [verifySubscription] Granting ${points}P (${isFirstMonth ? "first month" : "renewal"})`,
      );

      // Update user's subscription status and grant points
      await admin.firestore().runTransaction(async (transaction) => {
        const userRef = admin.firestore().collection("users").doc(userId);

        // Grant points
        transaction.update(userRef, {
          points: admin.firestore.FieldValue.increment(points),
          isPremium: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Create or update subscription record
        if (isFirstMonth) {
          const subRef = admin.firestore().collection("subscriptions").doc();
          transaction.set(subRef, {
            userId,
            productId,
            transactionId,
            expiresAt: admin.firestore.Timestamp.fromMillis(expirationDate),
            isActive: expirationDate > Date.now(),
            isFirstMonth: true,
            firstMonthGrantedAt:
              admin.firestore.FieldValue.serverTimestamp(),
            totalPointsGranted: points,
            purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
            lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            autoRenewing: true,
            status: "active",
          });
        } else {
          const subRef = existingSubSnapshot.docs[0].ref;
          transaction.update(subRef, {
            transactionId,
            expiresAt: admin.firestore.Timestamp.fromMillis(expirationDate),
            isActive: expirationDate > Date.now(),
            lastMonthlyGrantedAt:
              admin.firestore.FieldValue.serverTimestamp(),
            totalPointsGranted: admin.firestore.FieldValue.increment(points),
            lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // Record point transaction
        const txnRef = admin
          .firestore()
          .collection("pointTransactions")
          .doc();
        transaction.set(txnRef, {
          userId,
          points,
          type: isFirstMonth ? "subscription_first" : "subscription_monthly",
          reason: isFirstMonth ?
            "プレミアム会員初月特典" :
            "プレミアム会員月次特典",
          productId,
          transactionId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      console.log(
        `✅ [verifySubscription] Subscription activated for user: ${userId}, granted ${points}P`,
      );

      return {
        success: true,
        isPremium: expirationDate > Date.now(),
        expiresAt: new Date(expirationDate).toISOString(),
        productId,
        pointsGranted: points,
        isFirstMonth,
      };
    } catch (error: unknown) {
      const err = error as Error;
      console.error("❌ [verifySubscription] Error:", err);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "サブスクリプションの検証に失敗しました",
      );
    }
  },
);

/**
 * Verify receipt with App Store
 * Uses both production and sandbox environments
 * @param {string} receiptData - Base64-encoded App Store receipt
 * @return {Promise<boolean>} True if receipt is valid
 */
async function verifyReceiptWithAppStore(
  receiptData: string,
): Promise<boolean> {
  const productionUrl =
    "https://buy.itunes.apple.com/verifyReceipt";
  const sandboxUrl =
    "https://sandbox.itunes.apple.com/verifyReceipt";

  try {
    // Try production first
    const productionResult = await verifyReceiptWithUrl(
      productionUrl,
      receiptData,
    );

    // If status is 21007, receipt is from sandbox, try sandbox URL
    if (productionResult.status === 21007) {
      console.log(
        "🔄 [verifySubscription] Production failed, trying sandbox...",
      );
      const sandboxResult = await verifyReceiptWithUrl(
        sandboxUrl,
        receiptData,
      );
      return sandboxResult.status === 0;
    }

    return productionResult.status === 0;
  } catch (error) {
    console.error(
      "❌ [verifySubscription] Receipt verification failed:",
      error,
    );
    return false;
  }
}

/**
 * Verify receipt with specific App Store URL
 * @param {string} url App Store verification URL
 * @param {string} receiptData Base64-encoded App Store receipt
 * @return {Promise<Object>} Verification response
 */
async function verifyReceiptWithUrl(
  url: string,
  receiptData: string,
): Promise<{status: number; latest_receipt_info?: ReceiptInfo[]}> {
  const requestBody = {
    "receipt-data": receiptData,
    "password": functions.config().appstore?.sharedsecret || "",
    "exclude-old-transactions": true,
  };

  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(requestBody),
  });

  return await response.json();
}

/**
 * Get subscription expiration date from receipt
 * @param {string} receiptData - Base64-encoded receipt
 * @param {string} productId - Subscription product ID
 * @return {Promise<number>} Expiration timestamp in milliseconds
 */
async function getSubscriptionExpiration(
  receiptData: string,
  productId: string,
): Promise<number> {
  const productionUrl =
    "https://buy.itunes.apple.com/verifyReceipt";
  const sandboxUrl =
    "https://sandbox.itunes.apple.com/verifyReceipt";

  try {
    // Try production first
    let result = await verifyReceiptWithUrl(productionUrl, receiptData);

    // If sandbox receipt, try sandbox URL
    if (result.status === 21007) {
      result = await verifyReceiptWithUrl(sandboxUrl, receiptData);
    }

    if (result.status !== 0) {
      throw new Error(`Receipt verification failed: ${result.status}`);
    }

    // Get latest receipt info for the subscription
    const latestReceipts = result.latest_receipt_info || [];
    const subscriptionReceipts = latestReceipts.filter(
      (receipt: ReceiptInfo) => receipt.product_id === productId,
    );

    if (subscriptionReceipts.length === 0) {
      throw new Error("No subscription found in receipt");
    }

    // Get the most recent expiration date
    const sortedReceipts = subscriptionReceipts.sort(
      (a: ReceiptInfo, b: ReceiptInfo) =>
        parseInt(b.expires_date_ms) - parseInt(a.expires_date_ms),
    );

    const expiresDateMs = parseInt(sortedReceipts[0].expires_date_ms);
    return expiresDateMs;
  } catch (error) {
    console.error(
      "❌ [verifySubscription] Failed to get expiration date:",
      error,
    );
    throw error;
  }
}
