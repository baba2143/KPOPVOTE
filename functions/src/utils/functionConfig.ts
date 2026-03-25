/**
 * Cloud Functions Runtime Configuration
 * Centralized runWith() configurations for scaling
 */

import * as functions from "firebase-functions";

/**
 * Function tiers for different workload types
 */

// Tier 1: Vote write operations (highest priority)
// - High memory for complex transactions
// - Long timeout for reliability
// - High maxInstances for burst handling
// - minInstances for warm start
export const VOTE_WRITE_CONFIG: functions.RuntimeOptions = {
  memory: "512MB",
  timeoutSeconds: 120,
  maxInstances: 50,
  minInstances: 1,
};

// Tier 2: High-traffic read operations
// - Standard memory
// - High maxInstances for read scaling
export const READ_HIGH_TRAFFIC_CONFIG: functions.RuntimeOptions = {
  memory: "256MB",
  timeoutSeconds: 60,
  maxInstances: 100,
  minInstances: 0,
};

// Tier 3: Express API (collections + calendar)
// - Higher memory for Express overhead
// - Long timeout for complex operations
// - High maxInstances for API traffic
// - minInstances for warm start
export const EXPRESS_API_CONFIG: functions.RuntimeOptions = {
  memory: "512MB",
  timeoutSeconds: 120,
  maxInstances: 80,
  minInstances: 1,
};

// Tier 4: Standard functions
// - Standard memory and timeout
// - Moderate maxInstances
export const STANDARD_CONFIG: functions.RuntimeOptions = {
  memory: "256MB",
  timeoutSeconds: 60,
  maxInstances: 30,
  minInstances: 0,
};

// Tier 5: Scheduled functions
// - Higher memory for batch processing
// - Long timeout for cron jobs
// - Single instance (no parallel runs needed)
export const SCHEDULED_CONFIG: functions.RuntimeOptions = {
  memory: "512MB",
  timeoutSeconds: 300,
  maxInstances: 1,
  minInstances: 0,
};

// Tier 6: Admin functions
// - Standard settings
// - Low maxInstances (admin usage is low)
export const ADMIN_CONFIG: functions.RuntimeOptions = {
  memory: "256MB",
  timeoutSeconds: 60,
  maxInstances: 10,
  minInstances: 0,
};

// Tier 7: Auth functions
// - Standard settings
// - Moderate maxInstances for login/register bursts
export const AUTH_CONFIG: functions.RuntimeOptions = {
  memory: "256MB",
  timeoutSeconds: 60,
  maxInstances: 30,
  minInstances: 0,
};

// Tier 8: Community functions
// - Standard memory
// - Higher maxInstances for social features
export const COMMUNITY_CONFIG: functions.RuntimeOptions = {
  memory: "256MB",
  timeoutSeconds: 60,
  maxInstances: 50,
  minInstances: 0,
};

// Tier 9: Storage/Upload functions
// - Higher memory for file processing
// - Longer timeout for uploads
export const STORAGE_CONFIG: functions.RuntimeOptions = {
  memory: "512MB",
  timeoutSeconds: 120,
  maxInstances: 20,
  minInstances: 0,
};
