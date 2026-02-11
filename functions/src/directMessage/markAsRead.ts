/**
 * Mark Messages As Read
 * 会話のメッセージを既読にする
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { STANDARD_CONFIG } from "../utils/functionConfig";

interface MarkAsReadRequest {
  conversationId: string;
}

interface MarkAsReadResponse {
  success: boolean;
  unreadCount: number;
}

export const markAsRead = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
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
      const { conversationId } = req.body as MarkAsReadRequest;

      if (!conversationId) {
        res.status(400).json({ success: false, error: "conversationId is required" } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();

      // 会話の存在確認と参加者確認
      const conversationRef = db.collection("conversations").doc(conversationId);
      const conversationDoc = await conversationRef.get();

      if (!conversationDoc.exists) {
        res.status(404).json({ success: false, error: "Conversation not found" } as ApiResponse<null>);
        return;
      }

      const conversationData = conversationDoc.data();
      if (
        conversationData?.participant1Id !== currentUser.uid &&
      conversationData?.participant2Id !== currentUser.uid
      ) {
        const errorMsg = "Not authorized to access this conversation";
        res.status(403).json({ success: false, error: errorMsg } as ApiResponse<null>);
        return;
      }

      // 自分がparticipant1かparticipant2かを判定
      const isParticipant1 = conversationData?.participant1Id === currentUser.uid;

      // 未読メッセージを既読に更新（相手から送られたメッセージのみ）
      const messagesRef = conversationRef.collection("messages");
      const unreadMessages = await messagesRef
        .where("senderId", "!=", currentUser.uid)
        .where("isRead", "==", false)
        .get();

      // バッチで更新
      const batch = db.batch();
      unreadMessages.docs.forEach((doc) => {
        batch.update(doc.ref, { isRead: true });
      });

      // 会話の未読カウントをリセット
      if (isParticipant1) {
        batch.update(conversationRef, {
          unreadCount1: 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(conversationRef, {
          unreadCount2: 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      res.status(200).json({
        success: true,
        data: {
          success: true,
          unreadCount: 0,
        } as MarkAsReadResponse,
      } as ApiResponse<MarkAsReadResponse>);
    } catch (error: unknown) {
      console.error("Mark as read error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
