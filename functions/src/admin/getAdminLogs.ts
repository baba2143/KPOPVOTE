/**
 * Get admin action logs
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const getAdminLogs = functions.https.onRequest(async (req, res) => {
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

    const adminActions = await Promise.all(
      adminActionsSnapshot.docs.map(async (doc) => {
        const data = doc.data();

        // Get target user email
        let targetUserEmail = "Unknown";
        try {
          const targetUserDoc = await db.collection("users").doc(data.targetUserId).get();
          if (targetUserDoc.exists) {
            targetUserEmail = targetUserDoc.data()!.email || "Unknown";
          }
        } catch (error) {
          console.error("Error fetching target user:", error);
        }

        // Get performer email
        let performerEmail = "System";
        if (data.performedBy) {
          try {
            const performerDoc = await db.collection("users").doc(data.performedBy).get();
            if (performerDoc.exists) {
              performerEmail = performerDoc.data()!.email || "Unknown";
            }
          } catch (error) {
            console.error("Error fetching performer:", error);
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
      })
    );

    // Get point transactions
    const pointTransactionsSnapshot = await db
      .collection("pointTransactions")
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();

    const pointTransactions = await Promise.all(
      pointTransactionsSnapshot.docs.map(async (doc) => {
        const data = doc.data();

        // Get target user email
        let targetUserEmail = "Unknown";
        try {
          const targetUserDoc = await db.collection("users").doc(data.userId).get();
          if (targetUserDoc.exists) {
            targetUserEmail = targetUserDoc.data()!.email || "Unknown";
          }
        } catch (error) {
          console.error("Error fetching target user:", error);
        }

        // Get granter email
        let granterEmail = "System";
        if (data.grantedBy) {
          try {
            const granterDoc = await db.collection("users").doc(data.grantedBy).get();
            if (granterDoc.exists) {
              granterEmail = granterDoc.data()!.email || "Unknown";
            }
          } catch (error) {
            console.error("Error fetching granter:", error);
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
      })
    );

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

    res.status(200).json({
      success: true,
      data: { logs: limitedLogs },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Get admin logs error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
