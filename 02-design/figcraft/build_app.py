#!/usr/bin/env python3
"""Build ALL Riayati screens in FigCraft: auth (welcome, login, register...) + app (link, home, report).

Each set is built in Light and Dark (dark = frame variable mode, same layers).
Reuses helpers and the "Riayati Color" variable collection from build_auth.py.
Coordinates mirror the HTML mockups in 02-design/ (360x800 dp, RTL).

Requires FigCraft running with:  figcraft.exe --control 7979
Usage:  python build_app.py            (everything)
        python build_app.py app        (only the app screens, light + dark)
"""
import glob
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import build_auth as A  # noqa: E402

W, H = A.W, A.H
PAD = A.PAD

A.ICONS.update({
    "backl": ["M19 12H5", "M12 19l-7-7 7-7"],
    "alerttri": ["M21.73 18l-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3", "M12 9v4", "M12 17h.01"],
    "bell": ["M10.268 21a2 2 0 0 0 3.464 0", "M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"],
    "home": ["M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8", "M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"],
    "cal": ["M8 2v4", "M16 2v4", "M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z", "M3 10h18"],
    "chat": ["M7.9 20A9 9 0 1 0 4 16.1L2 22Z"],
    "file": ["M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z", "M14 2v4a2 2 0 0 0 2 2h4", "M10 9H8", "M16 13H8", "M16 17H8"],
    "copy": ["M10 8h10a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H10a2 2 0 0 1-2-2V10a2 2 0 0 1 2-2z", "M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"],
    "share": ["M21 5a3 3 0 1 1-6 0 3 3 0 0 1 6 0z", "M9 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0z", "M21 19a3 3 0 1 1-6 0 3 3 0 0 1 6 0z", "M8.59 13.51l6.83 3.98", "M15.41 6.51l-6.82 3.98"],
    "download": ["M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4", "M7 10l5 5 5-5", "M12 15V3"],
    "print": ["M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2", "M6 9V3a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v6", "M7 14h10a1 1 0 0 1 1 1v6a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1v-6a1 1 0 0 1 1-1z"],
    "image": ["M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z", "M11 9a2 2 0 1 1-4 0 2 2 0 0 1 4 0z", "M21 15l-3.086-3.086a2 2 0 0 0-2.828 0L6 21"],
    "video": ["M16 13l5.223 3.482a.5.5 0 0 0 .777-.416V7.87a.5.5 0 0 0-.752-.432L16 10.5", "M4 6h10a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2z"],
    "clip": ["M16 6l-8.414 8.586a2 2 0 0 0 2.829 2.829l8.414-8.586a4 4 0 1 0-5.657-5.657l-8.379 8.551a6 6 0 1 0 8.485 8.485l8.379-8.551"],
    "x": ["M18 6L6 18", "M6 6l12 12"],
    "clock": ["M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0z", "M12 6v6l4 2"],
    # mirrored for RTL (points left)
    "send": ["M9.464 21.686a.5.5 0 0 1-.937-.024l-6.5-19a.496.496 0 0 1 .635-.635l19 6.5a.5.5 0 0 1 .024.937l-7.93 3.18a2 2 0 0 0-1.112 1.11z", "M2.146 2.147l10.94 10.939"],
})


# ----------------------------------------------------------------------------- helpers
def rtext(fid, name, s, right, y, size, weight, color, lh=1.65, direction="rtl"):
    """Auto-width text whose RIGHT edge sits at `right` (RTL anchoring)."""
    nid, w, h = A.text(fid, name, s, 0, y, size, weight, color, lh=lh, direction=direction, align="right")
    A.ex("node.set", id=nid, x=right - w)
    return nid, w, h


def card(fid, name, x, y, w, h, fill="surface/card", stroke="border/default", r=16):
    return A.rect(fid, name, x, y, w, h, fill=fill, stroke=stroke, sw=1, r=r)


