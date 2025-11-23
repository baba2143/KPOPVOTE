/**
 * Get all reward settings
 * 報酬設定一覧取得（管理者専用）
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export interface RewardSetting {
  id: string;
  actionType: string;
  basePoints: number;
  description: string;
  isActive: boolean;
  updatedAt: Date;
}

export const getRewardSettings = functions.https.onRequest(async (req, res) => {
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
    const db = admin.firestore();
    const snapshot = await db.collection("rewardSettings").get();

    if (snapshot.empty) {
      // rewardSettingsが未作成の場合、空配列を返す
      res.status(200).json({
        success: true,
        data: [],
      } as ApiResponse<RewardSetting[]>);
      return;
    }

    const settings: RewardSetting[] = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      settings.push({
        id: doc.id,
        actionType: data.actionType,
        basePoints: data.basePoints,
        description: data.description,
        isActive: data.isActive,
        updatedAt: data.updatedAt?.toDate() || new Date(),
      });
    });

    console.log(`✅ [getRewardSettings] Retrieved ${settings.length} settings`);

    res.status(200).json({
      success: true,
      data: settings,
    } as ApiResponse<RewardSetting[]>);
  } catch (error: unknown) {
    console.error("❌ [getRewardSettings] Error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
