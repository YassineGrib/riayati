#!/usr/bin/env python3
"""Build the Riayati welcome + auth screens in FigCraft (Arabic, RTL, Android 360x800).

Colors come from 01-brand/tokens/colors.json and are created as FigCraft variables
(collection "Riayati Color", modes Light/Dark), then bound to every layer, so dark mode
is a frame mode switch rather than a second set of colors.

Requires FigCraft running with:  figcraft.exe --control 7979
Usage:  python build_auth.py [welcome|login|...]   (no argument builds everything)
"""
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "figcraft-connector", "lib"))
import fc  # noqa: E402

# thmanyah: loaded from local files for this session only (never installed, never redistributed)
FONT = "thmanyah sans"                 # UI
DISPLAY = "thmanyah serif display"     # large titles and the wordmark
SERIF = "thmanyah serif text"          # long reading text (legal answers)
FONT_DIR = os.path.join(ROOT, "01-brand", "fonts", "thmanyah")
COLL = "Riayati Color"
OUT = os.path.join(ROOT, "02-design", "figcraft", "output")
W, H = 360, 800
STATUS_H, GESTURE_H, APPBAR_H = 28, 20, 56
PAD = 24

# --------------------------------------------------------------------------- tokens
_colors = json.load(open(os.path.join(ROOT, "01-brand", "tokens", "colors.json"), encoding="utf-8"))


def _get(node, dotted):
    for k in dotted.split("."):
        node = node[k]
    return node


def _resolve(value, overrides_path=None):
    while isinstance(value, str) and value.startswith("{"):
        value = _get(_colors, value[1:-1])["$value"]
    return value


def semantic_leaves(node, prefix=()):
    for k, v in node.items():
        if k.startswith("$"):
            continue
        if "$value" in v:
            yield prefix + (k,), v
        else:
            yield from semantic_leaves(v, prefix + (k,))


LIGHT, DARK = {}, {}
for path, tok in semantic_leaves(_colors["semantic"]):
    val = _resolve(tok["$value"])
    if not (isinstance(val, str) and re.fullmatch(r"#[0-9a-fA-F]{6}", val)):
        continue  # rgba overlays are not used in these screens
    name = "/".join(path)
    LIGHT[name] = val
    try:
        dk = _get(_colors["dark"], ".".join(path))
        DARK[name] = _resolve(dk["$value"])
    except KeyError:
        DARK[name] = val
for k in ("olive", "lime"):
    v = _colors["primitive"]["logo"][k]["$value"]
    LIGHT["logo/" + k] = v
    DARK["logo/" + k] = v


# --------------------------------------------------------------------------- helpers
def ok(res, what=""):
    if not res.get("ok"):
        raise RuntimeError(f"{what} failed: {res}")
    return res["result"]


def ex(cmd, **p):
    return ok(fc.ex(cmd, **p), cmd)


def setup_variables():
    old = fc.ex("variable.list")
    try:
        for c in ok(old).get("collections", []):
            if c.get("name") == COLL:
                ex("variable.deleteCollection", collection=COLL)
    except Exception:
        pass
    ex("variable.createCollection", name=COLL, modes=["Light", "Dark"])
    for name in sorted(LIGHT):
        ex("variable.create", collection=COLL, name=name, type="color",
           values={"Light": LIGHT[name], "Dark": DARK[name]})


def bind(node_id, field, token):
    """Bind fill/stroke of a layer to a color variable."""
    ok(fc.ex("variable.bind", ids=[node_id], field=field, variable=token), "variable.bind")


def rect(parent, name, x, y, w, h, fill=None, stroke=None, sw=1, r=0, align="inside", opacity=None):
    props = {"cornerRadius": r}
    if fill:
        props["fill"] = LIGHT[fill]
    if stroke:
        props.update({"stroke": LIGHT[stroke], "strokeWeight": sw, "strokeAlign": align})
    if opacity is not None:
        props["opacity"] = opacity
    nid = ex("shape.rectangle", x=x, y=y, width=w, height=h, parent=parent, name=name,
             select=False, props=props)["id"]
    if fill:
        bind(nid, "fill", fill)
    else:
        ex("node.set", id=nid, fill="none")
    if stroke:
        bind(nid, "stroke", stroke)
    return nid


