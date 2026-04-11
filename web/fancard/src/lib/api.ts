/**
 * API utilities for FanCard frontend
 */

import { FanCardPublicData } from "@/types/fancard";

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ||
  "https://us-central1-kpopvote-9de2b.cloudfunctions.net";

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

/**
 * Fetch FanCard by odDisplayName (public endpoint)
 */
export async function getFanCardByOdDisplayName(
  odDisplayName: string
): Promise<FanCardPublicData | null> {
  const url = `${API_BASE_URL}/getFanCardByOdDisplayName?odDisplayName=${encodeURIComponent(
    odDisplayName
  )}`;

  try {
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
      cache: "no-store", // Always fetch fresh data
    });

    if (!response.ok) {
      if (response.status === 404) {
        return null;
      }
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const result: ApiResponse<FanCardPublicData> = await response.json();

    if (!result.success || !result.data) {
      return null;
    }

    return result.data;
  } catch (error) {
    console.error("Failed to fetch FanCard:", error);
    return null;
  }
}

/**
 * Increment view count (fire-and-forget)
 */
export async function incrementViewCount(odDisplayName: string): Promise<void> {
  try {
    await fetch(`${API_BASE_URL}/incrementFanCardViewCount`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ odDisplayName }),
    });
  } catch (error) {
    // Silently fail - view count is not critical
    console.warn("Failed to increment view count:", error);
  }
}

/**
 * Extract YouTube video ID from URL
 */
export function extractYoutubeVideoId(url: string): string | null {
  const patterns = [
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
    /youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/,
  ];

  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match) {
      return match[1];
    }
  }

  return null;
}

/**
 * Get YouTube thumbnail URL
 */
export function getYoutubeThumbnail(
  videoId: string,
  quality: "default" | "hqdefault" | "mqdefault" | "sddefault" | "maxresdefault" = "hqdefault"
): string {
  return `https://img.youtube.com/vi/${videoId}/${quality}.jpg`;
}
