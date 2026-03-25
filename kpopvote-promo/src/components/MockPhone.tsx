import { useCurrentFrame, interpolate, spring, useVideoConfig } from "remotion";

interface MockPhoneProps {
  children: React.ReactNode;
  delay?: number;
}

export const MockPhone: React.FC<MockPhoneProps> = ({ children, delay = 0 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const scale = spring({
    frame: frame - delay,
    fps,
    config: {
      damping: 15,
      stiffness: 80,
    },
  });

  const opacity = interpolate(frame - delay, [0, 10], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        width: 320,
        height: 640,
        backgroundColor: "#1A2744",
        borderRadius: 40,
        padding: 8,
        boxShadow: "0 25px 50px rgba(0, 0, 0, 0.5)",
        transform: `scale(${scale})`,
        opacity,
        overflow: "hidden",
        border: "4px solid #2D3F5F",
      }}
    >
      {/* Notch */}
      <div
        style={{
          width: 120,
          height: 28,
          backgroundColor: "#0A1628",
          borderRadius: 20,
          margin: "0 auto 8px",
        }}
      />
      {/* Screen */}
      <div
        style={{
          width: "100%",
          height: "calc(100% - 36px)",
          backgroundColor: "#0A1628",
          borderRadius: 32,
          overflow: "hidden",
        }}
      >
        {children}
      </div>
    </div>
  );
};
