/**
 * Scheduled Function: Check Calendar Reminders
 * Runs every hour to send reminder notifications for upcoming calendar events.
 * Respects user settings for notification timing (1h, 3h, 24h before event).
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { sendPushNotification } from "../utils/fcmHelper";
import { CalendarEventType, UserCalendarSettings } from "../types/calendar";

const db = admin.firestore();

// Default reminder times in hours
const DEFAULT_REMINDER_HOURS = [1, 24];

// Event type icons for notifications
const EVENT_TYPE_ICONS: Record<CalendarEventType, string> = {
  tv: "📺",
  release: "💿",
  live: "🎤",
  vote: "🗳️",
  youtube: "▶️",
};

// Event type labels for notifications
const EVENT_TYPE_LABELS: Record<CalendarEventType, string> = {
  tv: "TV出演",
  release: "リリース",
  live: "ライブ/イベント",
  vote: "投票",
  youtube: "YouTube公開",
};

/**
 * Check calendar event reminders and send notifications
 * Scheduled to run every hour
 */
export const checkCalendarReminders = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const nowMs = now.toMillis();

    console.log(`📅 [Calendar] Checking reminders at ${now.toDate().toISOString()}`);

    try {
      // Check events starting within the next 25 hours (to catch 24h reminders)
      const maxFutureMs = nowMs + 25 * 60 * 60 * 1000;
      const maxFutureTimestamp = admin.firestore.Timestamp.fromMillis(maxFutureMs);

      // Get upcoming events
      const eventsSnapshot = await db
        .collection("calendarEvents")
        .where("startDate", ">", now)
        .where("startDate", "<=", maxFutureTimestamp)
        .get();

      if (eventsSnapshot.empty) {
        console.log("ℹ️ [Calendar] No upcoming events in the next 25 hours");
        return null;
      }

      let totalNotifications = 0;

      for (const eventDoc of eventsSnapshot.docs) {
        const eventData = eventDoc.data();
        const startDate = eventData.startDate?.toDate();

        if (!startDate) continue;

        const startMs = startDate.getTime();
        const hoursUntilStart = (startMs - nowMs) / (1000 * 60 * 60);

        // Check each reminder threshold (1h, 24h)
        for (const reminderHours of DEFAULT_REMINDER_HOURS) {
          // Check if we're within the reminder window (±30 minutes)
          const isInWindow =
            hoursUntilStart > reminderHours - 0.5 &&
            hoursUntilStart <= reminderHours + 0.5;

          if (isInWindow) {
            console.log(
              `⏰ [Calendar] Event "${eventData.title}" starts in ~${Math.round(hoursUntilStart)} hours`
            );

            // Send notifications to attendees
            const notified = await notifyEventReminder(
              eventDoc.id,
              eventData,
              reminderHours
            );
            totalNotifications += notified;
          }
        }
      }

      console.log(`📅 [Calendar] Sent ${totalNotifications} reminder notifications`);
      return null;
    } catch (error) {
      console.error("❌ [Calendar] Error checking reminders:", error);
      return null;
    }
  });

/**
 * Send reminder notifications to event attendees
 */