def ellipse(parent, name, x, y, w, h, fill=None, stroke=None, sw=1):
    props = {}
    if fill:
        props["fill"] = LIGHT[fill]
    if stroke:
        props.update({"stroke": LIGHT[stroke], "strokeWeight": sw})
    nid = ex("shape.ellipse", x=x, y=y, width=w, height=h, parent=parent, name=name,
             select=False, props=props)["id"]
    if fill:
        bind(nid, "fill", fill)
    else:
        ex("node.set", id=nid, fill="none")
    if stroke:
        bind(nid, "stroke", stroke)
    return nid


def text(parent, name, s, x, y, size, weight, color, w=None, align="right", lh=1.65, direction="rtl"):
    """Create a text layer. w=None hugs content. Returns (id, width, height)."""
    family = DISPLAY if name == "Title" else (SERIF if name.startswith("Answer") else FONT)
    p = {"fontSize": size, "fontFamily": family, "fontWeight": weight, "fill": LIGHT[color],
         "lineHeight": round(size * lh, 2), "letterSpacing": 0}
    params = dict(text=s, x=x, y=y, parent=parent, name=name, select=False, props=p)
    if w:
        params["width"] = w
    nid = ex("text.create", **params)["id"]
    ex("text.direction", direction=direction, ids=[nid])
    ex({"right": "text.alignRight", "center": "text.alignCenter", "left": "text.alignLeft"}[align], ids=[nid])
    bind(nid, "fill", color)
    n = ex("node.get", id=nid)
    return nid, n["width"], n["height"]


# lucide icons, rect/circle converted to path data
ICONS = {
    "mail": ["M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z", "M22 7l-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"],
    "lock": ["M5 11h14a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2z", "M7 11V7a5 5 0 0 1 10 0v4"],
    "eye": ["M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0", "M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0z"],
    "user": ["M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2", "M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0z"],
    "arrow": ["M5 12h14", "M12 5l7 7-7 7"],
    "shield": ["M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z", "M9 12l2 2 4-4"],
    "alert": ["M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0z", "M12 8v4", "M12 16h.01"],
    "check": ["M20 6 9 17l-5-5"],
    "mailcheck": ["M22 13V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v12c0 1.1.9 2 2 2h8", "M22 7l-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7", "M16 19l2 2 4-4"],
}


def place_path(parent, name, d, x0, y0, scale, origin=(0, 0), fill=None, stroke=None, sw=2, opacity=None, rotate=None):
    """Create a vector whose path-space point `origin` lands at (x0, y0), scaled by `scale`."""
    ox, oy = origin
    cx, cy = x0 - ox * scale, y0 - oy * scale
    props = {}
    if fill:
        props["fill"] = LIGHT[fill]
    if stroke:
        props.update({"stroke": LIGHT[stroke], "strokeWeight": sw, "strokeCap": "round", "strokeJoin": "round"})
    if opacity is not None:
        props["opacity"] = opacity
    nid = ex("vector.create", path=d, x=cx, y=cy, parent=parent, name=name, select=False, props=props)["id"]
    n = ex("node.get", id=nid)
    off_x, off_y = n["x"] - cx, n["y"] - cy
    ex("node.set", id=nid, width=n["width"] * scale, height=n["height"] * scale,
       x=cx + off_x * scale, y=cy + off_y * scale)
    if rotate is not None:
        ex("node.set", id=nid, rotation=rotate)
    if fill:
        bind(nid, "fill", fill)
    else:
        ex("node.set", id=nid, fill="none")
    if stroke:
        bind(nid, "stroke", stroke)
    return nid


def icon(parent, name, key, x, y, size, color, sw=2):
    return place_path(parent, name, " ".join(ICONS[key]), x, y, size / 24.0, stroke=color, sw=sw)


