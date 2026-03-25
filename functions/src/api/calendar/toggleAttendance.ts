//
// toggleAttendance.ts
// K-VOTE COLLECTOR - Toggle Calendar Event Attendance
//

import { Request, Response } from "express";
import * as admin from "firebase-admin";
import { Timestamp, FieldValue } from "firebase-admin/firestore";
import { EventAttendee } from "../../types/calendar";

const db = admin.firestore();

export const toggleAttendance = async (
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

    const attendeeRef = db
      .collection("calendarEventAttendees")
      .doc(eventId)
      .collection("users")
      .doc(userId);

    const attendeeDoc = await attendeeRef.get();

    let isAttending: boolean;
    let attendeeCount: number;

    if (attendeeDoc.exists) {
      // Remove attendance
      await db.runTransaction(async (transaction) => {
        transaction.delete(attendeeRef);
        transaction.update(eventRef, {
          attendeeCount: FieldValue.increment(-1),
        });
      });
      isAttending = false;
      attendeeCount = (eventDoc.data()?.attendeeCount || 1) - 1;
    } else {
      // Add attendance
      const attendeeData: EventAttendee = {
        userId,
        addedAt: Timestamp.now(),
      };

      await db.runTransaction(async (transaction) => {
        transaction.set(attendeeRef, attendeeData);
        transaction.update(eventRef, {
          attendeeCount: FieldValue.increment(1),
        });
      });
      isAttending = true;
      attendeeCount = (eventDoc.data()?.attendeeCount || 0) + 1;
    }

    res.json({
      success: true,
      data: {
        eventId,
        isAttending,
        attendeeCount,
      },
    });
  } catch (error) {
    console.error("Error toggling attendance:", error);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
};
