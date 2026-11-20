#!/usr/bin/env python3
"""Build the whole Riayati FigCraft document, organised in pages.

  00 Cover            title, what is inside
  01 Foundations      colors, semantic colors (light + dark), typography, icons, brand
  -- Mobile app
  02 Auth             welcome, login, register, password reset
  03 Home             link co-parent, home
  04 Reports          new report, summary, list, empty
  05 Calendar         calendar, propose visit, visit detail
  06 Assistant        first open, answer, no sources
  07 Profile          profile linked / not linked
  -- Admin panel
  08 Admin            (added by build_admin.py)

Every screen is built twice (Light and Dark = the same layers with a variable mode switch) and each row is
wrapped in a named section. Requires FigCraft running with --control 7979.
Usage: python build_doc.py
"""
import glob
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import build_auth as A  # noqa: E402
import build_app as B  # noqa: E402
import build_cal as C  # noqa: E402
import build_reports as R  # noqa: E402
import build_library as LIB  # noqa: E402
import build_centers as CEN  # noqa: E402
import build_admin_sections as ADS  # noqa: E402

W, H = A.W, A.H
PAGE_BG = "#E9EDE5"
HERE = os.path.dirname(os.path.abspath(__file__))
COLORS = json.load(open(os.path.join(A.ROOT, "01-brand", "tokens", "colors.json"), encoding="utf-8"))

ALL = {name: (fn, bg) for name, fn, bg in A.SCREENS + B.APP_SCREENS + C.CAL_SCREENS + R.REPORT_SCREENS + LIB.LIBRARY_SCREENS + CEN.CENTERS_SCREENS}

SCREEN_PAGES = [
    ("02 Auth", ["Welcome", "Login", "Login error", "Register", "Forgot password", "Forgot password sent"],
     "Welcome, sign in, register, password reset. Email and password only, no OTP."),
    ("03 Home", ["Link co-parent", "Home"],
     "Linking the two parents with an invite code, and the home screen with the SOS report button and shortcuts."),
    ("04 Reports", ["New report", "Report summary", "Reports list", "Reports empty"],
     "Create an incident report with attachments, the sent summary with PDF export, and the reports list."),
    ("05 Calendar", ["Calendar", "Propose visit", "Visit detail"],
     "Shared visit calendar: propose, accept or decline, confirm."),
    ("06 Assistant", ["Assistant empty", "Assistant answer", "Assistant no sources"],
     "Legal assistant: first open, answer with cited sources, and the not-enough-in-the-sources state."),
    ("07 Profile", ["Profile", "Profile unlinked"],
     "Account, settings, and the linked or not-linked state of the other parent."),
    ("09 Library", ["Library list", "Library detail", "Library empty", "Library error"],
     "Educational content library: articles, laws, Supreme Court rulings, guides, detail, empty and error."),
    ("10 Centers", ["Centers list", "Centers wilaya filter", "Center detail", "Centers empty"],
     "Support centers and judicial directory: search, wilaya filter sheet, detail with tap-to-call, empty."),
]


# --------------------------------------------------------------------------- small helpers
def ltr(fid, name, s, x, y, size, weight, color, w=None, align="left", lh=1.4):
    return A.text(fid, name, s, x, y, size, weight, color, w=w, align=align, lh=lh, direction="ltr")


def doc_frame(name, x, y, w, h, fill="surface/page", radius=16, parent=None):
    params = dict(x=x, y=y, width=w, height=h, name=name, select=False,
                  props={"fill": A.LIGHT[fill], "cornerRadius": radius, "clip": True})
    if parent:
        params["parent"] = parent
    fid = A.ex("frame.create", **params)["id"]
    A.bind(fid, "fill", fill)
    return fid


def dark_mode(fid):
    A.ex("variable.setMode", ids=[fid], collection=A.COLL, mode="Dark")


def wipe_page(pid):
    A.ex("page.select", id=pid)
    for kind in ("SECTION", "FRAME", "TEXT"):
        ids = A.ex("node.find", type=kind, limit=5000)["ids"]
        for i in ids:
            try:
                A.ex("edit.delete", ids=[i])
            except Exception:
                pass


