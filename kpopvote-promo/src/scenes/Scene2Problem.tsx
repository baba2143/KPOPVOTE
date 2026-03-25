import {
  AbsoluteFill,
  useCurrentFrame,
  interpolate,
  spring,
  useVideoConfig,
} from "remotion";
import { AnimatedText } from "../components/AnimatedText";

const AppIcon: React.FC<{
  emoji: string;
  x: number;
  y: number;
  delay: number;
}> = ({ emoji, x, y, delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const appear = spring({
    frame: frame - delay,
    fps,
    config: { damping: 12 },
  });

  const floatOffset = interpolate(
    frame,
    [delay, delay + 30, delay + 60],
    [0, -10, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "extend" }
  );

  const rotation = interpolate(frame, [0, 90], [0, 360 * ((x + y) % 2 === 0 ? 1 : -1)], {
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        fontSize: 60,
        transform: `scale(${appear}) translateY(${floatOffset}px) rotate(${rotation * 0.1}deg)`,
        opacity: interpolate(appear, [0, 1], [0, 0.6]),
      }}
    >
      {emoji}
    </div>
  );
};

export const Scene2Problem: React.FC = () => {
  const frame = useCurrentFrame();

  // Scattered app icons
  const icons = [
    { emoji: "📱", x: 100, y: 400, delay: 0 },
    { emoji: "🗳️", x: 850, y: 350, delay: 5 },
    { emoji: "📊", x: 200, y: 800, delay: 10 },
    { emoji: "⏰", x: 780, y: 900, delay: 15 },
    { emoji: "📅", x: 150, y: 1200, delay: 20 },
    { emoji: "🔔", x: 820, y: 1300, delay: 25 },
    { emoji: "❓", x: 450, y: 600, delay: 30 },
    { emoji: "😵", x: 550, y: 1100, delay: 35 },
  ];

  // Fade out at end
  const fadeOut = interpolate(frame, [70, 90], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill style={{ opacity: fadeOut }}>
      {/* Scattered icons in background */}
      {icons.map((icon, i) => (
        <AppIcon key={i} {...icon} />
      ))}

      {/* Problem text */}
      <AbsoluteFill
        style={{
          justifyContent: "center",
          alignItems: "center",
          flexDirection: "column",
          gap: 50,
        }}
      >
        <AnimatedText
          text="投票情報が分散..."
          delay={10}
          fontSize={52}
          color="#FF6B6B"
        />
        <AnimatedText
          text="締め切りを見落とす..."
          delay={25}
          fontSize={52}
          color="#FF6B6B"
        />
        <AnimatedText
          text="どこに投票したか忘れる..."
          delay={40}
          fontSize={52}
          color="#FF6B6B"
        />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
