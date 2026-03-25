//
// createEvent.ts
// K-VOTE COLLECTOR - Create Calendar Event
//

import { Request, Response } from "express";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import {
  CreateCalendarEventRequest,
  CalendarEventResponse,
} from "../../types/calendar";

const db = admin.firestore();

export const createEvent = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const userId = (req as any).user?.uid;
    if (!userId) {
      res.status(401).json({ success: false, error: "Unauthorized" });
      return;
    }

    const body: CreateCalendarEventRequest = req.body;

    // Validate required fields
    if (!body.artistId || !body.eventType || !body.title || !body.startDate) {
      res.status(400).json({
        success: false,
        error: "Missing required fields: artistId, eventType, title, startDate",
      });
      return;
    }

    // Validate event type
    const validEventTypes = ["tv", "release", "live", "vote", "youtube"];
    if (!validEventTypes.includes(body.eventType)) {
      res.status(400).json({
        success: false,
        error: `Invalid eventType. Must be one of: ${validEventTypes.join(", ")}`,
      });
      return;
    }

    // Validate date format
    const startDate = new Date(body.startDate);
    if (isNaN(startDate.getTime())) {
      res.status(400).json({
        success: false,
        error: "Invalid startDate format. Use ISO 8601 format.",
      });
      return;
    }

    let endDate: Date | undefined;
    if (body.endDate) {
      endDate = new Date(body.endDate);
      if (isNaN(endDate.getTime())) {
        res.status(400).json({
          success: false,
          error: "Invalid endDate format. Use ISO 8601 format.",
        });
        return;
      }
    }

    const now = Timestamp.now();
    const eventRef = db.collection("calendarEvents").doc();

    // Build event data without undefined fields (Firestore doesn't accept undefined)
    const eventData: Record<string, any> = {
      eventId: eventRef.id,
      artistId: body.artistId,
      eventType: body.eventType,
      title: body.title,
      startDate: Timestamp.fromDate(startDate),
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
      attendeeCount: 0,
    };

    // Only add optional fields if they have values
    if (body.description) eventData.description = body.description;
    if (endDate) eventData.endDate = Timestamp.fromDate(endDate);
    if (body.location) eventData.location = body.location;
    if (body.url) eventData.url = body.url;
    if (body.thumbnailUrl) eventData.thumbnailUrl = body.thumbnailUrl;

    await eventRef.set(eventData);

    const response: CalendarEventResponse = {
      eventId: eventData.eventId,
      artistId: eventData.artistId,
      eventType: eventData.eventType,
      title: eventData.title,
      description: eventData.description,
      startDate: startDate.toISOString(),
      endDate: endDate?.toISOString(),
      location: eventData.location,
      url: eventData.url,
      thumbnailUrl: eventData.thumbnailUrl,
      createdBy: eventData.createdBy,
      createdAt: eventData.createdAt.toDate().toISOString(),
      updatedAt: eventData.updatedAt.toDate().toISOString(),
      attendeeCount: eventData.attendeeCount,
      isAttending: false,
    };

    res.status(201).json({ success: true, data: response });
  } catch (error) {
    console.error("Error creating calendar event:", error);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
};
