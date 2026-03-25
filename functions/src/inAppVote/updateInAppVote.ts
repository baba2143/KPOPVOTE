/**
 * Update in-app vote
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { InAppVoteUpdateRequest, ApiResponse, InAppVoteChoice, VoteChoiceInput } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";
import { initializeVoteShards } from "../utils/shardedCounter";

export const updateInAppVote = functions
  .runWith(ADMIN_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "PATCH") {
      res.status(405).json({ success: false, error: "Method not allowed. Use PATCH." } as ApiResponse<null>);
      return;
    }

    await new Promise<void>((resolve, reject) => {
      verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
    });

    await new Promise<void>((resolve, reject) => {
      verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
    });

    try {
      const {
        voteId,
        title,
        description,
        startDate,
        endDate,
        requiredPoints,
        coverImageUrl,
        isFeatured,
        isDraft, // 🆕 下書きフラグ
        choices, // 🆕 選択肢（下書き時のみ更新可能）
        restrictions, // 🆕 投票制限設定
      } = req.body as InAppVoteUpdateRequest;

      if (!voteId) {
        res.status(400).json({ success: false, error: "voteId is required" } as ApiResponse<null>);
        return;
      }

      const voteRef = admin.firestore().collection("inAppVotes").doc(voteId);
      const voteDoc = await voteRef.get();

      if (!voteDoc.exists) {
        res.status(404).json({ success: false, error: "Vote not found" } as ApiResponse<null>);
        return;
      }

      const updateData: Record<string, unknown> = {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // タイムゾーン情報がない場合はJSTとして解釈
      const parseAsJST = (dateStr: string) => {
        if (!dateStr.includes("+") && !dateStr.includes("Z")) {
          return new Date(dateStr + "+09:00");
        }
        return new Date(dateStr);
      };

      if (title) updateData.title = title.trim();
      if (description) updateData.description = description.trim();
      if (startDate) updateData.startDate = admin.firestore.Timestamp.fromDate(parseAsJST(startDate));
      if (endDate) updateData.endDate = admin.firestore.Timestamp.fromDate(parseAsJST(endDate));
      if (typeof requiredPoints === "number") updateData.requiredPoints = requiredPoints;
      if (coverImageUrl !== undefined) updateData.coverImageUrl = coverImageUrl;
      if (isFeatured !== undefined) updateData.isFeatured = isFeatured;
      if (isDraft !== undefined) {
        updateData.isDraft = isDraft;
        // 下書きを解除する場合はstatusを再計算
        if (!isDraft) {
          const now = admin.firestore.Timestamp.now();
          const existingData = voteDoc.data();
          const startTimestamp = updateData.startDate || existingData?.startDate;
          const endTimestamp = updateData.endDate || existingData?.endDate;

          let newStatus: "upcoming" | "active" | "ended" = "upcoming";
          if (startTimestamp && now.toMillis() >= startTimestamp.toMillis()) {
            newStatus = "active";
          }
          if (endTimestamp && now.toMillis() >= endTimestamp.toMillis()) {
            newStatus = "ended";
          }
          updateData.status = newStatus;
        }
      }
      if (restrictions !== undefined) updateData.restrictions = restrictions; // 🆕 投票制限設定

      // 選択肢の更新（下書き時のみ許可）
      const existingData = voteDoc.data();
      const isCurrentlyDraft = existingData?.isDraft || existingData?.status === "draft";
      if (choices && Array.isArray(choices) && choices.length >= 2 && isCurrentlyDraft) {
        const voteChoices: InAppVoteChoice[] = choices.map((choice, index) => {
          const isString = typeof choice === "string";
          const choiceInput = choice as VoteChoiceInput;
          return {
            choiceId: `choice_${index + 1}`,
            label: isString ? (choice as string) : choiceInput.label,
            voteCount: 0,
            ...(!isString && choiceInput.idolId && { idolId: choiceInput.idolId }),
            ...(!isString && choiceInput.imageUrl && { imageUrl: choiceInput.imageUrl }),
            ...(!isString && choiceInput.groupName && { groupName: choiceInput.groupName }),
            ...(!isString && choiceInput.groupId && { groupId: choiceInput.groupId }),
          };
        });
        updateData.choices = voteChoices;

        // シャードを再初期化
        const choiceIds = voteChoices.map((c) => c.choiceId);
        await initializeVoteShards(admin.firestore(), voteId, choiceIds);
      }

      await voteRef.update(updateData);

      res.status(200).json({ success: true, data: { voteId, ...updateData } } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("Update in-app vote error:", error);
      res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
    }
  });
