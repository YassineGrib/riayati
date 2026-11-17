#!/usr/bin/env python3
"""Calendar + assistant screens for FigCraft (360x800 dp, RTL). Mirrors 02-design/calendar-assistant/index.html.
Use build_all.py to build every screen set in one document."""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import build_auth as A  # noqa: E402
import build_app as B  # noqa: E402

PAD, W = A.PAD, A.W

A.ICONS.update({
    "chevl": ["M15 18l-6-6 6-6"],
    "chevr": ["M9 18l6-6-6-6"],
    "plus": ["M5 12h14", "M12 5v14"],
    "calcheck": ["M8 2v4", "M16 2v4", "M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z", "M3 10h18", "M9 16l2 2 4-4"],
    "info": ["M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0z", "M12 16v-4", "M12 8h.01"],
    "book": ["M12 7v14", "M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z"],
})

DAYS = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]


def heading(fid, s, y, size=16):
    B.rtext(fid, "Heading " + s, s, 336, y, size, 700, "text/primary", lh=1.65)


def info_box(fid, y, s):
    A.rect(fid, "Info box", 24, y, 312, 68, fill="feedback/info-bg", stroke="feedback/info-border", r=12)
    A.icon(fid, "Info icon", "info", 300, y + 14, 20, "feedback/info-icon")
    A.text(fid, "Info text", s, 40, y + 13, 14, 400, "feedback/info-text", w=252, lh=1.5)


def composer(fid):
    A.rect(fid, "Composer", 16, 632, 328, 56, fill="surface/card", stroke="border/strong", r=12)
    B.rtext(fid, "Composer placeholder", "اكتب سؤالك…", 328, 646, 16, 400, "text/tertiary", lh=1.4)
    A.ellipse(fid, "Composer send", 24, 640, 40, 40, fill="action/primary")
    A.icon(fid, "Composer send icon", "send", 34, 650, 20, "text/on-action")


def bubble_user(fid, s, y, width=None, lines=1):
    tmp, tw, _ = A.text(fid, "tmp", s, 0, 0, 16, 400, "text/on-action", lh=1.5)
    A.ex("edit.delete", ids=[tmp])
    bw = width or (tw + 32)
    h = 24 * lines + 24
    A.rect(fid, "User bubble", 336 - bw, y, bw, h, fill="action/primary", r=16)
    A.text(fid, "User message", s, 336 - bw + 16, y + 12, 16, 400, "text/on-action", w=bw - 32, lh=1.5)


def source_row(fid, s, y):
    A.rect(fid, "Source", 40, y, 280, 48, fill="surface/brand-soft", stroke="border/default", r=12)
    A.icon(fid, "Source icon", "book", 288, y + 14, 20, "action/primary")
    B.rtext(fid, "Source label", s, 280, y + 12.5, 14, 500, "text/primary", lh=1.65)
    A.icon(fid, "Source go", "chevl", 52, y + 14, 20, "text/secondary")


def legal_note(fid, y):
    A.icon(fid, "Note icon", "info", 300, y, 20, "text/secondary")
    A.text(fid, "Legal note", "معلومات عامة وليست استشارة قانونية.", 40, y, 14, 400, "text/secondary", w=252, lh=1.5)


