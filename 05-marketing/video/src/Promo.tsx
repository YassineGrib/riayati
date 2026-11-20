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
import { APP_INFO, C, CROPS, EASE, H, PROMO_TOTAL, SANS, SCREEN, TL, VH, VW, W, WIPE } from "./theme";

type SceneProps = { v: boolean };

/** Pick value for landscape (l) or vertical (p). */
const pick = <T,>(v: boolean, l: T, p: T): T => (v ? p : l);

/* 1 · Opening ------------------------------------------------------------ */
const Opening: React.FC<SceneProps> = ({ v }) => {
  const f = useCurrentFrame();
  const w = pick(v, W, VW);
  const h = pick(v, H, VH);
  const open = prog(f, 12, 28, EASE.out);
  const out = 1 - prog(f, 58, 8, EASE.in);

  return (
    <SceneShell bg={C.ink} wipe={false} push={0.04} duration={70}>
      <Rings cx={w / 2} cy={h / 2} r={pick(v, 340, 390)} fill="rgba(197,231,108,0.05)" ring="rgba(101,142,63,0.18)" />
      <div style={{ position: "absolute", inset: 0, opacity: out }}>
        <Caption
          frame={f}
          start={4}
          text="مساحة آمنة"
          size={pick(v, 48, 54)}
          color={C.lime}
          style={{ left: 0, right: 0, textAlign: "center", top: pick(v, 140, 480) }}
        />
        <Place x={w / 2} y={pick(v, 390, 680)}>
          <Mark width={pick(v, 240, 300)} open={open} />
        </Place>
        <Headline
          frame={f}
          start={28}
          lines={[APP_INFO.name]}
          size={pick(v, 140, 170)}
          color={C.white}
          weight={900}
          align="center"
          style={{ left: 0, right: 0, top: pick(v, 520, 850) }}
        />
        <Caption
          frame={f}
          start={42}
          text="لحماية الطفل في إطار الحضانة"
          size={pick(v, 38, 42)}
          color={C.tintDark}
          style={{ left: 0, right: 0, textAlign: "center", top: pick(v, 760, 1150) }}
        />
      </div>
    </SceneShell>
  );
};

/* 2 · Intro -------------------------------------------------------------- */
const Intro: React.FC<SceneProps> = ({ v }) => {
  const f = useCurrentFrame();
  const w = pick(v, W, VW);
  const h = pick(v, H, VH);
  const p = prog(f, 8, 48, EASE.out);
  const y = pick(v, lerp(h + 700, h * 0.74, p), lerp(h + 900, 1360, p));
  const x = pick(v, lerp(300, 560, p), 540);

  return (
    <SceneShell bg={C.dark} duration={96}>
      <Rings cx={pick(v, 560, 540)} cy={pick(v, 620, 1250)} r={pick(v, 420, 430)} fill="rgba(197,231,108,0.06)" ring="rgba(255,255,255,0.12)" />
      <Place x={x} y={y}>
        <div style={{ filter: "drop-shadow(0 50px 70px rgba(10,20,10,0.5))" }}>
          <Phone
            src={SCREEN.home}
            cropH={1350}
            w={pick(v, 480, 600)}
            rotateX={6}
            rotateY={pick(v, -16, -8)}
            rotateZ={pick(v, -4, -3)}
            glare={prog(f, 10, 70, (t) => t)}
          />
        </div>
      </Place>
      <Headline
        frame={f}
        start={10}
        lines={["مساحة آمنة،", "لحماية حقوق الطفل"]}
        size={pick(v, 118, 114)}
        color={C.white}
        weight={900}
        lineColors={[undefined, C.lime]}
        style={pick(v, { right: 130, top: 260 }, { right: 80, top: 220 })}
      />
      <Caption
        frame={f}
        start={34}
        text="بيئة هادئة ومنظمة لتنظيم شؤون الحضانة بكل احترام"
        size={pick(v, 44, 46)}
        color={C.tintLight}
        style={pick(v, { right: 130, top: 620 }, { right: 80, top: 540 })}
      />
    </SceneShell>
  );
};

