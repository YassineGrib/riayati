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
import { APP_INFO, C, CROPS, Crop, EASE, SANS, SCREEN, SERIF, VW, WIPE } from "./theme";

export const PROBLEMS_TOTAL = 900; // 30 s
const INTRO = 75;
const PAIR = 174; // problem 60 + solution 114
const PROB = 60;
const OUTRO_AT = INTRO + PAIR * 4;

type Pair = {
  q: string;
  title: string[];
  sub: string;
  screen: string;
  card: {
    src: string;
    crop: Crop;
    w: number;
    to: [number, number];
    rot: [number, number, number];
  };
  bg: string;
  fg: string;
  accent: string;
  subColor: string;
  light: boolean;
};

const LIGHT = {
  bg: C.tintLight,
  fg: C.ink,
  accent: C.olive,
  subColor: C.textSoft,
  light: true,
};
const MID = {
  bg: C.olive,
  fg: C.white,
  accent: C.lime,
  subColor: C.tintLight,
  light: false,
};
const DARK = {
  bg: C.ink,
  fg: C.white,
  accent: C.lime,
  subColor: C.tintDark,
  light: false,
};

const PAIRS: Pair[] = [
  {
    q: "كيف أوثّق ما حدث بشكل منظم؟",
    title: ["توثيق رسمي", "غير قابل للحذف"],
    sub: "سجّل الوقائع بالمرفقات واستخرج تقرير PDF منظم",
    screen: SCREEN.reportSummary,
    card: {
      src: SCREEN.reportSummary,
      crop: CROPS.reportPdfCard,
      w: 560,
      to: [300, 1140],
      rot: [0, 12, -3],
    },
    ...LIGHT,
  },
  {
    q: "كيف ننسّق الزيارات دون خلاف؟",
    title: ["تقويم مشترك", "لتأكيد المواعيد"],
    sub: "اقتراح وتأكيد مواعيد الزيارة لتفادي أي خلاف",
    screen: SCREEN.calendar,
    card: {
      src: SCREEN.calendar,
      crop: CROPS.calendarVisit,
      w: 560,
      to: [780, 1150],
      rot: [0, -12, 3],
    },
    ...MID,
  },
  {
    q: "أين أجد الجهات المختصة؟",
    title: ["دليل المحاكم", "والهيئات المتخصصة"],
    sub: "دليل شامل حسب ولايتك مع إمكانية الاتصال المباشر",
    screen: SCREEN.centersList,
    card: {
      src: SCREEN.centersList,
      crop: CROPS.centerCard,
      w: 560,
      to: [300, 1150],
      rot: [0, 12, -3],
    },
    ...DARK,
  },
  {
    q: "من يرى بياناتي؟",
    title: ["خصوصية تامة", "وعزل كامل للبيانات"],
    sub: "كل والد يطّلع على تقاريره الخاصة فقط وبكل سرية",
    screen: SCREEN.link,
    card: {
      src: SCREEN.link,
      crop: CROPS.linkCode,
      w: 540,
      to: [780, 1140],
      rot: [0, -12, 3],
    },
    ...LIGHT,
  },
];

const Intro: React.FC = () => {
  const f = useCurrentFrame();
  return (
    <SceneShell bg={C.ink} wipe={false} push={0.04} duration={90}>
      <Rings cx={VW / 2} cy={900} r={340} fill="rgba(197,231,108,0.06)" ring="rgba(101,142,63,0.18)" />
      <Headline
        frame={f}
        start={4}
        lines={["تساؤلات حول", "تنظيم الحضانة؟"]}
        size={130}
        color={C.white}
        weight={900}
        align="center"
        lineColors={[undefined, C.lime]}
        style={{ left: 0, right: 0, top: 680 }}
      />
      <Caption
        frame={f}
        start={34}
        text="تطبيق رعايتي يقدّم الحلول العملية"
        size={54}
        color={C.tintDark}
        style={{ left: 0, right: 0, textAlign: "center", top: 1150 }}
      />
    </SceneShell>
  );
};