# --------------------------------------------------------------------------- screens
def screen_calendar(fid):
    B.shell(fid)
    B.rtext(fid, "Title", "التقويم", 336, 46, 20, 700, "text/primary", lh=1.4)
    A.icon(fid, "Previous month", "chevr", 312, 104, 24, "text/primary")
    A.icon(fid, "Next month", "chevl", 20, 104, 24, "text/primary")
    A.text(fid, "Title", "نوفمبر 2026", 0, 101, 18, 700, "text/primary", w=W, align="center", lh=1.65)
    cw = 340 / 7
    for c, d in enumerate(DAYS):
        A.text(fid, f"Weekday {d}", d, 10 + (6 - c) * cw, 140, 12, 500, "text/secondary", w=cw, align="center", lh=2)
    for d in range(1, 31):
        c, r = (d - 1) % 7, (d - 1) // 7
        x, y = 10 + (6 - c) * cw, 164 + r * 48
        cx = x + cw / 2 - 24
        col = "text/primary"
        if d == 20:
            A.ellipse(fid, "Selected day", cx, y, 48, 48, fill="action/primary")
            col = "text/on-action"
        elif d == 17:
            A.ellipse(fid, "Today", cx + 1, y + 1, 46, 46, stroke="border/focus", sw=2)
        A.text(fid, f"Day {d}", str(d), x, y + 12.5, 14, 500, col, w=cw, align="center", lh=1.65)
        if d in (6, 28, 20):
            dot = "feedback/warning-icon" if d == 20 and False else ("text/on-action" if d == 20 else "action/primary")
            if d == 20:
                dot = "text/on-action"
            A.ellipse(fid, f"Visit dot {d}", x + cw / 2 - 3, y + 37, 6, 6, fill=dot)
    heading(fid, "الزيارات القادمة", 416)
    B.card(fid, "Visit card", 24, 450, 312, 147)
    B.rtext(fid, "Visit title", "الجمعة 20 نوفمبر", 320, 469, 16, 700, "text/primary", lh=1.5)
    B.chip(fid, 40, 467, "بانتظار ردّك", "warn", "clock")
    B.rtext(fid, "Visit meta", "10:00 – 14:00 · اقترحها الطرف الآخر", 320, 499, 14, 400, "text/secondary", lh=1.5)
    B.button(fid, "قبول", 186, 532, 134, 48, "primary")
    B.button(fid, "رفض", 40, 532, 134, 48, "outline")
    fab = A.rect(fid, "FAB", 16, 628, 141, 56, fill="action/primary", r=16)
    A.ex("effect.add", ids=[fab], effect={"type": "dropShadow", "offset": [0, 4], "radius": 16, "color": "#0000004d"})
    A.icon(fid, "FAB icon", "plus", 16 + 141 - 20 - 20, 646, 20, "text/on-action")
    tid, tw, _ = A.text(fid, "FAB label", "اقتراح زيارة", 0, 645, 16, 700, "text/on-action", lh=1.65)
    A.ex("node.set", id=tid, x=16 + 141 - 20 - 20 - 8 - tw)
    B.tabbar(fid, 1)


def screen_propose(fid):
    B.shell(fid)
    B.appbar_title(fid, "اقتراح زيارة")
    A.field(fid, "التاريخ", 92, "cal", "الجمعة 27 نوفمبر 2026", ltr=False, state="focus")
    for label, val, x in (("من", "10:00", 186), ("إلى", "14:00", 24)):
        A.text(fid, f"Label {label}", label, x, 193, 14, 500, "text/primary", w=150, lh=1.65)
        A.rect(fid, f"{label} control", x, 222, 150, 56, fill="surface/card", stroke="border/strong", r=12)
        A.icon(fid, f"{label} icon", "clock", x + 150 - 16 - 20, 240, 20, "text/secondary")
        A.text(fid, f"{label} value", val, x + 16, 236, 16, 400, "text/primary", w=150 - 16 - 20 - 8 - 16, align="right", lh=1.4, direction="ltr")
    A.label(fid, "ملاحظة (اختياري)", 294)
    A.rect(fid, "Note control", 24, 323, 312, 88, fill="surface/card", stroke="border/strong", r=12)
    A.text(fid, "Note placeholder", "مثال: مكان التسليم.", 40, 335, 16, 400, "text/tertiary", w=280)
    info_box(fid, 441, "سيصل الاقتراح إلى الطرف الآخر ليقبله أو يرفضه، وستصلك نتيجة ردّه.")
    B.button(fid, "إرسال الاقتراح", 24, 704, 312, 56, "primary")


def screen_detail(fid):
    B.shell(fid)
    B.appbar_title(fid, "تفاصيل الزيارة")
    B.card(fid, "Visit card", 24, 92, 312, 89)
    B.rtext(fid, "Visit title", "الجمعة 20 نوفمبر", 320, 108, 20, 700, "text/primary", lh=1.5)
    B.chip(fid, 40, 109, "بانتظار ردّك", "warn", "clock")
    B.rtext(fid, "Visit meta", "10:00 – 14:00 · اقترحها الطرف الآخر", 320, 142, 14, 400, "text/secondary", lh=1.5)
    heading(fid, "مراحل الزيارة", 200)
    steps = [
        ("تم اقتراح الزيارة", "الأحد 15 نوفمبر · 18:20", "done", 239),
        ("ردّك", "بانتظار قبولك أو رفضك", "now", 304),
        ("تأكيد الزيارة", "بعد القبول", "todo", 369),
    ]
    for i, (t, sub, state, y) in enumerate(steps):
        if i < 2:
            A.rect(fid, "Step line", 319, y + 32, 2, 33, fill="border/default")
        if state == "done":
            A.ellipse(fid, "Step marker", 304, y, 32, 32, fill="action/primary")
            A.icon(fid, "Step icon", "check", 312, y + 8, 16, "text/on-action")
        elif state == "now":
            A.ellipse(fid, "Step marker", 304, y, 32, 32, fill="feedback/warning-bg", stroke="feedback/warning-icon", sw=2)
            A.icon(fid, "Step icon", "clock", 312, y + 8, 16, "feedback/warning-text")
        else:
            A.ellipse(fid, "Step marker", 304, y, 32, 32, fill="surface/card", stroke="border/strong", sw=2)
            A.icon(fid, "Step icon", "calcheck", 312, y + 8, 16, "text/secondary")
        B.rtext(fid, "Step title", t, 288, y, 16, 700, "text/primary", lh=1.5)
        B.rtext(fid, "Step meta", sub, 288, y + 24, 14, 400, "text/secondary", lh=1.5)
    B.button(fid, "قبول", 186, 704, 150, 56, "primary")
    B.button(fid, "رفض", 24, 704, 150, 56, "outline")


