import React from "react";
import { AbsoluteFill, Sequence, useCurrentFrame } from "remotion";
import {
  Caption,
  Disclaimer,
  FloatCard,
  Headline,
  Mark,
  Phone,
  Place,
  Rings,
  SceneShell,
  lerp,
  prog,
  useBrandFonts,
} from "./kit";
import { APP_INFO, C, CROPS, EASE, H, SANS, SCREEN, VH, VW, W, WIPE } from "./theme";

export const STORY_TOTAL = 1200; // 40 s
const S = [0, 180, 360, 600, 810, 990]; // scene starts (frames)

const pick = <T,>(v: boolean, l: T, p: T): T => (v ? p : l);
type P = { v: boolean };

/** Scene 1: Calm context. Rings slowly contract. */
const SceneA: React.FC<P> = ({ v }) => {
  const f = useCurrentFrame();
  const w = pick(v, W, VW);
  const h = pick(v, H, VH);
  const r = lerp(pick(v, 520, 560), pick(v, 340, 370), prog(f, 0, 180, (t) => t));

  return (
    <SceneShell bg={C.ink} wipe={false} push={0.04} duration={200}>
      <Rings
        cx={w / 2}
        cy={h / 2}
        r={r}
        fill="rgba(197,231,108,0.03)"
        ring="rgba(101,142,63,0.12)"
        count={4}
      />
      <Headline
        frame={f}
        start={10}
        mode="fade"
        lines={["تنظيم رعاية الطفل،", "يتطلب الكثير من الهدوء"]}
        size={pick(v, 106, 84)}
        color={C.white}
        weight={900}
        align="center"
        lineColors={[undefined, C.lime]}
        style={{ left: 0, right: 0, top: h / 2 - pick(v, 160, 200) }}
      />
      <Caption
        frame={f}
        start={56}
        text="لتفادي الخلافات اليومية وبناء بيئة مستقرة للأبناء"
        size={pick(v, 44, 40)}
        color={C.tintDark}
        style={{ left: 0, right: 0, textAlign: "center", top: h / 2 + pick(v, 130, 140) }}
      />
    </SceneShell>
  );
};

/** Scene 2: The turn. Rings open outward on olive ground. */
const SceneB: React.FC<P> = ({ v }) => {
  const f = useCurrentFrame();
  const w = pick(v, W, VW);
  const h = pick(v, H, VH);
  const r = lerp(220, pick(v, 540, 490), prog(f, 0, 90, EASE.out));

  return (
    <SceneShell bg={C.dark} duration={200}>
      <Rings cx={w / 2} cy={h / 2} r={r} fill="rgba(197,231,108,0.05)" ring="rgba(255,255,255,0.12)" count={4} />
      <Headline
        frame={f}
        start={8}
        lines={["فمصلحة الطفل تبدأ", "بحوار واضح وبيئة يسودها الاحترام"]}
        size={pick(v, 96, 70)}
        color={C.white}
        weight={900}
        align="center"
        lineColors={[undefined, C.lime]}
        style={{ left: 0, right: 0, top: h / 2 - pick(v, 160, 180) }}
      />
      <Caption
        frame={f}
        start={48}
        text="وتنظيم مبني على الوضوح والمسؤولية المشتركة"
        size={pick(v, 48, 46)}
        color={C.tintLight}
        style={{ left: 0, right: 0, textAlign: "center", top: h / 2 + pick(v, 130, 140) }}
      />
    </SceneShell>
  );
};

