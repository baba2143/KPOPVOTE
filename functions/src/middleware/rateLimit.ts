/**
 * Rate Limiting Middleware
 * In-memory rate limiter for Cloud Functions (per-instance)
 */

import { Request, Response, NextFunction } from "express";

interface RateLimitEntry {
  count: number;
  resetTime: number;
}

// In-memory store (per Cloud Function instance)
const rateLimitStore = new Map<string, RateLimitEntry>();

// Cleanup old entries every 5 minutes
const CLEANUP_INTERVAL = 5 * 60 * 1000;
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of rateLimitStore.entries()) {
    if (entry.resetTime < now) {
      rateLimitStore.delete(key);
    }
  }
}, CLEANUP_INTERVAL);

/**
 * Rate limit configuration
 */
export interface RateLimitConfig {
  /** Maximum requests allowed in the window */
  maxRequests: number;
  /** Time window in milliseconds */
  windowMs: number;
  /** Key prefix for namespacing */
  keyPrefix?: string;
}

/** Vote endpoints: 30 requests per minute */
export const VOTE_RATE_LIMIT: RateLimitConfig = {
  maxRequests: 30,
  windowMs: 60 * 1000,
  keyPrefix: "vote",
};

/** General endpoints: 60 requests per minute */
export const GENERAL_RATE_LIMIT: RateLimitConfig = {
  maxRequests: 60,
  windowMs: 60 * 1000,
  keyPrefix: "general",
};

/**
 * Check rate limit for a given user
 * @param userId User identifier (from Firebase Auth)
 * @param config Rate limit configuration
 * @returns Object with allowed status and remaining requests
 */
export function checkRateLimit(
  userId: string,
  config: RateLimitConfig
): { allowed: boolean; remaining: number; resetTime: number; retryAfter?: number } {
  const key = `${config.keyPrefix || "default"}:${userId}`;
  const now = Date.now();
  const entry = rateLimitStore.get(key);

  // If no entry or window has passed, create new entry
  if (!entry || entry.resetTime < now) {
    const newEntry: RateLimitEntry = {
      count: 1,
      resetTime: now + config.windowMs,
    };
    rateLimitStore.set(key, newEntry);
    return {
      allowed: true,
      remaining: config.maxRequests - 1,
      resetTime: newEntry.resetTime,
    };
  }

  // Check if limit exceeded
  if (entry.count >= config.maxRequests) {
    const retryAfter = Math.ceil((entry.resetTime - now) / 1000);
    return {
      allowed: false,
      remaining: 0,
      resetTime: entry.resetTime,
      retryAfter,
    };
  }

  // Increment count
  entry.count++;
  rateLimitStore.set(key, entry);

  return {
    allowed: true,
    remaining: config.maxRequests - entry.count,
    resetTime: entry.resetTime,
  };
}

/**
 * Rate limit middleware for Express routes
 * @param config Rate limit configuration
 * @returns Express middleware function
 */
export function rateLimitMiddleware(config: RateLimitConfig) {
  return (req: Request, res: Response, next: NextFunction): void => {
    // Get user ID from request (set by auth middleware)
    const userId = (req as any).user?.uid;

    if (!userId) {
      // If no user ID, skip rate limiting (auth will handle it)
      next();
      return;
    }

    const result = checkRateLimit(userId, config);

    // Set rate limit headers
    res.set("X-RateLimit-Limit", config.maxRequests.toString());
    res.set("X-RateLimit-Remaining", result.remaining.toString());
    res.set("X-RateLimit-Reset", Math.ceil(result.resetTime / 1000).toString());

    if (!result.allowed) {
      res.set("Retry-After", result.retryAfter!.toString());
      res.status(429).json({
        success: false,
        error: "Too many requests. Please try again later.",
        retryAfter: result.retryAfter,
      });
      return;
    }

    next();
  };
}

/**
 * Rate limit check for non-Express Cloud Functions
 * Call this after authentication to check rate limits
 * @param userId User ID from Firebase Auth
 * @param res Response object
 * @param config Rate limit configuration
 * @returns true if rate limited (response already sent), false if allowed
 */
export function applyRateLimit(
  userId: string,
  res: Response,
  config: RateLimitConfig
): boolean {
  const result = checkRateLimit(userId, config);

  // Set rate limit headers
  res.set("X-RateLimit-Limit", config.maxRequests.toString());
  res.set("X-RateLimit-Remaining", result.remaining.toString());
  res.set("X-RateLimit-Reset", Math.ceil(result.resetTime / 1000).toString());

  if (!result.allowed) {
    res.set("Retry-After", result.retryAfter!.toString());
    res.status(429).json({
      success: false,
      error: "Too many requests. Please try again later.",
      retryAfter: result.retryAfter,
    });
    return true; // Rate limited
  }

  return false; // Allowed
}
