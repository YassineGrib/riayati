import { Easing } from "remotion";

/** Riayati brand palette (Sage / Olive / Lime theme). */
export const C = {
  ink: "#1B2418",
  inkSoft: "#283424",
  olive: "#658E3F",
  lime: "#C5E76C",
  dark: "#406A05",
  darkDeep: "#2E4D04",
  tintLight: "#F3F8EC",
  tintDark: "#E4EFD3",
  white: "#FFFFFF",
  sos: "#DC2626",
  sosSoft: "#FEE2E2",
  text: "#1B2418",
  textSoft: "#52604D",
  borderSoft: "rgba(101, 142, 63, 0.16)",
} as const;

export const FPS = 30;
export const W = 1920;
export const H = 1080;
export const VW = 1080;
export const VH = 1920;

export const SANS = "'Thmanyah Sans', 'Segoe UI', system-ui, sans-serif";
export const SERIF = "'Thmanyah Serif Display', 'Thmanyah Sans', serif";
export const SERIF_TEXT = "'Thmanyah Serif Text', 'Thmanyah Sans', serif";

export const EASE = {
  out: Easing.bezier(0.16, 1, 0.3, 1),
  inOut: Easing.bezier(0.76, 0, 0.24, 1),
  soft: Easing.bezier(0.33, 1, 0.68, 1),
  in: Easing.bezier(0.7, 0, 0.84, 0),
};

export const WIPE = 14;

/** Promo timeline (frames at 30 fps): start of each scene's wipe. */
export const TL = {
  s1: 0,
  s2: 66,
  s3: 156,
  s4: 258,
  s5: 360,
  s6: 456,
  s7: 534,
} as const;
export const PROMO_TOTAL = 660; // 22 s

/** Screens are 1080x2400 exports of the Figcraft design. */
export const SRC_W = 1080;
export const SRC_H = 2400;
export type Crop = readonly [number, number, number, number];

export const SCREEN = {
  welcome: "screens/02-Auth_Welcome_Light.png",
  login: "screens/02-Auth_Login_Light.png",
  link: "screens/03-Home_Link-co-parent_Light.png",
  home: "screens/03-Home_Home_Light.png",
  homeDark: "screens/03-Home_Home_Dark.png",
  newReport: "screens/04-Reports_New-report_Light.png",
  reportSummary: "screens/04-Reports_Report-summary_Light.png",
  reportsList: "screens/04-Reports_Reports-list_Light.png",
  calendar: "screens/05-Calendar_Calendar_Light.png",
  calendarVisit: "screens/05-Calendar_Visit-detail_Light.png",
  calendarPropose: "screens/05-Calendar_Propose-visit_Light.png",
  libraryList: "screens/09-Library_Library-list_Light.png",
  libraryDetail: "screens/09-Library_Library-detail_Light.png",
  centersList: "screens/10-Centers_Centers-list_Light.png",
  centerDetail: "screens/10-Centers_Center-detail_Light.png",
  profile: "screens/07-Profile_Profile_Light.png",
} as const;

/** Source-pixel rectangles [x, y, w, h] used for floating UI cards from real screens. */
export const CROPS = {
  homeSos: [48, 280, 984, 260] as Crop,
  homeVisit: [48, 560, 984, 460] as Crop,
  homeQuick: [48, 1040, 984, 340] as Crop,
  reportSummaryFact: [48, 380, 984, 720] as Crop,
  reportPdfCard: [48, 1120, 984, 240] as Crop,
  newReportForm: [48, 280, 984, 620] as Crop,
  newReportAttach: [48, 920, 984, 520] as Crop,
  calendarMonth: [48, 280, 984, 740] as Crop,
  calendarVisit: [48, 1040, 984, 460] as Crop,
  calendarPropose: [48, 380, 984, 760] as Crop,
  libraryCard: [48, 380, 984, 440] as Crop,
  centerCard: [48, 380, 984, 460] as Crop,
  linkCode: [48, 380, 984, 480] as Crop,
  profileCard: [48, 280, 984, 420] as Crop,
};

export const APP_INFO = {
  name: "رعايتي",
  tagline: "مساحة آمنة لحماية الطفل في إطار الحضانة",
  ctaText: "حمّل النسخة التجريبية لأندرويد من riayati.site",
  ctaUrl: "riayati.site",
  disclaimer: "محتوى تعريفي للإرشاد الأولي، ولا يغني عن استشارة مختص أو عن نص القانون الرسمي",
} as const;