# logo paths (viewBox 225 314 350 295)
LOGO_OLIVE = [
    "M 268.8,503.7 C 279.5,516.3 295.7,523.4 311.2,522.8 C 329.1,522.1 344.6,513.2 359.2,498.5 L 376.7,528.7 C 354.5,548.5 329.4,557.1 304.5,557.1 C 278.5,557.1 265.2,551.6 263.8,526.3 C 263.1,517.5 264.6,509.5 268.8,503.7 Z",
    "M 370.6,483.3 C 391.5,449.0 415.1,424.2 445.2,417.0 C 472.9,410.5 500.4,441.3 506.2,462.8 C 508.6,471.2 508.4,480.2 506.2,486.1 C 496.8,477.2 484.5,473.5 470.8,473.5 C 443.1,473.5 420.4,487.9 397.3,510.9 Z",
]
RIBBON = ("M 445.2,417.0 C 452.2,415.1 459.9,414.5 467.7,414.5 C 516.1,414.5 554.9,453.2 554.9,501.9 "
          "C 554.9,550.4 515.8,588.9 467.5,588.9 C 431.6,588.9 410.7,570.9 390.6,547.2 C 371.2,524.4 356.2,503.6 337.8,490.4 "
          "C 328.3,483.4 317.7,479.4 305.3,479.4 C 286.7,479.4 273.6,488.9 267.6,504.3 C 261.3,520.4 265.9,545.5 286.9,554.9 "
          "C 263.0,550.6 245.6,528.5 245.6,502.1 C 245.6,471.0 270.2,446.0 302.4,446.0 C 336.7,446.0 357.8,460.3 375.5,483.0 "
          "C 396.3,508.6 415.5,537.8 451.9,537.8 C 480.3,537.8 505.4,513.9 505.4,482.1 C 505.4,448.8 479.3,421.8 445.2,417.0 Z")
DOT_L = "M 327.2,391.4 a 25.3,25.3 0 1 1 -50.6,0 a 25.3,25.3 0 1 1 50.6,0 Z"
DOT_R = "M 494.6,359.7 a 25.3,25.3 0 1 1 -50.6,0 a 25.3,25.3 0 1 1 50.6,0 Z"


def logo(parent, x, y, width):
    s = width / 350.0
    for i, d in enumerate(LOGO_OLIVE):
        place_path(parent, f"Logo olive {i + 1}", d, x, y, s, origin=(225, 314), fill="logo/olive")
    place_path(parent, "Logo ribbon", RIBBON + " " + DOT_L + " " + DOT_R, x, y, s, origin=(225, 314), fill="logo/lime")


def watermark(parent, left, top, width, rotate, opacity=0.08):
    s = width / 311.0
    place_path(parent, "Watermark", RIBBON, left, top, s, origin=(245, 414), fill="action/primary",
               opacity=opacity, rotate=rotate)


# --------------------------------------------------------------------------- frame chrome
def new_frame(name, x, y, fill="surface/page"):
    fid = ex("frame.create", x=x, y=y, width=W, height=H, name=name, select=False,
             props={"fill": LIGHT[fill], "cornerRadius": 24, "clip": True,
                    "stroke": LIGHT["border/strong"], "strokeWeight": 2, "strokeAlign": "inside"})["id"]
    bind(fid, "fill", fill)
    bind(fid, "stroke", "border/strong")
    return fid


def chrome(fid):
    text(fid, "Status time", "9:41", 20, 5, 12, 400, "text/primary", align="left", lh=1.4, direction="ltr")
    rect(fid, "Status battery", W - 20 - 22, 9, 22, 11, stroke="text/primary", r=3)
    rect(fid, "Status battery level", W - 20 - 21, 10, 15, 9, fill="text/primary", r=1)
    rect(fid, "Gesture bar", (W - 108) / 2, H - GESTURE_H + 8, 108, 4, fill="text/primary", r=2, opacity=0.6)


def back_button(fid):
    icon(fid, "Back", "arrow", W - 8 - 48 + 12, STATUS_H + 4 + 12, 24, "text/primary")


# --------------------------------------------------------------------------- components
def label(fid, s, y):
    text(fid, f"Label {s}", s, PAD, y, 14, 500, "text/primary", w=W - 2 * PAD, lh=1.65)


def control(fid, name, y, state="default"):
    stroke, sw = "border/strong", 1
    if state == "focus":
        stroke, sw = "border/focus", 2
    elif state == "error":
        stroke, sw = "border/error", 2
    rect(fid, f"{name} control", PAD, y, W - 2 * PAD, 56, fill="surface/card", stroke=stroke, sw=sw, r=12)


