/**
 * Notification Helper Utility
 * Common functions for checking notification settings and sending notifications
 */

import * as admin from "firebase-admin";
import { UserNotificationSettings } from "../types";

/**
 * Check if notification should be sent based on user settings
 * @param userId - User ID to check settings for
 * @param notificationType - Type of notification (likes, comments, mentions, etc.)
 * @returns true if notification should be sent, false otherwise
 */
export async function shouldSendNotification(
  userId: string,
  notificationType: keyof Omit<
    UserNotificationSettings,
    "userId" | "createdAt" | "updatedAt"
  >
): Promise<boolean> {
  try {
    const db = admin.firestore();

    // Get user notification settings
    const settingsDoc = await db
      .collection("userNotificationSettings")
      .doc(userId)
      .get();

    // If document doesn't exist, default to all notifications enabled
    if (!settingsDoc.exists) {
      console.log(
        `[NotificationHelper] Settings not found for user ${userId}, defaulting to enabled`
      );
      return true;
    }

    const settings = settingsDoc.data();

    if (!settings) {
      return true;
    }

    // Check master switch first
    if (settings.pushEnabled === false) {
      console.log(
        `[NotificationHelper] Push notifications disabled for user ${userId}`
      );
      return false;
    }

    // Check specific notification type
    const isEnabled = settings[notificationType] ?? true;

    if (!isEnabled) {
      console.log(
        `[NotificationHelper] ${notificationType} notifications disabled for user ${userId}`
      );
    }

    return isEnabled;
  } catch (error) {
    console.error(
      `[NotificationHelper] Error checking notification settings for user ${userId}:`,
      error
    );
    // On error, default to enabled to avoid blocking notifications
    return true;
  }
}

/**
 * Cache for notification settings with 5-minute TTL
 * Format: { userId: { settings: UserNotificationSettings, expiry: timestamp } }
 */
const settingsCache = new Map<
  string,
  { settings: Record<string, boolean>; expiry: number }
>();
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Check if notification should be sent with caching
 * @param userId - User ID to check settings for
 * @param notificationType - Type of notification
 * @returns true if notification should be sent, false otherwise
 */
export async function shouldSendNotificationCached(
  userId: string,
  notificationType: keyof Omit<
    UserNotificationSettings,
    "userId" | "createdAt" | "updatedAt"
  >
): Promise<boolean> {
  try {
    const now = Date.now();
    const cached = settingsCache.get(userId);

    // Check if cache is valid
    if (cached && cached.expiry > now) {
      const pushEnabled = cached.settings.pushEnabled ?? true;
      const typeEnabled = cached.settings[notificationType] ?? true;
      return pushEnabled && typeEnabled;
    }

    // Fetch from Firestore
    const db = admin.firestore();
    const settingsDoc = await db
      .collection("userNotificationSettings")
      .doc(userId)
      .get();

    let settings: Record<string, boolean>;

    if (!settingsDoc.exists) {
      // Default: all enabled
      settings = {
        pushEnabled: true,
        likes: true,
        comments: true,
        mentions: true,
        followers: true,
        newPosts: true,
        voteReminders: true,
        calendarReminders: true,
        announcements: true,
        directMessages: true,
        sameBiasFans: true,
      };
    } else {
      const data = settingsDoc.data();
      settings = {
        pushEnabled: data?.pushEnabled ?? true,
        likes: data?.likes ?? true,
        comments: data?.comments ?? true,
        mentions: data?.mentions ?? true,
        followers: data?.followers ?? true,
        newPosts: data?.newPosts ?? true,
        voteReminders: data?.voteReminders ?? true,
        calendarReminders: data?.calendarReminders ?? true,
        announcements: data?.announcements ?? true,
        directMessages: data?.directMessages ?? true,
        sameBiasFans: data?.sameBiasFans ?? true,
      };
    }

    // Update cache
    settingsCache.set(userId, {
      settings,
      expiry: now + CACHE_TTL_MS,
    });

    const pushEnabled = settings.pushEnabled ?? true;
    const typeEnabled = settings[notificationType] ?? true;

    return pushEnabled && typeEnabled;
  } catch (error) {
    console.error(
      `[NotificationHelper] Error checking notification settings for user ${userId}:`,
      error
    );
    // On error, default to enabled
    return true;
  }
}

/**
 * Clear cache for a specific user (useful after settings update)
 * @param userId - User ID to clear cache for
 */
export function clearNotificationSettingsCache(userId: string): void {
  settingsCache.delete(userId);
}

/**
 * Clear entire cache (useful for testing or maintenance)
 */
export function clearAllNotificationSettingsCache(): void {
  settingsCache.clear();
}
