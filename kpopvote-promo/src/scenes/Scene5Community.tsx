import {
  AbsoluteFill,
  useCurrentFrame,
  interpolate,
  spring,
  useVideoConfig,
} from "remotion";
import { AnimatedText } from "../components/AnimatedText";

const FloatingEmoji: React.FC<{
  emoji: string;
  startX: number;
  delay: number;
}> = ({ emoji, startX, delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const appear = spring({
    frame: frame - delay,
    fps,
    config: { damping: 20 },
  });

  const floatY = interpolate(
    frame - delay,
    [0, 30, 60],
    [0, -100, -200],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  const opacity = interpolate(
    frame - delay,
    [0, 10, 40, 60],
    [0, 1, 1, 0],
    { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
  );

  return (
    <div
      style={{
        position: "absolute",
        left: startX,
        bottom: 500,
        fontSize: 50,
        transform: `scale(${appear}) translateY(${floatY}px)`,
        opacity,
      }}
    >
      {emoji}
    </div>
  );
};

const CommunityCard: React.FC<{
  username: string;
  content: string;
  likes: number;
  comments: number;
  delay: number;
}> = ({ username, content, likes, comments, delay }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const scale = spring({
    frame: frame - delay,
    fps,
    config: { damping: 15 },
  });

  return (
    <div
      style={{
        transform: `scale(${scale})`,
        opacity: scale,
        background: "linear-gradient(135deg, #1A2744 0%, #243350 100%)",
        borderRadius: 20,
        padding: 24,
        marginBottom: 20,
        border: "1px solid #2D3F5F",
        width: 450,
      }}
    >
      {/* User info */}
      <div style={{ display: "flex", alignItems: "center", marginBottom: 16 }}>
        <div
          style={{
            width: 48,
            height: 48,
            borderRadius: "50%",
            background: "linear-gradient(135deg, #FF1F8F 0%, #7C3AED 100%)",
            marginRight: 12,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 24,
          }}
        >
          💜
        </div>
        <div>
          <div style={{ color: "#FFFFFF", fontSize: 18, fontWeight: 600 }}>
            {username}
          </div>
          <div style={{ color: "#9CA3AF", fontSize: 12 }}>たった今</div>
        </div>
      </div>

      {/* Content */}
      <div
        style={{
          color: "#E5E7EB",
          fontSize: 16,
          lineHeight: 1.5,
          marginBottom: 16,
        }}
      >
        {content}
      </div>

      {/* Actions */}
      <div style={{ display: "flex", gap: 24 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <span style={{ fontSize: 20 }}>❤️</span>
          <span style={{ color: "#FF1F8F", fontSize: 14 }}>{likes}</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <span style={{ fontSize: 20 }}>💬</span>
          <span style={{ color: "#9CA3AF", fontSize: 14 }}>{comments}</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <span style={{ fontSize: 20 }}>🔄</span>
          <span style={{ color: "#9CA3AF", fontSize: 14 }}>Share</span>
        </div>
      </div>
    </div>
  );
};

export const Scene5Community: React.FC = () => {
  const frame = useCurrentFrame();

  const emojis = [
    { emoji: "💜", startX: 150, delay: 20 },
    { emoji: "💖", startX: 350, delay: 30 },
    { emoji: "✨", startX: 550, delay: 25 },
    { emoji: "🎉", startX: 750, delay: 35 },
    { emoji: "🔥", startX: 250, delay: 40 },
    { emoji: "💕", startX: 650, delay: 45 },
  ];

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
      {/* Floating emojis */}
      {emojis.map((e, i) => (
        <FloatingEmoji key={i} {...e} />
      ))}

      {/* Title */}
      <AnimatedText
        text="同じ推しのファンとつながる"
        delay={0}
        fontSize={44}
        style={{
          background: "linear-gradient(135deg, #FF1F8F 0%, #7C3AED 100%)",
          WebkitBackgroundClip: "text",
          WebkitTextFillColor: "transparent",
          textAlign: "center",
        }}
      />

      {/* Community posts */}
      <CommunityCard
        username="LE SSERAFIM推し"
        content="今日の投票完了しました！みんなも頑張ろう🔥 #FEARNOT"
        likes={234}
        comments={18}
        delay={15}
      />

      <CommunityCard
        username="KPOP大好き"
        content="AAA投票のリマインダー設定した！締め切り前に通知来るの便利すぎ✨"
        likes={156}
        comments={12}
        delay={35}
      />

      {/* Feature icons */}
      <div
        style={{
          display: "flex",
          gap: 60,
          marginTop: 20,
        }}
      >
        {[
          { icon: "📝", label: "投稿" },
          { icon: "❤️", label: "いいね" },
          { icon: "💬", label: "コメント" },
        ].map((item, i) => {
          const iconScale = spring({
            frame: frame - 55 - i * 10,
            fps: 30,
            config: { damping: 12 },
          });
          return (
            <div
              key={i}
              style={{
                textAlign: "center",
                transform: `scale(${iconScale})`,
                opacity: iconScale,
              }}
            >
              <div style={{ fontSize: 48, marginBottom: 8 }}>{item.icon}</div>
              <div style={{ color: "#9CA3AF", fontSize: 16 }}>{item.label}</div>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
