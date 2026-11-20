import React, { createContext, useContext, useEffect, useState } from "react";
import {
  Img,
  continueRender,
  delayRender,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
} from "remotion";
import { APP_INFO, C, Crop, EASE, FPS, SANS, SERIF, SRC_H, SRC_W, WIPE } from "./theme";

/* ------------------------------------------------------------------ helpers */
export const clamp = (v: number, a = 0, b = 1) => Math.min(b, Math.max(a, v));
export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

export const prog = (
  frame: number,
  start: number,
  dur: number,
  easing: (t: number) => number = EASE.out,
) =>
  interpolate(frame, [start, start + dur], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing,
  });

export const pop = (frame: number, delay: number, damping = 15, stiffness = 120) =>
  spring({ frame: frame - delay, fps: FPS, config: { damping, stiffness, mass: 0.85 } });

/* -------------------------------------------------------------------- fonts */
const FACES: [string, string, string][] = [
  ["Thmanyah Sans", "400", "thmanyahsans-Regular.woff2"],
  ["Thmanyah Sans", "500", "thmanyahsans-Medium.woff2"],
  ["Thmanyah Sans", "700", "thmanyahsans-Bold.woff2"],
  ["Thmanyah Sans", "900", "thmanyahsans-Black.woff2"],
  ["Thmanyah Serif Display", "700", "thmanyahserifdisplay-Bold.woff2"],
  ["Thmanyah Serif Display", "900", "thmanyahserifdisplay-Black.woff2"],
  ["Thmanyah Serif Text", "400", "thmanyahseriftext-Regular.woff2"],
  ["Thmanyah Serif Text", "700", "thmanyahseriftext-Bold.woff2"],
];

export const useBrandFonts = () => {
  const [handle] = useState(() => delayRender("Loading Thmanyah"));
  useEffect(() => {
    Promise.all(
      FACES.map(([family, weight, file]) =>
        new FontFace(family, `url(${staticFile(`fonts/${file}`)}) format('woff2')`, { weight })
          .load()
          .then((f) => (document.fonts as unknown as { add(f: FontFace): void }).add(f)),
      ),
    )
      .then(() => continueRender(handle))
      .catch(() => continueRender(handle));
  }, [handle]);
};

/* -------------------------------------------------------------- scene shell */
export const SceneLengthContext = createContext<number | undefined>(undefined);

/** Full-frame scene background; reveals through a slanted wipe travelling right -> left. */
export const SceneShell: React.FC<{
  bg: string;
  wipe?: boolean;
  push?: number;
  duration?: number;
  children: React.ReactNode;
}> = ({ bg, wipe = true, push = 0.03, duration = 100, children }) => {
  const frame = useCurrentFrame();
  const p = wipe ? prog(frame, 0, WIPE, EASE.inOut) : 1;
  const edge = 114 - 132 * p;
  const clip = p >= 1 ? undefined : `polygon(${edge}% 0%, 101% 0%, 101% 100%, ${edge - 14}% 100%)`;
  const len = useContext(SceneLengthContext);
  const scale = 1 + push * prog(frame, 0, len ?? duration, (t) => t);
  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        background: bg,
        clipPath: clip,
        overflow: "hidden",
        fontFamily: SANS,
        direction: "rtl",
      }}
    >
      <div style={{ position: "absolute", inset: 0, transform: `scale(${scale})` }}>
        {children}
      </div>
    </div>
  );
};

/** Decorative hero circle with thin concentric rings (Riayati circular emblem motif). */
export const Rings: React.FC<{
  cx: number;
  cy: number;
  r: number;
  fill?: string;
  ring?: string;
  count?: number;
}> = ({
  cx,
  cy,
  r,
  fill = "rgba(197,231,108,0.06)",
  ring = "rgba(101,142,63,0.12)",
  count = 3,
}) => (
  <>
    <div
      style={{
        position: "absolute",
        left: cx - r,
        top: cy - r,
        width: r * 2,
        height: r * 2,
        borderRadius: "50%",
        background: fill,
      }}
    />
    {Array.from({ length: count }).map((_, i) => {
      const rr = r * (1.18 + i * 0.22);
      return (
        <div
          key={i}
          style={{
            position: "absolute",
            left: cx - rr,
            top: cy - rr,
            width: rr * 2,
            height: rr * 2,
            borderRadius: "50%",
            border: `2px solid ${ring}`,
          }}
        />
      );
    })}
  </>
);

