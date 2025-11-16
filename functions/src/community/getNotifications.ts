/**
 * Get notifications list
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const getNotifications = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "GET") {
    res.status(405).json({ success: false, error: "Method not allowed. Use GET." } as ApiResponse<null>);
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
    const unreadOnly = req.query.unreadOnly === "true";
    const limit = parseInt(req.query.limit as string) || 20;
    const lastNotificationId = req.query.lastNotificationId as string | undefined;

    const db = admin.firestore();
    let query: admin.firestore.Query = db.collection("notifications")
      .where("userId", "==", currentUser.uid);

    // Filter by read status if unreadOnly
    if (unreadOnly) {
      query = query.where("isRead", "==", false);
    }

    query = query.orderBy("createdAt", "desc").limit(limit + 1);

    if (lastNotificationId) {
      const lastNotificationDoc = await db.collection("notifications").doc(lastNotificationId).get();
      if (lastNotificationDoc.exists) {
        query = query.startAfter(lastNotificationDoc);
      }
    }

    const snapshot = await query.get();
    const hasMore = snapshot.size > limit;
    const notifications = snapshot.docs.slice(0, limit);

    const notificationsData = notifications.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt?.toDate().toISOString() || null,
      };
    });

    // Get unread count
    const unreadCountSnapshot = await db.collection("notifications")
      .where("userId", "==", currentUser.uid)
      .where("isRead", "==", false)
      .get();

    res.status(200).json({
      success: true,
      data: {
        notifications: notificationsData,
        hasMore,
        unreadCount: unreadCountSnapshot.size,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Get notifications error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
