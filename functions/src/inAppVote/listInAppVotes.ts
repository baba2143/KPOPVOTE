/**
 * List in-app votes
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { READ_HIGH_TRAFFIC_CONFIG } from "../utils/functionConfig";

export const listInAppVotes = functions
  .runWith(READ_HIGH_TRAFFIC_CONFIG)
  .https.onRequest(async (req, res) => {
  // Set CORS headers for all requests
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.set("Access-Control-Max-Age", "3600");
    // CDN cache for vote list (60s browser, 120s CDN)
    res.set("Cache-Control", "public, max-age=60, s-maxage=120");

    // Handle CORS preflight request
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

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

      let query = admin
        .firestore()
        .collection("inAppVotes")
        .limit(limit);

      // Check if we have any filter conditions
      const hasFilter = (status && ["upcoming", "active", "ended"].includes(status)) || featured === "true";

      // Only use orderBy when no filters are applied (to avoid composite index requirement)
      if (!hasFilter) {
        query = query.orderBy("createdAt", "desc") as admin.firestore.Query<admin.firestore.DocumentData>;
      }

      if (status && ["upcoming", "active", "ended"].includes(status)) {
        query = query.where(
          "status",
          "==",
          status
        ) as admin.firestore.Query<admin.firestore.DocumentData>;
      }

      if (featured === "true") {
        query = query.where(
          "isFeatured",
          "==",
          true
        ) as admin.firestore.Query<admin.firestore.DocumentData>;
      }

      const snapshot = await query.get();

      const now = new Date();
      const votes = snapshot.docs
        .map((doc) => {
          const data = doc.data();
          const startDate = data.startDate.toDate();
          const endDate = data.endDate.toDate();

          // Calculate status dynamically based on current time
          let calculatedStatus: "upcoming" | "active" | "ended" = "upcoming";
          if (now >= startDate) {
            calculatedStatus = "active";
          }
          if (now >= endDate) {
            calculatedStatus = "ended";
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
            ...(data.restrictions && { restrictions: data.restrictions }),
            createdAt: data.createdAt?.toDate().toISOString() || null,
            updatedAt: data.updatedAt?.toDate().toISOString() || null,
          };
        })
        .sort((a, b) => {
        // Sort by createdAt descending on the application side
          if (!a.createdAt || !b.createdAt) return 0;
          return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
        });

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
