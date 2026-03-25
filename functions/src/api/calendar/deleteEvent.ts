//
// deleteEvent.ts
// K-VOTE COLLECTOR - Delete Calendar Event
//

import { Request, Response } from "express";
import * as admin from "firebase-admin";
import { CalendarEvent } from "../../types/calendar";

const db = admin.firestore();

export const deleteEvent = async (
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

    // Only creator can delete
    if (existingData.createdBy !== userId) {
      res.status(403).json({
        success: false,
        error: "Only the creator can delete this event",
      });
      return;
    }

    // Delete attendees subcollection
    const attendeesSnapshot = await db
      .collection("calendarEventAttendees")
      .doc(eventId)
      .collection("users")
      .get();

    const batch = db.batch();

    attendeesSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // Delete the event
    batch.delete(eventRef);

    await batch.commit();

    res.json({
      success: true,
      data: { eventId, deleted: true },
    });
  } catch (error) {
    console.error("Error deleting calendar event:", error);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
};