def field(fid, label_s, y, icon_key, value, placeholder=False, ltr=True, eye=False, state="default", hint=None):
    """RTL text field: lead icon on the right, optional eye on the left. Returns next y."""
    label(fid, label_s, y)
    cy = y + 29
    control(fid, label_s, cy, state)
    icon(fid, f"{label_s} icon", icon_key, W - PAD - 16 - 20, cy + 18, 20, "text/secondary")
    right = W - PAD - 16 - 20 - 8
    left = PAD + 16 + (48 if eye else 0) - (0 if eye else 0)
    if eye:
        icon(fid, "Show password", "eye", PAD + 16 + 14 - 4, cy + 18, 20, "text/secondary")
    color = "text/tertiary" if placeholder else "text/primary"
    text(fid, f"{label_s} value", value, left, cy + 14, 16, 400, color, w=right - left, align="right",
         lh=1.65 if not ltr else 1.4, direction="ltr" if ltr else "rtl")
    y = cy + 56
    if hint:
        text(fid, "Hint", hint, PAD, y + 6, 14, 400, "text/secondary", w=W - 2 * PAD, lh=1.65)
        y += 6 + 23
    return y + 16


def button(fid, label_s, y, kind="primary"):
    if kind == "primary":
        rect(fid, f"Button {label_s}", PAD, y, W - 2 * PAD, 56, fill="action/primary", r=12)
        col = "text/on-action"
    else:
        rect(fid, f"Button {label_s}", PAD, y, W - 2 * PAD, 56, stroke="border/strong", r=12)
        col = "text/primary"
    text(fid, f"Button label {label_s}", label_s, PAD, y + 15, 16, 700, col, w=W - 2 * PAD, align="center", lh=1.65)


def link(fid, s, x, y, size=14):
    nid, w, h = text(fid, f"Link {s}", s, x, y, size, 500, "action/primary", align="right", lh=1.65)
    return nid, w, h


def underline(fid, x, y, w):
    rect(fid, "Link underline", x, y, w, 1, fill="action/primary")


def foot_pair(fid, plain, linked):
    """Centered 'question + link' row, anchored at the bottom (RTL: question on the right)."""
    y = H - GESTURE_H - 16 - 48 + 12
    t1, w1, h1 = text(fid, "Foot text", plain, 0, y, 14, 400, "text/secondary", lh=1.65)
    t2, w2, h2 = text(fid, "Foot link", linked, 0, y, 14, 500, "action/primary", lh=1.65)
    gap = 4
    total = w1 + gap + w2
    start = (W - total) / 2
    ex("node.set", id=t2, x=start)
    ex("node.set", id=t1, x=start + w2 + gap)
    underline(fid, start, y + h2 - 5, w2)


def alert(fid, y, s):
    nid, w, h = None, None, None
    box = rect(fid, "Error banner", PAD, y, W - 2 * PAD, 68, fill="feedback/error-bg", stroke="feedback/error-border", r=12)
    icon(fid, "Error icon", "alert", W - PAD - 16 - 20, y + 14, 20, "feedback/error-icon")
    text(fid, "Error text", s, PAD + 16, y + 12, 14, 400, "feedback/error-text", w=W - 2 * PAD - 16 - 20 - 12 - 16, lh=1.5)
    return y + 68 + 20


# --------------------------------------------------------------------------- screens
def screen_welcome(fid):
    watermark(fid, -250, STATUS_H - 70, 520, -24)
    watermark(fid, 530 - 340, 740 - 192, 340, 156)
    chrome(fid)
    logo(fid, (W - 148) / 2, 28 + 48, 148)
    text(fid, "Title", "رعايتي", PAD, 28 + 48 + 126 + 20, 48, 700, "text/primary", w=W - 2 * PAD, align="center", lh=1.4)
    text(fid, "Tagline", "مساحة آمنة لحماية الأطفال ومعرفة الحقوق في إطار الحضانة.", 46, 28 + 48 + 126 + 20 + 67 + 4, 18, 400,
         "text/secondary", w=268, align="center")
    by = H - GESTURE_H - 12 - 56 - 12 - 56 - 16 - 48 - 8
    button(fid, "إنشاء حساب", by, "primary")
    button(fid, "تسجيل الدخول", by + 68, "outline")
    icon(fid, "Privacy icon", "shield", W - PAD - 20, by + 68 + 56 + 18, 20, "action/primary")
    text(fid, "Privacy text", "بياناتك خاصة، ولا يطّلع الطرف الآخر إلا على التقويم المشترك.", PAD, by + 68 + 56 + 14, 14, 400,
         "text/secondary", w=W - 2 * PAD - 28, align="right", lh=1.65)


