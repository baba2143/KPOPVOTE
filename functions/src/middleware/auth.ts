/**
 * Authentication middleware for K-VOTE COLLECTOR
 */

import * as admin from "firebase-admin";
import { Request, Response, NextFunction } from "express";

/**
 * Extended Request type with authenticated user info
 */
export interface AuthenticatedRequest extends Request {
  user?: {
    uid: string;
    email?: string;
  };
}

/**
 * Middleware to verify Firebase ID token
 * @param {AuthenticatedRequest} req - Express request with user info
 * @param {Response} res - Express response
 * @param {NextFunction} next - Express next function
 */
export const verifyToken = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    // Get token from Authorization header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({
        success: false,
        error: "Unauthorized: No token provided",
      });
      return;
    }

    const token = authHeader.split("Bearer ")[1];

    // Verify token with Firebase Admin
    const decodedToken = await admin.auth().verifyIdToken(token);

    // Attach user info to request
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
    };

    next();
  } catch (error) {
    console.error("Token verification error:", error);
    // CORS headers are set by handleCors() in the calling endpoint
    res.status(401).json({
      success: false,
      error: "Unauthorized: Invalid token",
    });
  }
};

/**
 * Middleware to verify admin role
 * @param {AuthenticatedRequest} req - Express request with user info
 * @param {Response} res - Express response
 * @param {NextFunction} next - Express next function
 */
export const verifyAdmin = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: "Unauthorized: User not authenticated",
      });
      return;
    }

    // Get user custom claims
    const userRecord = await admin.auth().getUser(req.user.uid);
    const isAdmin = userRecord.customClaims?.admin === true;

    if (!isAdmin) {
      res.status(403).json({
        success: false,
        error: "Forbidden: Admin access required",
      });
      return;
    }

    next();
  } catch (error) {
    console.error("Admin verification error:", error);
    // CORS headers are set by handleCors() in the calling endpoint
    res.status(403).json({
      success: false,
      error: "Forbidden: Admin verification failed",
    });
  }
};

/**
 * Simple auth middleware alias for collections API
 */
export const authMiddleware = verifyToken;

/**
 * Optional auth middleware - parses token if present, but doesn't reject requests without token
 * Use this for public routes that need to know the user identity if available
 */
export const optionalAuthMiddleware = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      // No token - continue without user info
      next();
      return;
    }

    const token = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(token);

    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
    };

    next();
  } catch (error) {
    // Invalid token - continue without user info (optional auth)
    console.warn("Optional auth: Invalid token, continuing without user");
    next();
  }
};

/**
 * Async version of verifyToken that returns boolean
 * Use this instead of Promise wrapper pattern to avoid hanging promises
 */
export const verifyTokenAsync = async (
  req: AuthenticatedRequest,
  res: Response
): Promise<boolean> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({
        success: false,
        error: "Unauthorized: No token provided",
      });
      return false;
    }

    const token = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(token);

    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
    };

    return true;
  } catch (error) {
    console.error("Token verification error:", error);
    res.status(401).json({
      success: false,
      error: "Unauthorized: Invalid token",
    });
    return false;
  }
};

/**
 * Async version of verifyAdmin that returns boolean
 * Use this instead of Promise wrapper pattern to avoid hanging promises
 */
export const verifyAdminAsync = async (
  req: AuthenticatedRequest,
  res: Response
): Promise<boolean> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: "Unauthorized: User not authenticated",
      });
      return false;
    }

    const userRecord = await admin.auth().getUser(req.user.uid);
    const isAdmin = userRecord.customClaims?.admin === true;

    if (!isAdmin) {
      res.status(403).json({
        success: false,
        error: "Forbidden: Admin access required",
      });
      return false;
    }

    return true;
  } catch (error) {
    console.error("Admin verification error:", error);
    res.status(403).json({
      success: false,
      error: "Forbidden: Admin verification failed",
    });
    return false;
  }
};