/* -------------------------------------------------------------------- phone */
const RATIO = SRC_H / SRC_W; // 2400 / 1080 = 2.222

export const Phone: React.FC<{
  src: string;
  w: number;
  cropH?: number;
  rotateX?: number;
  rotateY?: number;
  rotateZ?: number;
  glare?: number;
  children?: React.ReactNode;
}> = ({ src, w, cropH, rotateX = 0, rotateY = 0, rotateZ = 0, glare = 0.5, children }) => {
  // Default to 2140 to crop out bottom navigation bar (and assistant tab) completely
  const visibleSrcH = cropH ?? 2140;
  const screenH = w * (visibleSrcH / SRC_W);
  const bezel = w * 0.028;
  const rScreen = w * 0.095;
  const rBody = rScreen + bezel;
  const transform = `perspective(1800px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) rotateZ(${rotateZ}deg)`;

  return (
    <div
      style={{
        width: w + bezel * 2,
        height: screenH + bezel * 2,
        borderRadius: rBody,
        padding: bezel,
        background: "linear-gradient(145deg, #384A32 0%, #151D12 50%, #2A3626 100%)",
        boxShadow:
          "0 45px 75px -15px rgba(27,36,24,0.45), 0 20px 35px -10px rgba(0,0,0,0.3), inset 0 1px 2px rgba(255,255,255,0.22)",
        transform,
        transformStyle: "preserve-3d",
        position: "relative",
      }}
    >
      {/* Screen container */}
      <div
        style={{
          width: w,
          height: screenH,
          borderRadius: rScreen,
          overflow: "hidden",
          position: "relative",
          background: C.tintLight,
        }}
      >
        <Img
          src={staticFile(src)}
          style={{
            position: "absolute",
            left: 0,
            top: 0,
            width: w,
            height: w * (SRC_H / SRC_W),
            display: "block",
          }}
        />
        {/* Dynamic glossy glare reflection */}
        {glare > 0 && (
          <div
            style={{
              position: "absolute",
              inset: 0,
              background: `linear-gradient(${115 + glare * 15}deg, rgba(255,255,255,${0.25 * glare}) 0%, rgba(255,255,255,0) 45%)`,
              pointerEvents: "none",
            }}
          />
        )}
        {children}
      </div>
    </div>
  );
};

/* ----------------------------------------------------------- fragment & card */
export const Fragment: React.FC<{
  src: string;
  crop: Crop;
  w: number;
  radius?: number;
  border?: string;
  shadow?: string;
}> = ({
  src,
  crop: [cx, cy, cw, ch],
  w,
  radius = 24,
  border = `1px solid ${C.borderSoft}`,
  shadow = "0 30px 50px -10px rgba(27,36,24,0.25)",
}) => {
  const scale = w / cw;
  const h = ch * scale;
  return (
    <div
      style={{
        width: w,
        height: h,
        borderRadius: radius,
        overflow: "hidden",
        position: "relative",
        border,
        boxShadow: shadow,
        background: C.white,
      }}
    >
      <Img
        src={staticFile(src)}
        style={{
          position: "absolute",
          left: -cx * scale,
          top: -cy * scale,
          width: SRC_W * scale,
          height: SRC_H * scale,
          maxWidth: "none",
        }}
      />
    </div>
  );
};

