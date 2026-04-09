"use client";

import { useEffect } from "react";
import { incrementViewCount } from "@/lib/api";

interface ViewCounterProps {
  odDisplayName: string;
}

/**
 * Client component to increment view count on page load
 */
export default function ViewCounter({ odDisplayName }: ViewCounterProps) {
  useEffect(() => {
    // Increment view count after a short delay to ensure page is loaded
    const timer = setTimeout(() => {
      incrementViewCount(odDisplayName);
    }, 1000);

    return () => clearTimeout(timer);
  }, [odDisplayName]);

  // This component doesn't render anything
  return null;
}
