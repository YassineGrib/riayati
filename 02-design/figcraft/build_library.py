#!/usr/bin/env python3
"""Educational content library screens for FigCraft (Arabic RTL, 360x800 dp).

Page 09 Library:
  - Library list: type chips (icons without backgrounds), search field, content cards
  - Library detail: article view with Serif Display title and Serif Text body
  - Library empty: search with no matching results
  - Library error: network failure state with retry button
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import build_auth as A  # noqa: E402
import build_app as B  # noqa: E402

PAD, W, H = A.PAD, A.W, A.H

A.ICONS.update({
    "scale": ["M16 16l3-8 3 8a3 3 0 0 1-6 0z", "M2 16l3-8 3 8a3 3 0 0 1-6 0z", "M7 21h10", "M12 3v18", "M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2"],
    "bookmark": ["M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"],
    "refresh": ["M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8", "M21 3v5h-5", "M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16", "M8 16H3v5"],
    "search": ["M21 21l-4.3-4.3", "M19 11a8 8 0 1 1-16 0 8 8 0 0 1 16 0z"],
})


def type_chip(fid, right, y, label, icon_name=None, selected=False):
    """Horizontal filter chip with icon without background."""
    col = "text/on-action" if selected else "text/primary"
    bg = "action/primary" if selected else "surface/sunken"
    tmp, tw, _ = A.text(fid, "tmp", label, 0, 0, 12, 600 if selected else 500, col, lh=1.4)
    A.ex("edit.delete", ids=[tmp])
    iw = 16 + 4 if icon_name else 0
    w = 8 + iw + tw + 8
    x = right - w
    A.rect(fid, f"Chip {label}", x, y, w, 30, fill=bg, r=15)
    if icon_name:
        ic_col = "text/on-action" if selected else "action/primary"
        A.icon(fid, f"Chip icon {label}", icon_name, right - 8 - 16, y + 7, 16, ic_col)
    A.text(fid, f"Chip label {label}", label, 0, y + 5.5, 12, 600 if selected else 500, col, w=tw, align="right", lh=1.4)
    tid = A.ex("node.find", name=f"Chip label {label}", type="TEXT")["ids"][-1]
    A.ex("node.set", id=tid, x=x + 8)
    return w


def content_card(fid, y, kind, kind_badge, title, summary, date_text):
    """Article/legal card with badge, title, 2-line summary, and reading time."""
    B.card(fid, f"Card {title}", 24, y, 312, 138, fill="surface/card", stroke="border/default", r=14)
    badge_bg, badge_col = {
        "قانون": ("feedback/info-bg", "feedback/info-text"),
        "مقال": ("surface/brand-soft", "action/primary"),
        "اجتهاد": ("feedback/warning-bg", "feedback/warning-text"),
        "دليل": ("feedback/success-bg", "feedback/success-text"),
    }.get(kind_badge, ("surface/sunken", "text/secondary"))

    # Badge top-right
    tmp, bw, _ = A.text(fid, "tmp", kind_badge, 0, 0, 12, 600, badge_col, lh=1.4)
    A.ex("edit.delete", ids=[tmp])
    A.rect(fid, f"Badge {kind_badge}", 320 - bw - 16, y + 14, bw + 16, 22, fill=badge_bg, r=11)
    A.text(fid, "Badge text", kind_badge, 320 - bw - 8, y + 15.5, 12, 600, badge_col, w=bw, align="center", lh=1.4)

    # Date / reading time top-left
    A.text(fid, "Date", date_text, 36, y + 16, 12, 400, "text/secondary", align="left", lh=1.4)

    # Title (bold)
    B.rtext(fid, "Card title", title, 320, y + 44, 15, 700, "text/primary", lh=1.4)

    # 2-line summary
    A.text(fid, "Summary", summary, 36, y + 74, 13, 400, "text/secondary", w=284, align="right", lh=1.5)

    # Chevron forward (flips in RTL -> chevl)
    A.icon(fid, "Card chevron", "chevl", 36, y + 110, 16, "text/tertiary")


# ----------------------------------------------------------------------------- screens
def screen_list(fid):
    B.shell(fid)
    B.appbar_title(fid, "المحتوى التعليمي")

    # Search bar
    A.rect(fid, "Search box", 24, 88, 312, 44, fill="surface/card", stroke="border/strong", r=12)
    A.icon(fid, "Search icon", "search", 304, 100, 20, "text/secondary")
    B.rtext(fid, "Search placeholder", "ابحث في المقالات والقوانين…", 294, 99, 14, 400, "text/tertiary", lh=1.4)

    # Type chips (icons without backgrounds)
    chips = [
        ("الكل", None, True),
        ("مقال", "file", False),
        ("قانون", "scale", False),
        ("اجتهاد", "book", False),
        ("دليل", "bookmark", False),
    ]
    cur_right = 336
    for label, ic, sel in chips:
        w = type_chip(fid, cur_right, 142, label, icon_name=ic, selected=sel)
        cur_right -= (w + 4)

    # 3 Content cards
    content_card(fid, 186, "قانون", "قانون", "تعريف مبسّط بالحضانة وأطرافها",
                 "عرض مبسّط لمفهوم الحضانة والجهات التي تنظر فيها، للتعريف والإرشاد الأولي.",
                 "18 نوفمبر 2026 · 4 د قراءة")

    content_card(fid, 334, "مقال", "مقال", "كيف تتجنب النزاع أثناء تسليم المحضون؟",
                 "إرشادات عملية ونفسية للوالدين لضمان بيئة آمنة وهادئة للطفل أثناء ممارسة حق الزيارة المقررة.",
                 "16 نوفمبر 2026 · 5 د قراءة")

    content_card(fid, 482, "اجتهاد", "اجتهاد", "مبدأ مصلحة الطفل الفضلى",
                 "قراءة مبسّطة لمبدأ يُراعى عند النظر في كل ما يخص الطفل.",
                 "12 نوفمبر 2026 · 6 د قراءة")

    # Bottom helper note
    A.rect(fid, "Legal note banner", 24, 634, 312, 54, fill="surface/brand-soft", r=12)
    A.icon(fid, "Legal note icon", "shield", 306, 650, 20, "action/primary")
    A.text(fid, "Legal note text", "محتوى تعريفي للإرشاد الأولي، ولا يغني عن استشارة مختص أو عن نص القانون الرسمي.",
           38, 644, 12, 400, "text/primary", w=258, align="right", lh=1.4)

    B.tabbar(fid, 0)


def screen_detail(fid):
    B.shell(fid)
    # Top bar: back button top-start (points right in RTL to go back)
    A.icon(fid, "Back", "arrow", 312, 44, 24, "text/primary")
    B.rtext(fid, "Appbar title", "المحتوى التعليمي", 292, 43, 16, 600, "text/secondary", lh=1.4)
    A.icon(fid, "Share icon", "share", 24, 44, 20, "text/secondary")

    # Category badge and reading time
    A.rect(fid, "Category badge", 280, 84, 56, 24, fill="feedback/info-bg", r=12)
    A.text(fid, "Category label", "قانون", 280, 86, 12, 600, "feedback/info-text", w=56, align="center", lh=1.4)
    B.rtext(fid, "Reading meta", "18 نوفمبر 2026 · 4 دقائق قراءة", 268, 86, 13, 400, "text/secondary", lh=1.4)

    # Title in Serif Display
    A.text(fid, "Title", "تعريف مبسّط بالحضانة وأطرافها",
           PAD, 122, 22, 700, "text/primary", w=312, align="right", lh=1.4)

    # Reference line box
    A.rect(fid, "Reference box", 24, 196, 312, 40, fill="surface/sunken", r=8)
    A.icon(fid, "Reference icon", "book", 308, 206, 18, "text/secondary")
    B.rtext(fid, "Reference text", "محتوى تعريفي للإرشاد الأولي", 298, 206, 13, 500, "text/secondary", lh=1.4)

    # Legal Body in Serif Text (long reading text)
    body1 = ("الحضانة في معناها العام رعاية الطفل وتربيته وحفظه بما يحقق مصلحته. "
             "يعرض هذا النص الفكرة بصيغة مبسطة، ويُرجع إلى النص الرسمي للقانون أو إلى مختص في الحالات الخاصة.")
    A.text(fid, "Answer body 1", body1, PAD, 252, 15, 400, "text/primary", w=312, align="right", lh=1.8)

    body2 = ("الغاية من هذا القسم أن تفهم الأساسيات قبل أن تتواصل مع الجهة المختصة، "
             "وأن تعرف أي أسئلة تطرح عليها.")
    A.text(fid, "Answer body 2", body2, PAD, 396, 15, 400, "text/primary", w=312, align="right", lh=1.8)

    # Highlight box with important caveat
    A.rect(fid, "Caveat box", 24, 536, 312, 82, fill="feedback/info-bg", stroke="feedback/info-border", sw=1, r=12)
    A.icon(fid, "Caveat icon", "info", 306, 552, 20, "feedback/info-icon")
    A.text(fid, "Caveat text", "ملاحظة: هذا النص للتعريف والإرشاد الأولي، ولا يغني عن النص الرسمي للقانون أو عن استشارة مختص.",
           38, 548, 13, 400, "feedback/info-text", w=258, align="right", lh=1.5)

    # Next / Related link at bottom
    B.card(fid, "Related card", 24, 634, 312, 60, fill="surface/card", stroke="border/default", r=12)
    B.rtext(fid, "Related label", "النص التالي: تنظيم الزيارات", 298, 644, 14, 600, "text/primary", lh=1.4)
    B.rtext(fid, "Related sub", "3 دقائق قراءة", 298, 666, 12, 400, "text/secondary", lh=1.4)
    A.icon(fid, "Related chevron", "chevl", 36, 656, 18, "action/primary")

    A.rect(fid, "Gesture bar", (W - 108) / 2, H - A.GESTURE_H + 8, 108, 4, fill="text/primary", r=2, opacity=0.6)


def screen_empty(fid):
    B.shell(fid)
    B.appbar_title(fid, "المحتوى التعليمي")

    # Search bar with search term
    A.rect(fid, "Search box", 24, 88, 312, 44, fill="surface/card", stroke="border/focus", sw=2, r=12)
    A.icon(fid, "Search icon", "search", 304, 100, 20, "text/secondary")
    B.rtext(fid, "Search value", "عقوبة الإهمال", 294, 99, 14, 600, "text/primary", lh=1.4)
    A.icon(fid, "Search clear", "x", 36, 100, 20, "text/secondary")

    # Chips
    type_chip(fid, 336, 142, "الكل", selected=True)
    type_chip(fid, 268, 142, "مقال", icon_name="file")
    type_chip(fid, 192, 142, "قانون", icon_name="scale")

    # Empty illustration
    A.ellipse(fid, "Empty circle", (W - 88) / 2, 280, 88, 88, fill="surface/sunken")
    A.icon(fid, "Empty icon", "search", (W - 40) / 2, 304, 40, "text/tertiary")

    A.text(fid, "Empty title", "لم نعثر على نتائج مطابقة", PAD, 390, 20, 700, "text/primary", w=312, align="center", lh=1.4)
    A.text(fid, "Empty desc", "لم نجد أي مقالات أو نصوص قانونية تطابق «عقوبة الإهمال». جرّب كلمات أكثر شمولاً مثل «حضانة» أو «زيارة».",
           36, 430, 14, 400, "text/secondary", w=288, align="center", lh=1.6)

    B.button(fid, "مسح البحث وتصفح الكل", 48, 520, 264, 48, "outline")
    B.tabbar(fid, 0)


def screen_error(fid):
    B.shell(fid)
    B.appbar_title(fid, "المحتوى التعليمي")

    # Error illustration
    A.ellipse(fid, "Error circle", (W - 88) / 2, 260, 88, 88, fill="feedback/error-bg")
    A.icon(fid, "Error icon", "alerttri", (W - 44) / 2, 282, 44, "feedback/error-icon")

    A.text(fid, "Error title", "تعذّر تحميل المحتوى", PAD, 370, 20, 700, "text/primary", w=312, align="center", lh=1.4)
    A.text(fid, "Error desc", "حدث خطأ أثناء محاولة جلب المقالات والنصوص. يُرجى التحقق من اتصال الإنترنت ثم إعادة المحاولة.",
           36, 410, 14, 400, "text/secondary", w=288, align="center", lh=1.6)

    B.button(fid, "إعادة المحاولة", 48, 490, 264, 48, "primary", icon="refresh")
    B.tabbar(fid, 0)


LIBRARY_SCREENS = [
    ("Library list", screen_list, "surface/page"),
    ("Library detail", screen_detail, "surface/page"),
    ("Library empty", screen_empty, "surface/page"),
    ("Library error", screen_error, "surface/page"),
]