/* 3 · Accounts & Link --------------------------------------------------- */
const Accounts: React.FC<SceneProps> = ({ v }) => {
  const f = useCurrentFrame();
  const up = prog(f, 6, 42, EASE.out);

  return (
    <SceneShell bg={C.tintLight} duration={108}>
      <Rings
        cx={pick(v, 540, 540)}
        cy={pick(v, 640, 1260)}
        r={pick(v, 420, 440)}
        fill="rgba(101,142,63,0.08)"
        ring="rgba(101,142,63,0.14)"
      />
      <Headline
        frame={f}
        start={6}
        lines={["حسابات مستقلة،", "وربط برمز دعوة"]}
        size={pick(v, 104, 108)}
        color={C.ink}
        weight={900}
        lineColors={[undefined, C.olive]}
        style={pick(v, { right: 130, top: 240 }, { right: 80, top: 220 })}
      />
      <Caption
        frame={f}
        start={28}
        text="حساب للأب وآخر للأم، مع الحفاظ على الخصوصية التامة"
        size={pick(v, 42, 44)}
        color={C.textSoft}
        style={pick(v, { right: 130, top: 540 }, { right: 80, top: 520 })}
      />
      <Place
        x={pick(v, 540, 540)}
        y={pick(v, lerp(1500, 720, up), lerp(2400, 1340, up))}
      >
        <div style={{ filter: "drop-shadow(0 40px 60px rgba(27,36,24,0.3))" }}>
          <Phone
            src={SCREEN.link}
            w={pick(v, 420, 560)}
            rotateX={4}
            rotateY={pick(v, 14, 8)}
            rotateZ={2}
          />
        </div>
      </Place>
      <FloatCard
        frame={f}
        delay={26}
        from={pick(v, [1100, 900], [540, 1900])}
        to={pick(v, [1400, 780], [540, 1680])}
        rot={[0, -10, 2]}
        src={SCREEN.link}
        crop={CROPS.linkCode}
        width={pick(v, 480, 440)}
      />
    </SceneShell>
  );
};

/* 4 · Report & Structured PDF ------------------------------------------- */
const Report: React.FC<SceneProps> = ({ v }) => {
  const f = useCurrentFrame();
  const up = prog(f, 6, 40, EASE.out);

  return (
    <SceneShell bg={C.ink} duration={108}>
      <Rings
        cx={pick(v, 560, 540)}
        cy={pick(v, 640, 1260)}
        r={pick(v, 420, 440)}
        fill="rgba(220,38,38,0.06)"
        ring="rgba(220,38,38,0.18)"
      />
      <Headline
        frame={f}
        start={6}
        lines={["توثيق منظم،", "بتقرير رسمي"]}
        size={pick(v, 110, 112)}
        color={C.white}
        weight={900}
        lineColors={[undefined, C.lime]}
        style={pick(v, { right: 130, top: 220 }, { right: 80, top: 210 })}
      />
      <div style={pick(v, { position: "absolute", right: 130, top: 540 }, { position: "absolute", right: 80, top: 520 })}>
        <Pill text="غير قابل للحذف بعد الإرسال" color="#FCA5A5" bg="rgba(220,38,38,0.2)" border="1px solid rgba(220,38,38,0.4)" />
      </div>
      <Caption
        frame={f}
        start={30}
        text="توثيق الوقائع بالنص والصور واستخراج تقرير PDF منظم"
        size={pick(v, 38, 42)}
        color={C.tintLight}
        style={pick(v, { right: 130, top: 620 }, { right: 80, top: 590 })}
      />
      <Place
        x={pick(v, 520, 540)}
        y={pick(v, lerp(1600, 720, up), lerp(2400, 1360, up))}
      >
        <div style={{ filter: "drop-shadow(0 45px 65px rgba(0,0,0,0.5))" }}>
          <Phone
            src={SCREEN.reportSummary}
            w={pick(v, 420, 560)}
            rotateX={4}
            rotateY={pick(v, -14, -8)}
            rotateZ={-2}
          />
        </div>
      </Place>
      <FloatCard
        frame={f}
        delay={24}
        from={pick(v, [1100, 900], [540, 1900])}
        to={pick(v, [1400, 780], [540, 1680])}
        rot={[0, 10, -2]}
        src={SCREEN.reportSummary}
        crop={CROPS.reportPdfCard}
        width={pick(v, 480, 440)}
      />
    </SceneShell>
  );
};

