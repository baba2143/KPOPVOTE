import { Composition } from "remotion";
import { KpopvotePromo } from "./KpopvotePromo";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="KpopvotePromo"
        component={KpopvotePromo}
        durationInFrames={600}
        fps={30}
        width={1080}
        height={1920}
      />
    </>
  );
};
