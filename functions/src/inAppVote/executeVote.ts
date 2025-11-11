/**
 * Execute vote (user votes for a choice)
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { VoteExecuteRequest, ApiResponse } from "../types";

export const executeVote = functions.https.onRequest(async (req, res) => {
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

  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ success: false, error: "Unauthorized: No token provided" } as ApiResponse<null>);
      return;
    }

    const token = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = decodedToken.uid;

    const { voteId, choiceId } = req.body as VoteExecuteRequest;

    if (!voteId || !choiceId) {
      res.status(400).json({ success: false, error: "voteId and choiceId are required" } as ApiResponse<null>);
      return;
    }

    const db = admin.firestore();
    const voteRef = db.collection("inAppVotes").doc(voteId);
    const voteDoc = await voteRef.get();

    if (!voteDoc.exists) {
      res.status(404).json({ success: false, error: "Vote not found" } as ApiResponse<null>);
      return;
    }

    const voteData = voteDoc.data()!;

    // Check if vote is active
    if (voteData.status !== "active") {
      res.status(400).json({ success: false, error: "Vote is not active" } as ApiResponse<null>);
      return;
    }

    // Check if user has enough points
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      res.status(404).json({ success: false, error: "User not found" } as ApiResponse<null>);
      return;
    }

    const userData = userDoc.data()!;
    const userPoints = userData.points || 0;

    if (userPoints < voteData.requiredPoints) {
      res.status(400).json({ success: false, error: "Insufficient points" } as ApiResponse<null>);
      return;
    }

    // Check if choice exists
    const choiceIndex = voteData.choices.findIndex((c: {choiceId: string}) => c.choiceId === choiceId);
    if (choiceIndex === -1) {
      res.status(400).json({ success: false, error: "Choice not found" } as ApiResponse<null>);
      return;
    }

    // Check if user already voted
    const voteRecordRef = db.collection("voteRecords").doc(`${voteId}_${uid}`);
    const voteRecord = await voteRecordRef.get();

    if (voteRecord.exists) {
      res.status(400).json({ success: false, error: "Already voted" } as ApiResponse<null>);
      return;
    }

    // Execute vote in transaction
    await db.runTransaction(async (transaction) => {
      // Deduct points
      transaction.update(userRef, {
        points: admin.firestore.FieldValue.increment(-voteData.requiredPoints),
      });

      // Update choice vote count
      const choices = voteData.choices;
      choices[choiceIndex].voteCount += 1;
      transaction.update(voteRef, {
        choices,
        totalVotes: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Record vote
      transaction.set(voteRecordRef, {
        voteId,
        userId: uid,
        choiceId,
        votedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    res.status(200).json({
      success: true,
      data: {
        voteId,
        choiceId,
        pointsDeducted: voteData.requiredPoints,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Execute vote error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
