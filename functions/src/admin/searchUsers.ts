/**
 * Search users
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApiResponse } from "../types";
import { verifyToken, verifyAdmin, AuthenticatedRequest } from "../middleware/auth";

export const searchUsers = functions.https.onRequest(async (req, res) => {
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

  await new Promise<void>((resolve, reject) => {
    verifyAdmin(req as AuthenticatedRequest, res, (error?: unknown) => error ? reject(error) : resolve());
  });

  try {
    const query = req.query.query as string | undefined;
    const limit = req.query.limit ? parseInt(req.query.limit as string) : 50;

    const db = admin.firestore();
    let usersQuery = db.collection("users").limit(limit);

    // Simple search by email or displayName prefix
    if (query) {
      usersQuery = usersQuery
        .where("email", ">=", query)
        .where("email", "<=", query + "\uf8ff") as admin.firestore.Query<admin.firestore.DocumentData>;
    }

    const snapshot = await usersQuery.get();

    const users = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        uid: doc.id,
        email: data.email,
        displayName: data.displayName || null,
        points: data.points || 0,
        isSuspended: data.isSuspended || false,
        createdAt: data.createdAt?.toDate().toISOString() || null,
      };
    });

    res.status(200).json({
      success: true,
      data: { users, count: users.length },
    } as ApiResponse<unknown>);
  } catch (error: unknown) {
    console.error("Search users error:", error);
    res.status(500).json({ success: false, error: "Internal server error" } as ApiResponse<null>);
  }
});