export const FloatCard: React.FC<{
  frame: number;
  delay: number;
  from: [number, number];
  to: [number, number];
  rot?: [number, number, number];
  src: string;
  crop: Crop;
  width: number;
  phase?: number;
}> = ({ frame, delay, from, to, rot = [0, 0, 0], src, crop, width, phase = 0 }) => {
  const p = prog(frame, delay, 28, EASE.out);
  const x = lerp(from[0], to[0], p);
  const y = lerp(from[1], to[1], p);
  // Soft gentle bobbing motion
  const bob = Math.sin((frame + phase * 20) * 0.05) * 6;
  const [rx, ry, rz] = rot;

  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y + bob,
        transform: `translate(-50%, -50%) perspective(1200px) rotateX(${rx}deg) rotateY(${ry}deg) rotateZ(${rz}deg)`,
        opacity: p,
      }}
    >
      <Fragment src={src} crop={crop} w={width} />
    </div>
  );
};

/* ---------------------------------------------------------------- typography */
export const Headline: React.FC<{
  frame: number;
  start: number;
  lines: string[];
  size?: number;
  color?: string;
  weight?: number;
  align?: "right" | "center" | "left";
  lineColors?: (string | undefined)[];
  style?: React.CSSProperties;
  mode?: "stagger" | "fade";
}> = ({
  frame,
  start,
  lines,
  size = 110,
  color = C.white,
  weight = 900,
  align = "right",
  lineColors,
  style,
  mode = "stagger",
}) => {
  const lineH = size * 1.22;
  const paddingBottom = size * 0.36; // Extra bottom padding: Arabic dots never clipped!

  return (
    <div
      dir="rtl"
      style={{
        position: "absolute",
        fontFamily: SERIF,
        fontSize: size,
        fontWeight: weight,
        lineHeight: `${lineH}px`,
        textAlign: align,
        color,
        letterSpacing: "-0.01em",
        ...style,
      }}
    >
      {lines.map((line, i) => {
        const lineCol = (lineColors && lineColors[i]) || color;
        if (mode === "fade") {
          const p = prog(frame, start + i * 8, 22, EASE.out);
          return (
            <div
              key={i}
              style={{
                color: lineCol,
                opacity: p,
                paddingBottom,
                transform: `translateY(${(1 - p) * 16}px)`,
              }}
            >
              {line}
            </div>
          );
        }
        // Staggered word animation
        const words = line.split(" ");
        return (
          <div
            key={i}
            style={{
              overflow: "hidden",
              paddingBottom,
              color: lineCol,
            }}
          >
            {words.map((w, j) => {
              const delay = start + i * 10 + j * 4;
              const p = prog(frame, delay, 20, EASE.out);
              return (
                <span
                  key={j}
                  style={{
                    display: "inline-block",
                    transform: `translateY(${(1 - p) * 110}%)`,
                    opacity: p,
                    marginInlineEnd: "0.26em",
                  }}
                >
                  {w}
                </span>
              );
            })}
          </div>
        );
      })}
    </div>
  );
};

export const Caption: React.FC<{
  frame: number;
  start: number;
  text: string;
  size?: number;
  color?: string;
  style?: React.CSSProperties;
}> = ({ frame, start, text, size = 44, color = C.tintDark, style }) => {
  const p = prog(frame, start, 22, EASE.out);
  return (
    <div
      dir="rtl"
      style={{
        position: "absolute",
        fontFamily: SANS,
        fontSize: size,
        fontWeight: 500,
        lineHeight: 1.45,
        color,
        opacity: p,
        transform: `translateY(${(1 - p) * 18}px)`,
        paddingBottom: size * 0.30,
        ...style,
      }}
    >
      {text}
    </div>
  );
};

export const Pill: React.FC<{
  text: string;
  color?: string;
  bg?: string;
  border?: string;
  size?: number;
}> = ({
  text,
  color = C.lime,
  bg = "rgba(197,231,108,0.12)",
  border = "1px solid rgba(197,231,108,0.25)",
  size = 28,
}) => (
  <span
    dir="rtl"
    style={{
      display: "inline-flex",
      alignItems: "center",
      gap: 8,
      padding: "6px 18px",
      borderRadius: 999,
      fontFamily: SANS,
      fontSize: size,
      fontWeight: 700,
      color,
      background: bg,
      border,
    }}
  >
    {text}
  </span>
);

