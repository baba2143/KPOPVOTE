/**
 * In-memory rate limiter for Cloud Functions
 * Note: Each Cloud Functions instance has its own memory, so this is per-instance rate limiting.
 * This provides a reasonable first line of defense against abuse.
 */

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

const rateLimitStore = new Map<string, RateLimitEntry>();

// Clean up expired entries every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of rateLimitStore) {
    if (now > entry.resetAt) {
      rateLimitStore.delete(key);
    }
  }
}, 5 * 60 * 1000);

interface RateLimitConfig {
  maxRequests: number;
  windowMs: number;
}

/**
 * Check rate limit for a given identifier.
 * Returns { allowed: true } or { allowed: false, retryAfterSeconds }.
 */
export function checkRateLimit(
  identifier: string,
  config: RateLimitConfig
): { allowed: true } | { allowed: false; retryAfterSeconds: number } {
  const now = Date.now();
  const entry = rateLimitStore.get(identifier);

  if (!entry || now > entry.resetAt) {
    rateLimitStore.set(identifier, {
      count: 1,
      resetAt: now + config.windowMs,
    });
    return { allowed: true };
  }

  if (entry.count >= config.maxRequests) {
    const retryAfterSeconds = Math.ceil((entry.resetAt - now) / 1000);
    return { allowed: false, retryAfterSeconds };
  }

  entry.count++;
  return { allowed: true };
}

/** Rate limit config for vote endpoints: 30 requests per minute */
export const VOTE_RATE_LIMIT: RateLimitConfig = {
  maxRequests: 30,
  windowMs: 60 * 1000,
};

/** Rate limit config for general endpoints: 60 requests per minute */
export const GENERAL_RATE_LIMIT: RateLimitConfig = {
  maxRequests: 60,
  windowMs: 60 * 1000,
};