async function notifyEventReminder(
  eventId: string,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  eventData: any,
  hoursUntilStart: number
): Promise<number> {
  let notifiedCount = 0;

  try {
    const eventType = eventData.eventType as CalendarEventType;
    const icon = EVENT_TYPE_ICONS[eventType] || "📅";
    const typeLabel = EVENT_TYPE_LABELS[eventType] || "イベント";

    // 1. Get attendees of this event
    const attendeesSnapshot = await db
      .collection("calendarEventAttendees")
      .doc(eventId)
      .collection("users")
      .get();

    const attendeeUserIds = new Set<string>();
    attendeesSnapshot.forEach((doc) => {
      attendeeUserIds.add(doc.id);
    });

    // 2. Get users who follow the artist
    const artistId = eventData.artistId;
    if (artistId) {
      const artistFollowersSnapshot = await db
        .collection("users")
        .where("biasIds", "array-contains", artistId)
        .limit(100)
        .get();

      artistFollowersSnapshot.forEach((doc) => {
        attendeeUserIds.add(doc.id);
      });
    }

    // Create reminder message
    const timeText = getTimeRemainingText(hoursUntilStart);
    const title = `${icon} ${timeText}に${typeLabel}があります`;
    const body = `「${eventData.title}」がまもなく始まります。`;

    // Send notifications to each user (respecting their settings)
    for (const userId of attendeeUserIds) {
      // Check user's notification settings
      const shouldSend = await shouldSendNotification(
        userId,
        artistId,
        eventType,
        hoursUntilStart
      );

      if (!shouldSend) continue;

      // Check if already sent this reminder
      const sentKey = `${userId}_calendarReminder_${eventId}_${hoursUntilStart}h`;
      const alreadySent = await checkNotificationSent(sentKey);

      if (!alreadySent) {
        // Create notification in Firestore
        const notificationRef = db.collection("notifications").doc();
        await notificationRef.set({
          id: notificationRef.id,
          userId,
          type: "system",
          title,
          body,
          isRead: false,
          relatedCalendarEventId: eventId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Send push notification
        await sendPushNotification({
          userId,
          type: "system",
          title,
          body,
          data: {
            notificationId: notificationRef.id,
          },
        });

        // Mark as sent
        await markNotificationSent(sentKey);
        notifiedCount++;
      }
    }

    console.log(
      `📱 [Calendar] Notified ${notifiedCount} users about "${eventData.title}" in ${hoursUntilStart}h`
    );

    return notifiedCount;
  } catch (error) {
    console.error("❌ [Calendar] Error notifying event reminder:", error);
    return 0;
  }
}

/**
 * Check if notification should be sent based on user settings
 */
async function shouldSendNotification(
  userId: string,
  artistId: string,
  eventType: CalendarEventType,
  hoursUntilStart: number
): Promise<boolean> {
  try {
    // Get user's calendar notification settings
    const settingsDoc = await db
      .collection("userCalendarSettings")
      .doc(userId)
      .get();

    if (!settingsDoc.exists) {
      // Default: send notifications
      return true;
    }

    const settings = settingsDoc.data() as UserCalendarSettings;

    // Check if notifications are enabled
    if (!settings.notificationEnabled) {
      return false;
    }

    // Check if this artist's notifications are enabled
    if (artistId && settings.artistNotifications) {
      const artistEnabled = settings.artistNotifications[artistId];
      if (artistEnabled === false) {
        return false;
      }
    }

    // Check if this event type's notifications are enabled
    if (settings.eventTypeNotifications) {
      const typeEnabled = settings.eventTypeNotifications[eventType];
      if (typeEnabled === false) {
        return false;
      }
    }

    // Check user's preferred reminder time
    if (settings.notifyBeforeHours) {
      // Only send if this matches user's preferred timing
      // Allow 24h reminders for all, but custom timing for shorter reminders
      if (hoursUntilStart <= 12 && settings.notifyBeforeHours !== hoursUntilStart) {
        return false;
      }
    }

    return true;
  } catch (error) {
    console.error("❌ [Calendar] Error checking user settings:", error);
    // Default to sending notification if settings check fails
    return true;
  }
}

/**
 * Get human-readable time remaining text
 */
function getTimeRemainingText(hours: number): string {
  if (hours <= 1) {
    return "あと1時間";
  } else if (hours <= 3) {
    return "あと3時間";
  } else if (hours <= 24) {
    return "明日";
  } else {
    return `あと${Math.round(hours)}時間`;
  }
}

/**
 * Check if a notification has already been sent
 */
async function checkNotificationSent(sentKey: string): Promise<boolean> {
  const doc = await db.collection("notificationsSent").doc(sentKey).get();
  return doc.exists;
}

/**
 * Mark a notification as sent
 */
async function markNotificationSent(sentKey: string): Promise<void> {
  await db.collection("notificationsSent").doc(sentKey).set({
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
