/**
 * Get admin action logs
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";
import { batchGetDocs } from "../utils/batchUtils";

export const getAdminLogs = functions
  .runWith(ADMIN_CONFIG)
  .https.onRequest(async (req, res) => {
    const startTime = Date.now();

    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "GET") {
      res.status(405).json({ success: false, error: "Method not allowed. Use GET." } as ApiResponse<null>);
      return;
    }

    await new Promise<void>((resolve, reject) => {
      verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
    });

    await new Promise<void>((resolve, reject) => {
      verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
    });

    try {
      const limitParam = req.query.limit as string | undefined;
      const limit = limitParam ? Math.min(parseInt(limitParam, 10), 100) : 50;

      const db = admin.firestore();

      // Get admin actions (suspend/restore)
      const adminActionsSnapshot = await db
        .collection("adminActions")
        .orderBy("performedAt", "desc")
        .limit(limit)
        .get();

      // Get point transactions
      const pointTransactionsSnapshot = await db
        .collection("pointTransactions")
        .orderBy("createdAt", "desc")
        .limit(limit)
        .get();

      // Step 1: Collect all user IDs from both collections
      const adminActionUserIds = adminActionsSnapshot.docs.flatMap((doc) => {
        const data = doc.data();
        return [data.targetUserId, data.performedBy].filter(Boolean);
      });
      const pointTxUserIds = pointTransactionsSnapshot.docs.flatMap((doc) => {
        const data = doc.data();
        return [data.userId, data.grantedBy].filter(Boolean);
      });
      const allUserIds = [...new Set([...adminActionUserIds, ...pointTxUserIds])];

      // Step 2: Batch fetch all users at once
      const userDocs = await batchGetDocs(db, "users", allUserIds);

      // Step 3: Map admin actions (no queries)
      const adminActions = adminActionsSnapshot.docs.map((doc) => {
        const data = doc.data();

        // Get target user email
        const targetUserDoc = userDocs.get(data.targetUserId);
        const targetUserEmail = targetUserDoc?.exists ?
          (targetUserDoc.data()?.email || "Unknown") :
          "Unknown";

        // Get performer email
        let performerEmail = "System";
        if (data.performedBy) {
          const performerDoc = userDocs.get(data.performedBy);
          if (performerDoc?.exists) {
            performerEmail = performerDoc.data()?.email || "Unknown";
          }
        }

        return {
          id: doc.id,
          type: "admin_action",
          actionType: data.actionType,
          targetUserId: data.targetUserId,
          targetUserEmail,
          reason: data.reason || null,
          suspendedUntil: data.suspendedUntil || null,
          performedBy: data.performedBy || null,
          performerEmail,
          performedAt: data.performedAt?.toDate?.()?.toISOString() || null,
        };
      });

      // Step 4: Map point transactions (no queries)
      const pointTransactions = pointTransactionsSnapshot.docs.map((doc) => {
        const data = doc.data();

        // Get target user email
        const targetUserDoc = userDocs.get(data.userId);
        const targetUserEmail = targetUserDoc?.exists ?
          (targetUserDoc.data()?.email || "Unknown") :
          "Unknown";

        // Get granter email
        let granterEmail = "System";
        if (data.grantedBy) {
          const granterDoc = userDocs.get(data.grantedBy);
          if (granterDoc?.exists) {
            granterEmail = granterDoc.data()?.email || "Unknown";
          }
        }

        return {
          id: doc.id,
          type: "point_transaction",
          userId: data.userId,
          targetUserEmail,
          points: data.points,
          transactionType: data.type,
          reason: data.reason,
          grantedBy: data.grantedBy || null,
          granterEmail,
          createdAt: data.createdAt?.toDate?.()?.toISOString() || null,
        };
      });

      // Combine and sort by date
      const allLogs = [...adminActions, ...pointTransactions].sort((a, b) => {
        const dateA = a.type === "admin_action" ?
          (a as typeof adminActions[0]).performedAt :
          (a as typeof pointTransactions[0]).createdAt;
        const dateB = b.type === "admin_action" ?
          (b as typeof adminActions[0]).performedAt :
          (b as typeof pointTransactions[0]).createdAt;
        if (!dateA || !dateB) return 0;
        return new Date(dateB).getTime() - new Date(dateA).getTime();
      });

      // Limit to requested count
      const limitedLogs = allLogs.slice(0, limit);

      const duration = Date.now() - startTime;
      functions.logger.info("[PERF] getAdminLogs completed", {
        duration: `${duration}ms`,
        itemCount: limitedLogs.length,
      });

      res.status(200).json({
        success: true,
        data: { logs: limitedLogs },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("Get admin logs error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