def button(fid, label, x, y, w, h, kind="primary", icon=None):
    if kind == "primary":
        A.rect(fid, f"Button {label}", x, y, w, h, fill="action/primary", r=12)
        col, ic = "text/on-action", "text/on-action"
    elif kind == "disabled":
        A.rect(fid, f"Button {label} (disabled)", x, y, w, h, fill="surface/disabled", r=12)
        col, ic = "text/disabled", "text/disabled"
    else:
        A.rect(fid, f"Button {label}", x, y, w, h, stroke="border/strong", r=12)
        col, ic = "text/primary", "text/primary"
    ty = y + (h - 26.4) / 2
    if icon:
        tid, tw, th = A.text(fid, f"Button label {label}", label, 0, ty, 16, 700, col, lh=1.65)
        total = 20 + 8 + tw
        start = x + (w - total) / 2
        A.ex("node.set", id=tid, x=start)
        A.icon(fid, f"Button icon {label}", icon, start + tw + 8, y + (h - 20) / 2, 20, ic)
    else:
        A.text(fid, f"Button label {label}", label, x, ty, 16, 700, col, w=w, align="center", lh=1.65)


def chip(fid, x_left, y, label, kind, icon=None, direction="rtl"):
    fill, col = {"warn": ("feedback/warning-bg", "feedback/warning-text"),
                 "neutral": ("surface/sunken", "text/primary"),
                 "ok": ("feedback/success-bg", "feedback/success-text"),
                 "info": ("feedback/info-bg", "feedback/info-text")}[kind]
    tmp, tw, _ = A.text(fid, "tmp", label, 0, 0, 14, 500, col, lh=1.5, direction=direction)
    A.ex("edit.delete", ids=[tmp])
    iw = 16 + 6 if icon else 0
    w = 12 + iw + tw + 12
    A.rect(fid, f"Chip {label}", x_left, y, w, 28, fill=fill, r=14)
    right = x_left + w - 12
    if icon:
        A.icon(fid, "Chip icon", icon, right - 16, y + 6, 16, col, sw=2)
        right -= 22
    tid, _, _ = A.text(fid, f"Chip label {label}", label, 0, y + 3.5, 14, 500, col, lh=1.5, direction=direction)
    A.ex("node.set", id=tid, x=right - tw)
    return w


def appbar_title(fid, s):
    A.icon(fid, "Back", "arrow", 312, 44, 24, "text/primary")
    rtext(fid, "Title", s, 292, 39, 20, 700, "text/primary", lh=1.65)


def shell(fid):
    A.watermark(fid, -150, A.STATUS_H + 8, 360, -24)
    A.chrome(fid)


def tabbar(fid, active):
    bar = A.rect(fid, "Tab bar", 16, 700, 328, 64, fill="surface/raised", stroke="border/default", r=32)
    A.ex("effect.add", ids=[bar], effect={"type": "dropShadow", "offset": [0, 8], "radius": 24, "color": "#00000029"})
    tabs = [("الرئيسية", "home"), ("التقويم", "cal"), ("المساعد", "chat"), ("بلاغاتي", "file"), ("حسابي", "user")]
    for i, (label, icon) in enumerate(tabs):  # RTL: index 0 is the rightmost tab
        cx = 24 + 62.4 * (4 - i) + 31.2
        on = i == active
        col = "action/primary" if on else "text/secondary"
        if on:
            A.rect(fid, f"Tab {label} indicator", cx - 28, 707, 56, 28, fill="interactive/selected-bg", r=14)
        A.icon(fid, f"Tab {label} icon", icon, cx - 12, 709, 24, col)
        A.text(fid, f"Tab {label}", label, cx - 31, 738, 12, 700 if on else 500, col, w=62, align="center", lh=1.65)


# ----------------------------------------------------------------------------- screens
def screen_link(fid):
    shell(fid)
    A.text(fid, "Title", "ربط حساب الطرف الآخر", PAD, 92, 30, 700, "text/primary", w=312, lh=1.4)
    A.text(fid, "Lead", "لتشاركا تقويم الزيارات، اربطا حسابيكما برمز دعوة. لن يطّلع الطرف الآخر إلا على التقويم المشترك.",
           PAD, 142, 16, 400, "text/secondary", w=312)
    card(fid, "Code card", 24, 210, 312, 206)
    rtext(fid, "Card title", "رمزك", 320, 229, 16, 700, "text/primary", lh=1.5)
    chip(fid, 40, 227, "ينتهي خلال 48 ساعة", "neutral", "clock")
    A.rect(fid, "Code box", 40, 267, 280, 72, fill="surface/brand-soft", r=12)
    A.text(fid, "Code", "K7M-4Q2", 40, 278, 36, 700, "text/primary", w=280, align="center", lh=1.4, direction="ltr")
    button(fid, "نسخ", 186, 351, 134, 48, "outline", "copy")
    button(fid, "مشاركة", 40, 351, 134, 48, "primary", "share")
    A.rect(fid, "Divider right", 24, 443, 138, 1, fill="border/default")
    A.rect(fid, "Divider left", 198, 443, 138, 1, fill="border/default")
    A.text(fid, "Or", "أو", 24, 432, 14, 400, "text/secondary", w=312, align="center", lh=1.65)
    A.label(fid, "لديّ رمز من الطرف الآخر", 471)
    A.control(fid, "Code input", 500, "focus")
    A.text(fid, "Code placeholder", "XXX-XXX", 24, 500 + 13, 20, 400, "text/tertiary", w=312, align="center", lh=1.4, direction="ltr")
    button(fid, "ربط الحساب", 24, 568, 312, 56, "disabled")
    nid, w, h = A.link(fid, "لاحقًا", 0, 701)
    A.ex("node.set", id=nid, x=(W - w) / 2)
    A.underline(fid, (W - w) / 2, 701 + h - 5, w)
    A.text(fid, "Note", "لن يعمل التقويم المشترك قبل الربط.", 24, 737, 14, 400, "text/secondary", w=312, align="center")


