//
// checkDuplicate.ts
// K-VOTE COLLECTOR - Check for Duplicate Calendar Events
//

import { Request, Response } from "express";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import {
  CheckDuplicateRequest,
  CheckDuplicateResponse,
  CalendarEvent,
  CalendarEventResponse,
} from "../../types/calendar";

const db = admin.firestore();

export const checkDuplicate = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const userId = (req as any).user?.uid;
    if (!userId) {
      res.status(401).json({ success: false, error: "Unauthorized" });
      return;
    }

    const body: CheckDuplicateRequest = req.body;
    console.log("🔍 [checkDuplicate] Request body:", JSON.stringify(body));

    if (!body.artistId || !body.eventType || !body.title || !body.startDate) {
      res.status(400).json({
        success: false,
        error: "Missing required fields: artistId, eventType, title, startDate",
      });
      return;
    }

    const startDate = new Date(body.startDate);
    console.log("📅 [checkDuplicate] Parsed startDate:", startDate.toISOString());

    if (isNaN(startDate.getTime())) {
      res.status(400).json({
        success: false,
        error: "Invalid startDate format",
      });
      return;
    }

    // Check for events with same artist and type on the same day
    const startOfDay = new Date(startDate);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(startDate);
    endOfDay.setHours(23, 59, 59, 999);

    console.log("📅 [checkDuplicate] Query range:", startOfDay.toISOString(), "-", endOfDay.toISOString());

    const query = db
      .collection("calendarEvents")
      .where("artistId", "==", body.artistId)
      .where("eventType", "==", body.eventType)
      .where("startDate", ">=", Timestamp.fromDate(startOfDay))
      .where("startDate", "<=", Timestamp.fromDate(endOfDay));

    console.log("🔍 [checkDuplicate] Executing query...");
    const snapshot = await query.get();
    console.log("✅ [checkDuplicate] Query returned", snapshot.size, "results");

    // Also check for similar titles (fuzzy matching)
    const similarEvents: CalendarEventResponse[] = [];
    const normalizedTitle = body.title.toLowerCase().trim();

    snapshot.docs.forEach((doc) => {
      const data = doc.data() as CalendarEvent;
      const existingTitle = data.title.toLowerCase().trim();

      // Check for exact match or significant similarity
      const isSimilar =
        existingTitle === normalizedTitle ||
        existingTitle.includes(normalizedTitle) ||
        normalizedTitle.includes(existingTitle) ||
        calculateSimilarity(existingTitle, normalizedTitle) > 0.7;

      if (isSimilar) {
        similarEvents.push({
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
        });
      }
    });

    const response: CheckDuplicateResponse = {
      hasDuplicate: similarEvents.length > 0,
      duplicateEvents: similarEvents.length > 0 ? similarEvents : undefined,
    };

    res.json({ success: true, data: response });
  } catch (error) {
    console.error("Error checking duplicate:", error);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
};

/**
 * Calculates similarity between two strings using Levenshtein distance.
 * @param {string} str1 - First string to compare
 * @param {string} str2 - Second string to compare
 * @return {number} Similarity score between 0 and 1
 */
function calculateSimilarity(str1: string, str2: string): number {
  const longer = str1.length > str2.length ? str1 : str2;
  const shorter = str1.length > str2.length ? str2 : str1;

  if (longer.length === 0) {
    return 1.0;
  }

  const editDistance = levenshteinDistance(longer, shorter);
  return (longer.length - editDistance) / longer.length;
}

/**
 * Calculates the Levenshtein distance between two strings.
 * @param {string} str1 - First string
 * @param {string} str2 - Second string
 * @return {number} The edit distance between the strings
 */
function levenshteinDistance(str1: string, str2: string): number {
  const matrix: number[][] = [];

  for (let i = 0; i <= str2.length; i++) {
    matrix[i] = [i];
  }

  for (let j = 0; j <= str1.length; j++) {
    matrix[0][j] = j;
  }

  for (let i = 1; i <= str2.length; i++) {
    for (let j = 1; j <= str1.length; j++) {
      if (str2.charAt(i - 1) === str1.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j] + 1
        );
      }
    }
  }

  return matrix[str2.length][str1.length];
}
