#!/usr/bin/env python3
"""My reports (list, empty) and Profile (linked, unlinked) for FigCraft. Mirrors 02-design/reports-profile/index.html.
Build everything with build_all.py."""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import build_auth as A  # noqa: E402
import build_app as B  # noqa: E402
import build_cal as C  # noqa: E402,F401  (registers chevron icons)

A.ICONS.update({
    "link": ["M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71", "M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"],
    "pencil": ["M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z", "M15 5l4 4"],
    "logout": ["M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4", "M16 17l5-5-5-5", "M21 12H9"],
})


def rchip(fid, right, y, label, kind, icon=None, direction="rtl"):
    """Chip whose right edge sits at `right`."""
    fill, col = {"warn": ("feedback/warning-bg", "feedback/warning-text"), "neutral": ("surface/sunken", "text/primary"),
                 "ok": ("feedback/success-bg", "feedback/success-text"), "info": ("feedback/info-bg", "feedback/info-text")}[kind]
    tmp, tw, _ = A.text(fid, "tmp", label, 0, 0, 14, 500, col, lh=1.5, direction=direction)
    A.ex("edit.delete", ids=[tmp])
    w = 24 + (22 if icon else 0) + tw
    B.chip(fid, right - w, y, label, kind, icon, direction)


def report_card(fid, y, ref, status, kind, date, excerpt, files, lines=2):
    h = 176 if lines == 2 else 155
    B.card(fid, f"Report {ref}", 24, y, 312, h)
    rchip(fid, 320, y + 16, ref, "neutral", direction="ltr")
    B.chip(fid, 40, y + 16, status, kind)
    B.rtext(fid, "Date", date, 320, y + 52, 14, 400, "text/secondary", lh=1.5)
    A.text(fid, "Excerpt", excerpt, 40, y + 81, 14, 400, "text/primary", w=280, lh=1.5)
    fy = y + 81 + 21 * lines + 12
    A.icon(fid, "Files icon", "clip", 304, fy + 3, 16, "text/secondary")
    B.rtext(fid, "Files", files, 298, fy, 14, 400, "text/secondary", lh=1.65)
    A.icon(fid, "Open", "chevl", 40, fy + 3, 16, "text/secondary")


def screen_reports(fid):
    B.shell(fid)
    B.rtext(fid, "Title", "بلاغاتي", 336, 46, 20, 700, "text/primary", lh=1.4)
    A.rect(fid, "Filter", 24, 92, 312, 48, fill="surface/sunken", r=12)
    A.rect(fid, "Filter selected", 232, 92, 104, 48, fill="surface/card", stroke="border/strong", r=12)
    for i, (label, on) in enumerate([("الكل", True), ("قيد المراجعة", False), ("تمت المراجعة", False)]):
        A.text(fid, f"Filter {label}", label, 232 - i * 104, 104.5, 14, 700 if on else 500,
               "text/primary" if on else "text/secondary", w=104, align="center", lh=1.65)
    report_card(fid, 156, "RIA-2026-0142", "قيد المراجعة", "info", "17 نوفمبر 2026 · 09:30",
                "عند تسليم الطفل بعد الزيارة لاحظتُ كدمة على ذراعه ولم يُقدَّم أي تفسير.", "ملفان")
    report_card(fid, 343, "RIA-2026-0138", "تمت المراجعة", "ok", "9 نوفمبر 2026 · 18:05",
                "تأخّر تسليم الطفل عن الموعد المتفق عليه بأكثر من ساعتين دون إشعار مسبق.", "ملف واحد")
    report_card(fid, 531, "RIA-2026-0131", "تمت المراجعة", "ok", "28 أكتوبر 2026 · 11:20",
                "تغيّر مكان التسليم دون اتفاق مسبق وبدون إخباري.", "بدون مرفقات", lines=1)
    fab = A.rect(fid, "FAB", 16, 628, 135, 56, fill="action/primary", r=16)
    A.ex("effect.add", ids=[fab], effect={"type": "dropShadow", "offset": [0, 4], "radius": 16, "color": "#0000004d"})
    A.icon(fid, "FAB icon", "plus", 16 + 135 - 20 - 20, 646, 20, "text/on-action")
    tid, tw, _ = A.text(fid, "FAB label", "بلاغ جديد", 0, 645, 16, 700, "text/on-action", lh=1.65)
    A.ex("node.set", id=tid, x=16 + 135 - 40 - 8 - tw)
    B.tabbar(fid, 3)


