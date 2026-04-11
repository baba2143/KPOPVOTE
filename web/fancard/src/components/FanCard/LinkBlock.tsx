import Image from "next/image";
import { LinkBlockData } from "@/types/fancard";

interface LinkBlockProps {
  data: LinkBlockData;
  primaryColor: string;
}

function getDisplayTitle(data: LinkBlockData): string {
  if (data.title && data.title.trim()) {
    return data.title;
  }
  // URLからドメイン名を抽出
  try {
    const url = new URL(data.url);
    return url.hostname.replace(/^www\./, "");
  } catch {
    return data.url;
  }
}

export default function LinkBlock({ data, primaryColor }: LinkBlockProps) {
  const bgColor = data.backgroundColor || primaryColor;
  const displayTitle = getDisplayTitle(data);

  return (
    <a
      href={data.url}
      target="_blank"
      rel="noopener noreferrer"
      className="block w-full p-4 rounded-xl text-white text-center font-medium shadow-sm hover:opacity-90 hover:shadow-md transition-all"
      style={{ backgroundColor: bgColor }}
    >
      <div className="flex items-center justify-center gap-3">
        {data.iconUrl && (
          <div className="relative w-6 h-6 flex-shrink-0">
            <Image
              src={data.iconUrl}
              alt=""
              fill
              className="object-contain rounded"
            />
          </div>
        )}
        <span>{displayTitle}</span>
      </div>
    </a>
  );
}
