import React from "react";
import { AbsoluteFill } from "remotion";
import {
  Caption,
  Disclaimer,
  FloatCard,
  Fragment,
  Headline,
  Mark,
  Phone,
  Pill,
  Place,
  Rings,
  useBrandFonts,
} from "./kit";
import { APP_INFO, C, CROPS, Crop, SANS, SCREEN, SERIF } from "./theme";

/** Static marketing artwork.
 * Post = 1080x1350 (feed 4:5)
 * Story = 1080x1920 (9:16, safe area ≈ 260px top / 220px bottom)
 */
export const POST_SIZE = { width: 1080, height: 1350 } as const;
export const STORY_SIZE = { width: 1080, height: 1920 } as const;

type Card = {
  src: string;
  crop: Crop;
  w: [number, number]; // [post, story]
  at: [[number, number], [number, number]];
  rot: [number, number, number];
};

type Design = {
  bg: string;
  fg: string;
  accent: string;
  sub: string;
  lines: string[];
  caption: string;
  pill?: string;
  screens: string[];
  cards: Card[];
  light?: boolean;
};

const DESIGNS: Design[] = [
  // 1 · Intro / Brand
  {
    bg: C.dark,
    fg: C.white,
    accent: C.lime,
    sub: C.tintLight,
    lines: ["مساحة آمنة،", "لحماية حقوق الطفل"],
    caption: "تطبيق ينظم شؤون الحضانة بروح المسؤولية والاحترام",
    screens: [SCREEN.home],
    cards: [
      {
        src: SCREEN.home,
        crop: CROPS.homeSos,
        w: [480, 520],
        at: [[280, 1010], [280, 1340]],
        rot: [0, 12, -4],
      },
    ],
  },
  // 2 · Incident Reports & PDF
  {
    bg: C.ink,
    fg: C.white,
    accent: C.lime,
    sub: C.tintDark,
    lines: ["توثيق منظم،", "بتقرير رسمي موثق"],
    caption: "إرفاق الصور والمستندات واستخراج PDF غير قابل للتعديل",
    pill: "غير قابل للحذف بعد الإرسال",
    screens: [SCREEN.reportSummary],
    cards: [
      {
        src: SCREEN.reportSummary,
        crop: CROPS.reportPdfCard,
        w: [520, 560],
        at: [[760, 1000], [770, 1330]],
        rot: [0, -12, 3],
      },
    ],
  },
  // 3 · Shared Calendar
  {
    bg: C.olive,
    fg: C.white,
    accent: C.lime,
    sub: C.tintLight,
    lines: ["تقويم مشترك،", "لتنسيق الزيارات"],
    caption: "اقتراح وتأكيد مواعيد الزيارة لتفادي الخلافات اليومية",
    screens: [SCREEN.calendar],
    cards: [
      {
        src: SCREEN.calendar,
        crop: CROPS.calendarVisit,
        w: [500, 540],
        at: [[290, 1010], [290, 1340]],
        rot: [0, 12, -3],
      },
    ],
  },
  // 4 · Educational Library
  {
    bg: C.tintLight,
    fg: C.ink,
    accent: C.olive,
    sub: C.textSoft,
    lines: ["مكتبة توعوية،", "لإرشاد الوالدين"],
    caption: "مقالات وأدلة تعريفية مبسطة للإرشاد الأولي، بلغة واضحة",
    screens: [SCREEN.libraryList],
    light: true,
    cards: [
      {
        src: SCREEN.libraryList,
        crop: CROPS.libraryCard,
        w: [500, 540],
        at: [[760, 1010], [760, 1340]],
        rot: [0, -12, 3],
      },
    ],
  },
  // 5 · Specialized Centers Directory
  {
    bg: C.tintDark,
    fg: C.ink,
    accent: C.olive,
    sub: C.textSoft,
    lines: ["دليل الهيئات،", "والمحاكم المختصة"],
    caption: "دليل للجهات المتخصصة حسب ولايتك، مع اتصال مباشر من التطبيق",
    screens: [SCREEN.centersList],
    light: true,
    cards: [
      {
        src: SCREEN.centersList,
        crop: CROPS.centerCard,
        w: [500, 540],
        at: [[290, 1010], [290, 1340]],
        rot: [0, 12, -3],
      },
    ],
  },
  // 6 · Privacy & Data Isolation
  {
    bg: C.darkDeep,
    fg: C.white,
    accent: C.lime,
    sub: C.tintDark,
    lines: ["خصوصية تامة،", "وعزل كامل للبيانات"],
    caption: "كل والد يطّلع على تقاريره الخاصة فقط، وبسرية تامة",
    screens: [SCREEN.link],
    cards: [
      {
        src: SCREEN.link,
        crop: CROPS.linkCode,
        w: [500, 540],
        at: [[770, 1000], [770, 1330]],
        rot: [0, -12, 3],
      },
    ],
  },
];

