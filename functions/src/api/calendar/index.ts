//
// index.ts
// K-VOTE COLLECTOR - Calendar API Router
//

import { Router } from "express";
import { getEvents } from "./getEvents";
import { getEventDetail } from "./getEventDetail";
import { createEvent } from "./createEvent";
import { updateEvent } from "./updateEvent";
import { deleteEvent } from "./deleteEvent";
import { toggleAttendance } from "./toggleAttendance";
import { checkDuplicate } from "./checkDuplicate";
import { authMiddleware } from "../../middleware/auth";

const router = Router();

// Public routes
router.get("/", getEvents); // GET /api/calendar?artistId=xxx
router.get("/:eventId", getEventDetail); // GET /api/calendar/:eventId

// Protected routes (require authentication)
router.post("/", authMiddleware, createEvent); // POST /api/calendar
router.put("/:eventId", authMiddleware, updateEvent); // PUT /api/calendar/:eventId
router.delete("/:eventId", authMiddleware, deleteEvent); // DELETE /api/calendar/:eventId
router.post("/:eventId/attend", authMiddleware, toggleAttendance); // POST /api/calendar/:eventId/attend
router.post("/check-duplicate", authMiddleware, checkDuplicate); // POST /api/calendar/check-duplicate

export default router;
