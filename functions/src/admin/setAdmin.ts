/**
 * Set admin role for a user
 *
 * Security:
 * - Initial admin setup: Only allowed for emails specified in environment variable
 * - Subsequent admin additions: Only existing admins can add new admins
 * - All admin operations are logged to adminLogs collection
 *
 * Environment variable setup:
 * firebase functions:config:set admin.initial_emails="admin@example.com,superadmin@example.com"
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import {
  AdminAuthRequest,
  ApiResponse,
  AdminAuthResponse,
} from "../types";
import { ADMIN_CONFIG } from "../utils/functionConfig";
import { handleCors } from "../middleware/cors";

// Get initial admin emails from environment config
const getInitialAdminEmails = (): string[] => {
  try {
    const config = functions.config();
    const emailsStr = config.admin?.initial_emails || "";
    if (!emailsStr) return [];
    return emailsStr.split(",").map((e: string) => e.trim().toLowerCase());
  } catch {
    return [];
  }
};

// Log admin operation to Firestore
const logAdminOperation = async (
  action: "grant" | "revoke",
  targetUid: string,
  targetEmail: string | undefined,
  callerUid: string,
  callerEmail: string | undefined,
  isInitialSetup: boolean
) => {
  await admin.firestore().collection("adminLogs").add({
    action,
    targetUid,
    targetEmail: targetEmail || null,
    callerUid,
    callerEmail: callerEmail || null,
    isInitialSetup,
    timestamp: Timestamp.now(),
  });
};

export const setAdmin = functions
  .runWith(ADMIN_CONFIG)
  .https.onRequest(async (req, res) => {
    // Handle CORS with whitelist
    if (handleCors(req, res)) return;

    // Only accept POST requests
    if (req.method !== "POST") {
      res.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      } as ApiResponse<null>);
      return;
    }

    try {
    // Verify authentication token
      const authHeader = req.headers.authorization;

      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({
          success: false,
          error: "Unauthorized: No token provided",
        } as ApiResponse<null>);
        return;
      }

      const token = authHeader.split("Bearer ")[1];
      const decodedToken = await admin.auth().verifyIdToken(token);
      const callerUid = decodedToken.uid;
      const callerEmail = decodedToken.email;

      // Check if caller is already an admin
      const callerRecord = await admin.auth().getUser(callerUid);
      const callerIsAdmin = callerRecord.customClaims?.admin === true;

      const { uid } = req.body as AdminAuthRequest;

      if (!uid || typeof uid !== "string") {
        res.status(400).json({
          success: false,
          error: "uid is required",
        } as ApiResponse<null>);
        return;
      }

      // Get target user info
      const targetRecord = await admin.auth().getUser(uid);
      const targetEmail = targetRecord.email;

      // Authorization logic
      let isInitialSetup = false;

      if (!callerIsAdmin) {
      // Non-admin caller - check if initial admin setup is allowed
        const initialAdminEmails = getInitialAdminEmails();

        // Check if any admins already exist
        const adminLogsSnapshot = await admin
          .firestore()
          .collection("adminLogs")
          .where("action", "==", "grant")
          .limit(1)
          .get();

        const adminExists = !adminLogsSnapshot.empty;

        if (adminExists) {
        // Admins exist - only existing admins can add new admins
          res.status(403).json({
            success: false,
            error: "Forbidden: Admin access required to add new admins",
          } as ApiResponse<null>);
          return;
        }

        // No admins exist - check if caller's email is in initial admin list
        const callerEmailLower = callerEmail?.toLowerCase() || "";

        if (
          initialAdminEmails.length === 0 ||
        !initialAdminEmails.includes(callerEmailLower)
        ) {
          res.status(403).json({
            success: false,
            error:
            "Forbidden: Your email is not authorized for initial admin setup",
          } as ApiResponse<null>);
          return;
        }

        // For initial setup, caller can only set themselves as admin
        if (uid !== callerUid) {
          res.status(403).json({
            success: false,
            error:
            "Forbidden: Initial admin setup only allows setting yourself as admin",
          } as ApiResponse<null>);
          return;
        }

        isInitialSetup = true;
      }

      // Set admin custom claim
      await admin.auth().setCustomUserClaims(uid, { admin: true });

      // Update Firestore user document
      await admin
        .firestore()
        .collection("users")
        .doc(uid)
        .set({ isAdmin: true }, { merge: true });

      // Log the admin operation
      await logAdminOperation(
        "grant",
        uid,
        targetEmail,
        callerUid,
        callerEmail,
        isInitialSetup
      );

      // Return success response
      res.status(200).json({
        success: true,
        data: {
          uid,
          isAdmin: true,
        },
      } as ApiResponse<AdminAuthResponse>);
    } catch (error: unknown) {
      console.error("Set admin error:", error);

      // Handle specific Firebase errors
      if (
        typeof error === "object" &&
      error !== null &&
      "code" in error &&
      error.code === "auth/user-not-found"
      ) {
        res.status(404).json({
          success: false,
          error: "User not found",
        } as ApiResponse<null>);
        return;
      }

      res.status(500).json({
        success: false,
        error: "Internal server error",
      } as ApiResponse<null>);
    }
  });
