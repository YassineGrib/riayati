import React from "react";
import { AbsoluteFill, Sequence, useCurrentFrame } from "remotion";
import {
  Caption,
  Disclaimer,
  FloatCard,
  Headline,
  Mark,
  Phone,
  Pill,
  Place,
  Rings,
  SceneShell,
  lerp,
  prog,
  useBrandFonts,
} from "./kit";
import { APP_INFO, C, CROPS, Crop, EASE, SANS, SCREEN, SERIF, VH, VW, WIPE } from "./theme";

export const HOWTO_TOTAL = 960; // 32 s
const INTRO = 90;
const STEP = 126;
const OUTRO_AT = INTRO + STEP * 6;

type StepDef = {
  num: string;
  title: string;
  sub: string;
  screen: string;
  card: {
    src: string;
    crop: Crop;
    w: number;
    to: [number, number];
    from: [number, number];
    rot: [number, number, number];
  };
  bg: string;
  fg: string;
  accent: string;
  subColor: string;
  ring: string;
};

const LIGHT = {
  bg: C.tintLight,
  fg: C.ink,
  accent: C.olive,
  subColor: C.textSoft,
  ring: "rgba(101,142,63,0.12)",
};
const MID = {
  bg: C.olive,
  fg: C.white,
  accent: C.lime,
  subColor: C.tintLight,
  ring: "rgba(255,255,255,0.14)",
};
const DARK = {
  bg: C.ink,
  fg: C.white,
  accent: C.lime,
  subColor: C.tintDark,
  ring: "rgba(197,231,108,0.15)",
};

const STEPS: StepDef[] = [
  {
    num: "٠١",
    title: "حمّل التطبيق",
    sub: "حمّل النسخة التجريبية لأندرويد مباشرة من موقعنا",
    screen: SCREEN.welcome,
    card: {
      src: SCREEN.welcome,
      crop: CROPS.homeQuick,
      w: 560,
      from: [540, 1700],
      to: [300, 1100],
      rot: [0, 12, -3],
    },
    ...LIGHT,
  },
  {
    num: "٠٢",
    title: "أنشئ حسابك",
    sub: "أنشئ حسابك كأب أو كأم لحماية حقوق طفلك",
    screen: SCREEN.profile,
    card: {
      src: SCREEN.profile,
      crop: CROPS.profileCard,
      w: 560,
      from: [540, 1700],
      to: [780, 1150],
      rot: [0, -12, 3],
    },
    ...MID,
  },
  {
    num: "٠٣",
    title: "اربط الطرف الآخر",
    sub: "تبادلا رمز دعوة آمن لتفعيل التقويم المشترك",
    screen: SCREEN.link,
    card: {
      src: SCREEN.link,
      crop: CROPS.linkCode,
      w: 540,
      from: [540, 1700],
      to: [300, 1130],
      rot: [0, 12, -3],
    },
    ...DARK,
  },
  {
    num: "٠٤",
    title: "وثّق أي واقعة",
    sub: "سجّل الوقائع بالصور والمرفقات بتقرير لا يُحذف",
    screen: SCREEN.reportSummary,
    card: {
      src: SCREEN.reportSummary,
      crop: CROPS.reportPdfCard,
      w: 560,
      from: [540, 1700],
      to: [780, 1180],
      rot: [0, -12, 3],
    },
    ...LIGHT,
  },
  {
    num: "٠٥",
    title: "نظّم الزيارات",
    sub: "اقترح مواعيد الزيارة وأكدها لتفادي الخلافات",
    screen: SCREEN.calendar,
    card: {
      src: SCREEN.calendar,
      crop: CROPS.calendarVisit,
      w: 560,
      from: [540, 1700],
      to: [300, 1180],
      rot: [0, 12, -3],
    },
    ...MID,
  },
  {
    num: "٠٦",
    title: "المكتبة ودليل المراكز",
    sub: "إرشادات قانونية ودليل للهيئات المتخصصة حسب ولايتك",
    screen: SCREEN.centersList,
    card: {
      src: SCREEN.centersList,
      crop: CROPS.centerCard,
      w: 560,
      from: [540, 1700],
      to: [780, 1150],
      rot: [0, -12, 3],
    },
    ...DARK,
  },
];

