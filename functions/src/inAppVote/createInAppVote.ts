/**
 * Create in-app vote
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  InAppVoteCreateRequest,
  ApiResponse,
  InAppVoteChoice,
} from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const createInAppVote = functions.https.onRequest(async (req, res) => {
  // Set CORS headers for all requests
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Max-Age", "3600");

  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Only accept POST requests
  if (req.method !== "POST") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use POST.",
    } as ApiResponse<null>);
    return;
  }

  try {
    // Verify authentication and admin role
    await new Promise<void>((resolve, reject) => {
      verifyToken(req as AuthenticatedRequest, res, (error?: unknown) => {
        if (error) reject(error);
        else resolve();
      });
    });

    await new Promise<void>((resolve, reject) => {
      verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => {
        if (error) reject(error);
        else resolve();
      });
    });

    const {
      title,
      description,
      choices,
      startDate,
      endDate,
      requiredPoints,
      coverImageUrl,
      isFeatured,
    } = req.body as InAppVoteCreateRequest;

    // Validate required fields
    if (!title || typeof title !== "string" || title.trim().length === 0) {
      res.status(400).json({
        success: false,
        error: "title is required",
      } as ApiResponse<null>);
      return;
    }

    if (
      !description ||
      typeof description !== "string" ||
      description.trim().length === 0
    ) {
      res.status(400).json({
        success: false,
        error: "description is required",
      } as ApiResponse<null>);
      return;
    }

    if (!Array.isArray(choices) || choices.length < 2) {
      res.status(400).json({
        success: false,
        error: "At least 2 choices are required",
      } as ApiResponse<null>);
      return;
    }

    if (!startDate || !endDate) {
      res.status(400).json({
        success: false,
        error: "startDate and endDate are required",
      } as ApiResponse<null>);
      return;
    }

    if (
      typeof requiredPoints !== "number" ||
      requiredPoints < 0
    ) {
      res.status(400).json({
        success: false,
        error: "requiredPoints must be a non-negative number",
      } as ApiResponse<null>);
      return;
    }

    // Validate dates
    const startTimestamp = admin.firestore.Timestamp.fromDate(
      new Date(startDate)
    );
    const endTimestamp = admin.firestore.Timestamp.fromDate(new Date(endDate));

    if (endTimestamp.toMillis() <= startTimestamp.toMillis()) {
      res.status(400).json({
        success: false,
        error: "endDate must be after startDate",
      } as ApiResponse<null>);
      return;
    }

    // Create vote choices
    const voteChoices: InAppVoteChoice[] = choices.map((choice, index) => ({
      choiceId: `choice_${index + 1}`,
      label: choice,
      voteCount: 0,
    }));

    // Determine vote status
    const now = admin.firestore.Timestamp.now();
    let status: "upcoming" | "active" | "ended" = "upcoming";
    if (now.toMillis() >= startTimestamp.toMillis()) {
      status = "active";
    }
    if (now.toMillis() >= endTimestamp.toMillis()) {
      status = "ended";
    }

    // Create vote document in Firestore
    const voteData = {
      title: title.trim(),
      description: description.trim(),
      choices: voteChoices,
      startDate: startTimestamp,
      endDate: endTimestamp,
      requiredPoints,
      status,
      totalVotes: 0,
      ...(coverImageUrl && { coverImageUrl }),
      ...(isFeatured !== undefined && { isFeatured }),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const voteRef = await admin
      .firestore()
      .collection("inAppVotes")
      .add(voteData);

    // Return success response
    res.status(201).json({
      success: true,
      data: {
        voteId: voteRef.id,
        ...voteData,
        startDate: startDate,
        endDate: endDate,
      },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Create in-app vote error:", error);

    res.status(500).json({
      success: false,
      error: "Internal server error",
    } as ApiResponse<null>);
  }
});