def screen_home(fid):
    shell(fid)
    rtext(fid, "Title", "مرحبًا، أمينة", 336, 34, 20, 700, "text/primary", lh=1.4)
    rtext(fid, "Date", "الثلاثاء 17 نوفمبر", 336, 62, 14, 400, "text/secondary", lh=1.65)
    A.icon(fid, "Notifications", "bell", 20, 48, 24, "text/primary")
    A.ellipse(fid, "Unread dot", 36, 44, 10, 10, fill="sos/bg", stroke="surface/page", sw=2)
    # SOS
    A.rect(fid, "SOS card", 24, 92, 312, 120, fill="sos/bg", r=16)
    A.ellipse(fid, "SOS badge", 256, 123, 56, 56, fill="sos/text-on-bg")
    A.icon(fid, "SOS icon", "alerttri", 270, 137, 28, "sos/bg")
    rtext(fid, "SOS title", "الإبلاغ عن حادثة", 240, 112, 24, 700, "sos/text-on-bg", lh=1.4)
    A.text(fid, "SOS text", "وثّق ما حدث بالنص والصور والفيديو.", 84, 149, 14, 400, "sos/text-on-bg", w=157, lh=1.5)
    A.icon(fid, "SOS go", "backl", 44, 139, 24, "sos/text-on-bg")
    # visit
    card(fid, "Visit card", 24, 227, 312, 193)
    rtext(fid, "Visit title", "الزيارة القادمة", 320, 246, 16, 700, "text/primary", lh=1.5)
    chip(fid, 40, 244, "بانتظار ردّك", "warn", "clock")
    rtext(fid, "Visit date", "الجمعة 20 نوفمبر", 320, 282, 20, 700, "text/primary", lh=1.5)
    rtext(fid, "Visit meta", "10:00 – 14:00 · اقترحها الطرف الآخر", 320, 318, 14, 400, "text/secondary", lh=1.5)
    button(fid, "قبول", 186, 355, 134, 48, "primary")
    button(fid, "رفض", 40, 355, 134, 48, "outline")
    # assistant
    card(fid, "Assistant card", 24, 436, 312, 196)
    A.ellipse(fid, "Assistant mark", 276, 453, 40, 40, fill="accent/soft")
    A.icon(fid, "Assistant icon", "chat", 286, 463, 20, "action/primary")
    rtext(fid, "Assistant title", "المساعد القانوني", 264, 461, 16, 700, "text/primary", lh=1.5)
    A.rect(fid, "Ask field", 40, 505, 280, 56, fill="surface/card", stroke="border/strong", r=12)
    rtext(fid, "Ask placeholder", "اسأل عن قانون الأسرة…", 304, 519, 16, 400, "text/tertiary", lh=1.4)
    A.ellipse(fid, "Ask send", 49, 513, 40, 40, fill="action/primary")
    A.icon(fid, "Ask send icon", "send", 59, 523, 20, "text/on-action")
    A.text(fid, "Assistant note", "أجوبة من نصوص قانون الأسرة الجزائري. لا تكتب أسماء أو تفاصيل قضية.", 40, 573, 14, 400,
           "text/secondary", w=280, lh=1.5)
    tabbar(fid, 0)


