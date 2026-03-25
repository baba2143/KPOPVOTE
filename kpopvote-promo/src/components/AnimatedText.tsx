import { useCurrentFrame, interpolate, spring, useVideoConfig } from "remotion";

interface AnimatedTextProps {
  text: string;
  delay?: number;
  style?: React.CSSProperties;
  fontSize?: number;
  color?: string;
  fontWeight?: number;
}

export const AnimatedText: React.FC<AnimatedTextProps> = ({
  text,
  delay = 0,
  style,
  fontSize = 48,
  color = "#FFFFFF",
  fontWeight = 700,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const opacity = spring({
    frame: frame - delay,
    fps,
    config: {
      damping: 20,
    },
  });

  const translateY = interpolate(
    spring({
      frame: frame - delay,
      fps,
      config: {
        damping: 15,
        stiffness: 80,
      },
    }),
    [0, 1],
    [30, 0]
  );

  return (
    <div
      style={{
        fontSize,
        fontWeight,
        color,
        opacity,
        transform: `translateY(${translateY}px)`,
        fontFamily:
          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        ...style,
      }}
    >
      {text}
    </div>
  );
};
