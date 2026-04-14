"use client";

import Image from "next/image";
import { FanCardPublicData, FanCardBlock } from "@/types/fancard";
import { getThemeColors, getFontClass } from "@/lib/theme";
import { normalizeImageUrl } from "@/lib/imageUrl";
import BiasBlock from "./BiasBlock";
import LinkBlock from "./LinkBlock";
import MVLinkBlock from "./MVLinkBlock";
import SNSBlock from "./SNSBlock";
import TextBlock from "./TextBlock";
import ImageBlock from "./ImageBlock";

interface FanCardViewProps {
  data: FanCardPublicData;
}

export default function FanCardView({ data }: FanCardViewProps) {
  const { fanCard, myBias } = data;
  const colors = getThemeColors(fanCard.theme);
  const fontClass = getFontClass(fanCard.theme.fontFamily);

  // Sort blocks by order
  const sortedBlocks = [...fanCard.blocks]
    .filter((b) => b.isVisible !== false)
    .sort((a, b) => a.order - b.order);

  const renderBlock = (block: FanCardBlock) => {
    switch (block.type) {
      case "bias":
        return (
          <BiasBlock
            key={block.id}
            data={block.data}
            myBias={myBias}
            primaryColor={fanCard.theme.primaryColor}
          />
        );
      case "link":
        return (
          <LinkBlock
            key={block.id}
            data={block.data}
            primaryColor={fanCard.theme.primaryColor}
          />
        );
      case "mvLink":
        return <MVLinkBlock key={block.id} data={block.data} />;
      case "sns":
        return <SNSBlock key={block.id} data={block.data} />;
      case "text":
        return <TextBlock key={block.id} data={block.data} />;
      case "image":
        return <ImageBlock key={block.id} data={block.data} />;
      default:
        return null;
    }
  };

  return (
    <main
      className={`min-h-screen ${fontClass}`}
      style={{ backgroundColor: colors.background }}
    >
      {/* Header Image */}
      <div className="relative w-full h-48 md:h-64">
        {fanCard.headerImageUrl ? (
          <Image
            src={normalizeImageUrl(fanCard.headerImageUrl) || ""}
            alt="Header"
            fill
            className="object-cover"
            priority
            unoptimized
          />
        ) : (
          <div
            className="w-full h-full"
            style={{
              background: `linear-gradient(135deg, ${fanCard.theme.primaryColor}40, ${fanCard.theme.primaryColor}20)`,
            }}
          />
        )}
        {/* Gradient overlay */}
        <div
          className="absolute inset-0"
          style={{
            background: `linear-gradient(to bottom, transparent 50%, ${colors.background})`,
          }}
        />
      </div>

      {/* Profile Section */}
      <div className="relative px-4 pb-8 -mt-16">
        <div className="max-w-lg mx-auto">
          {/* Avatar */}
          <div className="flex justify-center mb-4">
            <div
              className="relative w-28 h-28 rounded-full border-4 overflow-hidden shadow-lg"
              style={{ borderColor: colors.background }}
            >
              {fanCard.profileImageUrl ? (
                <Image
                  src={normalizeImageUrl(fanCard.profileImageUrl) || ""}
                  alt={fanCard.displayName}
                  fill
                  className="object-cover"
                  priority
                  unoptimized
                />
              ) : (
                <div
                  className="w-full h-full flex items-center justify-center text-3xl"
                  style={{ backgroundColor: fanCard.theme.primaryColor }}
                >
                  {fanCard.displayName.charAt(0)}
                </div>
              )}
            </div>
          </div>

          {/* Name */}
          <h1
            className="text-2xl font-bold text-center mb-2"
            style={{ color: colors.text }}
          >
            {fanCard.displayName}
          </h1>

          {/* Bio */}
          {fanCard.bio && (
            <p
              className="text-center mb-6 whitespace-pre-wrap"
              style={{ color: colors.muted }}
            >
              {fanCard.bio}
            </p>
          )}

          {/* Blocks */}
          <div className="space-y-4">{sortedBlocks.map(renderBlock)}</div>

          {/* Footer */}
          <footer className="mt-12 pt-6 border-t text-center" style={{ borderColor: colors.border }}>
            <a
              href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 text-sm hover:opacity-80 transition-opacity"
              style={{ color: colors.muted }}
            >
              <span>🎤</span>
              <span>OSHI Pick でFanCardを作る</span>
            </a>
          </footer>
        </div>
      </div>
    </main>
  );
}
