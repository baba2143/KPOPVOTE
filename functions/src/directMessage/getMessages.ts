/**
 * Get Messages
 * 会話のメッセージ一覧を取得
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { STANDARD_CONFIG } from "../utils/functionConfig";

interface MessageResponse {
  id: string;
  conversationId: string;
  senderId: string;
  senderName: string | null;
  senderPhotoURL: string | null;
  text: string | null;
  imageURL: string | null;
  isRead: boolean;
  createdAt: string;
}

interface GetMessagesResponse {
  messages: MessageResponse[];
  hasMore: boolean;
}

export const getMessages = functions
  .runWith(STANDARD_CONFIG)
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

    await new Promise<void>((resolve, reject) => {
      verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
    });

    const currentUser = (req as AuthenticatedRequest).user;
    if (!currentUser) {
      res.status(401).json({ success: false, error: "Unauthorized" } as ApiResponse<null>);
      return;
    }

    try {
      const conversationId = req.query.conversationId as string;
      const limit = parseInt(req.query.limit as string) || 30;
      const lastMessageId = req.query.lastMessageId as string | undefined;

      if (!conversationId) {
        res.status(400).json({ success: false, error: "conversationId is required" } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();

      // 会話の存在確認と参加者確認
      const conversationDoc = await db.collection("conversations").doc(conversationId).get();
      if (!conversationDoc.exists) {
        res.status(404).json({ success: false, error: "Conversation not found" } as ApiResponse<null>);
        return;
      }

      const conversationData = conversationDoc.data();
      if (
        conversationData?.participant1Id !== currentUser.uid &&
      conversationData?.participant2Id !== currentUser.uid
      ) {
        res.status(403).json({
          success: false, error: "Not authorized to view this conversation",
        } as ApiResponse<null>);
        return;
      }

      // メッセージを取得（新しい順）
      let query = db
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .orderBy("createdAt", "desc")
        .limit(limit + 1);

      // ページネーション処理
      if (lastMessageId) {
        const lastDoc = await db
          .collection("conversations")
          .doc(conversationId)
          .collection("messages")
          .doc(lastMessageId)
          .get();

        if (lastDoc.exists) {
          query = query.startAfter(lastDoc);
        }
      }

      const snapshot = await query.get();
      const hasMore = snapshot.docs.length > limit;
      const docs = snapshot.docs.slice(0, limit);

      const messages: MessageResponse[] = docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          conversationId: data.conversationId,
          senderId: data.senderId,
          senderName: data.senderName || null,
          senderPhotoURL: data.senderPhotoURL || null,
          text: data.text || null,
          imageURL: data.imageURL || null,
          isRead: data.isRead || false,
          createdAt: data.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
        };
      });

      // メッセージを古い順に並べ替え（UIで表示しやすいように）
      messages.reverse();

      res.status(200).json({
        success: true,
        data: {
          messages,
          hasMore,
        } as GetMessagesResponse,
      } as ApiResponse<GetMessagesResponse>);
    } catch (error: unknown) {
      console.error("Get messages error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
