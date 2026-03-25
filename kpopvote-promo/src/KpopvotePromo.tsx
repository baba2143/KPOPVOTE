import { AbsoluteFill, Sequence } from "remotion";
import { Scene1Logo } from "./scenes/Scene1Logo";
import { Scene2Problem } from "./scenes/Scene2Problem";
import { Scene3Tasks } from "./scenes/Scene3Tasks";
import { Scene4Ranking } from "./scenes/Scene4Ranking";
import { Scene5Community } from "./scenes/Scene5Community";
import { Scene6CTA } from "./scenes/Scene6CTA";
import { GradientBackground } from "./components/GradientBackground";

export const KpopvotePromo: React.FC = () => {
  return (
    <AbsoluteFill>
      <GradientBackground />

      {/* Scene 1: Logo & Title (0-3s / 0-90 frames) */}
      <Sequence from={0} durationInFrames={90}>
        <Scene1Logo />
      </Sequence>

      {/* Scene 2: Problem (3-6s / 90-180 frames) */}
      <Sequence from={90} durationInFrames={90}>
        <Scene2Problem />
      </Sequence>

      {/* Scene 3: Task Management (6-10s / 180-300 frames) */}
      <Sequence from={180} durationInFrames={120}>
        <Scene3Tasks />
      </Sequence>

      {/* Scene 4: Ranking (10-14s / 300-420 frames) */}
      <Sequence from={300} durationInFrames={120}>
        <Scene4Ranking />
      </Sequence>

      {/* Scene 5: Community (14-17s / 420-510 frames) */}
      <Sequence from={420} durationInFrames={90}>
        <Scene5Community />
      </Sequence>

      {/* Scene 6: CTA (17-20s / 510-600 frames) */}
      <Sequence from={510} durationInFrames={90}>
        <Scene6CTA />
      </Sequence>
    </AbsoluteFill>
  );
};
