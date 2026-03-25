import {
  AbsoluteFill,
  useCurrentFrame,
  interpolate,
  spring,
  useVideoConfig,
  staticFile,
  Img,
} from "remotion";
import { AnimatedText } from "../components/AnimatedText";

export const Scene1Logo: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Logo animation
  const logoScale = spring({
    frame,
    fps,
    config: {
      damping: 12,
      stiffness: 100,
    },
  });

  const logoOpacity = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Glow effect
  const glowIntensity = interpolate(
    frame,
    [30, 45, 60, 75],
    [0, 1, 0.5, 1],
    {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    }
  );

  return (
    <AbsoluteFill
      style={{
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
        gap: 40,
      }}
    >
      {/* Logo with glow */}
      <div
        style={{
          position: "relative",
          transform: `scale(${logoScale})`,
          opacity: logoOpacity,
        }}
      >
        {/* Glow layer */}
        <div
          style={{
            position: "absolute",
            top: -20,
            left: -20,
            right: -20,
            bottom: -20,
            background: `radial-gradient(circle, rgba(255, 31, 143, ${glowIntensity * 0.5}) 0%, transparent 70%)`,
            borderRadius: "50%",
          }}
        />
        <Img
          src={staticFile("logo.png")}
          style={{
            width: 200,
            height: 200,
            objectFit: "contain",
          }}
        />
      </div>

      {/* App Name */}
      <AnimatedText
        text="K-VOTE COLLECTOR"
        delay={15}
        fontSize={56}
        fontWeight={800}
        style={{
          background: "linear-gradient(135deg, #FF1F8F 0%, #7C3AED 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          letterSpacing: 2,
        }}
      />

      {/* Tagline */}
      <AnimatedText
        text="推し活を、もっとスマートに"
        delay={30}
        fontSize={36}
        fontWeight={500}
        color="#9CA3AF"
      />
    </AbsoluteFill>
  );
};