const Art: React.FC<{ d: Design; isStory: boolean }> = ({ d, isStory }) => {
  useBrandFonts();
  const W = 1080;
  const H = isStory ? 1920 : 1350;

  // Safe area margins: in Stories, keep text comfortably inside (>= 280px from top, >= 220px from bottom)
  const topPad = isStory ? 280 : 140;
  const bottomPad = isStory ? 230 : 90;

  // The phone emerges from a flat bottom bar that carries the call to action and the disclaimer.
  const barH = isStory ? 380 : 200;
  const phoneW = isStory ? 600 : 470;
  const phoneX = 540;
  const phoneTop = isStory ? 820 : 600;
  const phoneY = phoneTop + (phoneW * 2.25) / 2;

  return (
    <AbsoluteFill
      style={{
        background: d.bg,
        fontFamily: SANS,
        direction: "rtl",
        overflow: "hidden",
      }}
    >
      {/* Decorative Rings */}
      <Rings
        cx={540}
        cy={isStory ? 1150 : 860}
        r={isStory ? 430 : 360}
        fill={d.light ? "rgba(101,142,63,0.06)" : "rgba(197,231,108,0.05)"}
        ring={d.light ? "rgba(101,142,63,0.12)" : "rgba(255,255,255,0.12)"}
      />

      {/* Top Brand Bar */}
      <div
        dir="rtl"
        style={{
          position: "absolute",
          top: isStory ? 140 : 60,
          right: 90,
          left: 90,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <Mark width={64} />
          <span
            style={{
              fontFamily: SERIF,
              fontSize: 34,
              fontWeight: 900,
              color: d.fg,
            }}
          >
            {APP_INFO.name}
          </span>
        </div>
        {d.pill ? (
          <Pill
            text={d.pill}
            color={d.accent}
            bg="rgba(0,0,0,0.15)"
            border={`1px solid ${d.accent}`}
            size={24}
          />
        ) : (
          <span
            style={{
              fontFamily: SANS,
              fontSize: 22,
              fontWeight: 600,
              color: d.sub,
            }}
          >
            {APP_INFO.ctaUrl}
          </span>
        )}
      </div>

      {/* Headline (within safe bounds) */}
      <Headline
        frame={999}
        start={0}
        lines={d.lines}
        size={isStory ? 104 : 96}
        color={d.fg}
        weight={900}
        lineColors={[undefined, d.accent]}
        style={{
          right: 90,
          left: 90,
          top: topPad,
        }}
      />

      {/* Caption */}
      <Caption
        frame={999}
        start={0}
        text={d.caption}
        size={isStory ? 40 : 36}
        color={d.sub}
        style={{
          right: 90,
          left: 90,
          top: topPad + (isStory ? 380 : 330),
        }}
      />

      {/* 3D Phone Mockup */}
      <Place x={phoneX} y={phoneY}>
        <div style={{ filter: "drop-shadow(0 40px 60px rgba(0,0,0,0.38))" }}>
          <Phone
            src={d.screens[0]}
            w={phoneW}
            rotateX={0}
            rotateY={0}
            rotateZ={0}
            glare={0.2}
          />
        </div>
      </Place>

      {/* Floating Card */}
      {[].map((c: Card, i: number) => {
        const [atX, atY] = isStory ? c.at[1] : c.at[0];
        const [rx, ry, rz] = c.rot;
        const w = isStory ? c.w[1] : c.w[0];
        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: atX,
              top: atY,
              transform: `translate(-50%, -50%) perspective(1200px) rotateX(${rx}deg) rotateY(${ry}deg) rotateZ(${rz}deg)`,
            }}
          >
            <Fragment src={c.src} crop={c.crop} w={w} />
          </div>
        );
      })}

      {/* Bottom CTA & Disclaimer inside safe area */}
      <div
        dir="rtl"
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          bottom: 0,
          height: barH,
          background: d.bg,
          borderTop: `1px solid ${d.light ? "rgba(27,36,24,0.12)" : "rgba(255,255,255,0.14)"}`,
          padding: isStory ? "44px 90px 0" : "34px 90px 0",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 16,
        }}
      >
        <div
          style={{
            background: d.light ? "rgba(101,142,63,0.12)" : "rgba(197,231,108,0.16)",
            border: `1.5px solid ${d.accent}`,
            borderRadius: 999,
            padding: "12px 36px",
            color: d.accent,
            fontFamily: SANS,
            fontSize: 30,
            fontWeight: 800,
            boxShadow: "0 8px 24px rgba(0,0,0,0.12)",
          }}
        >
          <span>{APP_INFO.ctaText}</span>
        </div>
        <span
          style={{
            fontFamily: SANS,
            fontSize: 20,
            fontWeight: 400,
            color: d.sub,
            textAlign: "center",
            lineHeight: 1.3,
          }}
        >
          {APP_INFO.disclaimer}
        </span>
      </div>
    </AbsoluteFill>
  );
};

/* Posts (1080x1350) */
export const Post1: React.FC = () => <Art d={DESIGNS[0]} isStory={false} />;
export const Post2: React.FC = () => <Art d={DESIGNS[1]} isStory={false} />;
export const Post3: React.FC = () => <Art d={DESIGNS[2]} isStory={false} />;
export const Post4: React.FC = () => <Art d={DESIGNS[3]} isStory={false} />;
export const Post5: React.FC = () => <Art d={DESIGNS[4]} isStory={false} />;
export const Post6: React.FC = () => <Art d={DESIGNS[5]} isStory={false} />;

/* Stories (1080x1920) */
export const Story1: React.FC = () => <Art d={DESIGNS[0]} isStory={true} />;
export const Story2: React.FC = () => <Art d={DESIGNS[1]} isStory={true} />;
export const Story3: React.FC = () => <Art d={DESIGNS[2]} isStory={true} />;
export const Story4: React.FC = () => <Art d={DESIGNS[3]} isStory={true} />;
export const Story5: React.FC = () => <Art d={DESIGNS[4]} isStory={true} />;
export const Story6: React.FC = () => <Art d={DESIGNS[5]} isStory={true} />;