# --------------------------------------------------------------------------- cover
def build_cover(pid):
    A.ex("page.select", id=pid)
    f = doc_frame("Cover", 0, 0, 1440, 900, "surface/brand-soft", 0)
    A.watermark(f, 760, -120, 900, -24)
    A.watermark(f, -260, 560, 560, 156)
    A.logo(f, 96, 96, 150)
    ltr(f, "Title", "Riayati", 96, 330, 88, 700, "text/primary")
    ltr(f, "Subtitle", "UI / UX design system and screens", 96, 440, 28, 500, "text/secondary")
    ltr(f, "Meta 1", "Mobile app (Android)  ·  Admin panel  ·  Arabic, right-to-left  ·  Light and dark", 96, 496, 18, 400, "text/secondary")
    ltr(f, "Meta 2", "Version 1.0  ·  November 2026  ·  Ref. RIA-MVP-001", 96, 530, 18, 400, "text/secondary")
    A.text(f, "Title", "رعايتي", 760, 150, 130, 700, "text/primary", w=584, align="right", lh=1.4)
    A.text(f, "Tagline", "منصة رقمية لحماية الأطفال في إطار الحضانة", 760, 330, 28, 400, "text/secondary", w=584, align="right")

    ltr(f, "Contents", "Contents", 96, 608, 16, 700, "action/primary")
    rows = [("01 Foundations", "Colors, semantic colors, typography, icons, brand"),
            ("02 Auth", "Welcome, sign in, register, password reset"),
            ("03 Home", "Link other parent, home with SOS and shortcuts"),
            ("04 Reports", "New report, sent summary and PDF, list"),
            ("05 Calendar", "Month view, propose a visit, visit detail"),
            ("06 Assistant", "Legal assistant with sources"),
            ("07 Profile", "Account, linked or not linked"),
            ("09 Library", "Educational library: articles, laws, rulings, guides"),
            ("10 Centers", "Support centers directory and wilaya filter"),
            ("08 Admin", "Admin panel: incident inbox and legal texts"),
            ("11 Admin Home", "Admin dashboard: statistics, charts, latest reports"),
            ("12 Admin Content", "Content library management and editor"),
            ("13 Admin Centers", "Support centers directory and editor"),
            ("14 Admin Users", "Users and families read-only overview"),
            ("15 Admin Visits", "Visits calendar read-only overview"),
            ("16 Admin Activity", "Activity log for evidence integrity")]
    for i, (name, desc) in enumerate(rows):
        col, row = divmod(i, 8)
        x, y = 96 + col * 560, 638 + row * 30
        ltr(f, "Index name", name, x, y, 14, 700, "text/primary", w=150)
        ltr(f, "Index text", desc, x + 155, y, 13, 400, "text/secondary", w=385)
    return f


# --------------------------------------------------------------------------- foundations
RAMPS = [("Brand · olive", "brand"), ("Lime · accent", "lime"), ("Neutral", "neutral"),
         ("Red · SOS, errors", "red"), ("Green · success", "green"), ("Amber · warning", "amber"), ("Blue · info", "blue")]
STEPS = ["50", "100", "200", "300", "400", "500", "600", "700", "800", "900", "950"]


def foundations_palette(x, y):
    h = 128 + len(RAMPS) * 140 + 24
    f = doc_frame("Colors / Palette", x, y, 1440, h)
    ltr(f, "Heading", "Color palette", 48, 40, 32, 700, "text/primary")
    ltr(f, "Note", "Primitive ramps generated in OKLCH from the logo olive and lime. Screens use the semantic variables, never these directly.",
        48, 84, 14, 400, "text/secondary", w=1200)
    for r, (label, key) in enumerate(RAMPS):
        y0 = 128 + r * 140
        ltr(f, "Ramp label", label, 48, y0 + 22, 16, 700, "text/primary", w=200)
        for i, step in enumerate(STEPS):
            hexv = COLORS["primitive"][key][step]["$value"]
            sx = 260 + i * 100
            A.ex("shape.rectangle", x=sx, y=y0, width=88, height=64, parent=f, name=f"{key} {step}", select=False,
                 props={"fill": hexv, "cornerRadius": 8, "stroke": A.LIGHT["border/default"], "strokeWeight": 1, "strokeAlign": "inside"})
            ltr(f, "Step", step, sx, y0 + 70, 12, 700, "text/primary", w=88)
            ltr(f, "Hex", hexv, sx, y0 + 88, 11, 400, "text/secondary", w=88)
    return f


