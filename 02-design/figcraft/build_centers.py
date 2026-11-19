#!/usr/bin/env python3
"""Support centers and judicial directory screens for FigCraft (Arabic RTL, 360x800 dp).

Page 10 Centers:
  - Centers list: directory with search, kind chips, wilaya filter, center cards with tap-to-call
  - Centers wilaya filter: searchable bottom sheet with top of the 58 Algerian wilayas
  - Center detail: all fields, big call button, copy phone, placeholder data disclaimer
  - Centers empty: no matching centers found
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import build_auth as A  # noqa: E402
import build_app as B  # noqa: E402

PAD, W, H = A.PAD, A.W, A.H

A.ICONS.update({
    "phone": ["M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"],
    "map-pin": ["M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0", "M12 10a2 2 0 1 0 0-4 2 2 0 0 0 0 4"],
    "building": ["M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z", "M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2", "M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2", "M10 6h4", "M10 10h4", "M10 14h4", "M10 18h4"],
    "chevd": ["M6 9l6 6 6-6"],
    "filter": ["M22 3H2l8 9.46V19l4 2v-8.54L22 3z"],
})


def center_card(fid, y, name, kind, wilaya, address, phone):
    """Directory center card with name, kind badge, wilaya, address and call action."""
    B.card(fid, f"Card {name}", 24, y, 312, 142, fill="surface/card", stroke="border/default", r=14)

    kind_bg, kind_col = {
        "محكمة": ("feedback/info-bg", "feedback/info-text"),
        "حماية الطفولة": ("feedback/success-bg", "feedback/success-text"),
        "مساعدة قانونية": ("surface/sunken", "text/primary"),
        "دعم نفسي": ("surface/brand-soft", "action/primary"),
        "جمعية": ("feedback/warning-bg", "feedback/warning-text"),
    }.get(kind, ("surface/sunken", "text/secondary"))

    # Kind badge top-right
    tmp, bw, _ = A.text(fid, "tmp", kind, 0, 0, 12, 600, kind_col, lh=1.4)
    A.ex("edit.delete", ids=[tmp])
    A.rect(fid, f"Badge {kind}", 320 - bw - 16, y + 14, bw + 16, 22, fill=kind_bg, r=11)
    A.text(fid, "Badge text", kind, 320 - bw - 8, y + 15.5, 12, 600, kind_col, w=bw, align="center", lh=1.4)

    # Wilaya chip top-left
    A.text(fid, "Wilaya", wilaya, 36, y + 16, 12, 500, "text/secondary", align="left", lh=1.4)

    # Name
    B.rtext(fid, "Center name", name, 320, y + 42, 15, 700, "text/primary", lh=1.4)

    # Address
    A.icon(fid, "Address icon", "map-pin", 318, y + 71, 15, "text/tertiary")
    B.rtext(fid, "Address text", address, 300, y + 70, 13, 400, "text/secondary", lh=1.4)

    # Call button
    A.rect(fid, "Call btn bg", 36, y + 96, 288, 34, fill="surface/sunken", stroke="border/strong", sw=1, r=8)
    A.icon(fid, "Call btn icon", "phone", 226, y + 104, 16, "action/primary")
    B.rtext(fid, "Call btn text", f"اتصال: {phone} (تجريبي)", 204, y + 103, 12, 600, "action/primary", lh=1.4)


# ----------------------------------------------------------------------------- screens
def screen_list(fid):
    B.shell(fid)
    B.appbar_title(fid, "مراكز وهيئات")

    # Search bar
    A.rect(fid, "Search box", 24, 88, 312, 44, fill="surface/card", stroke="border/strong", r=12)
    A.icon(fid, "Search icon", "search", 304, 100, 20, "text/secondary")
    B.rtext(fid, "Search placeholder", "ابحث باسم المركز أو العنوان…", 294, 99, 14, 400, "text/tertiary", lh=1.4)

    # Wilaya filter bar + Demo disclaimer
    A.rect(fid, "Wilaya filter btn", 154, 140, 182, 34, fill="surface/sunken", stroke="border/strong", sw=1, r=17)
    A.icon(fid, "Wilaya filter icon", "map-pin", 318, 148, 16, "action/primary")
    B.rtext(fid, "Wilaya filter text", "الولاية: 16 - الجزائر", 298, 147, 13, 600, "text/primary", lh=1.4)
    A.icon(fid, "Wilaya chevron", "chevd", 166, 151, 14, "text/secondary")

    # Demo badge
    A.rect(fid, "Demo badge", 24, 140, 120, 34, fill="feedback/info-bg", r=17)
    A.text(fid, "Demo badge text", "بيانات تجريبية", 24, 147, 12, 600, "feedback/info-text", w=120, align="center", lh=1.4)

    # Kind chips wrapped in two lines to fit comfortably within the 360 frame
    chip_rows = [
        (182, [("الكل", True), ("محكمة", False), ("حماية الطفولة", False)]),
        (216, [("مساعدة قانونية", False), ("دعم نفسي", False), ("خط مساعدة", False)]),
    ]
    for row_y, row_chips in chip_rows:
        cur_right = 336
        for label, sel in row_chips:
            col = "text/on-action" if sel else "text/primary"
            bg = "action/primary" if sel else "surface/sunken"
            tmp, tw, _ = A.text(fid, "tmp", label, 0, 0, 12, 600 if sel else 500, col, lh=1.4)
            A.ex("edit.delete", ids=[tmp])
            w = tw + 20
            x = cur_right - w
            A.rect(fid, f"Chip {label}", x, row_y, w, 28, fill=bg, r=14)
            A.text(fid, f"Chip text {label}", label, x, row_y + 4.5, 12, 600 if sel else 500, col, w=w, align="center", lh=1.4)
            cur_right -= (w + 6)

    # 3 Center cards
    center_card(fid, 252, "محكمة سيدي امحمد - قسم الأسرة", "محكمة", "16 - الجزائر",
                "شارع عبان رمضان، الجزائر العاصمة", "000-000-000")

    center_card(fid, 398, "الهيئة الوطنية لحماية الطفولة", "حماية الطفولة", "16 - الجزائر",
                "الأبيار · الرقم الأخضر المجاني 1111", "11-11")

    center_card(fid, 544, "مكتب المساعدة القضائية", "مساعدة قانونية", "16 - الجزائر",
                "قصر العدالة، شارع رضا حوحو", "000-000-000")

    B.tabbar(fid, 0)


def screen_wilaya_filter(fid):
    # Base list under scrim
    screen_list(fid)

    # Dark Scrim
    scrim = A.ex("shape.rectangle", x=0, y=0, width=W, height=H, parent=fid, name="Scrim", select=False,
                 props={"fill": "#0D140A", "opacity": 0.55})["id"]

    # Bottom Sheet (height 580)
    sheet = A.rect(fid, "Bottom sheet", 0, 220, W, 580, fill="surface/raised", r=24)
    A.ex("effect.add", ids=[sheet], effect={"type": "dropShadow", "offset": [0, -8], "radius": 32, "color": "#00000040"})

    # Handle bar
    A.rect(fid, "Handle", (W - 40) / 2, 230, 40, 4, fill="border/strong", r=2)

    # Title & Close
    B.rtext(fid, "Sheet title", "اختر الولاية (58 ولاية)", 336, 248, 18, 700, "text/primary", lh=1.4)
    A.icon(fid, "Sheet close", "x", 24, 250, 20, "text/secondary")

    # Search wilaya box
    A.rect(fid, "Sheet search", 24, 288, 312, 42, fill="surface/sunken", stroke="border/strong", r=10)
    A.icon(fid, "Sheet search icon", "search", 304, 300, 18, "text/secondary")
    B.rtext(fid, "Sheet search placeholder", "ابحث عن ولاية أو رقم…", 294, 299, 13, 400, "text/tertiary", lh=1.4)

    # Top of the 58 Wilayas list
    wilayas = [
        ("01", "أدرار", False),
        ("02", "الشلف", False),
        ("03", "الأغواط", False),
        ("04", "أم البواقي", False),
        ("05", "باتنة", False),
        ("06", "بجاية", False),
        ("16", "الجزائر (العاصمة)", True),
        ("31", "وهران", False),
    ]

    y = 342
    for code, w_name, selected in wilayas:
        bg = "interactive/selected-bg" if selected else "surface/raised"
        col = "action/primary" if selected else "text/primary"
        A.rect(fid, f"Row {code}", 24, y, 312, 44, fill=bg, r=8)
        B.rtext(fid, f"Wilaya {code}", f"{code} - {w_name}", 320, y + 12, 14, 600 if selected else 400, col, lh=1.4)
        if selected:
            A.icon(fid, "Selected check", "check", 38, y + 14, 18, "action/primary")
        A.rect(fid, f"Div {code}", 24, y + 43, 312, 1, fill="border/default")
        y += 45

    # Bottom Confirm Button
    B.button(fid, "تأكيد اختيار الولاية", 24, 720, 312, 50, "primary")


def screen_detail(fid):
    B.shell(fid)
    A.icon(fid, "Back", "arrow", 312, 44, 24, "text/primary")
    B.rtext(fid, "Appbar title", "تفاصيل المركز", 292, 43, 16, 600, "text/secondary", lh=1.4)

    # Badges row: Kind badge + Demo badge
    A.rect(fid, "Kind badge", 264, 88, 72, 24, fill="feedback/info-bg", r=12)
    A.text(fid, "Kind text", "محكمة", 264, 90, 12, 600, "feedback/info-text", w=72, align="center", lh=1.4)

    A.rect(fid, "Demo badge", 144, 88, 112, 24, fill="surface/sunken", r=12)
    A.text(fid, "Demo text", "بيانات تجريبية", 144, 90, 12, 500, "text/secondary", w=112, align="center", lh=1.4)

    # Title in Serif Display
    A.text(fid, "Title", "محكمة سيدي امحمد · قسم شؤون الأسرة",
           PAD, 124, 20, 700, "text/primary", w=312, align="right", lh=1.4)

    # Details Card
    B.card(fid, "Info card", 24, 180, 312, 380, fill="surface/card", stroke="border/default", r=14)

    fields = [
        ("الولاية", "16 - الجزائر (الجزائر العاصمة)"),
        ("العنوان الكامل", "شارع عبان رمضان، الجزائر الوسطى"),
        ("أوقات العمل", "الأحد إلى الخميس: 08:30 – 16:30"),
        ("الهاتف الرئيسي", "000-000-000 (رقم تجريبي)"),
        ("الرقم الأخضر / المساعدة", "11-11"),
        ("الاختصاص والمهام", "النظر في دعاوى الحضانة والزيارة والنفقة. يجب إحضار الوثائق الرسمية والأحكام السابقة."),
    ]

    fy = 196
    for i, (label, val) in enumerate(fields):
        B.rtext(fid, f"Label {i}", label, 320, fy, 12, 500, "text/secondary", lh=1.4)
        if label == "الاختصاص والمهام":
            A.text(fid, f"Val {i}", val, 36, fy + 20, 13, 400, "text/primary", w=284, align="right", lh=1.5)
            fy += 64
        else:
            B.rtext(fid, f"Val {i}", val, 320, fy + 20, 13, 600, "text/primary", lh=1.4)
            fy += 48
        if i < len(fields) - 1:
            A.rect(fid, f"Div {i}", 36, fy - 8, 288, 1, fill="border/default")

    # Important note banner
    A.rect(fid, "Note banner", 24, 574, 312, 48, fill="feedback/info-bg", stroke="feedback/info-border", sw=1, r=10)
    A.icon(fid, "Note icon", "info", 306, 588, 18, "feedback/info-icon")
    A.text(fid, "Note text", "هذه المعلومات مخصصة للإرشاد الأولي ولا تعوّض التوجيه الصادر عن أمانة الضبط.",
           36, 584, 12, 400, "feedback/info-text", w=262, align="right", lh=1.4)

    # Actions at bottom
    B.button(fid, "اتصال بالمركز (000-000-000)", 24, 638, 312, 52, "primary", icon="phone")
    B.button(fid, "نسخ رقم الهاتف", 24, 700, 312, 46, "outline", icon="copy")

    A.rect(fid, "Gesture bar", (W - 108) / 2, H - A.GESTURE_H + 8, 108, 4, fill="text/primary", r=2, opacity=0.6)


def screen_empty(fid):
    B.shell(fid)
    B.appbar_title(fid, "مراكز وهيئات")

    # Search bar with search term
    A.rect(fid, "Search box", 24, 88, 312, 44, fill="surface/card", stroke="border/focus", sw=2, r=12)
    A.icon(fid, "Search icon", "search", 304, 100, 20, "text/secondary")
    B.rtext(fid, "Search value", "عيادة خاصة", 294, 99, 14, 600, "text/primary", lh=1.4)
    A.icon(fid, "Search clear", "x", 36, 100, 20, "text/secondary")

    # Wilaya filter bar
    A.rect(fid, "Wilaya filter btn", 154, 140, 182, 34, fill="surface/sunken", stroke="border/strong", sw=1, r=17)
    A.icon(fid, "Wilaya filter icon", "map-pin", 318, 148, 16, "action/primary")
    B.rtext(fid, "Wilaya filter text", "الولاية: 47 - غرداية", 298, 147, 13, 600, "text/primary", lh=1.4)

    # Empty illustration
    A.ellipse(fid, "Empty circle", (W - 88) / 2, 280, 88, 88, fill="surface/sunken")
    A.icon(fid, "Empty icon", "building", (W - 40) / 2, 304, 40, "text/tertiary")

    A.text(fid, "Empty title", "لا توجد مراكز مطابقة", PAD, 390, 20, 700, "text/primary", w=312, align="center", lh=1.4)
    A.text(fid, "Empty desc", "لم نعثر على أي مراكز قضائية أو هيئات حماية تطابق «عيادة خاصة» في ولاية غرداية. يمكنك تصفح باقي الولايات.",
           36, 430, 14, 400, "text/secondary", w=288, align="center", lh=1.6)

    B.button(fid, "عرض جميع المراكز في الوطن", 48, 520, 264, 48, "primary")
    B.tabbar(fid, 0)


CENTERS_SCREENS = [
    ("Centers list", screen_list, "surface/page"),
    ("Centers wilaya filter", screen_wilaya_filter, "surface/page"),
    ("Center detail", screen_detail, "surface/page"),
    ("Centers empty", screen_empty, "surface/page"),
]