const Problem: React.FC<{ i: number }> = ({ i }) => {
  const f = useCurrentFrame();
  const p = PAIRS[i];
  return (
    <SceneShell bg={C.ink} duration={PROB + WIPE}>
      <Rings cx={VW / 2} cy={960} r={380} fill="rgba(197,231,108,0.04)" ring="rgba(101,142,63,0.14)" />
      <div
        dir="rtl"
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 560,
          textAlign: "center",
          fontFamily: SERIF,
          fontWeight: 900,
          fontSize: 220,
          color: C.lime,
          opacity: prog(f, 2, 18) * 0.85,
        }}
      >
        {String(i + 1).padStart(2, "0")}
      </div>
      <Headline
        frame={f}
        start={8}
        lines={[p.q]}
        size={102}
        color={C.white}
        weight={900}
        align="center"
        style={{ left: 0, right: 0, top: 880 }}
      />
    </SceneShell>
  );
};

const Solution: React.FC<{ i: number }> = ({ i }) => {
  const f = useCurrentFrame();
  const p = PAIRS[i];
  const up = prog(f, 8, 40, EASE.out);

  return (
    <SceneShell bg={p.bg} duration={114 + WIPE}>
      <Rings
        cx={VW / 2}
        cy={1280}
        r={420}
        fill={p.light ? "rgba(101,142,63,0.08)" : "rgba(255,255,255,0.06)"}
        ring={p.light ? "rgba(101,142,63,0.14)" : "rgba(255,255,255,0.14)"}
      />
      <Headline
        frame={f}
        start={6}
        lines={p.title}
        size={110}
        color={p.fg}
        weight={900}
        lineColors={[undefined, p.accent]}
        style={{ right: 90, top: 230 }}
      />
      <Caption
        frame={f}
        start={26}
        text={p.sub}
        size={42}
        color={p.subColor}
        style={{ right: 90, top: 540, maxWidth: VW - 180 }}
      />
      <Place x={VW / 2} y={lerp(2500, 1380, up)}>
        <div style={{ filter: "drop-shadow(0 40px 60px rgba(0,0,0,0.35))" }}>
          <Phone
            src={p.screen}
            w={560}
            rotateX={5}
            rotateY={i % 2 === 0 ? -7 : 7}
            rotateZ={i % 2 === 0 ? -2 : 2}
            glare={prog(f, 10, 80, (t) => t)}
          />
        </div>
      </Place>
      <FloatCard
        frame={f}
        delay={22}
        from={[VW / 2, 1700]}
        to={p.card.to}
        rot={p.card.rot}
        src={p.card.src}
        crop={p.card.crop}
        width={p.card.w}
      />
    </SceneShell>
  );
};

const Outro: React.FC = () => {
  const f = useCurrentFrame();
  const open = prog(f, 8, 28, EASE.out);

  return (
    <SceneShell bg={C.ink} duration={PROBLEMS_TOTAL - OUTRO_AT}>
      <Rings cx={VW / 2} cy={800} r={380} fill="rgba(197,231,108,0.06)" ring="rgba(101,142,63,0.2)" />
      <Place x={VW / 2} y={560}>
        <Mark width={320} open={open} />
      </Place>
      <Headline
        frame={f}
        start={20}
        lines={[APP_INFO.name]}
        size={160}
        color={C.white}
        weight={900}
        align="center"
        style={{ left: 0, right: 0, top: 780 }}
      />
      <Caption
        frame={f}
        start={34}
        text={APP_INFO.tagline}
        size={46}
        color={C.tintDark}
        style={{ left: 0, right: 0, textAlign: "center", top: 1090 }}
      />
      <div
        dir="rtl"
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: 1260,
          display: "flex",
          justifyContent: "center",
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
            fontSize: 38,
            fontWeight: 800,
          }}
        >
          <span>{APP_INFO.ctaText}</span>
        </div>
      </div>
      <Disclaimer size={26} style={{ bottom: 70 }} />
    </SceneShell>
  );
};

export const Problems: React.FC = () => {
  useBrandFonts();
  return (
    <AbsoluteFill style={{ background: C.ink }}>
      <Sequence from={0} durationInFrames={INTRO + WIPE}>
        <Intro />
      </Sequence>
      {PAIRS.map((_, i) => {
        const start = INTRO + PAIR * i;
        return (
          <React.Fragment key={i}>
            <Sequence from={start} durationInFrames={PROB + WIPE}>
              <Problem i={i} />
            </Sequence>
            <Sequence from={start + PROB} durationInFrames={114 + WIPE}>
              <Solution i={i} />
            </Sequence>
          </React.Fragment>
        );
      })}
      <Sequence from={OUTRO_AT} durationInFrames={PROBLEMS_TOTAL - OUTRO_AT}>
        <Outro />
      </Sequence>
    </AbsoluteFill>
  );
};
