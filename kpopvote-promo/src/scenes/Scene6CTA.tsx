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

export const Scene6CTA: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Logo animation
  const logoScale = spring({
    frame,
    fps,
    config: { damping: 15, stiffness: 100 },
  });

  // Button pulse
  const buttonPulse = interpolate(
    frame,
    [30, 45, 60, 75, 90],
    [1, 1.08, 1, 1.08, 1],
    { extrapolateRight: "clamp" }
  );

  // Glow animation
  const glowOpacity = interpolate(
    frame,
    [0, 30, 60, 90],
    [0.3, 0.8, 0.5, 0.8],
    { extrapolateRight: "clamp" }
  );

  // Particle animation
  const particles = Array.from({ length: 12 }, (_, i) => {
    const angle = (i / 12) * Math.PI * 2;
    const radius = interpolate(frame, [0, 45], [100, 250], {
      extrapolateRight: "clamp",
    });
    const x = Math.cos(angle + frame * 0.02) * radius;
    const y = Math.sin(angle + frame * 0.02) * radius;
    const opacity = interpolate(frame, [0, 20, 70, 90], [0, 0.6, 0.6, 0], {
      extrapolateRight: "clamp",
    });
    return { x, y, opacity };
  });

  return (
    <AbsoluteFill
      style={{
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
        gap: 50,
      }}
    >
      {/* Background glow */}
      <div
        style={{
          position: "absolute",
          width: 600,
          height: 600,
          borderRadius: "50%",
          background: `radial-gradient(circle, rgba(255, 31, 143, ${glowOpacity}) 0%, transparent 70%)`,
          filter: "blur(60px)",
        }}
      />

      {/* Particles */}
      {particles.map((p, i) => (
        <div
          key={i}
          style={{
            position: "absolute",
            width: 8,
            height: 8,
            borderRadius: "50%",
            background: i % 2 === 0 ? "#FF1F8F" : "#7C3AED",
            transform: `translate(${p.x}px, ${p.y}px)`,
            opacity: p.opacity,
          }}
        />
      ))}

      {/* Logo */}
      <div style={{ transform: `scale(${logoScale})` }}>
        <Img
          src={staticFile("logo.png")}
          style={{
            width: 180,
            height: 180,
            objectFit: "contain",
          }}
        />
      </div>

      {/* App name */}
      <AnimatedText
        text="K-VOTE COLLECTOR"
        delay={10}
        fontSize={52}
        fontWeight={800}
        style={{
          background: "linear-gradient(135deg, #FF1F8F 0%, #7C3AED 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          letterSpacing: 2,
        }}
      />

      {/* CTA Button */}
      <div
        style={{
          transform: `scale(${buttonPulse})`,
          background: "linear-gradient(135deg, #FF1F8F 0%, #7C3AED 100%)",
          padding: "24px 64px",
          borderRadius: 50,
          boxShadow: "0 10px 40px rgba(255, 31, 143, 0.4)",
        }}
      >
        <AnimatedText
          text="今すぐダウンロード"
          delay={25}
          fontSize={32}
          fontWeight={700}
          color="#FFFFFF"
        />
      </div>

      {/* App Store badge placeholder */}
      <div
        style={{
          display: "flex",
          gap: 20,
          marginTop: 20,
        }}
      >
        {/* App Store */}
        <div
          style={{
            background: "#000000",
            borderRadius: 12,
            padding: "14px 28px",
            display: "flex",
            alignItems: "center",
            gap: 12,
            transform: `scale(${spring({ frame: frame - 40, fps, config: { damping: 15 } })})`,
            opacity: spring({ frame: frame - 40, fps, config: { damping: 15 } }),
          }}
        >
          <span style={{ fontSize: 32 }}>🍎</span>
          <div>
            <div style={{ color: "#9CA3AF", fontSize: 10 }}>Download on the</div>
            <div style={{ color: "#FFFFFF", fontSize: 18, fontWeight: 600 }}>
              App Store
            </div>
          </div>
        </div>
      </div>

      {/* Tagline */}
      <AnimatedText
        text="推し活を、もっとスマートに"
        delay={55}
        fontSize={28}
        color="#9CA3AF"
      />
    </AbsoluteFill>
  );
};