/** Scene 3: Shared Calendar. */
const SceneC: React.FC<P> = ({ v }) => {
  const f = useCurrentFrame();
  const up = prog(f, 6, 40, EASE.out);

  return (
    <SceneShell bg={C.tintLight} duration={260}>
      <Rings
        cx={pick(v, 560, 540)}
        cy={pick(v, 620, 1260)}
        r={pick(v, 420, 440)}
        fill="rgba(101,142,63,0.08)"
        ring="rgba(101,142,63,0.15)"
      />
      <Headline
        frame={f}
        start={6}
        lines={["تقويم مشترك يتيح الاتفاق،", "على المواعيد دون تصادم"]}
        size={pick(v, 94, 72)}
        color={C.ink}
        weight={900}
        lineColors={[undefined, C.olive]}
        style={pick(v, { right: 130, top: 290 }, { right: 80, top: 210 })}
      />
      <Place
        x={pick(v, 560, 540)}
        y={pick(v, lerp(1500, 710, up), lerp(2400, 1320, up))}
      >
        <div style={{ filter: "drop-shadow(0 40px 60px rgba(27,36,24,0.3))" }}>
          <Phone
            src={SCREEN.calendar}
            w={pick(v, 390, 530)}
            rotateX={4}
            rotateY={pick(v, 12, 8)}
            rotateZ={2}
          />
        </div>
      </Place>
      <FloatCard
        frame={f}
        delay={26}
        from={pick(v, [1100, 900], [300, 1550])}
        to={pick(v, [1380, 810], [300, 1020])}
        rot={[0, -12, 3]}
        src={SCREEN.calendar}
        crop={CROPS.calendarVisit}
        width={pick(v, 560, 520)}
      />
    </SceneShell>
  );
};

/** Scene 4: Clear Documentation & Report. */
const SceneD: React.FC<P> = ({ v }) => {
  const f = useCurrentFrame();
  const up = prog(f, 6, 40, EASE.out);

  return (
    <SceneShell bg={C.ink} duration={230}>
      <Rings
        cx={pick(v, 560, 540)}
        cy={pick(v, 640, 1280)}
        r={pick(v, 420, 440)}
        fill="rgba(197,231,108,0.06)"
        ring="rgba(101,142,63,0.18)"
      />
      <Headline
        frame={f}
        start={6}
        lines={["وتوثيق منظم يحفظ الوقائع،", "بملفات رسمية واضحة"]}
        size={pick(v, 92, 72)}
        color={C.white}
        weight={900}
        lineColors={[undefined, C.lime]}
        style={pick(v, { right: 130, top: 270 }, { right: 80, top: 200 })}
      />
      <Caption
        frame={f}
        start={30}
        text="تقارير مدعمة بالصور ومستند PDF غير قابل للتعديل"
        size={pick(v, 42, 42)}
        color={C.tintDark}
        style={pick(v, { right: 130, top: 540 }, { right: 80, top: 460 })}
      />
      <Place
        x={pick(v, 540, 540)}
        y={pick(v, lerp(1600, 750, up), lerp(2400, 1360, up))}
      >
        <div style={{ filter: "drop-shadow(0 40px 60px rgba(0,0,0,0.45))" }}>
          <Phone
            src={SCREEN.reportSummary}
            w={pick(v, 390, 530)}
            rotateX={4}
            rotateY={pick(v, -12, -8)}
            rotateZ={-2}
          />
        </div>
      </Place>
      <FloatCard
        frame={f}
        delay={24}
        from={pick(v, [1100, 900], [780, 1550])}
        to={pick(v, [1380, 800], [780, 1080])}
        rot={[0, 12, -3]}
        src={SCREEN.reportSummary}
        crop={CROPS.reportPdfCard}
        width={pick(v, 560, 520)}
      />
    </SceneShell>
  );
};

/** Scene 5: Centers and Guidance. */
const SceneE: React.FC<P> = ({ v }) => {
  const f = useCurrentFrame();
  const up = prog(f, 6, 40, EASE.out);

  return (
    <SceneShell bg={C.tintDark} duration={200}>
      <Rings
        cx={pick(v, 560, 540)}
        cy={pick(v, 640, 1280)}
        r={pick(v, 420, 440)}
        fill="rgba(101,142,63,0.08)"
        ring="rgba(101,142,63,0.16)"
      />
      <Headline
        frame={f}
        start={6}
        lines={["ومع مكتبة تعريفية ودليل،", "للجهات المتخصصة حسب ولايتك"]}
        size={pick(v, 94, 72)}
        color={C.ink}
        weight={900}
        lineColors={[undefined, C.olive]}
        style={pick(v, { right: 130, top: 260 }, { right: 80, top: 200 })}
      />
      <Place
        x={pick(v, 540, 540)}
        y={pick(v, lerp(1600, 750, up), lerp(2400, 1360, up))}
      >
        <div style={{ filter: "drop-shadow(0 35px 55px rgba(27,36,24,0.3))" }}>
          <Phone
            src={SCREEN.centersList}
            w={pick(v, 390, 520)}
            rotateX={4}
            rotateY={6}
          />
        </div>
      </Place>
      <FloatCard
        frame={f}
        delay={22}
        from={pick(v, [1100, 900], [300, 1500])}
        to={pick(v, [1380, 800], [300, 1040])}
        rot={[0, 14, -4]}
        src={SCREEN.centersList}
        crop={CROPS.centerCard}
        width={pick(v, 560, 520)}
      />
    </SceneShell>
  );
};