def screen_report(fid):
    shell(fid)
    appbar_title(fid, "بلاغ جديد")
    A.label(fid, "ماذا حدث؟", 92)
    A.rect(fid, "Description control", 24, 121, 312, 120, fill="surface/card", stroke="border/focus", sw=2, r=12)
    A.text(fid, "Description placeholder", "صف ما حدث بإيجاز: ماذا، ومتى، وأين، ومن كان حاضرًا.", 40, 133, 16, 400, "text/tertiary", w=280)
    A.field(fid, "تاريخ الحادثة ووقتها", 257, "cal", "17 نوفمبر 2026 · 09:30", ltr=False)
    rtext(fid, "Attachments", "المرفقات", 336, 358, 14, 500, "text/primary", lh=1.65)
    A.text(fid, "Attachments count", "2 من 5", 24, 358, 14, 400, "text/secondary", w=80, align="left")
    bw = (312 - 16) / 3
    for i, (label, icon) in enumerate([("صورة", "image"), ("فيديو", "video"), ("ملف", "clip")]):
        button(fid, label, 24 + (2 - i) * (bw + 8), 387, bw, 56, "outline", icon)
    # file rows
    card(fid, "File 1", 24, 455, 312, 56)
    A.rect(fid, "File 1 tile", 280, 463, 40, 40, fill="surface/sunken", r=8)
    A.icon(fid, "File 1 icon", "image", 290, 473, 20, "text/secondary")
    rtext(fid, "File 1 name", "صورة 1", 268, 464, 14, 500, "text/primary", lh=1.5)
    rtext(fid, "File 1 size", "2.4 ميغابايت", 268, 486, 14, 400, "text/secondary", lh=1.5)
    A.icon(fid, "File 1 remove", "x", 42, 473, 20, "text/secondary")
    card(fid, "File 2", 24, 519, 312, 66)
    A.rect(fid, "File 2 tile", 280, 532, 40, 40, fill="surface/sunken", r=8)
    A.icon(fid, "File 2 icon", "video", 290, 542, 20, "text/secondary")
    rtext(fid, "File 2 name", "فيديو 1", 268, 533, 14, 500, "text/primary", lh=1.5)
    rtext(fid, "File 2 status", "جارٍ الضغط، 60٪", 268, 554, 14, 400, "text/secondary", lh=1.5)
    A.rect(fid, "Progress track", 88, 577, 180, 4, fill="border/default", r=2)
    A.rect(fid, "Progress fill", 88 + 72, 577, 108, 4, fill="action/primary", r=2)
    A.icon(fid, "File 2 remove", "x", 42, 542, 20, "text/secondary")
    rtext(fid, "Limits", "حتى 5 ملفات، وبحد أقصى 30 ميغابايت للملف.", 336, 597, 14, 400, "text/secondary", lh=1.5)
    A.icon(fid, "Privacy lock", "lock", 316, 644, 20, "text/secondary")
    A.text(fid, "Privacy note", "لا يطّلع على هذا البلاغ إلا أنت وفريق الإدارة.", 24, 644, 14, 400, "text/secondary", w=284, lh=1.5)
    button(fid, "إرسال البلاغ", 24, 704, 312, 56, "primary")


