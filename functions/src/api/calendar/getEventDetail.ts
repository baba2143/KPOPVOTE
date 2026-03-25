//
// getEventDetail.ts
// K-VOTE COLLECTOR - Get Calendar Event Detail
//

import { Request, Response } from "express";
import * as admin from "firebase-admin";
import { CalendarEvent, CalendarEventResponse } from "../../types/calendar";

const db = admin.firestore();

export const getEventDetail = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { eventId } = req.params;
    const userId = (req as any).user?.uid; // May be undefined for public access

    if (!eventId) {
      res.status(400).json({
        success: false,
        error: "eventId is required",
      });
      return;
    }

    const eventDoc = await db.collection("calendarEvents").doc(eventId).get();

    if (!eventDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Event not found",
      });
      return;
    }

    const data = eventDoc.data() as CalendarEvent;

    // Check if current user is attending
    let isAttending = false;
    if (userId) {
      const attendeeDoc = await db
        .collection("calendarEventAttendees")
        .doc(eventId)
        .collection("users")
        .doc(userId)
        .get();
      isAttending = attendeeDoc.exists;
    }

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
      isAttending,
    };

    res.json({ success: true, data: response });
  } catch (error) {
    console.error("Error getting calendar event detail:", error);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
};
