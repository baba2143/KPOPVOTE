import { ImageResponse } from "next/og";
import { getFanCardByOdDisplayName } from "@/lib/api";

export const runtime = "edge";

export const alt = "FanCard";
export const size = {
  width: 1200,
  height: 630,
};
export const contentType = "image/png";

export default async function Image({
  params,
}: {
  params: { username: string };
}) {
  const data = await getFanCardByOdDisplayName(params.username);

  if (!data) {
    // Return a default "not found" image
    return new ImageResponse(
      (
        <div
          style={{
            width: "100%",
            height: "100%",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            backgroundColor: "#f3f4f6",
            fontFamily: "sans-serif",
          }}
        >
          <div style={{ fontSize: 64, marginBottom: 20 }}>🔍</div>
          <div style={{ fontSize: 32, color: "#374151" }}>
            FanCard Not Found
          </div>
        </div>
      ),
      { ...size }
    );
  }

  const { fanCard, myBias } = data;

  // Build bias display text
  const biasText =
    myBias && myBias.length > 0
      ? myBias
          .map((b) => {
            const members = b.memberNames.slice(0, 2).join(", ");
            return members ? `${b.artistName} (${members})` : b.artistName;
          })
          .slice(0, 2)
          .join(" / ")
      : "";

  // Determine background color based on theme
  const themeColors: Record<string, { bg: string; accent: string }> = {
    default: { bg: "#ffffff", accent: "#9333ea" },
    cute: { bg: "#fdf2f8", accent: "#ec4899" },
    cool: { bg: "#f0f9ff", accent: "#0ea5e9" },
    elegant: { bg: "#faf5ff", accent: "#a855f7" },
    dark: { bg: "#1f1f1f", accent: "#a855f7" },
  };

  const colors = themeColors[fanCard.theme.template] || themeColors.default;
  const primaryColor = fanCard.theme.primaryColor || colors.accent;
  const isDark = fanCard.theme.template === "dark";
  const textColor = isDark ? "#f3f4f6" : "#1f2937";
  const mutedColor = isDark ? "#9ca3af" : "#6b7280";

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          backgroundColor: colors.bg,
          fontFamily: "sans-serif",
        }}
      >
        {/* Header gradient */}
        <div
          style={{
            width: "100%",
            height: "200px",
            background: `linear-gradient(135deg, ${primaryColor}40, ${primaryColor}20)`,
            display: "flex",
          }}
        />

        {/* Content */}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            marginTop: "-80px",
            padding: "0 60px",
          }}
        >
          {/* Avatar */}
          <div
            style={{
              width: 160,
              height: 160,
              borderRadius: "50%",
              backgroundColor: primaryColor,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              border: `6px solid ${colors.bg}`,
              boxShadow: "0 10px 40px rgba(0,0,0,0.1)",
              overflow: "hidden",
            }}
          >
            {fanCard.profileImageUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={fanCard.profileImageUrl}
                alt=""
                width={160}
                height={160}
                style={{ objectFit: "cover" }}
              />
            ) : (
              <span style={{ fontSize: 64, color: "white" }}>
                {fanCard.displayName.charAt(0)}
              </span>
            )}
          </div>

          {/* Name */}
          <div
            style={{
              fontSize: 48,
              fontWeight: 700,
              color: textColor,
              marginTop: 24,
              textAlign: "center",
            }}
          >
            {fanCard.displayName}
          </div>

          {/* Bias */}
          {biasText && (
            <div
              style={{
                fontSize: 28,
                color: mutedColor,
                marginTop: 12,
                display: "flex",
                alignItems: "center",
                gap: 8,
              }}
            >
              <span>💜</span>
              <span>{biasText}</span>
            </div>
          )}

          {/* Bio preview */}
          {fanCard.bio && (
            <div
              style={{
                fontSize: 24,
                color: mutedColor,
                marginTop: 16,
                textAlign: "center",
                maxWidth: 800,
                overflow: "hidden",
                textOverflow: "ellipsis",
                display: "-webkit-box",
                WebkitLineClamp: 2,
                WebkitBoxOrient: "vertical",
              }}
            >
              {fanCard.bio.substring(0, 100)}
              {fanCard.bio.length > 100 ? "..." : ""}
            </div>
          )}
        </div>

        {/* Footer */}
        <div
          style={{
            position: "absolute",
            bottom: 40,
            left: 0,
            right: 0,
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            gap: 12,
          }}
        >
          <span style={{ fontSize: 24 }}>🎤</span>
          <span style={{ fontSize: 20, color: mutedColor }}>
            K-VOTE COLLECTOR FanCard
          </span>
        </div>
      </div>
    ),
    { ...size }
  );
}
