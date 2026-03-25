/**
 * List in-app votes
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { READ_HIGH_TRAFFIC_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

export const listInAppVotes = functions
  .runWith(READ_HIGH_TRAFFIC_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;
    // CDN cache for vote list (60s browser, 120s CDN)
    res.set("Cache-Control", "public, max-age=60, s-maxage=120");

    if (req.method !== "GET") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use GET.",
      } as ApiResponse<null>);
      return;
    }

    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          success: false,
          error: "Unauthorized: No token provided",
        } as ApiResponse<null>);
        return;
      }

      const token = authHeader.split("Bearer ")[1];
      await admin.auth().verifyIdToken(token);

      const limit = req.query.limit ? parseInt(req.query.limit as string) : 50;
      const status = req.query.status as string | undefined;
      const featured = req.query.featured as string | undefined;

      let query: admin.firestore.Query<admin.firestore.DocumentData> = admin
        .firestore()
        .collection("inAppVotes");

      // Apply filters first (required for composite index with orderBy)
      if (status && ["upcoming", "active", "ended", "draft"].includes(status)) {
        query = query.where("status", "==", status);
      }

      if (featured === "true") {
        query = query.where("isFeatured", "==", true);
      }

      // Always use Firestore orderBy for efficient sorting (composite indexes support this)
      query = query.orderBy("createdAt", "desc").limit(limit);

      const snapshot = await query.get();

      const now = new Date();
      const votes = snapshot.docs
        .map((doc) => {
          const data = doc.data();
          const startDate = data.startDate.toDate();
          const endDate = data.endDate.toDate();

          // Calculate status dynamically based on current time
          // 下書きの場合はそのままdraftを維持
          let calculatedStatus: "upcoming" | "active" | "ended" | "draft" = "upcoming";
          if (data.isDraft || data.status === "draft") {
            calculatedStatus = "draft";
          } else {
            if (now >= startDate) {
              calculatedStatus = "active";
            }
            if (now >= endDate) {
              calculatedStatus = "ended";
            }
          }

          return {
            voteId: doc.id,
            title: data.title,
            description: data.description,
            choices: data.choices,
            startDate: startDate.toISOString(),
            endDate: endDate.toISOString(),
            requiredPoints: data.requiredPoints,
            status: calculatedStatus,
            totalVotes: data.totalVotes,
            ...(data.coverImageUrl && { coverImageUrl: data.coverImageUrl }),
            ...(data.isFeatured !== undefined && { isFeatured: data.isFeatured }),
            ...(data.isDraft !== undefined && { isDraft: data.isDraft }),
            ...(data.restrictions && { restrictions: data.restrictions }),
            createdAt: data.createdAt?.toDate().toISOString() || null,
            updatedAt: data.updatedAt?.toDate().toISOString() || null,
          };
        });
      // Note: Firestore orderBy already sorts by createdAt desc, no memory sort needed

      res.status(200).json({
        success: true,
        data: {
          votes,
          count: votes.length,
        },
      } as ApiResponse<unknown>);
    } catch (error: unknown) {
      console.error("List in-app votes error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
