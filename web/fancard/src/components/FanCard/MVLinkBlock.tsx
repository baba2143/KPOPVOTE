import Image from "next/image";
import { MVLinkBlockData } from "@/types/fancard";
import { extractYoutubeVideoId, getYoutubeThumbnail } from "@/lib/api";

interface MVLinkBlockProps {
  data: MVLinkBlockData;
}

export default function MVLinkBlock({ data }: MVLinkBlockProps) {
  const videoId = extractYoutubeVideoId(data.youtubeUrl);
  const thumbnailUrl =
    data.thumbnailUrl || (videoId ? getYoutubeThumbnail(videoId) : null);

  return (
    <a
      href={data.youtubeUrl}
      target="_blank"
      rel="noopener noreferrer"
      className="block rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-shadow bg-white"
    >
      {/* Thumbnail */}
      <div className="relative aspect-video bg-gray-100">
        {thumbnailUrl ? (
          <Image
            src={thumbnailUrl}
            alt={data.title}
            fill
            className="object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center text-gray-400">
            <svg
              className="w-12 h-12"
              fill="currentColor"
              viewBox="0 0 24 24"
            >
              <path d="M10 16.5l6-4.5-6-4.5v9zM12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z" />
            </svg>
          </div>
        )}
        {/* Play button overlay */}
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="w-14 h-14 bg-red-600 rounded-full flex items-center justify-center shadow-lg">
            <svg
              className="w-6 h-6 text-white ml-1"
              fill="currentColor"
              viewBox="0 0 24 24"
            >
              <path d="M8 5v14l11-7z" />
            </svg>
          </div>
        </div>
      </div>
      {/* Title */}
      <div className="p-3">
        <p className="font-medium text-gray-900 line-clamp-2">{data.title}</p>
        {data.artistName && (
          <p className="text-sm text-gray-500 mt-1">{data.artistName}</p>
        )}
      </div>
    </a>
  );
}