def screen_login(fid, error=False):
    watermark(fid, -150, STATUS_H + 8, 360, -24)
    chrome(fid)
    back_button(fid)
    y = STATUS_H + APPBAR_H + 8
    text(fid, "Title", "مرحبًا بعودتك", PAD, y, 30, 700, "text/primary", w=W - 2 * PAD, lh=1.4)
    text(fid, "Lead", "سجّل الدخول لمتابعة ملفك.", PAD, y + 42 + 8, 16, 400, "text/secondary", w=W - 2 * PAD)
    y = y + 42 + 8 + 26 + 24
    if error:
        y = alert(fid, y, "البريد الإلكتروني أو كلمة المرور غير صحيحة. تحقق منهما وحاول مجددًا.")
    st_e = "error" if error else "default"
    y = field(fid, "البريد الإلكتروني", y, "mail", "amina@example.com", state=st_e)
    y = field(fid, "كلمة المرور", y, "lock", "wrongpass" if False else ("••••••••"), placeholder=not error, eye=True,
              state="error" if error else "focus")
    ly = y - 16 - 8
    nid, w, h = link(fid, "نسيت كلمة المرور؟", PAD, ly + 12)
    ex("node.set", id=nid, x=W - PAD - w)
    underline(fid, W - PAD - w, ly + 12 + h - 5, w)
    button(fid, "تسجيل الدخول", ly + 48 + 12, "primary")
    foot_pair(fid, "ليس لديك حساب؟", "إنشاء حساب")


def screen_register(fid):
    watermark(fid, -150, STATUS_H + 8, 360, -24)
    chrome(fid)
    back_button(fid)
    y = STATUS_H + APPBAR_H + 8
    text(fid, "Title", "إنشاء حساب", PAD, y, 30, 700, "text/primary", w=W - 2 * PAD, lh=1.4)
    y = y + 42 + 20
    y = field(fid, "الاسم الكامل", y, "user", "الاسم واللقب", placeholder=True, ltr=False)
    y = field(fid, "البريد الإلكتروني", y, "mail", "name@example.com", placeholder=True)
    y = field(fid, "كلمة المرور", y, "lock", "••••••••", placeholder=True, eye=True, hint="8 أحرف على الأقل.")
    label(fid, "أنا", y)
    ry = y + 29
    half = (W - 2 * PAD - 12) / 2
    # RTL: first option (father) on the right
    rect(fid, "Role father", PAD + half + 12, ry, half, 56, fill="interactive/selected-bg", stroke="border/focus", sw=2, r=12)
    text(fid, "Role father label", "أب", PAD + half + 12, ry + 15, 16, 500, "text/primary", w=half, align="center")
    icon(fid, "Role father check", "check", PAD + half + 12 + half / 2 + 20, ry + 18, 20, "text/primary")
    rect(fid, "Role mother", PAD, ry, half, 56, fill="surface/card", stroke="border/strong", sw=1, r=12)
    text(fid, "Role mother label", "أم", PAD, ry + 15, 16, 500, "text/primary", w=half, align="center")
    cy = ry + 56 + 16 + 4
    rect(fid, "Consent box", W - PAD - 24, cy + 2, 24, 24, fill="surface/card", stroke="border/strong", sw=2, r=4)
    text(fid, "Consent text", "أوافق على شروط الاستخدام وسياسة الخصوصية.", PAD, cy + 2, 14, 400, "text/primary",
         w=W - 2 * PAD - 24 - 12, lh=1.5)
    button(fid, "إنشاء الحساب", cy + 48 + 12, "primary")
    foot_pair(fid, "لديك حساب؟", "تسجيل الدخول")


