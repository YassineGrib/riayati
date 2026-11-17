#!/usr/bin/env python3
"""Admin panel screens for FigCraft (desktop 1280 x 800, Arabic RTL). Mirrors 02-design/admin/index.html.

The admin is a website, so it uses IBM Plex Sans Arabic (the thmanyah license forbids serving that font on the web).
Used by build_doc.py (page "08 Admin"); light and dark rows like every other page.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import build_auth as A  # noqa: E402
import build_app as B  # noqa: E402
import build_cal as C  # noqa: E402,F401
import build_reports as R  # noqa: E402,F401

AW, AH = 1280, 800
WEB_FONT = "IBM Plex Sans Arabic"

A.ICONS.update({
    "search": ["M21 21l-4.3-4.3", "M19 11a8 8 0 1 1-16 0 8 8 0 0 1 16 0z"],
    "trash": ["M3 6h18", "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6", "M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"],
    "refresh": ["M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8", "M21 3v5h-5", "M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16", "M8 16H3v5"],
})


# --------------------------------------------------------------------------- helpers
def rt(f, s, right, y, size=14, weight=400, color="text/primary", lh=1.4, direction="rtl"):
    """Right-anchored auto-width text."""
    return B.rtext(f, "Text", s, right, y, size, weight, color, lh=lh, direction=direction)


def lt(f, s, x, y, size=14, weight=400, color="text/primary", lh=1.4, direction="rtl", w=None, align="left"):
    return A.text(f, "Text", s, x, y, size, weight, color, w=w, align=align, lh=lh, direction=direction)


def measure(f, s, size, weight, direction="rtl", lh=1.4):
    tmp, tw, th = A.text(f, "tmp", s, 0, 0, size, weight, "text/primary", lh=lh, direction=direction)
    A.ex("edit.delete", ids=[tmp])
    return tw


def btn(f, x, y, w, h, label, kind="outline", icon=None):
    fill, stroke, col = {
        "primary": ("action/primary", None, "text/on-action"),
        "outline": ("surface/card", "border/strong", "text/primary"),
        "danger": ("action/destructive", None, "text/on-action"),
        "danger-o": ("surface/card", "feedback/error-border", "feedback/error-text"),
    }[kind]
    A.rect(f, f"Button {label}", x, y, w, h, fill=fill, stroke=stroke, sw=1, r=8)
    tw = measure(f, label, 14, 600)
    total = tw + (16 + 8 if icon else 0)
    start = x + (w - total) / 2
    tid, _, _ = A.text(f, f"Button label {label}", label, 0, y + (h - 20) / 2, 14, 600, col, lh=1.4)
    A.ex("node.set", id=tid, x=start)
    if icon:
        A.icon(f, f"Button icon {label}", icon, start + tw + 8, y + (h - 16) / 2, 16, col)


def badge(f, right, y, label, kind, icon=None):
    fill, col = {"info": ("feedback/info-bg", "feedback/info-text"), "ok": ("feedback/success-bg", "feedback/success-text"),
                 "warn": ("feedback/warning-bg", "feedback/warning-text"), "bad": ("feedback/error-bg", "feedback/error-text"),
                 "gray": ("surface/sunken", "text/primary")}[kind]
    tw = measure(f, label, 12, 600)
    w = 24 + (18 if icon else 0) + tw
    A.rect(f, f"Badge {label}", right - w, y, w, 24, fill=fill, r=12)
    r = right - 12
    if icon:
        A.icon(f, "Badge icon", icon, r - 14, y + 5, 14, col)
        r -= 18
    tid, _, _ = A.text(f, f"Badge label {label}", label, 0, y + 4, 12, 600, col, lh=1.4)
    A.ex("node.set", id=tid, x=r - tw)
    return w


def hline(f, x, y, w, color="border/default"):
    A.rect(f, "Line", x, y, w, 1, fill=color)


def card(f, x, y, w, h):
    return A.rect(f, "Card", x, y, w, h, fill="surface/card", stroke="border/default", sw=1, r=12)


def new_frame(name, x, y):
    fid = A.ex("frame.create", x=x, y=y, width=AW, height=AH, name=name, select=False,
               props={"fill": A.LIGHT["surface/sunken"], "clip": True})["id"]
    A.bind(fid, "fill", "surface/sunken")
    # Logo-ribbon watermarks behind the page area, so the panel is not a flat empty sheet.
    # Drawn first: the sidebar and top bar (opaque) cover whatever spills into them.
    A.watermark(fid, -230, 30, 760, -24, opacity=0.09)
    A.watermark(fid, 560, 470, 640, 156, opacity=0.09)
    return fid


def shell(f, active, c1, c2):
    # sidebar
    A.rect(f, "Sidebar", 1012, 0, 268, AH, fill="surface/card")
    A.rect(f, "Sidebar divider", 1012, 0, 1, AH, fill="border/default")
    # Watermark in the empty middle of the sidebar, cut off by a clipped frame so it cannot spill.
    clip = A.ex("frame.create", x=1013, y=190, width=266, height=510, parent=f, name="Sidebar watermark", select=False,
                props={"clip": True})["id"]
    A.ex("node.set", id=clip, fill="none")
    A.watermark(clip, -120, 120, 520, -24, opacity=0.09)
    A.logo(f, 1223, 29, 36)
    rt(f, "رعايتي", 1211, 20, 20, 700, "text/primary")
    rt(f, "لوحة الإدارة", 1211, 49, 12, 500, "text/secondary")
    items = [("reports", "البلاغات", "file", "5", 96), ("legal", "النصوص القانونية", "book", "", 144)]
    for key, label, icon, count, y in items:
        on = key == active
        if on:
            A.rect(f, f"Nav {label} active", 1028, y, 231, 44, fill="interactive/selected-bg", r=8)
        col = "text/link" if on else "text/secondary"
        A.icon(f, f"Nav icon {label}", icon, 1227, y + 12, 20, col)
        rt(f, label, 1215, y + 11, 16, 700 if on else 500, col, lh=1.4)
        if count:
            A.rect(f, "Nav count", 1040, y + 10, 24, 24, fill="action/primary", r=12)
            A.text(f, "Nav count text", count, 1040, y + 14, 12, 700, "text/on-action", w=24, align="center", lh=1.4)
    A.rect(f, "Admin card", 1028, 718, 231, 62, fill="surface/sunken", r=8)
    A.ellipse(f, "Admin avatar", 1211, 731, 36, 36, fill="accent/soft")
    A.text(f, "Avatar letter", "م", 1211, 739, 16, 700, "action/primary", w=36, align="center", lh=1.4)
    rt(f, "المسؤول", 1199, 728, 14, 700, "text/primary")
    rt(f, "admin@example.com", 1199, 750, 12, 400, "text/secondary", direction="ltr")
    # top bar
    A.rect(f, "Top bar", 0, 0, 1012, 64, fill="surface/card")
    hline(f, 0, 63, 1012)
    w2 = measure(f, c2, 14, 600)
    w1 = measure(f, c1, 14, 400)
    rt(f, c1, 980, 21, 14, 400, "text/secondary")
    A.icon(f, "Crumb sep", "chevl", 980 - w1 - 8 - 16, 23, 16, "text/secondary")
    rt(f, c2, 980 - w1 - 8 - 16 - 8, 21, 14, 600, "text/primary")
    A.icon(f, "Search", "search", 130, 21, 20, "text/secondary")
    A.icon(f, "Notifications", "bell", 86, 21, 20, "text/secondary")
    A.ellipse(f, "Unread dot", 97, 19, 9, 9, fill="sos/bg", stroke="surface/card", sw=2)
    A.icon(f, "Logout", "logout", 42, 21, 20, "text/secondary")


def page_title(f, s, ltr=False):
    rt(f, s, 980, 88, 30, 700, "text/primary", lh=1.4, direction="ltr" if ltr else "rtl")


def field_box(f, x, y, w, h=40, focus=False):
    A.rect(f, "Field", x, y, w, h, fill="surface/card", stroke="border/focus" if focus else "border/strong", sw=2 if focus else 1, r=8)


def toolbar_search(f, y, right, placeholder):
    field_box(f, right - 360, y, 360)
    A.icon(f, "Search icon", "search", right - 28, y + 12, 16, "text/secondary")
    rt(f, placeholder, right - 36, y + 10, 14, 400, "text/tertiary")


def th(f, labels, y, rights):
    A.rect(f, "Table head", 33, y, 947, 42, fill="surface/sunken")
    hline(f, 33, y + 41, 947)
    for s, r in zip(labels, rights):
        if s:
            rt(f, s, r - 20, y + 12, 12, 600, "text/secondary")


# --------------------------------------------------------------------------- screens
def screen_inbox(f):
    shell(f, "reports", "البلاغات", "قائمة البلاغات")
    page_title(f, "البلاغات")
    stats = [(675, "قيد المراجعة", "5", "تحتاج إلى مراجعة"), (353, "تمت مراجعتها", "12", "منذ بداية الاستخدام"), (32, "وردت هذا الأسبوع", "4", "آخر بلاغ قبل ساعتين")]
    for x, small, big, sub in stats:
        card(f, x, 150, 306, 122)
        rt(f, small, x + 285, 169, 14, 500, "text/secondary", lh=1.3)
        rt(f, big, x + 285, 191, 30, 700, "text/primary", lh=1.4)
        rt(f, sub, x + 285, 236, 12, 400, "text/secondary", lh=1.4)
    card(f, 32, 291, 949, 481)
    toolbar_search(f, 304, 960, "ابحث برقم البلاغ أو اسم مقدّم البلاغ")
    for x, label in ((408, "الحالة: الكل"), (216, "الدور: الكل")):
        field_box(f, x, 304, 180)
        rt(f, label, x + 168, 314, 14, 400, "text/secondary")
    hline(f, 33, 357, 947)
    rights = [979, 815, 698, 477, 374, 189]
    th(f, ["رقم البلاغ", "مقدّم البلاغ", "تاريخ الحادثة", "المرفقات", "الحالة", ""], 357, rights)
    rows = [("RIA-2026-0142", "أمينة", "أم", "17 نوفمبر 2026 · 09:30", "2", "info"),
            ("RIA-2026-0141", "ياسين", "أب", "16 نوفمبر 2026 · 20:10", "0", "info"),
            ("RIA-2026-0140", "أمينة", "أم", "14 نوفمبر 2026 · 08:45", "3", "info"),
            ("RIA-2026-0138", "ياسين", "أب", "9 نوفمبر 2026 · 18:05", "1", "ok"),
            ("RIA-2026-0131", "أمينة", "أم", "28 أكتوبر 2026 · 11:20", "0", "ok")]
    y = 399
    for i, (ref, name, role, date, n, st) in enumerate(rows):
        h = 67 if i < 4 else 66
        rt(f, ref, 959, y + 23, 13, 500, "text/primary", direction="ltr")
        rt(f, name, 795, y + 14, 14, 600, "text/primary", lh=1.5)
        rt(f, role, 795, y + 36, 12, 400, "text/secondary", lh=1.5)
        rt(f, date, 678, y + 23, 14, 400, "text/primary")
        rt(f, n, 457, y + 23, 14, 400, "text/primary")
        if st == "info":
            badge(f, 355, y + 22, "قيد المراجعة", "info")
        else:
            badge(f, 355, y + 22, "تمت المراجعة", "ok", "check")
        btn(f, 52, y + 14, 86, 40, "عرض", "outline", "eye")
        if i < 4:
            hline(f, 33, y + h - 1, 947)
        y += h
    hline(f, 33, 733, 947)
    rt(f, "عرض 1 – 5 من 17", 960, 746, 14, 400, "text/secondary")
    lt(f, "الصفحة 1 من 4", 52, 746, 14, 400, "text/secondary")


def screen_detail(f):
    shell(f, "reports", "البلاغات", "RIA-2026-0142")
    page_title(f, "RIA-2026-0142", ltr=True)
    badge(f, 754, 97, "قيد المراجعة", "info")
    btn(f, 209, 89, 147, 40, "تنزيل التقرير PDF", "outline", "download")
    btn(f, 32, 89, 165, 40, "تعليم كتمّت المراجعة", "primary", "check")
    card(f, 361, 150, 619, 156)
    rt(f, "الوصف", 959, 166, 16, 700, "text/primary", lh=1.5)
    hline(f, 362, 207, 617)
    A.text(f, "Text", "عند تسليم الطفل بعد الزيارة لاحظتُ كدمة على ذراعه ولم يُقدَّم أي تفسير. صوّرتُ المكان فورًا وأرفقتُ الصورة والفيديو.",
           382, 227, 16, 400, "text/primary", w=578, align="right", lh=1.8)
    card(f, 361, 326, 619, 337)
    rt(f, "المرفقات", 959, 342, 16, 700, "text/primary", lh=1.5)
    badge(f, 413, 342, "2", "gray")
    hline(f, 362, 383, 617)
    for x, name, size, icon in ((775, "صورة 1", "2.4 ميغابايت", "image"), (579, "فيديو 1", "18 ميغابايت", "video")):
        A.rect(f, "Tile", x, 403, 185, 162, fill="surface/card", stroke="border/default", sw=1, r=8)
        A.rect(f, "Tile preview", x + 1, 404, 183, 96, fill="surface/sunken", r=7)
        A.icon(f, "Tile icon", icon, x + 76, 436, 32, "text/secondary")
        rt(f, name, x + 172, 513, 14, 700, "text/primary", lh=1.5)
        rt(f, size, x + 172, 534, 12, 400, "text/secondary", lh=1.4)
        btn(f, x + 13, 512, 45, 40, "فتح", "outline")
    A.rect(f, "Note", 382, 581, 578, 47, fill="feedback/info-bg", stroke="feedback/info-border", sw=1, r=8)
    A.icon(f, "Note icon", "lock", 928, 595, 16, "feedback/info-icon")
    rt(f, "روابط الملفات مؤقتة وتنتهي بعد وقت قصير. افتح الملف من هنا عند الحاجة.", 916, 593, 14, 400, "feedback/info-text", lh=1.5)
    # reporter
    card(f, 32, 150, 310, 252)
    rt(f, "مقدّم البلاغ", 320, 166, 16, 700, "text/primary", lh=1.5)
    hline(f, 33, 207, 308)
    kv = [("الاسم", "أمينة"), ("الدور", "أم"), ("البريد", "amina@example.com"), ("تاريخ الحادثة", "17 نوفمبر 2026 · 09:30"), ("أُرسل في", "17 نوفمبر 2026 · 09:41")]
    for i, (k, v) in enumerate(kv):
        yy = 227 + i * 33
        rt(f, k, 320, yy, 14, 400, "text/secondary", lh=1.5)
        lt(f, v, 52, yy, 14, 600, "text/primary", lh=1.5, direction="ltr" if "@" in v else "rtl", w=200, align="left")
    # status log
    card(f, 32, 421, 310, 191)
    rt(f, "سجل الحالة", 320, 438, 16, 700, "text/primary", lh=1.5)
    hline(f, 33, 479, 308)
    A.ellipse(f, "Step 1", 296, 499, 24, 24, fill="action/primary")
    A.icon(f, "Step 1 icon", "check", 301, 504, 14, "text/on-action")
    A.rect(f, "Step line", 307, 523, 2, 30, fill="border/default")
    rt(f, "أُرسل البلاغ", 284, 499, 14, 700, "text/primary", lh=1.5)
    rt(f, "17 نوفمبر 2026 · 09:41", 284, 520, 12, 400, "text/secondary", lh=1.4)
    A.ellipse(f, "Step 2", 296, 553, 24, 24, fill="feedback/info-bg")
    A.icon(f, "Step 2 icon", "clock", 301, 558, 14, "feedback/info-text")
    rt(f, "قيد المراجعة", 284, 553, 14, 700, "text/primary", lh=1.5)
    rt(f, "بانتظار الإدارة", 284, 574, 12, 400, "text/secondary", lh=1.4)


LEGAL_ROWS = [
    ("قانون الأسرة · المادة 64", "قانون الأسرة", "FC-064", "15 نوفمبر 2026", "ok", "مفهرس", "edit"),
    ("قانون الأسرة · المادة 65", "قانون الأسرة", "FC-065", "15 نوفمبر 2026", "ok", "مفهرس", "edit"),
    ("قانون الأسرة · المادة 66", "قانون الأسرة", "FC-066", "اليوم · 09:12", "info", "قيد الفهرسة", "edit"),
    ("قرار المحكمة العليا (مثال 1)", "المحكمة العليا", "SC-0001", "12 نوفمبر 2026", "bad", "تعذّرت الفهرسة", "retry"),
    ("قرار المحكمة العليا (مثال 2)", "المحكمة العليا", "SC-0002", "12 نوفمبر 2026", "ok", "مفهرس", "edit"),
]


def screen_legal_list(f):
    shell(f, "legal", "النصوص القانونية", "قائمة النصوص")
    page_title(f, "النصوص القانونية")
    btn(f, 32, 89, 120, 40, "إضافة نص", "primary", "plus")
    card(f, 32, 150, 949, 530)
    # tabs
    tabs = [("الكل (24)", 874, 86, True), ("قانون الأسرة (18)", 743, 127, False), ("قرارات المحكمة العليا (6)", 571, 168, False)]
    hline(f, 33, 193, 947)
    for label, x, w, on in tabs:
        A.text(f, "Tab", label, x, 160, 14, 600, "text/link" if on else "text/secondary", w=w, align="center", lh=1.4)
        if on:
            A.rect(f, "Tab underline", x, 192, w, 2, fill="action/primary")
    toolbar_search(f, 206, 960, "ابحث في العنوان أو المرجع أو النص")
    field_box(f, 388, 206, 200)
    rt(f, "الفهرسة: الكل", 576, 216, 14, 400, "text/secondary")
    hline(f, 33, 258, 947)
    th(f, ["العنوان", "النوع", "المرجع", "آخر تحديث", "الفهرسة", ""], 259, [980, 793, 663, 575, 448, 294])
    y = 301
    for i, (title, typ, ref, date, st, stlabel, act) in enumerate(LEGAL_ROWS):
        h = 66
        rt(f, title, 960, y + 22, 14, 600, "text/primary", lh=1.5)
        badge(f, 773, y + 21, typ, "gray")
        rt(f, ref, 643, y + 22, 13, 500, "text/primary", direction="ltr")
        rt(f, date, 555, y + 22, 14, 400, "text/primary")
        badge(f, 428, y + 21, stlabel, st, {"ok": "check", "info": "clock", "bad": "alert"}[st])
        if act == "retry":
            btn(f, 52, y + 13, 150, 40, "إعادة المحاولة", "outline", "refresh")
            btn(f, 206, y + 13, 80, 40, "حذف", "danger-o", "trash")
        else:
            btn(f, 52, y + 13, 80, 40, "حذف", "danger-o", "trash")
            btn(f, 136, y + 13, 98, 40, "تعديل", "outline", "pencil")
        if i < 4:
            hline(f, 33, y + h - 1, 947)
        y += h
    hline(f, 33, 633, 947)
    rt(f, "عرض 1 – 5 من 24", 960, 646, 14, 400, "text/secondary")
    lt(f, "الصفحة 1 من 5", 52, 646, 14, 400, "text/secondary")


def screen_legal_edit(f):
    shell(f, "legal", "النصوص القانونية", "تعديل")
    page_title(f, "تعديل: قانون الأسرة · المادة 64")
    card(f, 361, 150, 619, 605)
    rt(f, "العنوان", 960, 170, 14, 600, "text/primary", lh=1.5)
    field_box(f, 382, 197, 578, 44, focus=True)
    rt(f, "قانون الأسرة · المادة 64", 944, 209, 14, 400, "text/primary")
    rt(f, "النوع", 960, 257, 14, 600, "text/primary", lh=1.5)
    field_box(f, 679, 284, 281, 44)
    rt(f, "قانون الأسرة", 944, 296, 14, 400, "text/primary")
    A.icon(f, "Chevron", "chevl", 695, 298, 16, "text/secondary")
    rt(f, "المرجع", 663, 257, 14, 600, "text/primary", lh=1.5)
    field_box(f, 382, 284, 281, 44)
    rt(f, "FC-064", 647, 296, 14, 400, "text/primary", direction="ltr")
    rt(f, "النص الكامل", 960, 344, 14, 600, "text/primary", lh=1.5)
    A.rect(f, "Textarea", 382, 371, 578, 224, fill="surface/card", stroke="border/strong", sw=1, r=8)
    A.text(f, "Text", "نص تجريبي لا يمثّل نص المادة الحقيقي. يُلصق هنا نص المادة كما ورد في المصدر المعتمد الذي قدّمه العميل، ثم يُحفظ، فتُعاد فهرسته تلقائيًا ليستخدمه المساعد القانوني في إجاباته مع ذكر المرجع.",
           398, 383, 16, 400, "text/primary", w=546, align="right", lh=1.8)
    rt(f, "يُقسَّم النص تلقائيًا إلى مقاطع صغيرة عند الفهرسة.", 960, 601, 12, 400, "text/secondary", lh=1.5)
    A.rect(f, "Switch", 920, 644, 40, 24, fill="action/primary", r=12)
    A.ellipse(f, "Switch knob", 923, 647, 18, 18, fill="text/on-action")
    rt(f, "مفعّل", 908, 635, 14, 700, "text/primary", lh=1.5)
    rt(f, "يستخدمه المساعد في إجاباته.", 908, 659, 12, 400, "text/secondary", lh=1.5)
    btn(f, 851, 693, 108, 40, "حفظ التغييرات", "primary")
    btn(f, 783, 693, 56, 40, "إلغاء", "outline")
    # indexing
    card(f, 32, 150, 310, 250)
    rt(f, "الفهرسة", 320, 166, 16, 700, "text/primary", lh=1.5)
    badge(f, 131, 166, "مفهرس", "ok", "check")
    hline(f, 33, 207, 308)
    rt(f, "المقاطع", 320, 227, 14, 400, "text/secondary", lh=1.5)
    lt(f, "38", 52, 227, 14, 600, "text/primary", lh=1.5, w=100, align="left")
    rt(f, "آخر فهرسة", 320, 260, 14, 400, "text/secondary", lh=1.5)
    lt(f, "قبل دقيقتين", 52, 260, 14, 600, "text/primary", lh=1.5, w=150, align="left")
    A.rect(f, "Note", 52, 297, 268, 68, fill="feedback/info-bg", stroke="feedback/info-border", sw=1, r=8)
    A.icon(f, "Note icon", "info", 292, 311, 16, "feedback/info-icon")
    A.text(f, "Text", "بعد الحفظ تُعاد الفهرسة تلقائيًا، ويظهر التحديث في المساعد خلال دقيقة تقريبًا.", 64, 309, 14, 400,
           "feedback/info-text", w=216, align="right", lh=1.5)
    # danger zone
    card(f, 32, 420, 310, 192)
    rt(f, "منطقة الحذف", 320, 436, 16, 700, "text/primary", lh=1.5)
    hline(f, 33, 477, 308)
    A.text(f, "Text", "عند الحذف لن يستخدم المساعد هذا النص بعد الآن.", 52, 497, 14, 400, "text/secondary", w=268, align="right", lh=1.5)
    btn(f, 202, 551, 119, 40, "حذف النص", "danger-o", "trash")


def screen_delete_modal(f):
    screen_legal_list(f)
    scrim = A.ex("shape.rectangle", x=0, y=0, width=AW, height=AH, parent=f, name="Scrim", select=False,
                 props={"fill": "#0D140A", "opacity": 0.5})["id"]
    m = A.rect(f, "Modal", 418, 259, 440, 279, fill="surface/raised", r=16)
    A.ex("effect.add", ids=[m], effect={"type": "dropShadow", "offset": [0, 16], "radius": 48, "color": "#00000059"})
    A.ellipse(f, "Modal icon bg", 610, 283, 56, 56, fill="feedback/error-bg")
    A.icon(f, "Modal icon", "trash", 624, 297, 28, "feedback/error-icon")
    A.text(f, "Text", "حذف النص؟", 418, 351, 20, 700, "text/primary", w=440, align="center", lh=1.5)
    A.text(f, "Text", "سيُحذف «قانون الأسرة · المادة 64» ولن يستخدمه المساعد بعد الآن. لا يمكن التراجع عن هذا الإجراء.",
           442, 393, 16, 400, "text/secondary", w=392, align="center", lh=1.65)
    btn(f, 644, 469, 190, 44, "حذف", "danger")
    btn(f, 442, 469, 190, 44, "إلغاء", "outline")


ADMIN_SCREENS = [
    ("Incident inbox", screen_inbox),
    ("Incident detail", screen_detail),
    ("Legal texts list", screen_legal_list),
    ("Legal text editor", screen_legal_edit),
    ("Delete confirmation", screen_delete_modal),
]


def build_admin_page(pid, page_header, made):
    """Light and dark rows of the five admin screens, each row in a section."""
    saved = (A.FONT, A.DISPLAY, A.SERIF)
    A.FONT = A.DISPLAY = A.SERIF = WEB_FONT
    try:
        A.ex("page.select", id=pid)
        A.ex("page.setBackground", id=pid, color="#E9EDE5")
        page_header("08 Admin", "Admin panel (Filament): incident inbox and detail, legal texts list and editor. Web font: IBM Plex Sans Arabic.")
        for r, mode in enumerate(("Light", "Dark")):
            ids = []
            for i, (name, fn) in enumerate(ADMIN_SCREENS):
                fid = new_frame(f"{name} / {mode}", (i % 3) * (AW + 80), (r * 2 + i // 3) * (AH + 120), )
                fn(fid)
                if mode == "Dark":
                    A.ex("variable.setMode", ids=[fid], collection=A.COLL, mode="Dark")
                A.ex("file.export", ids=[fid], format="png", scale=1,
                     path=os.path.join(A.OUT, f"08-Admin_{name.replace(' ', '-')}_{mode}.png"))
                ids.append(fid)
                made.append(f"Admin / {name} / {mode}")
                print("built Admin /", name, "/", mode, flush=True)
            A.ex("object.wrapInSection", ids=ids, name=f"Admin · {mode}")
    finally:
        A.FONT, A.DISPLAY, A.SERIF = saved