export const Disclaimer: React.FC<{
  color?: string;
  size?: number;
  style?: React.CSSProperties;
}> = ({ color = "rgba(255,255,255,0.65)", size = 24, style }) => (
  <div
    dir="rtl"
    style={{
      position: "absolute",
      left: 60,
      right: 60,
      bottom: 35,
      textAlign: "center",
      fontFamily: SANS,
      fontSize: size,
      fontWeight: 400,
      color,
      lineHeight: 1.4,
      ...style,
    }}
  >
    {APP_INFO.disclaimer}
  </div>
);

/* ------------------------------------------------------------- logo & layout */
export const Place: React.FC<{
  x: number;
  y: number;
  children: React.ReactNode;
}> = ({ x, y, children }) => (
  <div
    style={{
      position: "absolute",
      left: x,
      top: y,
      transform: "translate(-50%, -50%)",
    }}
  >
    {children}
  </div>
);

/** Riayati SVG emblem with smooth opening animation. */
export const Mark: React.FC<{
  width: number;
  open?: number;
  dark?: boolean;
}> = ({ width, open = 1, dark = false }) => {
  const height = width * (295 / 350);
  const scale = clamp(open, 0, 1);
  const opacity = clamp(open * 1.5, 0, 1);

  return (
    <div
      style={{
        width,
        height,
        position: "relative",
        transform: `scale(${scale})`,
        opacity,
      }}
    >
      <svg
        viewBox="225 314 350 295"
        width={width}
        height={height}
        style={{ display: "block" }}
      >
        <g id="olive-ribbons" fill={C.olive}>
          <path
            d="M 268.8,503.7
              C 279.5,516.3 295.7,523.4 311.2,522.8
              C 329.1,522.1 344.6,513.2 359.2,498.5
              L 376.7,528.7
              C 354.5,548.5 329.4,557.1 304.5,557.1
              C 278.5,557.1 265.2,551.6 263.8,526.3
              C 263.1,517.5 264.6,509.5 268.8,503.7 Z"
          />
          <path
            d="M 370.6,483.3
              C 391.5,449.0 415.1,424.2 445.2,417.0
              C 472.9,410.5 500.4,441.3 506.2,462.8
              C 508.6,471.2 508.4,480.2 506.2,486.1
              C 496.8,477.2 484.5,473.5 470.8,473.5
              C 443.1,473.5 420.4,487.9 397.3,510.9 Z"
          />
        </g>
        <g id="lime-elements" fill={C.lime}>
          <path
            d="M 445.2,417.0
              C 452.2,415.1 459.9,414.5 467.7,414.5
              C 516.1,414.5 554.9,453.2 554.9,501.9
              C 554.9,550.4 515.8,588.9 467.5,588.9
              C 431.6,588.9 410.7,570.9 390.6,547.2
              C 371.2,524.4 356.2,503.6 337.8,490.4
              C 328.3,483.4 317.7,479.4 305.3,479.4
              C 286.7,479.4 273.6,488.9 267.6,504.3
              C 261.3,520.4 265.9,545.5 286.9,554.9
              C 263.0,550.6 245.6,528.5 245.6,502.1
              C 245.6,471.0 270.2,446.0 302.4,446.0
              C 336.7,446.0 357.8,460.3 375.5,483.0
              C 396.3,508.6 415.5,537.8 451.9,537.8
              C 480.3,537.8 505.4,513.9 505.4,482.1
              C 505.4,448.8 479.3,421.8 445.2,417.0 Z"
          />
          <circle cx="301.9" cy="391.4" r="25.3" />
          <circle cx="469.3" cy="359.7" r="25.3" />
        </g>
      </svg>
    </div>
  );
};
