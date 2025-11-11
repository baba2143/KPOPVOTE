/**
 * Fetch OGP (Open Graph Protocol) data for a task
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";
import * as cheerio from "cheerio";
import { ApiResponse } from "../types";

/**
 * Extract OGP data from HTML
 * @param {string} html - HTML content
 * @return {object} OGP data with title and image
 */
function extractOGP(html: string): { title: string | null; image: string | null } {
  const $ = cheerio.load(html);

  // Try to get OGP title
  let title =
    $('meta[property="og:title"]').attr("content") ||
    $('meta[name="og:title"]').attr("content") ||
    $("title").text() ||
    null;

  // Try to get OGP image
  let image =
    $('meta[property="og:image"]').attr("content") ||
    $('meta[name="og:image"]').attr("content") ||
    null;

  // Clean up title
  if (title) {
    title = title.trim();
  }

  return { title, image };
}

export const fetchTaskOGP = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Handle preflight request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Only accept POST requests
  if (req.method !== "POST") {
    res.status(405).json({
      success: false,
      error: "Method not allowed. Use POST.",
    } as ApiResponse<null>);
    return;
  }

  try {
    // Verify authentication token
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({
        success: false,
        error: "Unauthorized: No token provided",
      } as ApiResponse<null>);
      return;
    }

    const token = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = decodedToken.uid;

    // Get request body
    const { taskId, url } = req.body;

    // Validate required fields
    if (!taskId || typeof taskId !== "string") {
      res.status(400).json({
        success: false,
        error: "taskId is required",
      } as ApiResponse<null>);
      return;
    }

    if (!url || typeof url !== "string") {
      res.status(400).json({
        success: false,
        error: "url is required",
      } as ApiResponse<null>);
      return;
    }

    // Fetch HTML from URL
    let html: string;
    try {
      const response = await axios.get(url, {
        timeout: 10000, // 10 seconds timeout
        headers: {
          "User-Agent":
            "Mozilla/5.0 (compatible; K-VOTE-COLLECTOR-Bot/1.0)",
        },
        maxRedirects: 5,
      });
      html = response.data;
    } catch (fetchError: unknown) {
      console.error("Fetch error:", fetchError);
      res.status(400).json({
        success: false,
        error: "Failed to fetch URL. Please check if the URL is accessible.",
      } as ApiResponse<null>);
      return;
    }

    // Extract OGP data
    const ogpData = extractOGP(html);

    // Update task with OGP data in Firestore
    const taskRef = admin
      .firestore()
      .collection("users")
      .doc(uid)
      .collection("tasks")
      .doc(taskId);

    // Check if task exists
    const taskDoc = await taskRef.get();
    if (!taskDoc.exists) {
      res.status(404).json({
        success: false,
        error: "Task not found",
      } as ApiResponse<null>);
      return;
    }

    // Update task with OGP data
    await taskRef.update({
      ogpTitle: ogpData.title,
      ogpImage: ogpData.image,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Return success response
    res.status(200).json({
      success: true,
      data: {
        taskId,
        ogpTitle: ogpData.title,
        ogpImage: ogpData.image,
      },
    } as ApiResponse<any>);
  } catch (error: unknown) {
    console.error("Fetch OGP error:", error);

    // Handle specific Firebase errors
    if (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      error.code === "auth/id-token-expired"
    ) {
      res.status(401).json({
        success: false,
        error: "Token expired",
      } as ApiResponse<null>);
      return;
    }

    res.status(500).json({
      success: false,
      error: "Internal server error",
    } as ApiResponse<null>);
  }
});
