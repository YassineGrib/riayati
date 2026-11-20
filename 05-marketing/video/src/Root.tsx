import React from "react";
import { Composition, Folder, Still } from "remotion";
import { HowTo, HOWTO_TOTAL } from "./HowTo";
import { LogoAnim } from "./LogoAnim";
import { Problems, PROBLEMS_TOTAL } from "./Problems";
import { Promo, PromoVertical } from "./Promo";
import {
  POST_SIZE,
  Post1,
  Post2,
  Post3,
  Post4,
  Post5,
  Post6,
  STORY_SIZE,
  Story1,
  Story2,
  Story3,
  Story4,
  Story5,
  Story6,
} from "./Social";
import { Story, STORY_TOTAL, StoryVertical } from "./Story";
import { FPS, H, PROMO_TOTAL, VH, VW, W } from "./theme";

export const RemotionRoot: React.FC = () => (
  <>
    <Folder name="Video">
      <Composition
        id="Promo"
        component={Promo}
        durationInFrames={PROMO_TOTAL}
        fps={FPS}
        width={W}
        height={H}
      />
      <Composition
        id="PromoVertical"
        component={PromoVertical}
        durationInFrames={PROMO_TOTAL}
        fps={FPS}
        width={VW}
        height={VH}
      />
      <Composition
        id="HowTo"
        component={HowTo}
        durationInFrames={HOWTO_TOTAL}
        fps={FPS}
        width={VW}
        height={VH}
      />
      <Composition
        id="Problems"
        component={Problems}
        durationInFrames={PROBLEMS_TOTAL}
        fps={FPS}
        width={VW}
        height={VH}
      />
      <Composition
        id="Story"
        component={Story}
        durationInFrames={STORY_TOTAL}
        fps={FPS}
        width={W}
        height={H}
      />
      <Composition
        id="StoryVertical"
        component={StoryVertical}
        durationInFrames={STORY_TOTAL}
        fps={FPS}
        width={VW}
        height={VH}
      />
      <Composition
        id="LogoLight"
        component={LogoAnim}
        defaultProps={{ dark: false }}
        durationInFrames={150}
        fps={FPS}
        width={1080}
        height={1080}
      />
      <Composition
        id="LogoDark"
        component={LogoAnim}
        defaultProps={{ dark: true }}
        durationInFrames={150}
        fps={FPS}
        width={1080}
        height={1080}
      />
    </Folder>
    <Folder name="Social">
      <Still id="Post1" component={Post1} {...POST_SIZE} />
      <Still id="Post2" component={Post2} {...POST_SIZE} />
      <Still id="Post3" component={Post3} {...POST_SIZE} />
      <Still id="Post4" component={Post4} {...POST_SIZE} />
      <Still id="Post5" component={Post5} {...POST_SIZE} />
      <Still id="Post6" component={Post6} {...POST_SIZE} />
      <Still id="Story1" component={Story1} {...STORY_SIZE} />
      <Still id="Story2" component={Story2} {...STORY_SIZE} />
      <Still id="Story3" component={Story3} {...STORY_SIZE} />
      <Still id="Story4" component={Story4} {...STORY_SIZE} />
      <Still id="Story5" component={Story5} {...STORY_SIZE} />
      <Still id="Story6" component={Story6} {...STORY_SIZE} />
    </Folder>
  </>
);
