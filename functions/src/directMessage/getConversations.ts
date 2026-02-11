/**
 * Get Conversations
 * 会話一覧を取得
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { STANDARD_CONFIG } from "../utils/functionConfig";

interface ConversationResponse {
  id: string;
  participantId: string;
  participantName: string | null;
  participantPhotoURL: string | null;
  lastMessage: string | null;
  lastMessageAt: string | null;
  unreadCount: number;
  updatedAt: string;
}

interface GetConversationsResponse {
  conversations: ConversationResponse[];
  hasMore: boolean;
  totalUnreadCount: number;
}

export const getConversations = functions
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
      const limit = parseInt(req.query.limit as string) || 20;
      const lastConversationId = req.query.lastConversationId as string | undefined;

      const db = admin.firestore();

      // 自分が参加している会話を取得（participant1またはparticipant2として）
      // Firestoreの制限により、2つのクエリを実行してマージする必要がある
      let query1 = db
        .collection("conversations")
        .where("participant1Id", "==", currentUser.uid)
        .orderBy("updatedAt", "desc")
        .limit(limit + 1);

      let query2 = db
        .collection("conversations")
        .where("participant2Id", "==", currentUser.uid)
        .orderBy("updatedAt", "desc")
        .limit(limit + 1);

      // ページネーション処理
      if (lastConversationId) {
        const lastDoc = await db.collection("conversations").doc(lastConversationId).get();
        if (lastDoc.exists) {
          query1 = query1.startAfter(lastDoc);
          query2 = query2.startAfter(lastDoc);
        }
      }

      const [snapshot1, snapshot2] = await Promise.all([query1.get(), query2.get()]);

      // 両方の結果をマージしてソート
      const allDocs = [...snapshot1.docs, ...snapshot2.docs];

      // 重複を除去（同じIDの会話が両方に含まれる可能性は低いが念のため）
      const uniqueDocs = Array.from(
        new Map(allDocs.map((doc) => [doc.id, doc])).values()
      );

      // updatedAtでソート
      uniqueDocs.sort((a, b) => {
        const aTime = a.data().updatedAt?.toDate?.()?.getTime() || 0;
        const bTime = b.data().updatedAt?.toDate?.()?.getTime() || 0;
        return bTime - aTime;
      });

      // limitを適用
      const hasMore = uniqueDocs.length > limit;
      const docs = uniqueDocs.slice(0, limit);

      let totalUnreadCount = 0;
      const conversations: ConversationResponse[] = docs.map((doc) => {
        const data = doc.data();
        const isParticipant1 = data.participant1Id === currentUser.uid;

        // 相手の情報を取得
        const participantId = isParticipant1 ? data.participant2Id : data.participant1Id;
        const participantName = isParticipant1 ? data.participant2Name : data.participant1Name;
        const participantPhotoURL = isParticipant1 ? data.participant2PhotoURL : data.participant1PhotoURL;

        // 自分の未読数を取得
        const unreadCount = isParticipant1 ? (data.unreadCount1 || 0) : (data.unreadCount2 || 0);
        totalUnreadCount += unreadCount;

        return {
          id: doc.id,
          participantId,
          participantName: participantName || null,
          participantPhotoURL: participantPhotoURL || null,
          lastMessage: data.lastMessage || null,
          lastMessageAt: data.lastMessageAt?.toDate?.()?.toISOString() || null,
          unreadCount,
          updatedAt: data.updatedAt?.toDate?.()?.toISOString() || new Date().toISOString(),
        };
      });

      res.status(200).json({
        success: true,
        data: {
          conversations,
          hasMore,
          totalUnreadCount,
        } as GetConversationsResponse,
      } as ApiResponse<GetConversationsResponse>);
    } catch (error: unknown) {
      console.error("Get conversations error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
