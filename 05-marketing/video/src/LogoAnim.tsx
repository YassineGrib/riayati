import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { Caption, Headline, Mark, Place, Rings, prog, useBrandFonts } from "./kit";
import { APP_INFO, C, EASE, SANS } from "./theme";

/** 5 s square logo reveal (1080x1080), light or dark. */
export const LogoAnim: React.FC<{ dark: boolean }> = ({ dark }) => {
  useBrandFonts();
  const f = useCurrentFrame();
  const open = prog(f, 8, 40, EASE.out);
  const bg = dark ? C.ink : C.tintLight;
  const fg = dark ? C.white : C.ink;
  const fade = interpolate(f, [130, 150], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const rr = 300 + prog(f, 0, 120, EASE.out) * 40;

  return (
    <AbsoluteFill style={{ background: bg, fontFamily: SANS, direction: "rtl" }}>
      <Rings
        cx={540}
        cy={470}
        r={rr}
        fill={dark ? "rgba(197,231,108,0.06)" : "rgba(101,142,63,0.08)"}
        ring={dark ? "rgba(101,142,63,0.18)" : "rgba(101,142,63,0.14)"}
      />
      <Place x={540} y={440}>
        <Mark width={380} open={open} dark={dark} />
      </Place>
      <Headline
        frame={f}
        start={36}
        lines={[APP_INFO.name]}
        size={190}
        color={fg}
        weight={900}
        align="center"
        style={{ left: 0, right: 0, top: 590 }}
      />
      <Caption
        frame={f}
        start={58}
        text={APP_INFO.tagline}
        size={44}
        color={dark ? C.lime : C.textSoft}
        style={{ left: 0, right: 0, textAlign: "center", top: 850 }}
      />
      <AbsoluteFill style={{ background: bg, opacity: fade }} />
    </AbsoluteFill>
  );
};