def screen_assistant_empty(fid):
    B.shell(fid)
    B.rtext(fid, "Title", "المساعد القانوني", 336, 46, 20, 700, "text/primary", lh=1.4)
    B.card(fid, "Intro card", 24, 92, 312, 124, fill="surface/brand-soft")
    A.ellipse(fid, "Intro mark", 276, 108, 40, 40, fill="surface/card")
    A.icon(fid, "Intro icon", "chat", 286, 118, 20, "action/primary")
    B.rtext(fid, "Intro title", "اسأل عن قانون الأسرة الجزائري", 264, 116, 16, 700, "text/primary", lh=1.5)
    A.text(fid, "Intro text", "أجيب من النصوص المعتمدة فقط، وأذكر المواد التي استندت إليها عند توفرها.", 40, 156, 14, 400,
           "text/secondary", w=280, lh=1.5)
    info_box(fid, 245, "لا تكتب أسماء أو تفاصيل قضية. هذه معلومات عامة وليست استشارة قانونية.")
    heading(fid, "جرّب أن تسأل", 343)
    for i, q in enumerate(["من الأحق بحضانة الطفل؟", "كيف تُنظَّم زيارة الطفل؟", "ما الذي تشمله نفقة الأولاد؟"]):
        y = 377 + i * 56
        A.rect(fid, "Suggestion", 24, y, 312, 48, stroke="border/strong", r=12)
        B.rtext(fid, "Suggestion text", q, 320, y + 11, 16, 400, "text/primary", lh=1.65)
        A.icon(fid, "Suggestion go", "chevl", 40, y + 14, 20, "text/secondary")
    composer(fid)
    B.tabbar(fid, 2)


def screen_assistant_answer(fid):
    B.shell(fid)
    B.rtext(fid, "Title", "المساعد القانوني", 336, 46, 20, 700, "text/primary", lh=1.4)
    bubble_user(fid, "من الأحق بحضانة الطفل؟", 92)
    B.card(fid, "Answer card", 24, 152, 312, 292)
    A.text(fid, "Answer text", "تنظّم المواد الخاصة بالحضانة في قانون الأسرة من تُسند إليها الحضانة وشروطها، وتجعل مصلحة المحضون معيارًا أساسيًا في ذلك.",
           40, 168, 16, 400, "text/primary", w=280, lh=1.8)
    B.rtext(fid, "Sources heading", "المصادر", 320, 267, 14, 700, "text/secondary", lh=1.65)
    source_row(fid, "قانون الأسرة · المادة 64", 296)
    source_row(fid, "قانون الأسرة · المادة 65", 350)
    legal_note(fid, 406)
    composer(fid)
    B.tabbar(fid, 2)


def screen_assistant_insufficient(fid):
    B.shell(fid)
    B.rtext(fid, "Title", "المساعد القانوني", 336, 46, 20, 700, "text/primary", lh=1.4)
    bubble_user(fid, "هل يحق لي السفر بالطفل إلى الخارج دون موافقة؟", 92, width=266, lines=2)
    B.card(fid, "Answer card", 24, 176, 312, 264)
    A.icon(fid, "Warning icon", "info", 300, 210, 20, "feedback/warning-icon")
    A.text(fid, "Warning text", "لم أجد في المصادر المتوفرة ما يجيب عن سؤالك بدقة.", 40, 208, 16, 700, "text/primary", w=252, lh=1.5)
    A.text(fid, "Answer text", "جرّب إعادة صياغة السؤال، أو استشر محاميًا أو الجهة القضائية المختصة.", 40, 272, 16, 400,
           "text/primary", w=280, lh=1.8)
    B.button(fid, "أعد صياغة السؤال", 40, 342, 280, 48, "outline")
    legal_note(fid, 402)
    composer(fid)
    B.tabbar(fid, 2)


CAL_SCREENS = [
    ("Calendar", screen_calendar, "surface/page"),
    ("Propose visit", screen_propose, "surface/page"),
    ("Visit detail", screen_detail, "surface/page"),
    ("Assistant empty", screen_assistant_empty, "surface/page"),
    ("Assistant answer", screen_assistant_answer, "surface/page"),
    ("Assistant no sources", screen_assistant_insufficient, "surface/page"),
]
