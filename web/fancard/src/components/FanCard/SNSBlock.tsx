import { SNSBlockData, SNSPlatform } from "@/types/fancard";

interface SNSBlockProps {
  data: SNSBlockData;
}

const SNS_ICONS: Record<SNSPlatform, { icon: string; color: string; name: string }> = {
  x: {
    icon: "𝕏",
    color: "#000000",
    name: "X (Twitter)",
  },
  instagram: {
    icon: "📷",
    color: "#E4405F",
    name: "Instagram",
  },
  tiktok: {
    icon: "🎵",
    color: "#000000",
    name: "TikTok",
  },
  youtube: {
    icon: "▶️",
    color: "#FF0000",
    name: "YouTube",
  },
  threads: {
    icon: "🧵",
    color: "#000000",
    name: "Threads",
  },
  other: {
    icon: "🔗",
    color: "#6B7280",
    name: "Link",
  },
};

export default function SNSBlock({ data }: SNSBlockProps) {
  const snsInfo = SNS_ICONS[data.platform] || SNS_ICONS.other;

  return (
    <a
      href={data.url}
      target="_blank"
      rel="noopener noreferrer"
      className="flex items-center gap-4 p-4 rounded-xl bg-white shadow-sm hover:shadow-md transition-shadow"
    >
      <div
        className="w-12 h-12 rounded-full flex items-center justify-center text-white text-xl"
        style={{ backgroundColor: snsInfo.color }}
      >
        {snsInfo.icon}
      </div>
      <div className="flex-1 min-w-0">
        <p className="font-medium text-gray-900">{snsInfo.name}</p>
        <p className="text-sm text-gray-500 truncate">@{data.username}</p>
      </div>
      <svg
        className="w-5 h-5 text-gray-400 flex-shrink-0"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M9 5l7 7-7 7"
        />
      </svg>
    </a>
  );
}
