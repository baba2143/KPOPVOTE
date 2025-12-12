/**
 * CORS Middleware for K-VOTE COLLECTOR
 *
 * Provides secure CORS configuration with origin whitelist
 */

import { Response, Request } from "express";

/**
 * Allowed origins for CORS
 * - Production: Firebase Hosting domains
 * - Development: localhost for testing
 */
const ALLOWED_ORIGINS = [
  // Production - App
  "https://kpopvote-9de2b.web.app",
  "https://kpopvote-9de2b.firebaseapp.com",
  // Production - Admin
  "https://kpopvote-admin.web.app",
  "https://kpopvote-admin.firebaseapp.com",
  // Development
  "http://localhost:3000",
  "http://localhost:5000",
  "http://localhost:5173",
];

/**
 * Check if origin is allowed
 * @param origin - The origin from the request
 * @returns true if origin is allowed
 */
const isAllowedOrigin = (origin: string | undefined): boolean => {
  if (!origin) {
    // No origin header = not a CORS request (e.g., native iOS app, server-to-server)
    // Allow these requests
    return true;
  }
  return ALLOWED_ORIGINS.includes(origin);
};

/**
 * Set CORS headers on response
 *
 * For iOS native apps:
 * - No Origin header is sent, so CORS doesn't apply
 * - Requests pass through normally
 *
 * For web browsers:
 * - Only whitelisted origins are allowed
 * - Preflight (OPTIONS) requests are handled
 *
 * @param req - Express request
 * @param res - Express response
 */
export const setCorsHeaders = (req: Request, res: Response): void => {
  const origin = req.headers.origin;

  if (isAllowedOrigin(origin)) {
    // Set the specific origin instead of wildcard for security
    res.set("Access-Control-Allow-Origin", origin || "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    res.set("Access-Control-Allow-Credentials", "true");
  } else {
    // For disallowed origins, don't set CORS headers
    // The browser will block the request
    console.warn(`[CORS] Blocked request from origin: ${origin}`);
  }
};

/**
 * Handle OPTIONS preflight request
 * @param req - Express request
 * @param res - Express response
 * @returns true if this was a preflight request and was handled
 */
export const handlePreflight = (req: Request, res: Response): boolean => {
  if (req.method === "OPTIONS") {
    setCorsHeaders(req, res);
    res.status(204).send("");
    return true;
  }
  return false;
};

/**
 * Combined CORS handler - sets headers and handles preflight
 * Use at the start of every HTTP function
 *
 * @example
 * export const myFunction = functions.https.onRequest(async (req, res) => {
 *   if (handleCors(req, res)) return;
 *   // ... rest of function
 * });
 *
 * @param req - Express request
 * @param res - Express response
 * @returns true if preflight was handled and function should return
 */
export const handleCors = (req: Request, res: Response): boolean => {
  setCorsHeaders(req, res);
  return handlePreflight(req, res);
};