def screen_summary(fid):
    shell(fid)
    appbar_title(fid, "تفاصيل البلاغ")
    A.ellipse(fid, "Done mark", 268, 92, 64, 64, fill="accent/soft")
    A.icon(fid, "Done icon", "check", 284, 108, 32, "action/primary")
    rtext(fid, "Title", "تم إرسال البلاغ", 252, 92, 24, 700, "text/primary", lh=1.4)
    tmp, tw, _ = A.text(fid, "tmp", "RIA-2026-0142", 0, 0, 14, 500, "text/primary", lh=1.5, direction="ltr")
    A.ex("edit.delete", ids=[tmp])
    cw = 24 + tw
    A.rect(fid, "Reference chip", 252 - cw, 129, cw, 28, fill="surface/sunken", r=14)
    A.text(fid, "Reference", "RIA-2026-0142", 252 - cw, 132.5, 14, 500, "text/primary", w=cw, align="center", lh=1.5, direction="ltr")
    card(fid, "Facts card", 24, 173, 312, 239)
    # rows
    rtext(fid, "Status label", "الحالة", 320, 188, 14, 400, "text/secondary", lh=1.5)
    chip(fid, 40, 186, "قيد المراجعة", "info")
    A.rect(fid, "Row line 1", 40, 222, 280, 1, fill="border/default")
    rtext(fid, "Date label", "تاريخ الحادثة", 320, 232, 14, 400, "text/secondary", lh=1.5)
    A.text(fid, "Date value", "17 نوفمبر 2026 · 09:30", 40, 232, 14, 500, "text/primary", w=200, align="left", lh=1.5)
    A.rect(fid, "Row line 2", 40, 266, 280, 1, fill="border/default")
    rtext(fid, "Files label", "المرفقات", 320, 276, 14, 400, "text/secondary", lh=1.5)
    A.text(fid, "Files value", "صورة وفيديو", 40, 276, 14, 500, "text/primary", w=200, align="left", lh=1.5)
    A.rect(fid, "Row line 3", 40, 310, 280, 1, fill="border/default")
    rtext(fid, "Description label", "الوصف", 320, 322, 14, 400, "text/secondary", lh=1.5)
    A.text(fid, "Description", "عند تسليم الطفل بعد الزيارة لاحظتُ كدمة على ذراعه ولم يُقدَّم أي تفسير. صوّرتُ المكان فورًا.",
           40, 349, 14, 400, "text/primary", w=280, lh=1.5)
    # pdf
    card(fid, "PDF card", 24, 424, 312, 66)
    A.rect(fid, "PDF tile", 280, 437, 40, 40, fill="surface/sunken", r=8)
    A.icon(fid, "PDF icon", "file", 290, 447, 20, "text/secondary")
    rtext(fid, "PDF name", "تقرير البلاغ", 268, 438, 14, 500, "text/primary", lh=1.5)
    rtext(fid, "PDF size", "ملف PDF · 214 كيلوبايت", 268, 460, 14, 400, "text/secondary", lh=1.5)
    A.ellipse(fid, "PDF download", 28, 433, 48, 48, fill="action/primary")
    A.icon(fid, "PDF download icon", "download", 42, 447, 20, "text/on-action")
    button(fid, "حفظ", 186, 502, 134, 48, "outline", "download")
    button(fid, "طباعة", 40, 502, 134, 48, "outline", "print")
    A.icon(fid, "Evidence lock", "lock", 316, 562, 20, "text/secondary")
    A.text(fid, "Evidence note", "لا يمكن حذف البلاغ بعد إرساله، للحفاظ عليه كدليل.", 24, 562, 14, 400, "text/secondary", w=284, lh=1.5)
    tabbar(fid, 3)


APP_SCREENS = [
    ("Link co-parent", screen_link, "surface/page"),
    ("Home", screen_home, "surface/page"),
    ("New report", screen_report, "surface/page"),
    ("Report summary", screen_summary, "surface/page"),
]


# ----------------------------------------------------------------------------- main
def build(group, screens, row, mode, made):
    for i, (name, fn, bg) in enumerate(screens):
        title = f"{group} / {name}" + (" (dark)" if mode == "Dark" else "")
        fid = A.new_frame(title, i * (W + 80), row * (H + 120), bg)
        fn(fid)
        if mode == "Dark":
            A.ex("variable.setMode", ids=[fid], collection=A.COLL, mode="Dark")
        fname = title.replace(" / ", "_").replace(" ", "-") + ".png"
        A.ex("file.export", ids=[fid], format="png", scale=1.5, path=os.path.join(A.OUT, fname))
        made.append(title)
        print("built", title, fid)


def main(only=None):
    if not A.fc.is_running():
        sys.exit("FigCraft is not running on 7979. Start: figcraft.exe --control 7979")
    for f in sorted(glob.glob(os.path.join(A.FONT_DIR, "*", "otf", "*.otf"))):
        A.ex("text.loadFont", path=f.replace("\\", "/"))
    page = A.ex("page.list")[0]["id"]
    A.ex("page.select", id=page)
    A.ex("page.setBackground", id=page, color="#E9EDE5")
    mine = [i for i in A.ex("node.find", type="FRAME", limit=1000)["ids"]
            if A.ex("node.get", id=i).get("name", "").startswith(("Auth /", "App /", "__probe"))]
    if mine:
        A.ex("edit.delete", ids=mine)
    A.setup_variables()
    os.makedirs(A.OUT, exist_ok=True)
    made = []
    row = 0
    for group, screens in (("Auth", A.SCREENS), ("App", APP_SCREENS)):
        if only and only.lower() != group.lower():
            continue
        for mode in ("Light", "Dark"):
            build(group, screens, row, mode, made)
            row += 1
    return made


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
