//
// getEvents.ts
// K-VOTE COLLECTOR - Get Calendar Events List
//

import { Request, Response } from "express";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import {
  CalendarEvent,
  CalendarEventResponse,
  CalendarEventType,
} from "../../types/calendar";

const db = admin.firestore();

export const getEvents = async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      artistId,
      startDate,
      endDate,
      eventType,
      limit = "50",
      lastEventId,
    } = req.query;

    if (!artistId || typeof artistId !== "string") {
      res.status(400).json({
        success: false,
        error: "artistId is required",
      });
      return;
    }

    let query: admin.firestore.Query = db
      .collection("calendarEvents")
      .where("artistId", "==", artistId)
      .orderBy("startDate", "asc");

    // Filter by date range
    if (startDate && typeof startDate === "string") {
      const start = new Date(startDate);
      if (!isNaN(start.getTime())) {
        query = query.where("startDate", ">=", Timestamp.fromDate(start));
      }
    }

    if (endDate && typeof endDate === "string") {
      const end = new Date(endDate);
      if (!isNaN(end.getTime())) {
        query = query.where("startDate", "<=", Timestamp.fromDate(end));
      }
    }

    // Filter by event type
    if (eventType && typeof eventType === "string") {
      query = query.where("eventType", "==", eventType as CalendarEventType);
    }

    // Pagination
    if (lastEventId && typeof lastEventId === "string") {
      const lastDoc = await db
        .collection("calendarEvents")
        .doc(lastEventId)
        .get();
      if (lastDoc.exists) {
        query = query.startAfter(lastDoc);
      }
    }

    const limitNum = Math.min(parseInt(limit as string, 10) || 50, 100);
    query = query.limit(limitNum);

    const snapshot = await query.get();

    const events: CalendarEventResponse[] = snapshot.docs.map((doc) => {
      const data = doc.data() as CalendarEvent;
      return {
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
    });

    res.json({
      success: true,
      data: {
        events,
        count: events.length,
        hasMore: events.length === limitNum,
      },
    });
  } catch (error) {
    console.error("Error getting calendar events:", error);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
};
