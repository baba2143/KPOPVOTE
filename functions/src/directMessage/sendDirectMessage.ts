/**
 * Send Direct Message
 * 相互フォローのユーザー間のみDM送信可能
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { sendPushNotification } from "../utils/fcmHelper";
import { shouldSendNotificationCached } from "../utils/notificationHelper";
import { STANDARD_CONFIG } from "../utils/functionConfig";

interface SendMessageRequest {
  recipientId: string;
  text?: string;
  imageURL?: string;
}

interface SendMessageResponse {
  messageId: string;
  conversationId: string;
  createdAt: string;
}

/**
 * 会話IDを生成（常に同じ順序でソート）
 * @param {string} userId1 - ユーザーID 1
 * @param {string} userId2 - ユーザーID 2
 * @returns {string} 生成された会話ID
 */
function generateConversationId(userId1: string, userId2: string): string {
  const sorted = [userId1, userId2].sort();
  return `${sorted[0]}_${sorted[1]}`;
}

/**
 * 相互フォローを確認
 * @param {admin.firestore.Firestore} db - Firestore instance
 * @param {string} userId1 - ユーザーID 1
 * @param {string} userId2 - ユーザーID 2
 * @returns {Promise<boolean>} 相互フォローかどうか
 */
async function checkMutualFollow(
  db: admin.firestore.Firestore,
  userId1: string,
  userId2: string
): Promise<boolean> {
  const follow1Id = `${userId1}_${userId2}`;
  const follow2Id = `${userId2}_${userId1}`;

  const [follow1, follow2] = await Promise.all([
    db.collection("follows").doc(follow1Id).get(),
    db.collection("follows").doc(follow2Id).get(),
  ]);

  return follow1.exists && follow2.exists;
}

export const sendDirectMessage = functions
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
      const { recipientId, text, imageURL } = req.body as SendMessageRequest;

      // Validation
      if (!recipientId) {
        res.status(400).json({ success: false, error: "recipientId is required" } as ApiResponse<null>);
        return;
      }

      if (!text && !imageURL) {
        res.status(400).json({ success: false, error: "text or imageURL is required" } as ApiResponse<null>);
        return;
      }

      if (recipientId === currentUser.uid) {
        res.status(400).json({ success: false, error: "Cannot send message to yourself" } as ApiResponse<null>);
        return;
      }

      const db = admin.firestore();

      // 相手ユーザーの存在確認
      const recipientDoc = await db.collection("users").doc(recipientId).get();
      if (!recipientDoc.exists) {
        res.status(404).json({ success: false, error: "Recipient not found" } as ApiResponse<null>);
        return;
      }

      // 相互フォロー確認
      const isMutualFollow = await checkMutualFollow(db, currentUser.uid, recipientId);
      if (!isMutualFollow) {
        res.status(403).json({ success: false, error: "Mutual follow required to send DM" } as ApiResponse<null>);
        return;
      }

      const conversationId = generateConversationId(currentUser.uid, recipientId);
      const conversationRef = db.collection("conversations").doc(conversationId);
      const messageRef = conversationRef.collection("messages").doc();

      // 送信者情報を取得
      const senderDoc = await db.collection("users").doc(currentUser.uid).get();
      const senderData = senderDoc.data();

      const now = admin.firestore.FieldValue.serverTimestamp();
      const nowDate = new Date();

      // メッセージデータ
      const messageData = {
        id: messageRef.id,
        conversationId: conversationId,
        senderId: currentUser.uid,
        senderName: senderData?.displayName || null,
        senderPhotoURL: senderData?.photoURL || null,
        text: text || null,
        imageURL: imageURL || null,
        isRead: false,
        createdAt: now,
      };

      // 会話ドキュメントを作成/更新
      const conversationDoc = await conversationRef.get();
      const lastMessageText = text || (imageURL ? "[画像]" : "");

      // 自分が participant1 か participant2 かを判定
      const sortedIds = [currentUser.uid, recipientId].sort();
      const isParticipant1 = currentUser.uid === sortedIds[0];

      if (conversationDoc.exists) {
      // 既存の会話を更新
        const updateData: Record<string, unknown> = {
          lastMessage: lastMessageText,
          lastMessageAt: now,
          updatedAt: now,
        };

        // 相手の未読カウントを増やす
        if (isParticipant1) {
          updateData.unreadCount2 = admin.firestore.FieldValue.increment(1);
        } else {
          updateData.unreadCount1 = admin.firestore.FieldValue.increment(1);
        }

        await conversationRef.update(updateData);
      } else {
      // 新規会話を作成
        const recipientData = recipientDoc.data();
        const conversationData = {
          id: conversationId,
          participant1Id: sortedIds[0],
          participant2Id: sortedIds[1],
          participant1Name: sortedIds[0] === currentUser.uid ? senderData?.displayName : recipientData?.displayName,
          participant1PhotoURL: sortedIds[0] === currentUser.uid ? senderData?.photoURL : recipientData?.photoURL,
          participant2Name: sortedIds[1] === currentUser.uid ? senderData?.displayName : recipientData?.displayName,
          participant2PhotoURL: sortedIds[1] === currentUser.uid ? senderData?.photoURL : recipientData?.photoURL,
          lastMessage: lastMessageText,
          lastMessageAt: now,
          unreadCount1: isParticipant1 ? 0 : 1,
          unreadCount2: isParticipant1 ? 1 : 0,
          createdAt: now,
          updatedAt: now,
        };

        await conversationRef.set(conversationData);
      }

      // メッセージを保存
      await messageRef.set(messageData);

      // Check notification settings
      const shouldNotify = await shouldSendNotificationCached(recipientId, "directMessages");

      if (shouldNotify) {
      // プッシュ通知を送信
        const notificationTitle = senderData?.displayName || "新しいメッセージ";
        const notificationBody = text || "画像を送信しました";

        await sendPushNotification({
          userId: recipientId,
          type: "dm",
          title: notificationTitle,
          body: notificationBody,
          data: {
            conversationId: conversationId,
            messageId: messageRef.id,
            senderId: currentUser.uid,
          },
        });

        // 通知レコードを作成
        const notificationRef = db.collection("notifications").doc();
        await notificationRef.set({
          id: notificationRef.id,
          userId: recipientId,
          type: "dm",
          title: notificationTitle,
          body: notificationBody,
          isRead: false,
          actionUserId: currentUser.uid,
          actionUserDisplayName: senderData?.displayName || null,
          actionUserPhotoURL: senderData?.photoURL || null,
          relatedConversationId: conversationId,
          createdAt: now,
        });
      } else {
        console.log(`[sendDirectMessage] Notification skipped: user ${recipientId} has DM notifications disabled`);
      }

      res.status(201).json({
        success: true,
        data: {
          messageId: messageRef.id,
          conversationId: conversationId,
          createdAt: nowDate.toISOString(),
        } as SendMessageResponse,
      } as ApiResponse<SendMessageResponse>);
    } catch (error: unknown) {
      console.error("Send direct message error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
