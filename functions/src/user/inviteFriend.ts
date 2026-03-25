/**
 * Friend invite endpoints
 * 新報酬設計: 友達招待報酬（招待された人が登録完了時に50P付与）
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { applyRateLimit, GENERAL_RATE_LIMIT } from "../middleware/rateLimit";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";
import { grantRewardPoints } from "../utils/rewardHelper";
import * as crypto from "crypto";

interface GenerateInviteCodeResponse {
  inviteCode: string;
  inviteLink: string;
}

interface ApplyInviteCodeRequest {
  inviteCode: string;
}

interface ApplyInviteCodeResponse {
  success: boolean;
  inviterDisplayName?: string;
}

/**
 * Generate or get user's invite code
 * 招待コード生成（またはすでにある場合は取得）
 */
export const generateInviteCode = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "POST" && req.method !== "GET") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use POST or GET.",
      } as ApiResponse<null>);
      return;
    }

    await new Promise<void>((resolve, reject) => {
      verifyToken(req as AuthenticatedRequest, res, (error?: unknown) =>
        error ? reject(error) : resolve()
      );
    });

    const currentUser = (req as AuthenticatedRequest).user;
    if (!currentUser) {
      res.status(401).json({
        success: false,
        error: "Unauthorized",
      } as ApiResponse<null>);
      return;
    }

    try {
      const db = admin.firestore();
      const userRef = db.collection("users").doc(currentUser.uid);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        res.status(404).json({
          success: false,
          error: "User not found",
        } as ApiResponse<null>);
        return;
      }

      const userData = userDoc.data();
      let inviteCode = userData?.inviteCode;

      // 招待コードがない場合は生成
      if (!inviteCode) {
        // 8文字のユニークなコードを生成
        inviteCode = generateUniqueCode(8);

        // 重複チェック（稀だが念のため）
        const existingCode = await db
          .collection("users")
          .where("inviteCode", "==", inviteCode)
          .get();

        if (!existingCode.empty) {
          // 重複があれば再生成
          inviteCode = generateUniqueCode(10);
        }

        await userRef.update({
          inviteCode,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ [generateInviteCode] Generated invite code: ${inviteCode} for user ${currentUser.uid}`);
      }

      // Universal Links形式の招待リンク（アプリで処理）
      const inviteLink = `https://kpopvote-9de2b.web.app/invite/${inviteCode}`;

      res.status(200).json({
        success: true,
        data: {
          inviteCode,
          inviteLink,
        } as GenerateInviteCodeResponse,
      } as ApiResponse<GenerateInviteCodeResponse>);
    } catch (error: unknown) {
      console.error("❌ [generateInviteCode] Error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });

/**
 * Apply invite code (called when invited user completes registration)
 * 招待コード適用（招待された人が登録完了時に呼び出し）
 */
export const applyInviteCode = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "POST") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      } as ApiResponse<null>);
      return;
    }

    await new Promise<void>((resolve, reject) => {
      verifyToken(req as AuthenticatedRequest, res, (error?: unknown) =>
        error ? reject(error) : resolve()
      );
    });

    const currentUser = (req as AuthenticatedRequest).user;
    if (!currentUser) {
      res.status(401).json({
        success: false,
        error: "Unauthorized",
      } as ApiResponse<null>);
      return;
    }

    // Apply rate limiting
    if (applyRateLimit(currentUser.uid, res, GENERAL_RATE_LIMIT)) {
      return; // Rate limited, response already sent
    }

    try {
      const { inviteCode } = req.body as ApplyInviteCodeRequest;

      // Validation
      if (!inviteCode) {
        res.status(400).json({
          success: false,
          error: "inviteCode is required",
        } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();

      // 現在のユーザーがすでに招待コードを使用済みかチェック
      const currentUserDoc = await db.collection("users").doc(currentUser.uid).get();
      const currentUserData = currentUserDoc.data();

      if (currentUserData?.invitedBy) {
        res.status(400).json({
          success: false,
          error: "You have already used an invite code",
        } as ApiResponse<null>);
        return;
      }

      // 招待コードを持つユーザーを検索
      const inviterQuery = await db
        .collection("users")
        .where("inviteCode", "==", inviteCode.toUpperCase())
        .limit(1)
        .get();

      if (inviterQuery.empty) {
        res.status(404).json({
          success: false,
          error: "Invalid invite code",
        } as ApiResponse<null>);
        return;
      }

      const inviterDoc = inviterQuery.docs[0];
      const inviterId = inviterDoc.id;
      const inviterData = inviterDoc.data();

      // 自分自身のコードは使用不可
      if (inviterId === currentUser.uid) {
        res.status(400).json({
          success: false,
          error: "Cannot use your own invite code",
        } as ApiResponse<null>);
        return;
      }

      // 招待記録を作成
      const inviteRecordRef = db.collection("inviteRecords").doc();
      await inviteRecordRef.set({
        id: inviteRecordRef.id,
        inviterId,
        inviteeId: currentUser.uid,
        inviteCode,
        rewardGranted: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 招待された側のユーザー情報を更新
      await db.collection("users").doc(currentUser.uid).update({
        invitedBy: inviterId,
        inviteCodeUsed: inviteCode,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 招待者のinviteCount増加
      await db.collection("users").doc(inviterId).update({
        inviteCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 招待者にポイント付与（単一ポイント制）
      const pointsGranted = await grantRewardPoints(
        inviterId,
        "friend_invite",
        currentUser.uid
      );

      // 招待記録を更新
      await inviteRecordRef.update({
        rewardGranted: true,
        pointsGranted,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `✅ [applyInviteCode] Invite applied: inviter=${inviterId}, invitee=${currentUser.uid}, points=${pointsGranted}`
      );

      res.status(200).json({
        success: true,
        data: {
          success: true,
          inviterDisplayName: inviterData?.displayName || undefined,
        } as ApplyInviteCodeResponse,
      } as ApiResponse<ApplyInviteCodeResponse>);
    } catch (error: unknown) {
      console.error("❌ [applyInviteCode] Error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });

/**
 * ユニークなコードを生成
 */
function generateUniqueCode(length: number): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // 紛らわしい文字を除外
  const bytes = crypto.randomBytes(length);
  let code = "";
  for (let i = 0; i < length; i++) {
    code += chars[bytes[i] % chars.length];
  }
  return code;
}
