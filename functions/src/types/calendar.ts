//
// calendar.ts
// K-VOTE COLLECTOR - Calendar Event Type Definitions
//

import { Timestamp } from "firebase-admin/firestore";

// Event Type Enum
export type CalendarEventType = "tv" | "release" | "live" | "vote" | "youtube";

// Calendar Event Interface
export interface CalendarEvent {
  eventId: string;
  artistId: string;
  eventType: CalendarEventType;
  title: string;
  description?: string;
  startDate: Timestamp;
  endDate?: Timestamp;
  location?: string;
  url?: string;
  thumbnailUrl?: string;
  createdBy: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  attendeeCount: number;
}

// Calendar Event Response (for API)
export interface CalendarEventResponse {
  eventId: string;
  artistId: string;
  eventType: CalendarEventType;
  title: string;
  description?: string;
  startDate: string; // ISO 8601
  endDate?: string; // ISO 8601
  location?: string;
  url?: string;
  thumbnailUrl?: string;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
  attendeeCount: number;
  isAttending?: boolean; // Current user's attendance status
}

// Create Event Request
export interface CreateCalendarEventRequest {
  artistId: string;
  eventType: CalendarEventType;
  title: string;
  description?: string;
  startDate: string; // ISO 8601
  endDate?: string; // ISO 8601
  location?: string;
  url?: string;
  thumbnailUrl?: string;
}

// Update Event Request
export interface UpdateCalendarEventRequest {
  eventType?: CalendarEventType;
  title?: string;
  description?: string;
  startDate?: string; // ISO 8601
  endDate?: string; // ISO 8601
  location?: string;
  url?: string;
  thumbnailUrl?: string;
}

// Get Events Request (Query Parameters)
export interface GetCalendarEventsQuery {
  artistId: string;
  startDate?: string; // ISO 8601 - filter events from this date
  endDate?: string; // ISO 8601 - filter events until this date
  eventType?: CalendarEventType;
  limit?: number;
  lastEventId?: string; // For pagination
}

// Event Attendee
export interface EventAttendee {
  userId: string;
  addedAt: Timestamp;
}

// Check Duplicate Request
export interface CheckDuplicateRequest {
  artistId: string;
  eventType: CalendarEventType;
  title: string;
  startDate: string; // ISO 8601
}

// Check Duplicate Response
export interface CheckDuplicateResponse {
  hasDuplicate: boolean;
  duplicateEvents?: CalendarEventResponse[];
}

// URL Metadata Request
export interface FetchUrlMetadataRequest {
  url: string;
}

// URL Metadata Response
export interface UrlMetadata {
  title?: string;
  description?: string;
  thumbnailUrl?: string;
  publishedAt?: string; // For YouTube videos
  source: "youtube" | "opengraph" | "manual";
}

// User Calendar Settings
export interface UserCalendarSettings {
  userId: string;
  notificationEnabled: boolean;
  notifyBeforeHours: number; // e.g., 1 = 1 hour before
  artistNotifications: Record<string, boolean>; // { [artistId]: boolean }
  eventTypeNotifications: Record<CalendarEventType, boolean>;
}
