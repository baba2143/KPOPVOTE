/**
 * Mark notification as read
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";

export const markNotificationAsRead = functions.https.onRequest(async (req, res) => {
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
    const { notificationId, markAll } = req.body;

    const db = admin.firestore();

    if (markAll === true) {
      // Mark all notifications as read
      const notificationsSnapshot = await db.collection("notifications")
        .where("userId", "==", currentUser.uid)
        .where("isRead", "==", false)
        .get();

      const batch = db.batch();
      notificationsSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          isRead: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();

      res.status(200).json({
        success: true,
        data: {
          message: "All notifications marked as read",
          count: notificationsSnapshot.size,
        },
      } as ApiResponse<unknown>);
    } else {
      // Mark single notification as read
      if (!notificationId) {
        res.status(400).json({ success: false, error: "notificationId is required" } as ApiResponse<null>);
        return;
      }

      const notificationRef = db.collection("notifications").doc(notificationId);
      const notificationDoc = await notificationRef.get();

      if (!notificationDoc.exists) {
        res.status(404).json({ success: false, error: "Notification not found" } as ApiResponse<null>);
        return;
      }

      const notificationData = notificationDoc.data()!;

      // Authorization: Only owner can mark as read
      if (notificationData.userId !== currentUser.uid) {
        res.status(403).json({
          success: false,
          error: "Forbidden: You can only mark your own notifications as read",
        } as ApiResponse<null>);
        return;
      }

      await notificationRef.update({
        isRead: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.status(200).json({
        success: true,
        data: {
          message: "Notification marked as read",
          notificationId,
        },
      } as ApiResponse<unknown>);
    }
  } catch (error: unknown) {
    console.error("Mark notification as read error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