def screen_forgot(fid):
    watermark(fid, -150, STATUS_H + 8, 360, -24)
    chrome(fid)
    back_button(fid)
    y = STATUS_H + APPBAR_H + 8
    text(fid, "Title", "استعادة كلمة المرور", PAD, y, 30, 700, "text/primary", w=W - 2 * PAD, lh=1.4)
    _, _, h = text(fid, "Lead", "أدخل بريدك الإلكتروني وسنرسل لك رابطًا لتعيين كلمة مرور جديدة.", PAD, y + 42 + 8, 16, 400,
                   "text/secondary", w=W - 2 * PAD)
    y = y + 42 + 8 + h + 24
    y = field(fid, "البريد الإلكتروني", y, "mail", "name@example.com", placeholder=True, state="focus")
    button(fid, "إرسال الرابط", y + 8, "primary")
    # centered link at the bottom
    ly = H - GESTURE_H - 16 - 48 + 12
    nid, w, h = link(fid, "العودة إلى تسجيل الدخول", 0, ly)
    ex("node.set", id=nid, x=(W - w) / 2)
    underline(fid, (W - w) / 2, ly + h - 5, w)


def screen_sent(fid):
    watermark(fid, -150, STATUS_H + 8, 360, -24)
    chrome(fid)
    back_button(fid)
    y = STATUS_H + APPBAR_H + 40
    ellipse(fid, "Mark circle", (W - 80) / 2, y, 80, 80, fill="accent/soft")
    icon(fid, "Mail check", "mailcheck", (W - 40) / 2, y + 20, 40, "action/primary", sw=2)
    y += 80 + 24
    text(fid, "Title", "تحقق من بريدك", PAD, y, 30, 700, "text/primary", w=W - 2 * PAD, align="center", lh=1.4)
    _, _, h = text(fid, "Lead", "أرسلنا رابط الاستعادة إلى amina@example.com. قد يستغرق وصوله بضع دقائق.", 45, y + 42 + 8, 16, 400,
                   "text/secondary", w=270, align="center")
    y = y + 42 + 8 + h + 24
    button(fid, "العودة إلى تسجيل الدخول", y, "primary")
    text(fid, "Resend", "لم يصلك؟ يمكنك إعادة الإرسال بعد 0:45", PAD, y + 56 + 8 + 12, 14, 400, "text/secondary",
         w=W - 2 * PAD, align="center")


SCREENS = [
    ("Welcome", screen_welcome, "surface/brand-soft"),
    ("Login", lambda f: screen_login(f, False), "surface/page"),
    ("Login error", lambda f: screen_login(f, True), "surface/page"),
    ("Register", screen_register, "surface/page"),
    ("Forgot password", screen_forgot, "surface/page"),
    ("Forgot password sent", screen_sent, "surface/page"),
]


def main(only=None):
    if not fc.is_running():
        sys.exit("FigCraft is not running on 7979. Start: figcraft.exe --control 7979")
    import glob
    for f in sorted(glob.glob(os.path.join(FONT_DIR, "*", "otf", "*.otf"))):
        ex("text.loadFont", path=f.replace("\\", "/"))
    page = ex("page.list")[0]["id"]
    ex("page.select", id=page)
    ex("page.setBackground", id=page, color="#E9EDE5")
    # idempotent: remove only frames this script (or the probe) created
    mine = [i for i in ex("node.find", type="FRAME", limit=500)["ids"]
            if ex("node.get", id=i).get("name", "").startswith(("Auth /", "__probe"))]
    if mine:
        ex("edit.delete", ids=mine)
    setup_variables()

    os.makedirs(OUT, exist_ok=True)
    made = []
    for row, mode in enumerate(("Light", "Dark")):
        for i, (name, fn, bg) in enumerate(SCREENS):
            if only and only.lower() not in name.lower():
                continue
            title = f"Auth / {name}" + (" (dark)" if mode == "Dark" else "")
            fid = new_frame(title, i * (W + 80), row * (H + 120), bg)
            fn(fid)
            if mode == "Dark":
                ex("variable.setMode", ids=[fid], collection=COLL, mode="Dark")
            ex("file.export", ids=[fid], format="png", scale=1.5,
               path=os.path.join(OUT, title.replace(" / ", "_").replace(" ", "-") + ".png"))
            made.append((title, fid))
            print("built", title, fid)
        if only:
            break
    return made


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