SEMANTIC = [
    ("Action", ["action/primary", "action/primary-hover", "action/secondary", "action/destructive"]),
    ("Text", ["text/primary", "text/secondary", "text/tertiary", "text/link", "text/on-action"]),
    ("Surface", ["surface/page", "surface/card", "surface/raised", "surface/sunken", "surface/brand-soft"]),
    ("Border", ["border/default", "border/strong", "border/focus", "border/error"]),
    ("Feedback", ["feedback/success-bg", "feedback/success-text", "feedback/warning-bg", "feedback/warning-text",
                  "feedback/error-bg", "feedback/error-text", "feedback/info-bg", "feedback/info-text"]),
    ("SOS and accent", ["sos/bg", "sos/bg-soft", "accent/default", "accent/soft"]),
]


def foundations_semantic(x, y, mode):
    values = A.DARK if mode == "Dark" else A.LIGHT
    h = 128 + sum(36 + ((len(t) + 5) // 6) * 120 + 18 for _, t in SEMANTIC) + 24
    f = doc_frame(f"Colors / Semantic / {mode}", x, y, 1440, h)
    ltr(f, "Heading", f"Semantic colors · {mode}", 48, 40, 32, 700, "text/primary")
    ltr(f, "Note", "Figma-style variables in the collection 'Riayati Color'. Dark is the same layers with the Dark mode switched on.",
        48, 84, 14, 400, "text/secondary", w=1200)
    cy = 128
    for title, tokens in SEMANTIC:
        ltr(f, "Group", title, 48, cy, 16, 700, "action/primary")
        cy += 36
        for i, tok in enumerate(tokens):
            col, row = i % 6, i // 6
            sx, sy = 48 + col * 226, cy + row * 120
            A.rect(f, f"Swatch {tok}", sx, sy, 210, 56, fill=tok, stroke="border/default", sw=1, r=10)
            ltr(f, "Token", tok, sx, sy + 62, 13, 700, "text/primary", w=210)
            ltr(f, "Hex", values.get(tok, ""), sx, sy + 82, 12, 400, "text/secondary", w=210)
        cy += ((len(tokens) + 5) // 6) * 120 + 18
    if mode == "Dark":
        dark_mode(f)
    return f


def foundations_type(x, y):
    f = doc_frame("Typography", x, y, 1440, 1020)
    ltr(f, "Heading", "Typography", 48, 40, 32, 700, "text/primary")
    ltr(f, "Note", "thmanyah: Sans for the interface, Serif Display for titles, Serif Text for long legal text. Letter-spacing is always 0 for Arabic. Local files only, never redistributed.",
        48, 84, 14, 400, "text/secondary", w=1280)
    specs = [
        ("Display · Serif Display · 36 / Bold · line 1.4", "رعايتي", "Title", 36, 700, 1.4),
        ("Heading 1 · Serif Display · 30 / Bold · line 1.4", "مرحبًا بعودتك", "Title", 30, 700, 1.4),
        ("Heading 2 · Sans · 24 / Bold · line 1.5", "الزيارات القادمة", "Spec", 24, 700, 1.5),
        ("Heading 3 · Sans · 20 / Bold · line 1.5", "الجمعة 20 نوفمبر", "Spec", 20, 700, 1.5),
        ("Heading 4 · Sans · 16 / Bold · line 1.5", "المساعد القانوني", "Spec", 16, 700, 1.5),
        ("Body · Sans · 16 / Regular · line 1.65", "سجّل الدخول لمتابعة ملفك. أجيب من النصوص المعتمدة فقط، وأذكر المواد التي استندت إليها.", "Spec", 16, 400, 1.65),
        ("Legal text · Serif Text · 16 / Regular · line 1.8", "تنظّم المواد الخاصة بالحضانة في قانون الأسرة من تُسند إليها الحضانة وشروطها.", "Answer", 16, 400, 1.8),
        ("Label · Sans · 14 / Medium · line 1.5", "البريد الإلكتروني", "Spec", 14, 500, 1.5),
        ("Caption · Sans · 14 / Regular · line 1.65", "8 أحرف على الأقل.", "Spec", 14, 400, 1.65),
        ("Tab label · Sans · 12 / Medium", "الرئيسية  التقويم  المساعد  بلاغاتي  حسابي", "Spec", 12, 500, 1.65),
    ]
    yy = 140
    for label, sample, name, size, weight, lh in specs:
        ltr(f, "Spec label", label, 48, yy + 6, 14, 500, "text/secondary", w=440)
        _, _, h = A.text(f, name, sample, 520, yy, size, weight, "text/primary", w=872, align="right", lh=lh)
        yy += max(64, int(h) + 28)
        A.rect(f, "Spec line", 48, yy - 14, 1344, 1, fill="border/default")
    return f


def foundations_icons(x, y):
    keys = sorted(A.ICONS)
    cols = 9
    rows = (len(keys) + cols - 1) // cols
    h = 140 + rows * 120 + 32
    f = doc_frame("Iconography", x, y, 1440, h)
    ltr(f, "Heading", "Iconography", 48, 40, 32, 700, "text/primary")
    ltr(f, "Note", "Lucide, 24 px grid, 2 px round stroke, one color from the semantic variables. Directional icons flip in right-to-left.",
        48, 84, 14, 400, "text/secondary", w=1200)
    for i, key in enumerate(keys):
        col, row = i % cols, i // cols
        cx, cy = 48 + col * 150, 140 + row * 120
        A.rect(f, f"Icon cell {key}", cx, cy, 134, 100, fill="surface/card", stroke="border/default", sw=1, r=12)
        try:
            A.icon(f, f"Icon {key}", key, cx + 55, cy + 22, 24, "text/primary")
        except RuntimeError as e:
            print("icon skipped:", key, str(e)[:80], flush=True)
        ltr(f, "Icon name", key, cx, cy + 68, 12, 500, "text/secondary", w=134, align="center")
    return f


def foundations_brand(x, y):
    f = doc_frame("Brand", x, y, 1440, 900)
    ltr(f, "Heading", "Brand", 48, 40, 32, 700, "text/primary")
    ltr(f, "Note", "Logo symbol, the corner watermark cut from it, spacing (4 px base) and corner radius.", 48, 84, 14, 400, "text/secondary", w=1200)
    # logo on light and dark
    A.rect(f, "Logo light", 48, 140, 420, 300, fill="surface/brand-soft", r=16)
    A.logo(f, 48 + (420 - 200) / 2, 140 + 80, 200)
    A.ex("shape.rectangle", x=492, y=140, width=420, height=300, parent=f, name="Logo dark bg", select=False,
         props={"fill": A.DARK["surface/page"], "cornerRadius": 16})
    A.logo(f, 492 + (420 - 200) / 2, 140 + 80, 200)
    ltr(f, "Caption", "Symbol on light and dark", 48, 452, 13, 500, "text/secondary")
    # watermark sample
    sample = doc_frame("Watermark sample", 940, 140, 452, 300, "surface/brand-soft", 16, parent=f)
    A.watermark(sample, -40, -30, 360, -24)
    A.text(sample, "Title", "رعايتي", 0, 110, 56, 700, "text/primary", w=452, align="center", lh=1.4)
    ltr(f, "Caption 2", "Corner watermark at 8% opacity, behind content", 940, 452, 13, 500, "text/secondary")
    # spacing
    ltr(f, "Spacing title", "Spacing", 48, 520, 18, 700, "text/primary")
    for i, v in enumerate([4, 8, 12, 16, 24, 32, 48]):
        A.rect(f, f"Space {v}", 48 + i * 130, 560, v, 40, fill="action/primary", r=2)
        ltr(f, "Space label", f"{v}", 48 + i * 130, 610, 12, 500, "text/secondary", w=100)
    # radius
    ltr(f, "Radius title", "Corner radius", 48, 670, 18, 700, "text/primary")
    for i, v in enumerate([6, 8, 12, 16, 24, 9999]):
        A.rect(f, f"Radius {v}", 48 + i * 150, 710, 110, 80, fill="surface/card", stroke="border/strong", sw=1, r=min(v, 40))
        ltr(f, "Radius label", "full" if v == 9999 else str(v), 48 + i * 150, 800, 12, 500, "text/secondary", w=110)
    return f


def build_foundations(pid):
    A.ex("page.select", id=pid)
    out = []
    out.append(foundations_palette(0, 0))
    out.append(foundations_semantic(0, 1260, "Light"))
    out.append(foundations_semantic(1520, 1260, "Dark"))
    out.append(foundations_type(0, 3000))
    out.append(foundations_icons(0, 4180))
    out.append(foundations_brand(0, 5300))
    return out


# --------------------------------------------------------------------------- screen pages
def page_header(title, desc):
    name = title.split(" ", 1)[1]
    # plain text on the page, above the first section
    for nm, s, size, wt, y in (("Page title", name, 56, 700, -250), ("Page description", desc, 20, 400, -170)):
        nid = A.ex("text.create", text=s, x=0, y=y, name=nm, select=False,
                   props={"fontSize": size, "fontFamily": A.FONT, "fontWeight": wt, "fill": A.LIGHT["text/primary"] if wt == 700 else A.LIGHT["text/secondary"],
                          "letterSpacing": 0})["id"]
        A.ex("text.direction", direction="ltr", ids=[nid])


def build_screens_page(pid, title, names, desc, made):
    A.ex("page.select", id=pid)
    A.ex("page.setBackground", id=pid, color=PAGE_BG)
    page_header(title, desc)
    short = title.split(" ", 1)[1]
    for r, mode in enumerate(("Light", "Dark")):
        ids = []
        for i, name in enumerate(names):
            fn, bg = ALL[name]
            fid = A.new_frame(f"{name} / {mode}", i * (W + 80), r * (H + 200), bg)
            fn(fid)
            if mode == "Dark":
                dark_mode(fid)
            fname = f"{title.replace(' ', '-')}_{name.replace(' ', '-')}_{mode}.png"
            A.ex("file.export", ids=[fid], format="png", scale=A.EXPORT_SCALE, path=os.path.join(A.OUT, fname))
            ids.append(fid)
            made.append(f"{short} / {name} / {mode}")
            print("built", short, "/", name, "/", mode, flush=True)
        A.ex("object.wrapInSection", ids=ids, name=f"{short} · {mode}")


# --------------------------------------------------------------------------- main
def main():
    if not A.fc.is_running():
        sys.exit("FigCraft is not running on 7979. Start: figcraft.exe --control 7979")
    for f in sorted(glob.glob(os.path.join(A.FONT_DIR, "*", "otf", "*.otf"))):
        A.ex("text.loadFont", path=f.replace("\\", "/"))

    # clean slate: one page left, emptied
    pages = A.ex("page.list")
    for p in pages[1:]:
        A.ex("page.delete", id=p["id"])
    first = pages[0]["id"]
    wipe_page(first)
    A.ex("page.rename", id=first, name="00 Cover")
    A.setup_variables()
    os.makedirs(A.OUT, exist_ok=True)
    for old in glob.glob(os.path.join(A.OUT, "*.png")):
        os.remove(old)

    def add(name):
        A.ex("page.add", name=name)
        return [p for p in A.ex("page.list") if p["name"] == name][-1]["id"] if not name.startswith("-") else None

    A.ex("page.setBackground", id=first, color=PAGE_BG)
    build_cover(first)

    foundations = add("01 Foundations")
    A.ex("page.setBackground", id=foundations, color=PAGE_BG)
    build_foundations(foundations)

    A.ex("page.add", name="- Mobile app")
    made = []
    for title, names, desc in SCREEN_PAGES:
        pid = add(title)
        build_screens_page(pid, title, names, desc, made)

    A.ex("page.add", name="- Admin panel")
    admin = add("08 Admin")
    import build_admin as AD
    AD.build_admin_page(admin, page_header, made)

    admin_home = add("11 Admin Home")
    ADS.build_admin_home_page(admin_home, page_header, made)

    admin_content = add("12 Admin Content")
    ADS.build_admin_content_page(admin_content, page_header, made)

    admin_centers = add("13 Admin Centers")
    ADS.build_admin_centers_page(admin_centers, page_header, made)

    admin_users = add("14 Admin Users")
    ADS.build_admin_users_page(admin_users, page_header, made)

    admin_visits = add("15 Admin Visits")
    ADS.build_admin_visits_page(admin_visits, page_header, made)

    admin_activity = add("16 Admin Activity log")
    ADS.build_admin_activity_page(admin_activity, page_header, made)

    A.ex("page.select", id=first)
    A.fc.ex("file.saveAs", path=os.path.join(HERE, "riayati-design.figcraft"))
    print("pages:", [p["name"] for p in A.ex("page.list")])
    print("saved; screens built:", len(made))


if __name__ == "__main__":
    main()
