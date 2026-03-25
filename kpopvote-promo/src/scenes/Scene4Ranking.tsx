import {
  AbsoluteFill,
  useCurrentFrame,
  interpolate,
  spring,
  useVideoConfig,
} from "remotion";
import { AnimatedText } from "../components/AnimatedText";
import { MockPhone } from "../components/MockPhone";

const RankingItem: React.FC<{
  rank: number;
  name: string;
  group: string;
  votes: number;
  delay: number;
  isTop?: boolean;
}> = ({ rank, name, group, votes, delay, isTop }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const slideIn = spring({
    frame: frame - delay,
    fps,
    config: { damping: 15 },
  });

  // Count up animation for votes
  const displayVotes = Math.floor(
    interpolate(frame - delay, [0, 40], [0, votes], {
      extrapolateLeft: "clamp",
      extrapolateRight: "clamp",
    })
  );

  const medalColors: Record<number, string> = {
    1: "#FFD700",
    2: "#C0C0C0",
    3: "#CD7F32",
  };

  return (
    <div
      style={{
        transform: `translateX(${interpolate(slideIn, [0, 1], [-300, 0])}px)`,
        opacity: slideIn,
        display: "flex",
        alignItems: "center",
        padding: 12,
        background: isTop
          ? "linear-gradient(135deg, rgba(255, 31, 143, 0.3) 0%, rgba(124, 58, 237, 0.3) 100%)"
          : "rgba(26, 39, 68, 0.8)",
        borderRadius: 12,
        marginBottom: 8,
        border: isTop ? "1px solid #FF1F8F" : "1px solid transparent",
      }}
    >
      {/* Rank */}
      <div
        style={{
          width: 32,
          height: 32,
          borderRadius: "50%",
          background: medalColors[rank] || "#4B5563",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 14,
          fontWeight: 700,
          color: rank <= 3 ? "#0A1628" : "#FFFFFF",
          marginRight: 12,
        }}
      >
        {rank}
      </div>

      {/* Avatar placeholder */}
      <div
        style={{
          width: 40,
          height: 40,
          borderRadius: "50%",
          background: "linear-gradient(135deg, #FF1F8F 0%, #7C3AED 100%)",
          marginRight: 12,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 20,
        }}
      >
        ✨
      </div>

      {/* Info */}
      <div style={{ flex: 1 }}>
        <div style={{ color: "#FFFFFF", fontSize: 14, fontWeight: 600 }}>{name}</div>
        <div style={{ color: "#9CA3AF", fontSize: 11 }}>{group}</div>
      </div>

      {/* Votes */}
      <div style={{ textAlign: "right" }}>
        <div
          style={{
            color: "#FF1F8F",
            fontSize: 16,
            fontWeight: 700,
            fontFamily: "monospace",
          }}
        >
          {displayVotes.toLocaleString()}
        </div>
        <div style={{ color: "#9CA3AF", fontSize: 10 }}>votes</div>
      </div>
    </div>
  );
};

export const Scene4Ranking: React.FC = () => {
  const frame = useCurrentFrame();

  // Crown animation
  const crownBounce = interpolate(
    frame,
    [0, 15, 30, 45, 60],
    [0, -10, 0, -5, 0],
    { extrapolateRight: "clamp" }
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
      {/* Title with crown */}
      <div style={{ position: "relative" }}>
        <span
          style={{
            position: "absolute",
            top: -50,
            left: "50%",
            transform: `translateX(-50%) translateY(${crownBounce}px)`,
            fontSize: 60,
          }}
        >
          👑
        </span>
        <AnimatedText
          text="推しを応援"
          delay={0}
          fontSize={48}
          style={{
            background: "linear-gradient(135deg, #FFD700 0%, #FF1F8F 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        />
      </div>

      {/* Phone with ranking */}
      <MockPhone delay={10}>
        <div style={{ padding: 16 }}>
          {/* Header */}
          <div
            style={{
              textAlign: "center",
              color: "#FFFFFF",
              fontSize: 14,
              fontWeight: 600,
              marginBottom: 16,
              paddingBottom: 12,
              borderBottom: "1px solid #2D3F5F",
            }}
          >
            🏆 アイドルランキング
          </div>

          <RankingItem
            rank={1}
            name="ユンジン"
            group="LE SSERAFIM"
            votes={15847}
            delay={20}
            isTop
          />
          <RankingItem
            rank={2}
            name="ウォニョン"
            group="IVE"
            votes={14392}
            delay={35}
          />
          <RankingItem
            rank={3}
            name="カリナ"
            group="aespa"
            votes={12856}
            delay={50}
          />
          <RankingItem
            rank={4}
            name="ミンジ"
            group="NewJeans"
            votes={11234}
            delay={65}
          />
          <RankingItem
            rank={5}
            name="チェヨン"
            group="TWICE"
            votes={9876}
            delay={80}
          />
        </div>
      </MockPhone>

      <AnimatedText
        text="投票数でランキング更新"
        delay={95}
        fontSize={28}
        color="#9CA3AF"
      />
    </AbsoluteFill>
  );
};
