/**
 * FCM (Firebase Cloud Messaging) Helper Utilities
 * Push notification sending and token management for K-VOTE COLLECTOR
 */

import * as admin from "firebase-admin";
import { Notification } from "../types";

// FCM Token Document Structure
export interface FCMToken {
  token: string;
  deviceId: string;
  platform: "ios" | "android";
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

// Push Notification Payload
export interface PushNotificationPayload {
  userId: string;
  type: Notification["type"];
  title: string;
  body: string;
  data?: {
    postId?: string;
    voteId?: string;
    commentId?: string;
    collectionId?: string;
    userId?: string;
    notificationId?: string;
    conversationId?: string;
    messageId?: string;
    senderId?: string;
  };
}

// Send Result
export interface SendPushResult {
  success: boolean;
  successCount: number;
  failureCount: number;
  invalidTokens: string[];
}

/**
 * Send push notification to a user via FCM
 * Handles multiple devices and automatically removes invalid tokens
 */
export async function sendPushNotification(
  payload: PushNotificationPayload
): Promise<SendPushResult> {
  const db = admin.firestore();
  const result: SendPushResult = {
    success: false,
    successCount: 0,
    failureCount: 0,
    invalidTokens: [],
  };

  try {
    // Get all FCM tokens for the user
    const tokensSnapshot = await db
      .collection("users")
      .doc(payload.userId)
      .collection("fcmTokens")
      .get();

    if (tokensSnapshot.empty) {
      console.log(`📱 [FCM] No FCM tokens found for user: ${payload.userId}`);
      return result;
    }

    const tokens: string[] = [];
    const tokenDocs: Map<string, admin.firestore.DocumentReference> = new Map();

    tokensSnapshot.forEach((doc) => {
      const data = doc.data() as FCMToken;
      tokens.push(data.token);
      tokenDocs.set(data.token, doc.ref);
    });

    console.log(`📱 [FCM] Sending to ${tokens.length} device(s) for user: ${payload.userId}`);

    // Build FCM message
    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: {
        type: payload.type,
        notificationId: payload.data?.notificationId || "",
        postId: payload.data?.postId || "",
        voteId: payload.data?.voteId || "",
        commentId: payload.data?.commentId || "",
        userId: payload.data?.userId || "",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      apns: {
        headers: {
          "apns-priority": "10",
        },
        payload: {
          aps: {
            "alert": {
              title: payload.title,
              body: payload.body,
            },
            "badge": 1,
            "sound": "default",
            "content-available": 1,
          },
        },
      },
      android: {
        priority: "high",
        notification: {
          channelId: "default",
          sound: "default",
          priority: "high",
        },
      },
    };

    // Send multicast message
    const response = await admin.messaging().sendEachForMulticast(message);

    result.successCount = response.successCount;
    result.failureCount = response.failureCount;
    result.success = response.successCount > 0;

    console.log(
      `✅ [FCM] Sent: ${response.successCount} success, ${response.failureCount} failure`
    );

    // Handle failed tokens (remove invalid ones)
    const invalidTokens: string[] = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errorCode = resp.error?.code;
        // Remove tokens that are invalid or unregistered
        if (
          errorCode === "messaging/invalid-registration-token" ||
          errorCode === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(tokens[idx]);
        }
        console.error(
          `❌ [FCM] Failed to send to token ${idx}: ${resp.error?.message}`
        );
      }
    });

    // Delete invalid tokens from Firestore
    if (invalidTokens.length > 0) {
      console.log(`🗑️ [FCM] Removing ${invalidTokens.length} invalid token(s)`);
      const batch = db.batch();
      for (const token of invalidTokens) {
        const docRef = tokenDocs.get(token);
        if (docRef) {
          batch.delete(docRef);
        }
      }
      await batch.commit();
      result.invalidTokens = invalidTokens;
    }

    return result;
  } catch (error) {
    console.error("❌ [FCM] Error sending push notification:", error);
    return result;
  }
}

/**
 * Register FCM token for a user's device
 */
export async function registerFCMToken(
  userId: string,
  token: string,
  deviceId: string,
  platform: "ios" | "android"
): Promise<boolean> {
  const db = admin.firestore();

  try {
    // Check if this token already exists for any user (to avoid duplicate registrations)
    const existingTokenQuery = await db
      .collectionGroup("fcmTokens")
      .where("token", "==", token)
      .get();

    // Delete existing token documents for this token (could be from a different user/device)
    if (!existingTokenQuery.empty) {
      const batch = db.batch();
      existingTokenQuery.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log("🔄 [FCM] Removed existing token registration(s)");
    }

    // Register token for the current user
    const tokenRef = db
      .collection("users")
      .doc(userId)
      .collection("fcmTokens")
      .doc(deviceId);

    await tokenRef.set({
      token,
      deviceId,
      platform,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(
      `✅ [FCM] Token registered for user: ${userId}, device: ${deviceId}, platform: ${platform}`
    );
    return true;
  } catch (error) {
    console.error("❌ [FCM] Error registering token:", error);
    return false;
  }
}

/**
 * Unregister FCM token for a user's device
 */
export async function unregisterFCMToken(
  userId: string,
  deviceId: string
): Promise<boolean> {
  const db = admin.firestore();

  try {
    const tokenRef = db
      .collection("users")
      .doc(userId)
      .collection("fcmTokens")
      .doc(deviceId);

    const doc = await tokenRef.get();
    if (doc.exists) {
      await tokenRef.delete();
      console.log(
        `✅ [FCM] Token unregistered for user: ${userId}, device: ${deviceId}`
      );
      return true;
    } else {
      console.log(
        `ℹ️ [FCM] No token found for user: ${userId}, device: ${deviceId}`
      );
      return true; // Still return true as the end state is as expected
    }
  } catch (error) {
    console.error("❌ [FCM] Error unregistering token:", error);
    return false;
  }
}

/**
 * Unregister all FCM tokens for a user (on account deletion or full logout)
 */
export async function unregisterAllFCMTokens(userId: string): Promise<boolean> {
  const db = admin.firestore();

  try {
    const tokensSnapshot = await db
      .collection("users")
      .doc(userId)
      .collection("fcmTokens")
      .get();

    if (tokensSnapshot.empty) {
      console.log(`ℹ️ [FCM] No tokens to unregister for user: ${userId}`);
      return true;
    }

    const batch = db.batch();
    tokensSnapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    console.log(
      `✅ [FCM] All tokens (${tokensSnapshot.size}) unregistered for user: ${userId}`
    );
    return true;
  } catch (error) {
    console.error("❌ [FCM] Error unregistering all tokens:", error);
    return false;
  }
}

/**
 * Helper to create notification and send push in one call
 * Used by likePost, followUser, createComment, etc.
 */
export async function createNotificationAndPush(
  notificationData: Omit<Notification, "id" | "createdAt">
): Promise<string | null> {
  const db = admin.firestore();

  try {
    // Create notification document
    const notificationRef = db.collection("notifications").doc();
    await notificationRef.set({
      id: notificationRef.id,
      ...notificationData,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`📝 [FCM] Notification created: ${notificationRef.id}`);

    // Send push notification
    await sendPushNotification({
      userId: notificationData.userId,
      type: notificationData.type,
      title: notificationData.title,
      body: notificationData.body,
      data: {
        notificationId: notificationRef.id,
        postId: notificationData.relatedPostId,
        voteId: notificationData.relatedVoteId,
        commentId: notificationData.relatedCommentId,
        userId: notificationData.actionUserId,
      },
    });

    return notificationRef.id;
  } catch (error) {
    console.error("❌ [FCM] Error creating notification and push:", error);
    return null;
  }
}