/* 5 · Calendar ----------------------------------------------------------- */
const Calendar: React.FC<SceneProps> = ({ v }) => {
  const f = useCurrentFrame();
  const up = prog(f, 6, 40, EASE.out);

  return (
    <SceneShell bg={C.olive} duration={102}>
      <Rings
        cx={pick(v, 560, 540)}
        cy={pick(v, 640, 1260)}
        r={pick(v, 420, 440)}
        fill="rgba(255,255,255,0.06)"
        ring="rgba(255,255,255,0.14)"
      />
      <Headline
        frame={f}
        start={6}
        lines={["تقويم مشترك،", "لتنسيق الزيارات"]}
        size={pick(v, 110, 112)}
        color={C.white}
        weight={900}
        lineColors={[undefined, C.lime]}
        style={pick(v, { right: 130, top: 230 }, { right: 80, top: 220 })}
      />
      <Caption
        frame={f}
        start={28}
        text="اقتراح المواعيد وتأكيدها باحترام لتجنب الخلافات اليومية"
        size={pick(v, 40, 44)}
        color={C.tintLight}
        style={pick(v, { right: 130, top: 540 }, { right: 80, top: 520 })}
      />
      <Place
        x={pick(v, 540, 540)}
        y={pick(v, lerp(1600, 720, up), lerp(2400, 1340, up))}
      >
        <div style={{ filter: "drop-shadow(0 40px 65px rgba(20,40,15,0.4))" }}>
          <Phone
            src={SCREEN.calendar}
            w={pick(v, 420, 560)}
            rotateX={4}
            rotateY={pick(v, 12, 6)}
            rotateZ={2}
          />
        </div>
      </Place>
      <FloatCard
        frame={f}
        delay={24}
        from={pick(v, [1100, 900], [540, 1900])}
        to={pick(v, [1400, 780], [540, 1680])}
        rot={[0, -10, 2]}
        src={SCREEN.calendar}
        crop={CROPS.calendarVisit}
        width={pick(v, 480, 440)}
      />
    </SceneShell>
  );
};

/* 6 · Library & Centers -------------------------------------------------- */
const Library: React.FC<SceneProps> = ({ v }) => {
  const f = useCurrentFrame();
  const a = prog(f, 6, 42, EASE.out);
  const b = prog(f, 16, 42, EASE.out);

  return (
    <SceneShell bg={C.tintDark} duration={88}>
      <Rings
        cx={pick(v, 560, 540)}
        cy={pick(v, 640, 1280)}
        r={pick(v, 420, 440)}
        fill="rgba(101,142,63,0.09)"
        ring="rgba(101,142,63,0.16)"
      />
      <Headline
        frame={f}
        start={6}
        lines={["مكتبة توعوية،", "ودليل للهيئات"]}
        size={pick(v, 110, 108)}
        color={C.ink}
        weight={900}
        lineColors={[undefined, C.olive]}
        style={pick(v, { right: 130, top: 230, maxWidth: 800 }, { right: 80, top: 220, maxWidth: 920 })}
      />
      <Caption
        frame={f}
        start={28}
        text="إرشادات قانونية مبسطة ودليل للمحاكم والمراكز حسب ولايتك"
        size={pick(v, 38, 42)}
        color={C.textSoft}
        style={pick(v, { right: 130, top: 560, maxWidth: 800, lineHeight: 1.5 }, { right: 80, top: 540, maxWidth: 920, lineHeight: 1.5 })}
      />
      <Place
        x={pick(v, 340, 360)}
        y={pick(v, lerp(1600, 780, a), lerp(2500, 1420, a))}
      >
        <div style={{ filter: "drop-shadow(0 35px 55px rgba(27,36,24,0.3))" }}>
          <Phone
            src={SCREEN.libraryList}
            w={pick(v, 340, 440)}
            rotateX={4}
            rotateY={14}
            rotateZ={3}
          />
        </div>
      </Place>
      <Place
        x={pick(v, 720, 720)}
        y={pick(v, lerp(1700, 840, b), lerp(2600, 1500, b))}
      >
        <div style={{ filter: "drop-shadow(0 35px 55px rgba(27,36,24,0.3))" }}>
          <Phone
            src={SCREEN.centersList}
            w={pick(v, 340, 440)}
            rotateX={4}
            rotateY={-12}
            rotateZ={-3}
          />
        </div>
      </Place>
    </SceneShell>
  );
};