const Intro: React.FC = () => {
  const f = useCurrentFrame();
  const open = prog(f, 8, 26, EASE.out);

  return (
    <SceneShell bg={C.ink} wipe={false} push={0.04} duration={100}>
      <Rings cx={VW / 2} cy={540} r={330} fill="rgba(197,231,108,0.06)" ring="rgba(101,142,63,0.18)" />
      <Place x={VW / 2} y={450}>
        <Mark width={300} open={open} />
      </Place>
      <Headline
        frame={f}
        start={26}
        lines={["كيف تبدأ مع", "تطبيق رعايتي؟"]}
        size={118}
        color={C.white}
        weight={900}
        align="center"
        lineColors={[undefined, C.lime]}
        style={{ left: 0, right: 0, top: 780 }}
      />
      <Caption
        frame={f}
        start={54}
        text="٦ خطوات مبسطة لتنظيم الحضانة"
        size={50}
        color={C.tintDark}
        style={{ left: 0, right: 0, textAlign: "center", top: 1140 }}
      />
    </SceneShell>
  );
};

const Step: React.FC<{ i: number }> = ({ i }) => {
  const f = useCurrentFrame();
  const s = STEPS[i];
  const up = prog(f, 8, 40, EASE.out);

  return (
    <SceneShell bg={s.bg} duration={STEP + WIPE}>
      <Rings
        cx={VW / 2}
        cy={1280}
        r={420}
        fill={s.bg === C.tintLight ? "rgba(101,142,63,0.08)" : "rgba(255,255,255,0.06)"}
        ring={s.ring}
      />
      {/* 6 progress segments at top */}
      <div
        dir="rtl"
        style={{
          position: "absolute",
          left: 90,
          right: 90,
          top: 110,
          display: "flex",
          gap: 14,
        }}
      >
        {STEPS.map((_, k) => (
          <div
            key={k}
            style={{
              flex: 1,
              height: 8,
              borderRadius: 8,
              background: "rgba(0,0,0,0.15)",
              overflow: "hidden",
            }}
          >
            <div
              style={{
                width: `${k < i ? 100 : k === i ? prog(f, 0, STEP, (t) => t) * 100 : 0}%`,
                height: "100%",
                background: s.accent,
                float: "right",
              }}
            />
          </div>
        ))}
      </div>

      {/* Step number badge */}
      <div
        style={{
          position: "absolute",
          right: 90,
          top: 170,
        }}
      >
        <Pill text={`خطوة ${s.num}`} color={s.accent} bg="rgba(0,0,0,0.12)" border={`1px solid ${s.accent}`} size={32} />
      </div>

      <Headline
        frame={f}
        start={6}
        lines={[s.title]}
        size={110}
        color={s.fg}
        weight={900}
        style={{ right: 90, top: 250 }}
      />
      <Caption
        frame={f}
        start={26}
        text={s.sub}
        size={42}
        color={s.subColor}
        style={{ right: 90, top: 520, maxWidth: VW - 180 }}
      />

      {/* Phone Mockup */}
      <Place x={VW / 2} y={lerp(2500, 1380, up)}>
        <div style={{ filter: "drop-shadow(0 40px 60px rgba(0,0,0,0.35))" }}>
          <Phone
            src={s.screen}
            w={560}
            rotateX={5}
            rotateY={i % 2 === 0 ? -7 : 7}
            rotateZ={i % 2 === 0 ? -2 : 2}
            glare={prog(f, 10, 80, (t) => t)}
          />
        </div>
      </Place>

      {/* Floating Card */}
      <FloatCard
        frame={f}
        delay={22}
        from={s.card.from}
        to={s.card.to}
        rot={s.card.rot}
        src={s.card.src}
        crop={s.card.crop}
        width={s.card.w}
      />
    </SceneShell>
  );
};

const Outro: React.FC = () => {
  const f = useCurrentFrame();
  const open = prog(f, 8, 28, EASE.out);

  return (
    <SceneShell bg={C.ink} duration={HOWTO_TOTAL - OUTRO_AT}>
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
      {/* CTA Button */}
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

export const HowTo: React.FC = () => {
  useBrandFonts();
  return (
    <AbsoluteFill style={{ background: C.ink }}>
      <Sequence from={0} durationInFrames={INTRO + WIPE}>
        <Intro />
      </Sequence>
      {STEPS.map((_, i) => (
        <Sequence
          key={i}
          from={INTRO + STEP * i}
          durationInFrames={STEP + WIPE}
        >
          <Step i={i} />
        </Sequence>
      ))}
      <Sequence from={OUTRO_AT} durationInFrames={HOWTO_TOTAL - OUTRO_AT}>
        <Outro />
      </Sequence>
    </AbsoluteFill>
  );
};
