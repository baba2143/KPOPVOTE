//
// updateEvent.ts
// K-VOTE COLLECTOR - Update Calendar Event
//

import { Request, Response } from "express";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import {
  UpdateCalendarEventRequest,
  CalendarEvent,
  CalendarEventResponse,
} from "../../types/calendar";

const db = admin.firestore();

export const updateEvent = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const userId = (req as any).user?.uid;
    if (!userId) {
      res.status(401).json({ success: false, error: "Unauthorized" });
      return;
    }

    const { eventId } = req.params;
    const body: UpdateCalendarEventRequest = req.body;

    if (!eventId) {
      res.status(400).json({
        success: false,
        error: "eventId is required",
      });
      return;
    }

    const eventRef = db.collection("calendarEvents").doc(eventId);
    const eventDoc = await eventRef.get();

    if (!eventDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Event not found",
      });
      return;
    }

    const existingData = eventDoc.data() as CalendarEvent;

    // Only creator can update
    if (existingData.createdBy !== userId) {
      res.status(403).json({
        success: false,
        error: "Only the creator can update this event",
      });
      return;
    }

    // Validate event type if provided
    if (body.eventType) {
      const validEventTypes = ["tv", "release", "live", "vote", "youtube"];
      if (!validEventTypes.includes(body.eventType)) {
        res.status(400).json({
          success: false,
          error: `Invalid eventType. Must be one of: ${validEventTypes.join(", ")}`,
        });
        return;
      }
    }

    // Build update object
    const updateData: Partial<CalendarEvent> = {
      updatedAt: Timestamp.now(),
    };

    if (body.eventType) updateData.eventType = body.eventType;
    if (body.title) updateData.title = body.title;
    if (body.description !== undefined) updateData.description = body.description;
    if (body.location !== undefined) updateData.location = body.location;
    if (body.url !== undefined) updateData.url = body.url;
    if (body.thumbnailUrl !== undefined) updateData.thumbnailUrl = body.thumbnailUrl;

    if (body.startDate) {
      const startDate = new Date(body.startDate);
      if (isNaN(startDate.getTime())) {
        res.status(400).json({
          success: false,
          error: "Invalid startDate format",
        });
        return;
      }
      updateData.startDate = Timestamp.fromDate(startDate);
    }

    if (body.endDate !== undefined) {
      if (body.endDate) {
        const endDate = new Date(body.endDate);
        if (isNaN(endDate.getTime())) {
          res.status(400).json({
            success: false,
            error: "Invalid endDate format",
          });
          return;
        }
        updateData.endDate = Timestamp.fromDate(endDate);
      } else {
        updateData.endDate = undefined;
      }
    }

    await eventRef.update(updateData);

    // Get updated document
    const updatedDoc = await eventRef.get();
    const data = updatedDoc.data() as CalendarEvent;

    const response: CalendarEventResponse = {
      eventId: data.eventId,
      artistId: data.artistId,
      eventType: data.eventType,
      title: data.title,
      description: data.description,
      startDate: data.startDate.toDate().toISOString(),
      endDate: data.endDate?.toDate().toISOString(),
      location: data.location,
      url: data.url,
      thumbnailUrl: data.thumbnailUrl,
      createdBy: data.createdBy,
      createdAt: data.createdAt.toDate().toISOString(),
      updatedAt: data.updatedAt.toDate().toISOString(),
      attendeeCount: data.attendeeCount,
    };

    res.json({ success: true, data: response });
  } catch (error) {
    console.error("Error updating calendar event:", error);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
};