/** Scene 6: Outro with CTA and Mandatory Disclaimer. */
const SceneF: React.FC<P> = ({ v }) => {
  const f = useCurrentFrame();
  const w = pick(v, W, VW);
  const h = pick(v, H, VH);
  const open = prog(f, 6, 28, EASE.out);
  const fade = prog(f, 18, 24, EASE.out);

  return (
    <SceneShell bg={C.ink} duration={STORY_TOTAL - S[5]}>
      <Rings cx={w / 2} cy={h / 2 - pick(v, 80, 120)} r={pick(v, 360, 400)} fill="rgba(197,231,108,0.06)" ring="rgba(101,142,63,0.2)" />
      <Place x={w / 2} y={h / 2 - pick(v, 200, 320)}>
        <Mark width={pick(v, 280, 340)} open={open} />
      </Place>
      <Headline
        frame={f}
        start={16}
        lines={[APP_INFO.name]}
        size={pick(v, 140, 160)}
        color={C.white}
        weight={900}
        align="center"
        style={{ left: 0, right: 0, top: h / 2 + pick(v, -60, -140) }}
      />
      <Caption
        frame={f}
        start={26}
        text={APP_INFO.tagline}
        size={pick(v, 44, 46)}
        color={C.tintDark}
        style={{ left: 0, right: 0, textAlign: "center", top: h / 2 + pick(v, 172, 150) }}
      />
      <div
        dir="rtl"
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: h / 2 + pick(v, 292, 280),
          display: "flex",
          justifyContent: "center",
          opacity: fade,
          transform: `translateY(${(1 - fade) * 16}px)`,
        }}
      >
        <div
          style={{
            background: "rgba(197,231,108,0.15)",
            border: "1.5px solid #C5E76C",
            borderRadius: 999,
            padding: "16px 42px",
            color: C.lime,
            fontFamily: SANS,
            fontSize: pick(v, 36, 38),
            fontWeight: 800,
          }}
        >
          <span>{APP_INFO.ctaText}</span>
        </div>
      </div>
      <Disclaimer size={pick(v, 24, 26)} style={{ bottom: pick(v, 35, 60) }} />
    </SceneShell>
  );
};

/* ---------------------------------------------------------------- Component */
const StoryBase: React.FC<P> = ({ v }) => {
  useBrandFonts();
  return (
    <AbsoluteFill style={{ background: C.ink }}>
      <Sequence from={S[0]} durationInFrames={S[1] - S[0] + WIPE}>
        <SceneA v={v} />
      </Sequence>
      <Sequence from={S[1]} durationInFrames={S[2] - S[1] + WIPE}>
        <SceneB v={v} />
      </Sequence>
      <Sequence from={S[2]} durationInFrames={S[3] - S[2] + WIPE}>
        <SceneC v={v} />
      </Sequence>
      <Sequence from={S[3]} durationInFrames={S[4] - S[3] + WIPE}>
        <SceneD v={v} />
      </Sequence>
      <Sequence from={S[4]} durationInFrames={S[5] - S[4] + WIPE}>
        <SceneE v={v} />
      </Sequence>
      <Sequence from={S[5]} durationInFrames={STORY_TOTAL - S[5]}>
        <SceneF v={v} />
      </Sequence>
    </AbsoluteFill>
  );
};

export const Story: React.FC = () => <StoryBase v={false} />;
export const StoryVertical: React.FC = () => <StoryBase v={true} />;
