/**
 * Get Same Bias Users API
 * Returns users who added the same bias in the past 24 hours
 * Only returns users with isPrivate = false
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, AuthenticatedRequest } from "../middleware/auth";
import { STANDARD_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

const db = admin.firestore();

interface SameBiasUser {
  userId: string;
  displayName: string | null;
  photoURL: string | null;
  addedAt: string;
}

interface GetSameBiasUsersResponse {
  biasId: string;
  biasType: string;
  biasName: string;
  users: SameBiasUser[];
  totalCount: number;
}

export const getSameBiasUsers = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    if (req.method !== "GET") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use GET.",
      } as ApiResponse<null>);
      return;
    }

    // Verify authentication
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
      const { biasId, biasType } = req.query;

      // Validation
      if (!biasId || typeof biasId !== "string") {
        res.status(400).json({
          success: false,
          error: "biasId is required",
        } as ApiResponse<null>);
        return;
      }

      if (!biasType || (biasType !== "group" && biasType !== "member")) {
        res.status(400).json({
          success: false,
          error: "biasType must be 'group' or 'member'",
        } as ApiResponse<null>);
        return;
      }

      const biasDocId = `${biasType}_${biasId}`;
      const now = admin.firestore.Timestamp.now();
      const yesterday = admin.firestore.Timestamp.fromMillis(
        now.toMillis() - 24 * 60 * 60 * 1000
      );

      // Get new users in the past 24 hours (non-private only)
      const newUsersSnapshot = await db
        .collection("biasUserHistory")
        .doc(biasDocId)
        .collection("users")
        .where("addedAt", ">", yesterday)
        .where("isPrivate", "==", false)
        .orderBy("addedAt", "desc")
        .limit(50) // Limit to 50 users
        .get();

      if (newUsersSnapshot.empty) {
        res.status(200).json({
          success: true,
          data: {
            biasId,
            biasType,
            biasName: "",
            users: [],
            totalCount: 0,
          },
        } as ApiResponse<GetSameBiasUsersResponse>);
        return;
      }

      // Get bias name from first document
      const firstUserData = newUsersSnapshot.docs[0].data();
      const biasName = firstUserData.biasName || "";

      // Get user profiles
      const userIds = newUsersSnapshot.docs.map((doc) => doc.id);
      const userProfiles = new Map<string, { displayName: string | null; photoURL: string | null }>();

      // Batch fetch user profiles (Firestore 'in' query supports max 10 items)
      for (let i = 0; i < userIds.length; i += 10) {
        const batch = userIds.slice(i, i + 10);
        const usersSnapshot = await db
          .collection("users")
          .where(admin.firestore.FieldPath.documentId(), "in", batch)
          .get();

        usersSnapshot.forEach((doc) => {
          const data = doc.data();
          userProfiles.set(doc.id, {
            displayName: data.displayName || null,
            photoURL: data.photoURL || null,
          });
        });
      }

      // Build response
      const users: SameBiasUser[] = newUsersSnapshot.docs
        .filter((doc) => doc.id !== currentUser.uid) // Exclude current user
        .map((doc) => {
          const data = doc.data();
          const profile = userProfiles.get(doc.id);
          return {
            userId: doc.id,
            displayName: profile?.displayName || null,
            photoURL: profile?.photoURL || null,
            addedAt: data.addedAt?.toDate().toISOString() || new Date().toISOString(),
          };
        });

      res.status(200).json({
        success: true,
        data: {
          biasId,
          biasType,
          biasName,
          users,
          totalCount: users.length,
        },
      } as ApiResponse<GetSameBiasUsersResponse>);
    } catch (error) {
      console.error("❌ [getSameBiasUsers] Error:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
