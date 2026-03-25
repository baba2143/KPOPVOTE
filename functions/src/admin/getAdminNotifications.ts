/**
 * Get Admin Notifications API
 * Retrieves notification history for the admin panel
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse, AdminNotification } from "../types";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

const db = admin.firestore();

interface AdminNotificationResponse {
  id: string;
  title: string;
  body: string;
  targetType: string;
  targetId?: string;
  targetName?: string;
  deepLinkUrl?: string;
  status: string;
  scheduledAt?: string;
  sentAt?: string;
  sentCount?: number;
  failedCount?: number;
  createdBy: string;
  createdAt: string;
}

export const getAdminNotifications = functions
  .runWith(ADMIN_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS
    if (handleCors(req, res)) return;

    // Only accept GET requests
    if (req.method !== "GET") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use GET.",
      } as ApiResponse<null>);
      return;
    }

    try {
      // Verify admin authentication
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
      const adminUid = decodedToken.uid;

      // Verify admin privileges
      const userRecord = await admin.auth().getUser(adminUid);
      if (!userRecord.customClaims?.admin) {
        res.status(403).json({
          success: false,
          error: "Forbidden: Admin privileges required",
        } as ApiResponse<null>);
        return;
      }

      // Parse query parameters
      const limit = parseInt(req.query.limit as string) || 50;
      const status = req.query.status as string; // "pending" | "sent" | "cancelled" | "failed"
      const lastNotificationId = req.query.lastNotificationId as string;

      // Build query
      let query: admin.firestore.Query = db
        .collection("adminNotifications")
        .orderBy("createdAt", "desc")
        .limit(limit + 1); // +1 to check if there are more

      if (status) {
        query = query.where("status", "==", status);
      }

      // Pagination
      if (lastNotificationId) {
        const lastDoc = await db
          .collection("adminNotifications")
          .doc(lastNotificationId)
          .get();
        if (lastDoc.exists) {
          query = query.startAfter(lastDoc);
        }
      }

      const snapshot = await query.get();

      // Check if there are more results
      const hasMore = snapshot.docs.length > limit;
      const docs = hasMore ? snapshot.docs.slice(0, limit) : snapshot.docs;

      // Format response
      const notifications: AdminNotificationResponse[] = docs.map((doc) => {
        const data = doc.data() as AdminNotification;
        return {
          id: data.id,
          title: data.title,
          body: data.body,
          targetType: data.targetType,
          targetId: data.targetId,
          targetName: data.targetName,
          deepLinkUrl: data.deepLinkUrl,
          status: data.status,
          scheduledAt: data.scheduledAt ?
            (data.scheduledAt as unknown as admin.firestore.Timestamp).toDate().toISOString() :
            undefined,
          sentAt: data.sentAt ?
            (data.sentAt as unknown as admin.firestore.Timestamp).toDate().toISOString() :
            undefined,
          sentCount: data.sentCount,
          failedCount: data.failedCount,
          createdBy: data.createdBy,
          createdAt: (data.createdAt as unknown as admin.firestore.Timestamp).toDate().toISOString(),
        };
      });

      res.status(200).json({
        success: true,
        data: {
          notifications,
          hasMore,
        },
      } as ApiResponse<{
        notifications: AdminNotificationResponse[];
        hasMore: boolean;
      }>);
    } catch (error) {
      console.error("❌ [GetAdminNotifications] Error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
