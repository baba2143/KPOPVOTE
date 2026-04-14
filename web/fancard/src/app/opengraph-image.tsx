import { ImageResponse } from "next/og";

export const runtime = "edge";
export const alt = "OSHI Pick - 推し活がそのまま投票に";
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
          background: "linear-gradient(135deg, #0a0a0f 0%, #1a1a2e 100%)",
          position: "relative",
        }}
      >
        {/* Background gradient orbs */}
        <div
          style={{
            position: "absolute",
            top: "-20%",
            right: "-10%",
            width: "600px",
            height: "600px",
            background:
              "radial-gradient(circle, rgba(255, 60, 120, 0.3) 0%, transparent 70%)",
            borderRadius: "50%",
          }}
        />
        <div
          style={{
            position: "absolute",
            bottom: "-20%",
            left: "-10%",
            width: "500px",
            height: "500px",
            background:
              "radial-gradient(circle, rgba(168, 85, 247, 0.25) 0%, transparent 70%)",
            borderRadius: "50%",
          }}
        />

        {/* Logo and Title */}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 10,
          }}
        >
          {/* Logo Circle */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              width: "120px",
              height: "120px",
              background: "linear-gradient(135deg, #ff3c78 0%, #a855f7 100%)",
              borderRadius: "30px",
              marginBottom: "30px",
              boxShadow: "0 20px 60px rgba(255, 60, 120, 0.4)",
            }}
          >
            <span
              style={{
                fontSize: "60px",
                fontWeight: "bold",
                color: "white",
              }}
            >
              O
            </span>
          </div>

          {/* App Name */}
          <div
            style={{
              display: "flex",
              alignItems: "center",
              marginBottom: "20px",
            }}
          >
            <span
              style={{
                fontSize: "72px",
                fontWeight: "900",
                color: "#ff3c78",
              }}
            >
              OSHI
            </span>
            <span
              style={{
                fontSize: "72px",
                fontWeight: "900",
                color: "white",
                marginLeft: "16px",
              }}
            >
              Pick
            </span>
          </div>

          {/* Tagline */}
          <div
            style={{
              fontSize: "36px",
              fontWeight: "600",
              color: "rgba(255, 255, 255, 0.9)",
              marginBottom: "40px",
            }}
          >
            推し活がそのまま投票に。
          </div>

          {/* Features */}
          <div
            style={{
              display: "flex",
              gap: "20px",
            }}
          >
            {["投票", "コミュニティ", "ランキング", "イベント"].map(
              (feature) => (
                <div
                  key={feature}
                  style={{
                    padding: "12px 24px",
                    background: "rgba(255, 255, 255, 0.1)",
                    borderRadius: "30px",
                    border: "1px solid rgba(255, 255, 255, 0.2)",
                    color: "white",
                    fontSize: "20px",
                    fontWeight: "500",
                  }}
                >
                  {feature}
                </div>
              )
            )}
          </div>
        </div>

        {/* App Store Badge hint */}
        <div
          style={{
            position: "absolute",
            bottom: "40px",
            display: "flex",
            alignItems: "center",
            gap: "10px",
            color: "rgba(255, 255, 255, 0.6)",
            fontSize: "18px",
          }}
        >
          <span>📱</span>
          <span>App Storeで無料ダウンロード</span>
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}
