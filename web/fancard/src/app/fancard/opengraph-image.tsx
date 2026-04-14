import { ImageResponse } from "next/og";

export const runtime = "edge";
export const alt = "FanCard - あなたの推し活プロフィールを作成して、共有しよう";
export const size = {
  width: 1200,
  height: 630,
};
export const contentType = "image/png";

export default async function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          height: "100%",
          width: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          background: "linear-gradient(135deg, #0d0d12 0%, #16161d 100%)",
          position: "relative",
        }}
      >
        {/* Background gradient orbs */}
        <div
          style={{
            position: "absolute",
            top: "-30%",
            left: "-10%",
            width: "500px",
            height: "500px",
            background:
              "radial-gradient(circle, rgba(168, 85, 247, 0.25) 0%, transparent 70%)",
            borderRadius: "50%",
          }}
        />
        <div
          style={{
            position: "absolute",
            bottom: "-20%",
            right: "-10%",
            width: "600px",
            height: "600px",
            background:
              "radial-gradient(circle, rgba(236, 72, 153, 0.2) 0%, transparent 70%)",
            borderRadius: "50%",
          }}
        />

        {/* Content */}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 10,
          }}
        >
          {/* Card Icon */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              width: "100px",
              height: "100px",
              background: "linear-gradient(135deg, #a855f7 0%, #ec4899 100%)",
              borderRadius: "24px",
              marginBottom: "30px",
              boxShadow: "0 20px 60px rgba(168, 85, 247, 0.4)",
            }}
          >
            <span style={{ fontSize: "50px" }}>💳</span>
          </div>

          {/* Title */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              marginBottom: "16px",
            }}
          >
            <span
              style={{
                fontSize: "64px",
                fontWeight: "900",
                background: "linear-gradient(135deg, #a855f7 0%, #ec4899 100%)",
                backgroundClip: "text",
                color: "transparent",
              }}
            >
              FanCard
            </span>
          </div>

          {/* Tagline */}
          <div
            style={{
              fontSize: "32px",
              fontWeight: "600",
              color: "rgba(255, 255, 255, 0.9)",
              marginBottom: "40px",
            }}
          >
            推し活プロフィールを作成して、共有しよう。
          </div>

          {/* Features */}
          <div
            style={{
              display: "flex",
              gap: "16px",
            }}
          >
            {["推しメンバー", "SNSリンク", "MV埋め込み", "カスタマイズ"].map(
              (feature) => (
                <div
                  key={feature}
                  style={{
                    padding: "10px 20px",
                    background: "rgba(168, 85, 247, 0.15)",
                    borderRadius: "20px",
                    border: "1px solid rgba(168, 85, 247, 0.3)",
                    color: "#c084fc",
                    fontSize: "18px",
                    fontWeight: "500",
                  }}
                >
                  {feature}
                </div>
              )
            )}
          </div>
        </div>

        {/* OSHI Pick branding */}
        <div
          style={{
            position: "absolute",
            bottom: "30px",
            display: "flex",
            alignItems: "center",
            gap: "8px",
            color: "rgba(255, 255, 255, 0.5)",
            fontSize: "16px",
          }}
        >
          <span>by</span>
          <span style={{ color: "#ff3c78", fontWeight: "bold" }}>OSHI</span>
          <span style={{ fontWeight: "bold" }}>Pick</span>
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}