/* 7 · Finale with CTA & Mandatory Disclaimer ---------------------------- */
const Finale: React.FC<SceneProps> = ({ v }) => {
  const f = useCurrentFrame();
  const w = pick(v, W, VW);
  const h = pick(v, H, VH);
  const open = prog(f, 6, 28, EASE.out);
  const fade = prog(f, 18, 24, EASE.out);

  return (
    <SceneShell bg={C.ink} duration={130}>
      <Rings cx={w / 2} cy={h / 2 - pick(v, 80, 120)} r={pick(v, 360, 400)} fill="rgba(197,231,108,0.06)" ring="rgba(101,142,63,0.2)" />
      <Place x={w / 2} y={pick(v, 260, 560)}>
        <Mark width={pick(v, 220, 280)} open={open} />
      </Place>
      <Headline
        frame={f}
        start={16}
        lines={[APP_INFO.name]}
        size={pick(v, 130, 150)}
        color={C.white}
        weight={900}
        align="center"
        style={{ left: 0, right: 0, top: pick(v, 370, 740) }}
      />
      <Caption
        frame={f}
        start={26}
        text={APP_INFO.tagline}
        size={pick(v, 36, 40)}
        color={C.tintDark}
        style={{ left: 0, right: 0, textAlign: "center", top: pick(v, 600, 1040) }}
      />
      {/* CTA Box */}
      <div
        dir="rtl"
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: pick(v, 700, 1180),
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
            fontSize: pick(v, 34, 38),
            fontWeight: 800,
            display: "inline-flex",
            alignItems: "center",
            gap: 14,
            boxShadow: "0 10px 30px rgba(197,231,108,0.15)",
          }}
        >
          <span>{APP_INFO.ctaText}</span>
        </div>
      </div>
      <Disclaimer size={pick(v, 24, 26)} style={{ bottom: pick(v, 35, 60) }} />
    </SceneShell>
  );
};

/* -------------------------------------------------------- Root Promo Export */
const PromoBase: React.FC<SceneProps> = ({ v }) => {
  useBrandFonts();
  return (
    <AbsoluteFill style={{ background: C.ink }}>
      <Sequence from={TL.s1} durationInFrames={TL.s2 - TL.s1 + WIPE}>
        <Opening v={v} />
      </Sequence>
      <Sequence from={TL.s2} durationInFrames={TL.s3 - TL.s2 + WIPE}>
        <Intro v={v} />
      </Sequence>
      <Sequence from={TL.s3} durationInFrames={TL.s4 - TL.s3 + WIPE}>
        <Accounts v={v} />
      </Sequence>
      <Sequence from={TL.s4} durationInFrames={TL.s5 - TL.s4 + WIPE}>
        <Report v={v} />
      </Sequence>
      <Sequence from={TL.s5} durationInFrames={TL.s6 - TL.s5 + WIPE}>
        <Calendar v={v} />
      </Sequence>
      <Sequence from={TL.s6} durationInFrames={TL.s7 - TL.s6 + WIPE}>
        <Library v={v} />
      </Sequence>
      <Sequence from={TL.s7} durationInFrames={PROMO_TOTAL - TL.s7}>
        <Finale v={v} />
      </Sequence>
    </AbsoluteFill>
  );
};

export const Promo: React.FC = () => <PromoBase v={false} />;
export const PromoVertical: React.FC = () => <PromoBase v={true} />;
