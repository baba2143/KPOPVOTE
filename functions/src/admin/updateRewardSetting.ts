/**
 * Update reward setting
 * 報酬設定更新（管理者専用）
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";

interface UpdateRewardSettingRequest {
  actionType: string; // ドキュメントID
  basePoints?: number;
  description?: string;
  isActive?: boolean;
}

interface UpdateRewardSettingResponse {
  actionType: string;
  basePoints: number;
  description: string;
  isActive: boolean;
  updatedAt: Date;
}

export const updateRewardSetting = functions
  .runWith(ADMIN_CONFIG)
  .https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "PATCH");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "PATCH") {
      res.status(405).json({ success: false, error: "Method not allowed. Use PATCH." } as ApiResponse<null>);
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
      const { actionType, basePoints, description, isActive } = req.body as UpdateRewardSettingRequest;

      // バリデーション
      if (!actionType) {
        res.status(400).json({ success: false, error: "actionType is required" } as ApiResponse<null>);
        return;
      }

      if (basePoints !== undefined && (typeof basePoints !== "number" || basePoints < 0)) {
        res.status(400).json({
          success: false, error: "basePoints must be a non-negative number",
        } as ApiResponse<null>);
        return;
      }

      if (isActive !== undefined && typeof isActive !== "boolean") {
        res.status(400).json({ success: false, error: "isActive must be a boolean" } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();
      const settingRef = db.collection("rewardSettings").doc(actionType);
      const settingDoc = await settingRef.get();

      if (!settingDoc.exists) {
        res.status(404).json({ success: false, error: `Reward setting not found: ${actionType}` } as ApiResponse<null>);
        return;
      }

      // 更新データ作成
      const updateData: {
      basePoints?: number;
      description?: string;
      isActive?: boolean;
      updatedAt: admin.firestore.FieldValue;
    } = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

      if (basePoints !== undefined) {
        updateData.basePoints = basePoints;
      }

      if (description !== undefined) {
        updateData.description = description;
      }

      if (isActive !== undefined) {
        updateData.isActive = isActive;
      }

      // 更新実行
      await settingRef.update(updateData);

      // 更新後のデータ取得
      const updatedDoc = await settingRef.get();
      const updatedData = updatedDoc.data()!;

      console.log(`✅ [updateRewardSetting] Updated: ${actionType}`, updateData);

      res.status(200).json({
        success: true,
        data: {
          actionType: updatedDoc.id,
          basePoints: updatedData.basePoints,
          description: updatedData.description,
          isActive: updatedData.isActive,
          updatedAt: updatedData.updatedAt?.toDate() || new Date(),
        },
      } as ApiResponse<UpdateRewardSettingResponse>);
    } catch (error: unknown) {
      console.error("❌ [updateRewardSetting] Error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
