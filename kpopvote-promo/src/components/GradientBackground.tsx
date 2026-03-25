import { AbsoluteFill, useCurrentFrame, interpolate } from "remotion";

export const GradientBackground: React.FC = () => {
  const frame = useCurrentFrame();

  // Subtle animation for background gradient
  const gradientRotation = interpolate(frame, [0, 600], [0, 360], {
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        background: `
          radial-gradient(
            ellipse at 50% 0%,
            rgba(124, 58, 237, 0.3) 0%,
            transparent 50%
          ),
          radial-gradient(
            ellipse at 100% 100%,
            rgba(255, 31, 143, 0.2) 0%,
            transparent 40%
          ),
          linear-gradient(
            ${gradientRotation}deg,
            #0A1628 0%,
            #0F1F35 50%,
            #0A1628 100%
          )
        `,
      }}
    />
  );
};
