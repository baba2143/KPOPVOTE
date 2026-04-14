import { ImageResponse } from "next/og";

export const size = {
  width: 32,
  height: 32,
};
export const contentType = "image/png";

export default function Icon() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "linear-gradient(135deg, #ff3c78 0%, #a855f7 100%)",
          borderRadius: "8px",
        }}
      >
        <span
          style={{
            fontSize: "20px",
            fontWeight: "bold",
            color: "white",
          }}
        >
          O
        </span>
      </div>
    ),
    {
      ...size,
    }
  );
}
