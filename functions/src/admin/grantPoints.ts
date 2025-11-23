/**
 * Grant points to user
 * マルチポイント対応版
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { PointGrantRequest, ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const grantPoints = functions.https.onRequest(async (req, res) => {
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

  await new Promise<void>((resolve, reject) => {
    verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  try {
    const requestBody = req.body as PointGrantRequest;
    const { uid, points, pointType, reason } = requestBody;

    // バリデーション
    if (!uid || typeof points !== "number" || !reason) {
      res.status(400).json({ success: false, error: "uid, points, and reason are required" } as ApiResponse<null>);
      return;
    }

    if (points === 0) {
      res.status(400).json({ success: false, error: "points must be non-zero" } as ApiResponse<null>);
      return;
    }

    if (!["premium", "regular"].includes(pointType)) {
      res.status(400).json({ success: false, error: "pointType must be 'premium' or 'regular'" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
      return;
    }

    const userData = userDoc.data()!;

    // ポイントフィールドの初期化（存在しない場合）
    if (userData.premiumPoints === undefined || userData.regularPoints === undefined) {
      await userRef.update({
        premiumPoints: 0,
        regularPoints: userData.points || 0, // 既存のpointsを青ポイントに移行
      });
    }

    // ポイントフィールド名決定
    const pointFieldName = pointType === "premium" ? "premiumPoints" : "regularPoints";

    // ポイント更新
    await userRef.update({
      [pointFieldName]: admin.firestore.FieldValue.increment(points),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // トランザクション記録
    await db.collection("pointTransactions").add({
      userId: uid,
      pointType, // 🆕 ポイントタイプ記録
      points,
      type: points > 0 ? "grant" : "deduct",
      reason,
      grantedBy: (req as AuthenticatedRequest).user?.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 更新後のポイント取得
    const updatedDoc = await userRef.get();
    const updatedData = updatedDoc.data()!;
    const currentPremiumPoints = updatedData.premiumPoints || 0;
    const currentRegularPoints = updatedData.regularPoints || 0;

    console.log(
      `✅ [grantPoints] Granted ${points}P (${pointType}) to ${uid}: ` +
        `premium=${currentPremiumPoints}, regular=${currentRegularPoints}`,
    );

    res.status(200).json({
      success: true,
      data: {
        uid,
        pointsGranted: points,
        pointType,
        currentPremiumPoints,
        currentRegularPoints,
        reason,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Grant points error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
