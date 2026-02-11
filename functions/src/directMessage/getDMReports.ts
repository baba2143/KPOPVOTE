/**
 * Get DM Reports
 * DM通報一覧を取得（管理者専用）
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";

interface DMReport {
  reportId: string;
  conversationId: string;
  messageId?: string;
  reporterId: string;
  reporteeId: string;
  reportType: "message" | "user";
  reason: string;
  messageContent?: string;
  status: "pending" | "reviewed" | "resolved";
  createdAt: string | null;
}

interface DMReportStats {
  totalReports: number;
  pendingReports: number;
  reviewedReports: number;
}

interface GetDMReportsResponse {
  reports: DMReport[];
  stats: DMReportStats;
  count: number;
}

export const getDMReports = functions
  .runWith(ADMIN_CONFIG)
  .https.onRequest(async (req, res) => {
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

    // 認証チェック
    await new Promise<void>((resolve, reject) => {
      verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
    });

    // 管理者チェック
    await new Promise<void>((resolve, reject) => {
      verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
    });

    try {
      const limit = parseInt(req.query.limit as string) || 50;
      const status = req.query.status as string | undefined;

      const db = admin.firestore();

      // クエリ構築
      let query = db
        .collection("dmReports")
        .orderBy("createdAt", "desc")
        .limit(limit);

      // ステータスフィルター（オプション）
      if (status && ["pending", "reviewed", "resolved"].includes(status)) {
        query = db
          .collection("dmReports")
          .where("status", "==", status)
          .orderBy("createdAt", "desc")
          .limit(limit);
      }

      const snapshot = await query.get();

      const reports: DMReport[] = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          reportId: doc.id,
          conversationId: data.conversationId || "",
          messageId: data.messageId || undefined,
          reporterId: data.reporterId || "",
          reporteeId: data.reporteeId || "",
          reportType: data.reportType || "user",
          reason: data.reason || "",
          messageContent: data.messageContent || undefined,
          status: data.status || "pending",
          createdAt: data.createdAt?.toDate?.()?.toISOString() || null,
        };
      });

      // 統計情報を取得
      const allReportsSnapshot = await db.collection("dmReports").get();
      let totalReports = 0;
      let pendingReports = 0;
      let reviewedReports = 0;

      allReportsSnapshot.docs.forEach((doc) => {
        const data = doc.data();
        totalReports++;
        if (data.status === "pending") pendingReports++;
        if (data.status === "reviewed" || data.status === "resolved") reviewedReports++;
      });

      const stats: DMReportStats = {
        totalReports,
        pendingReports,
        reviewedReports,
      };

      res.status(200).json({
        success: true,
        data: {
          reports,
          stats,
          count: reports.length,
        } as GetDMReportsResponse,
      } as ApiResponse<GetDMReportsResponse>);
    } catch (error: unknown) {
      console.error("Get DM reports error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