def screen_reports_empty(fid):
    B.shell(fid)
    B.rtext(fid, "Title", "بلاغاتي", 336, 46, 20, 700, "text/primary", lh=1.4)
    A.ellipse(fid, "Empty mark", 140, 217, 80, 80, fill="accent/soft")
    A.icon(fid, "Empty icon", "file", 160, 237, 40, "action/primary")
    A.text(fid, "Title", "لا توجد بلاغات بعد", 0, 317, 24, 700, "text/primary", w=360, align="center", lh=1.4)
    A.text(fid, "Empty text", "عند توثيق حادثة ستظهر هنا بلاغاتك مع حالة كل بلاغ.", 32, 362, 16, 400, "text/secondary", w=296, align="center")
    B.button(fid, "بلاغ جديد", 102, 439, 156, 56, "primary", "plus")
    B.tabbar(fid, 3)


def profile_header(fid):
    B.rtext(fid, "Title", "حسابي", 336, 46, 20, 700, "text/primary", lh=1.4)
    A.ellipse(fid, "Avatar", 264, 100, 72, 72, fill="accent/soft")
    A.text(fid, "Title", "أ", 264, 115, 30, 700, "action/primary", w=72, align="center", lh=1.4)
    B.rtext(fid, "Title", "أمينة", 248, 92, 24, 700, "text/primary", lh=1.4)
    B.rtext(fid, "Email", "amina@example.com", 248, 125, 14, 400, "text/secondary", lh=1.5, direction="ltr")
    rchip(fid, 248, 152, "أم", "neutral")


def rows_card(fid, y):
    B.card(fid, "Settings card", 24, y, 312, 226)
    rows = [("pencil", "تعديل الاسم والبريد"), ("lock", "تغيير كلمة المرور"), ("shield", "خصوصية بياناتي"),
            ("file", "شروط الاستخدام وسياسة الخصوصية")]
    for i, (icon, label) in enumerate(rows):
        ry = y + 1 + i * 56
        if i:
            A.rect(fid, "Row line", 25, ry, 310, 1, fill="border/default")
        A.icon(fid, f"Row icon {label}", icon, 300, ry + 18, 20, "text/secondary")
        if i == 3:
            A.text(fid, f"Row {label}", label, 60, ry + 1.6, 16, 400, "text/primary", w=228, lh=1.65)
        else:
            B.rtext(fid, f"Row {label}", label, 288, ry + 15, 16, 400, "text/primary", lh=1.65)
        A.icon(fid, "Row go", "chevl", 40, ry + 18, 20, "text/secondary")


def screen_profile(fid):
    B.shell(fid)
    profile_header(fid)
    B.card(fid, "Link card", 24, 196, 312, 79)
    A.icon(fid, "Link icon", "link", 296, 223.5, 24, "action/primary")
    B.rtext(fid, "Link title", "حساب الطرف الآخر", 280, 213, 16, 700, "text/primary", lh=1.5)
    B.rtext(fid, "Link meta", "يرى التقويم المشترك فقط.", 280, 237, 14, 400, "text/secondary", lh=1.5)
    B.chip(fid, 40, 222, "مرتبط", "ok", "check")
    rows_card(fid, 291)
    B.button(fid, "تسجيل الخروج", 24, 532, 312, 56, "outline", "logout")
    B.tabbar(fid, 4)


def screen_profile_unlinked(fid):
    B.shell(fid)
    profile_header(fid)
    B.card(fid, "Link card", 24, 196, 312, 172)
    A.icon(fid, "Link icon", "link", 296, 223.5, 24, "feedback/warning-icon")
    B.rtext(fid, "Link title", "حساب الطرف الآخر", 280, 213, 16, 700, "text/primary", lh=1.5)
    B.rtext(fid, "Link meta", "لم يتم الربط بعد.", 280, 237, 14, 400, "text/secondary", lh=1.5)
    B.chip(fid, 40, 222, "غير مرتبط", "warn")
    B.rtext(fid, "Link note", "اربط الحسابين لتفعيل التقويم المشترك.", 320, 270, 14, 400, "text/secondary", lh=1.5)
    B.button(fid, "ربط الحساب", 40, 303, 280, 48, "primary", "link")
    rows_card(fid, 384)
    B.tabbar(fid, 4)


REPORT_SCREENS = [
    ("Reports list", screen_reports, "surface/page"),
    ("Reports empty", screen_reports_empty, "surface/page"),
    ("Profile", screen_profile, "surface/page"),
    ("Profile unlinked", screen_profile_unlinked, "surface/page"),
]
