import {
  AbsoluteFill,
  useCurrentFrame,
  interpolate,
  spring,
  useVideoConfig,
} from "remotion";
import { AnimatedText } from "../components/AnimatedText";
import { MockPhone } from "../components/MockPhone";

const TaskCard: React.FC<{
  title: string;
  deadline: string;
  votes: number;
  delay: number;
  color: string;
}> = ({ title, deadline, votes, delay, color }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const slideIn = spring({
    frame: frame - delay,
    fps,
    config: { damping: 15, stiffness: 80 },
  });

  const translateX = interpolate(slideIn, [0, 1], [300, 0]);
  const opacity = interpolate(slideIn, [0, 0.3, 1], [0, 0, 1]);

  return (
    <div
      style={{
        transform: `translateX(${translateX}px)`,
        opacity,
        background: "linear-gradient(135deg, #1A2744 0%, #243350 100%)",
        borderRadius: 16,
        padding: 16,
        marginBottom: 12,
        borderLeft: `4px solid ${color}`,
      }}
    >
      <div style={{ color: "#FFFFFF", fontSize: 16, fontWeight: 600, marginBottom: 8 }}>
        {title}
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={{ color: "#FF1F8F", fontSize: 12 }}>⏰ {deadline}</div>
        <div style={{ color: "#9CA3AF", fontSize: 12 }}>🗳️ {votes}票</div>
      </div>
    </div>
  );
};

export const Scene3Tasks: React.FC = () => {
  const frame = useCurrentFrame();

  // Pulse effect for URL
  const urlPulse = interpolate(
    frame,
    [30, 45, 60, 75],
    [1, 1.05, 1, 1.05],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  return (
    <AbsoluteFill
      style={{
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
        gap: 40,
        padding: 40,
      }}
    >
      {/* Title */}
      <AnimatedText
        text="ワンタップで投票管理"
        delay={0}
        fontSize={48}
        style={{
          background: "linear-gradient(135deg, #FF1F8F 0%, #7C3AED 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
        }}
      />

      {/* Phone mockup */}
      <MockPhone delay={10}>
        <div style={{ padding: 20 }}>
          {/* URL input */}
          <div
            style={{
              background: "#243350",
              borderRadius: 12,
              padding: 12,
              marginBottom: 20,
              display: "flex",
              alignItems: "center",
              gap: 8,
              transform: `scale(${urlPulse})`,
              border: "2px solid #FF1F8F",
            }}
          >
            <span style={{ fontSize: 16 }}>🔗</span>
            <span style={{ color: "#9CA3AF", fontSize: 12 }}>URLを貼り付けて登録</span>
          </div>

          {/* Task cards */}
          <TaskCard
            title="MAMA 2024 投票"
            deadline="12/15 23:59"
            votes={42}
            delay={30}
            color="#FF1F8F"
          />
          <TaskCard
            title="AAA 人気賞"
            deadline="12/20 18:00"
            votes={28}
            delay={45}
            color="#7C3AED"
          />
          <TaskCard
            title="MelOn Top100 投票"
            deadline="毎日 24:00"
            votes={365}
            delay={60}
            color="#00D9FF"
          />
        </div>
      </MockPhone>

      {/* Feature highlight */}
      <AnimatedText
        text="URL登録でOGP自動取得"
        delay={80}
        fontSize={28}
        color="#9CA3AF"
      />
    </AbsoluteFill>
  );
};
