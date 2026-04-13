"use client";

import { useMemo, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import FanCardView from "@/components/FanCard/FanCardView";
import { FanCardPublicData, FanCardResponse, FanCardBlock } from "@/types/fancard";

/**
 * Preview data structure from iOS
 * iOS sends a simplified structure that we need to transform
 */
interface PreviewFanCard {
  odDisplayName: string;
  displayName: string;
  bio: string;
  profileImageUrl: string;
  headerImageUrl: string;
  theme: {
    template: string;
    backgroundColor: string;
    primaryColor: string;
    fontFamily: string;
  };
  blocks: FanCardBlock[];
  isPublic: boolean;
}

function PreviewContent() {
  const searchParams = useSearchParams();
  const data = searchParams.get("data");

  const fanCardData = useMemo<FanCardPublicData | null>(() => {
    if (!data) return null;

    try {
      // Base64 decode → JSON parse
      const decoded = atob(data);
      const preview = JSON.parse(decoded) as PreviewFanCard;

      // Transform to FanCardPublicData format
      const fanCard: FanCardResponse = {
        odDisplayName: preview.odDisplayName || "preview",
        userId: "preview",
        displayName: preview.displayName || "プレビュー",
        bio: preview.bio || "",
        profileImageUrl: preview.profileImageUrl || "",
        headerImageUrl: preview.headerImageUrl || "",
        theme: {
          template: (preview.theme?.template as FanCardResponse["theme"]["template"]) || "default",
          backgroundColor: preview.theme?.backgroundColor || "#ffffff",
          primaryColor: preview.theme?.primaryColor || "#8b5cf6",
          fontFamily: (preview.theme?.fontFamily as FanCardResponse["theme"]["fontFamily"]) || "default",
        },
        blocks: preview.blocks || [],
        isPublic: preview.isPublic ?? true,
        viewCount: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      return {
        fanCard,
        myBias: [],
      };
    } catch (error) {
      console.error("Failed to parse preview data:", error);
      return null;
    }
  }, [data]);

  if (!fanCardData) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-100">
        <div className="text-center p-8">
          <p className="text-gray-600 text-lg">プレビューデータがありません</p>
          <p className="text-gray-400 text-sm mt-2">
            iOSアプリからプレビューを開いてください
          </p>
        </div>
      </div>
    );
  }

  return <FanCardView data={fanCardData} />;
}

/**
 * FanCard Preview Page
 * Displays a FanCard preview from Base64-encoded JSON data
 *
 * URL format: /preview?data=BASE64_ENCODED_JSON
 *
 * Used by iOS app to preview FanCard before saving
 */
export default function PreviewPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-gray-100">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600 mx-auto"></div>
            <p className="text-gray-600 mt-4">読み込み中...</p>
          </div>
        </div>
      }
    >
      <PreviewContent />
    </Suspense>
  );
}
