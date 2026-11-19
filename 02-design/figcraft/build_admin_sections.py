#!/usr/bin/env python3
"""New admin panel screens for FigCraft (desktop 1280 x 800, Arabic RTL).

Implements the Task 7 Design list:
  - 11 Admin Home: Dashboard home (4 stat cards, reports chart, doughnut chart, latest reports table)
  - 12 Admin Content: Content library list with type tabs + edit form (rich text, published toggle)
  - 13 Admin Centers: Centers list with kind tabs & wilaya filter + edit form
  - 14 Admin Users: Users & families table (read-only, linked status)
  - 15 Admin Visits: Shared visits table (read-only, 4 status badges: proposed, accepted, declined, confirmed)
  - 16 Admin Activity log: Activity log table for evidence integrity
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import build_auth as A  # noqa: E402
import build_admin as AD  # noqa: E402

AW, AH = AD.AW, AD.AH
WEB_FONT = AD.WEB_FONT


# ----------------------------------------------------------------------------- 11 Admin Home (Dashboard)
def screen_dashboard_home(f):
    AD.shell(f, "dashboard", "لوحة التحكم", "نظرة عامة")
    AD.page_title(f, "لوحة التحكم الرئيسية")

    # 4 Stat Cards at y = 148
    stats = [
        (751, "بلاغات قيد المراجعة", "5", "3 وردت هذا الأسبوع", "warn", "عاجل"),
        (511, "زيارات قادمة", "12", "خلال الـ 7 أيام القادمة", "info", "مجدولة"),
        (271, "عائلات مسجلة", "36", "18 عائلة مكتملة الربط", "ok", "نشطة"),
        (32, "المحتوى والمراكز", "36", "24 نص · 12 مركز", "gray", "مفهرس"),
    ]
    for x, label, val, sub, badge_kind, badge_text in stats:
        AD.card(f, x, 148, 226, 108)
        bw = AD.measure(f, badge_text, 12, 600) + 24
        AD.badge(f, x + 16 + bw, 160, badge_text, badge_kind)
        AD.rt(f, label, x + 210, 162, 13, 500, "text/secondary", lh=1.3)
        AD.rt(f, val, x + 210, 186, 28, 700, "text/primary", lh=1.3)
        AD.rt(f, sub, x + 210, 224, 11, 400, "text/secondary", lh=1.3)

    # Middle Row at y = 270 (h = 240)
    # Right: Reports per week chart
    cw = 595
    AD.card(f, 382, 270, cw, 240)
    AD.rt(f, "البلاغات المنشأة أسبوعيًا", 382 + cw - 20, 286, 15, 700, "text/primary", lh=1.4)
    AD.rt(f, "آخر 8 أسابيع (العدد الإجمالي: 30 بلاغ)", 382 + cw - 20, 308, 12, 400, "text/secondary", lh=1.4)

    # Chart grid lines
    for i, gy in enumerate([350, 395, 440]):
        AD.hline(f, 412, gy, 535)
        AD.lt(f, str((3 - i) * 2), 954, gy - 8, 10, 400, "text/tertiary")

    # 8 Columns (weeks 1 to 8)
    counts = [2, 4, 1, 5, 3, 6, 4, 5]
    max_c = 6
    base_y = 440
    chart_h = 90
    for i, c in enumerate(counts):
        bx = 428 + i * 65
        bh = int((c / max_c) * chart_h)
        by = base_y - bh
        # Track background
        A.rect(f, f"Track {i}", bx, base_y - chart_h, 32, chart_h, fill="surface/sunken", r=4)
        # Active bar
        A.rect(f, f"Bar {i}", bx, by, 32, bh, fill="action/primary", r=4)
        # Value above
        A.text(f, f"Val {i}", str(c), bx, by - 16, 11, 700, "text/primary", w=32, align="center", lh=1.4)
        # Label below
        A.text(f, f"Week {i}", f"س {i + 1}", bx, base_y + 8, 11, 500, "text/secondary", w=32, align="center", lh=1.4)

    # Left: Status Doughnut Chart
    dw = 334
    AD.card(f, 32, 270, dw, 240)
    AD.rt(f, "توزيع البلاغات حسب الحالة", 32 + dw - 20, 286, 15, 700, "text/primary", lh=1.4)
    AD.rt(f, "19 بلاغ إجمالي", 32 + dw - 20, 308, 12, 400, "text/secondary", lh=1.4)

    # Doughnut Visual (center x=120, y=390)
    cx, cy = 110, 390
    A.ellipse(f, "Doughnut outer", cx - 55, cy - 55, 110, 110, fill="action/primary")
    A.ellipse(f, "Doughnut reviewed slice", cx - 55, cy - 55, 110, 110, fill="feedback/success-text")
    # Accent ring
    A.ellipse(f, "Doughnut pending slice", cx - 45, cy - 45, 90, 90, fill="feedback/warning-text")
    A.ellipse(f, "Doughnut inner hole", cx - 35, cy - 35, 70, 70, fill="surface/card")
    A.text(f, "Doughnut count", "19", cx - 35, cy - 14, 20, 700, "text/primary", w=70, align="center", lh=1.3)
    A.text(f, "Doughnut sub", "إجمالي", cx - 35, cy + 8, 11, 400, "text/secondary", w=70, align="center", lh=1.3)

    # Doughnut Legend
    legend_items = [
        ("تمت المراجعة: 12", "feedback/success-bg", "feedback/success-text"),
        ("قيد المراجعة: 5", "feedback/warning-bg", "feedback/warning-text"),
        ("أخرى / مغلقة: 2", "surface/sunken", "text/secondary"),
    ]
    ly = 352
    for label, bg_c, text_c in legend_items:
        A.ellipse(f, "Legend dot", 298, ly + 4, 10, 10, fill=text_c)
        AD.rt(f, label, 290, ly, 12, 600, "text/primary", lh=1.4)
        ly += 30

    # Bottom Row: Latest reports table (y = 526, h = 246)
    AD.card(f, 32, 526, 945, 246)
    AD.rt(f, "أحدث البلاغات الواردة", 955, 542, 15, 700, "text/primary", lh=1.4)
    AD.btn(f, 52, 538, 126, 32, "عرض كل البلاغات", "outline", "eye")

    AD.th(f, ["رقم البلاغ", "مقدّم البلاغ", "تاريخ الحادثة", "المرفقات", "الحالة", ""], 574, [979, 815, 698, 477, 374, 189])
    rows = [
        ("RIA-2026-0142", "أمينة", "أم", "17 نوفمبر 2026 · 09:30", "2", "info"),
        ("RIA-2026-0141", "ياسين", "أب", "16 نوفمبر 2026 · 20:10", "0", "info"),
        ("RIA-2026-0140", "أمينة", "أم", "14 نوفمبر 2026 · 08:45", "3", "ok"),
    ]
    y = 616
    for i, (ref, name, role, date, n, st) in enumerate(rows):
        AD.rt(f, ref, 959, y + 10, 13, 500, "text/primary", direction="ltr")
        AD.rt(f, f"{name} ({role})", 795, y + 10, 13, 600, "text/primary", lh=1.4)
        AD.rt(f, date, 678, y + 10, 13, 400, "text/primary")
        AD.rt(f, n, 457, y + 10, 13, 400, "text/primary")
        if st == "info":
            AD.badge(f, 355, y + 8, "قيد المراجعة", "info")
        else:
            AD.badge(f, 355, y + 8, "تمت المراجعة", "ok", "check")
        AD.btn(f, 52, y + 4, 80, 32, "عرض", "outline", "eye")
        if i < 2:
            AD.hline(f, 33, y + 42, 943)
        y += 43


# ----------------------------------------------------------------------------- 12 Admin Content
def screen_content_list(f):
    AD.shell(f, "content", "المحتوى", "المحتوى التعليمي")
    AD.page_title(f, "المحتوى التعليمي")
    AD.btn(f, 32, 89, 140, 40, "إضافة محتوى", "primary", "plus")

    AD.card(f, 32, 150, 949, 580)
    # Type tabs
    tabs = [("الكل (24)", 874, 86, True), ("مقالات (8)", 764, 98, False), ("قوانين (6)", 656, 96, False),
            ("اجتهادات (6)", 538, 106, False), ("أدلة (4)", 432, 94, False)]
    AD.hline(f, 33, 193, 947)
    for label, x, w, on in tabs:
        A.text(f, "Tab", label, x, 160, 14, 600, "text/link" if on else "text/secondary", w=w, align="center", lh=1.4)
        if on:
            A.rect(f, "Tab underline", x, 192, w, 2, fill="action/primary")

    AD.toolbar_search(f, 206, 960, "ابحث في العنوان، المرجع، أو الكلمات المفتاحية...")
    AD.field_box(f, 388, 206, 200)
    AD.rt(f, "الحالة: الكل", 576, 216, 14, 400, "text/secondary")

    AD.hline(f, 33, 258, 947)
    AD.th(f, ["العنوان", "النوع", "المرجع", "تاريخ النشر", "الحالة", ""], 259, [980, 710, 590, 490, 390, 270])

    content_rows = [
        ("شروط استحقاق الحضانة وسقوطها", "قانون", "FC-064", "18 نوفمبر 2026", "ok", "منشور"),
        ("كيف تتجنب النزاع أثناء تسليم المحضون؟", "مقال", "ART-012", "16 نوفمبر 2026", "ok", "منشور"),
        ("قرار المحكمة العليا رقم 412580", "اجتهاد", "SC-0412", "12 نوفمبر 2026", "ok", "منشور"),
        ("دليل الوالدين للتعامل مع الزيارة المشتركة", "دليل", "GD-003", "10 نوفمبر 2026", "ok", "منشور"),
        ("إجراءات إثبات الضرر والتبليغ القانوني", "مقال", "ART-015", "05 نوفمبر 2026", "gray", "مسودة"),
    ]
    y = 301
    for i, (title, typ, ref, date, st, stlabel) in enumerate(content_rows):
        h = 66
        AD.rt(f, title, 960, y + 22, 14, 600, "text/primary", lh=1.4)
        AD.badge(f, 690, y + 21, typ, "gray")
        AD.rt(f, ref, 570, y + 22, 13, 500, "text/primary", direction="ltr")
        AD.rt(f, date, 470, y + 22, 14, 400, "text/primary")
        AD.badge(f, 370, y + 21, stlabel, st, "check" if st == "ok" else None)
        AD.btn(f, 52, y + 13, 80, 40, "حذف", "danger-o", "trash")
        AD.btn(f, 138, y + 13, 94, 40, "تعديل", "outline", "pencil")
        if i < 4:
            AD.hline(f, 33, y + h - 1, 947)
        y += h

    AD.hline(f, 33, 680, 947)
    AD.rt(f, "عرض 1 – 5 من 24", 960, 694, 14, 400, "text/secondary")
    AD.lt(f, "الصفحة 1 من 5", 52, 694, 14, 400, "text/secondary")


def screen_content_edit(f):
    AD.shell(f, "content", "المحتوى التعليمي", "تعديل محتوى")
    AD.page_title(f, "تعديل: شروط استحقاق الحضانة وسقوطها")

    # Main Card
    AD.card(f, 361, 150, 619, 615)
    AD.rt(f, "العنوان", 960, 168, 14, 600, "text/primary", lh=1.4)
    AD.field_box(f, 382, 192, 578, 42, focus=True)
    AD.rt(f, "شروط استحقاق الحضانة وسقوطها", 944, 203, 14, 400, "text/primary")

    # Type & Reference row
    AD.rt(f, "النوع", 960, 246, 14, 600, "text/primary", lh=1.4)
    AD.field_box(f, 679, 270, 281, 42)
    AD.rt(f, "قانون", 944, 281, 14, 400, "text/primary")
    A.icon(f, "Type chevron", "chevd", 695, 284, 16, "text/secondary")

    AD.rt(f, "المرجع", 663, 246, 14, 600, "text/primary", lh=1.4)
    AD.field_box(f, 382, 270, 281, 42)
    AD.rt(f, "FC-064 · المادة 64", 647, 281, 14, 400, "text/primary")

    # Summary
    AD.rt(f, "الملخص الموجز (يظهر في بطاقة القائمة)", 960, 324, 14, 600, "text/primary", lh=1.4)
    AD.field_box(f, 382, 348, 578, 52)
    AD.rt(f, "ملخص لأهم المواد المنظمة للحضانة في قانون الأسرة الجزائري وشروط ممارستها وحالات إسقاطها.",
          944, 362, 13, 400, "text/primary")

    # Rich Text Area
    AD.rt(f, "المحتوى الكامل (Rich Text)", 960, 412, 14, 600, "text/primary", lh=1.4)
    A.rect(f, "Editor box", 382, 436, 578, 180, fill="surface/card", stroke="border/strong", sw=1, r=8)
    # Editor toolbar
    A.rect(f, "Editor toolbar", 382, 436, 578, 34, fill="surface/sunken", r=8)
    tools = ["B", "I", "H2", "H3", "List", "Link"]
    for idx, t in enumerate(tools):
        A.rect(f, f"Tool {t}", 916 - idx * 36, 440, 28, 26, fill="surface/card", stroke="border/default", sw=1, r=4)
        A.text(f, f"Tool text {t}", t, 916 - idx * 36, 445, 11, 700, "text/secondary", w=28, align="center", lh=1.3)
    AD.hline(f, 382, 470, 578)

    sample_rich = ("الحضانة هي حفظ الولد وتربيته ورعايته بما يحقق مصلحته الفضلى. "
                   "وقد أسندها المشرّع في المادة 64 إلى الأم أولاً، ثم إلى أمها، ثم إلى خالتها، ثم إلى الأب.")
    A.text(f, "Rich text body", sample_rich, 398, 482, 13, 400, "text/primary", w=546, align="right", lh=1.6)

    # Published toggle
    A.rect(f, "Switch", 920, 630, 40, 24, fill="action/primary", r=12)
    A.ellipse(f, "Switch knob", 923, 633, 18, 18, fill="text/on-action")
    AD.rt(f, "منشور في التطبيق", 908, 624, 14, 700, "text/primary", lh=1.4)
    AD.rt(f, "يظهر هذا المحتوى لجميع الوالدين في مكتبة التطبيق.", 908, 646, 12, 400, "text/secondary", lh=1.4)

    # Buttons
    AD.btn(f, 851, 680, 108, 40, "حفظ التغييرات", "primary")
    AD.btn(f, 783, 680, 56, 40, "إلغاء", "outline")

    # Side Cards
    AD.card(f, 32, 150, 310, 230)
    AD.rt(f, "حالة النشر والمشاهدات", 320, 166, 15, 700, "text/primary", lh=1.4)
    AD.badge(f, 131, 166, "منشور", "ok", "check")
    AD.hline(f, 33, 204, 308)
    meta_rows = [("تاريخ الإنشاء", "10 نوفمبر 2026"), ("آخر تعديل", "اليوم · قبل ساعتين"), ("الكاتب / المسؤول", "مسؤول النظام"), ("قراءات الوالدين", "142 قراءة")]
    for i, (k, v) in enumerate(meta_rows):
        yy = 216 + i * 26
        AD.rt(f, k, 320, yy, 12, 400, "text/secondary", lh=1.4)
        AD.lt(f, v, 52, yy, 12, 600, "text/primary", lh=1.4, w=150, align="left")

    # Side Danger Card
    AD.card(f, 32, 400, 310, 180)
    AD.rt(f, "منطقة الحذف", 320, 416, 15, 700, "text/primary", lh=1.4)
    AD.hline(f, 33, 454, 308)
    A.text(f, "Danger text", "عند حذف هذا النص التعليمي، ستتم إزالته من تطبيق الهاتف ولن يتمكن الوالدان من الوصول إليه.",
           52, 470, 13, 400, "text/secondary", w=268, align="right", lh=1.5)
    AD.btn(f, 202, 524, 119, 40, "حذف المحتوى", "danger-o", "trash")


# ----------------------------------------------------------------------------- 13 Admin Centers
def screen_centers_list(f):
    AD.shell(f, "centers", "المحتوى", "مراكز وهيئات")
    AD.page_title(f, "دليل المراكز والهيئات")
    AD.btn(f, 32, 89, 130, 40, "إضافة مركز", "primary", "plus")

    AD.card(f, 32, 150, 949, 580)
    # Tabs by kind
    tabs = [("الكل (12)", 874, 86, True), ("محاكم (4)", 764, 98, False), ("حماية الطفولة (2)", 622, 130, False),
            ("مساعدة قانونية (2)", 478, 132, False), ("دعم نفسي (2)", 356, 110, False)]
    AD.hline(f, 33, 193, 947)
    for label, x, w, on in tabs:
        A.text(f, "Tab", label, x, 160, 14, 600, "text/link" if on else "text/secondary", w=w, align="center", lh=1.4)
        if on:
            A.rect(f, "Tab underline", x, 192, w, 2, fill="action/primary")

    AD.toolbar_search(f, 206, 960, "ابحث باسم المركز أو العنوان أو رقم الهاتف...")
    AD.field_box(f, 388, 206, 200)
    AD.rt(f, "الولاية: 16 - الجزائر", 576, 216, 13, 400, "text/secondary")
    A.icon(f, "Wilaya drop icon", "chevd", 400, 218, 16, "text/secondary")

    AD.hline(f, 33, 258, 947)
    AD.th(f, ["اسم المركز", "النوع", "الولاية", "الهاتف", "الحالة", ""], 259, [980, 680, 560, 460, 360, 260])

    centers_rows = [
        ("محكمة سيدي امحمد - قسم شؤون الأسرة", "محكمة", "16 - الجزائر", "000-000-000", "ok", "منشور"),
        ("الهيئة الوطنية لحماية وترقية الطفولة", "حماية الطفولة", "16 - الجزائر", "11-11", "ok", "منشور"),
        ("مكتب المساعدة القضائية - وهران", "مساعدة قانونية", "31 - وهران", "000-000-000", "ok", "منشور"),
        ("مركز الدعم النفسي والإرشادي الأسري", "دعم نفسي", "09 - البليدة", "000-000-000", "ok", "منشور"),
        ("جمعية أمان للطفولة والأسرة", "جمعية", "25 - قسنطينة", "000-000-000", "gray", "مسودة"),
    ]
    y = 301
    for i, (name, typ, wilaya, phone, st, stlabel) in enumerate(centers_rows):
        h = 66
        AD.rt(f, name, 960, y + 22, 14, 600, "text/primary", lh=1.4)
        AD.badge(f, 660, y + 21, typ, "gray")
        AD.rt(f, wilaya, 540, y + 22, 13, 400, "text/primary")
        AD.rt(f, phone, 440, y + 22, 13, 500, "text/primary", direction="ltr")
        AD.badge(f, 340, y + 21, stlabel, st, "check" if st == "ok" else None)
        AD.btn(f, 52, y + 13, 80, 40, "حذف", "danger-o", "trash")
        AD.btn(f, 138, y + 13, 94, 40, "تعديل", "outline", "pencil")
        if i < 4:
            AD.hline(f, 33, y + h - 1, 947)
        y += h

    AD.hline(f, 33, 680, 947)
    AD.rt(f, "عرض 1 – 5 من 12 مركز", 960, 694, 14, 400, "text/secondary")
    AD.lt(f, "الصفحة 1 من 3", 52, 694, 14, 400, "text/secondary")


def screen_centers_edit(f):
    AD.shell(f, "centers", "مراكز وهيئات", "تعديل مركز")
    AD.page_title(f, "تعديل: محكمة سيدي امحمد - قسم شؤون الأسرة")

    # Main Card
    AD.card(f, 361, 150, 619, 615)
    AD.rt(f, "اسم المركز أو الهيئة", 960, 168, 14, 600, "text/primary", lh=1.4)
    AD.field_box(f, 382, 192, 578, 42, focus=True)
    AD.rt(f, "محكمة سيدي امحمد - قسم شؤون الأسرة", 944, 203, 14, 400, "text/primary")

    # Kind & Wilaya row
    AD.rt(f, "النوع والتصنيف", 960, 246, 14, 600, "text/primary", lh=1.4)
    AD.field_box(f, 679, 270, 281, 42)
    AD.rt(f, "محكمة شؤون الأسرة", 944, 281, 14, 400, "text/primary")
    A.icon(f, "Kind drop icon", "chevd", 695, 284, 16, "text/secondary")

    AD.rt(f, "الولاية", 663, 246, 14, 600, "text/primary", lh=1.4)
    AD.field_box(f, 382, 270, 281, 42)
    AD.rt(f, "16 - الجزائر (العاصمة)", 647, 281, 14, 400, "text/primary")
    A.icon(f, "Wilaya drop icon 2", "chevd", 398, 284, 16, "text/secondary")

    # Address
    AD.rt(f, "العنوان التفصيلي", 960, 324, 14, 600, "text/primary", lh=1.4)
    AD.field_box(f, 382, 348, 578, 42)
    AD.rt(f, "شارع عبان رمضان، الجزائر الوسطى، الجزائر العاصمة", 944, 359, 13, 400, "text/primary")

    # Phone & Hotline
    AD.rt(f, "الهاتف الرئيسي", 960, 402, 14, 600, "text/primary", lh=1.4)
    AD.field_box(f, 679, 426, 281, 42)
    AD.rt(f, "000-000-000", 944, 437, 13, 500, "text/primary", direction="ltr")

    AD.rt(f, "الخط الأخضر / المباشر (اختياري)", 663, 402, 14, 600, "text/primary", lh=1.4)
    AD.field_box(f, 382, 426, 281, 42)
    AD.rt(f, "11-11", 647, 437, 13, 500, "text/primary", direction="ltr")

    # Notes
    AD.rt(f, "ملاحظات واختصاص المركز", 960, 480, 14, 600, "text/primary", lh=1.4)
    AD.field_box(f, 382, 504, 578, 64)
    AD.rt(f, "بيانات تجريبية لأغراض العرض والتقييم. يستقبل المواطنين لرفع دعاوى شؤون الأسرة وتنظيم الزيارات.",
          944, 516, 13, 400, "text/primary")

    # Published toggle
    A.rect(f, "Switch centers", 920, 590, 40, 24, fill="action/primary", r=12)
    A.ellipse(f, "Switch knob centers", 923, 593, 18, 18, fill="text/on-action")
    AD.rt(f, "منشور في الدليل", 908, 584, 14, 700, "text/primary", lh=1.4)
    AD.rt(f, "يظهر هذا المركز في دليل الهيئات بالهاتف مع زر الاتصال المباشر.", 908, 606, 12, 400, "text/secondary", lh=1.4)

    # Buttons
    AD.btn(f, 851, 650, 108, 40, "حفظ المركز", "primary")
    AD.btn(f, 783, 650, 56, 40, "إلغاء", "outline")

    # Side Cards
    AD.card(f, 32, 150, 310, 230)
    AD.rt(f, "بيانات المركز والتحديث", 320, 166, 15, 700, "text/primary", lh=1.4)
    AD.badge(f, 131, 166, "منشور", "ok", "check")
    AD.hline(f, 33, 204, 308)
    meta_rows = [("حالة السجل", "نشط"), ("التحقق الميداني", "تم التحقق"), ("آخر مراجعة", "15 نوفمبر 2026"), ("المسؤول عن الإدخال", "مسؤول النظام")]
    for i, (k, v) in enumerate(meta_rows):
        yy = 216 + i * 26
        AD.rt(f, k, 320, yy, 12, 400, "text/secondary", lh=1.4)
        AD.lt(f, v, 52, yy, 12, 600, "text/primary", lh=1.4, w=150, align="left")

    # Danger Card
    AD.card(f, 32, 400, 310, 180)
    AD.rt(f, "منطقة الحذف", 320, 416, 15, 700, "text/primary", lh=1.4)
    AD.hline(f, 33, 454, 308)
    A.text(f, "Danger text 2", "عند حذف هذا المركز سيتم إزالته فورًا من دليل الهيئات في تطبيق الهاتف.",
           52, 470, 13, 400, "text/secondary", w=268, align="right", lh=1.5)
    AD.btn(f, 202, 524, 119, 40, "حذف المركز", "danger-o", "trash")


# ----------------------------------------------------------------------------- 14 Admin Users
def screen_users_table(f):
    AD.shell(f, "users", "الحسابات", "المستخدمون")
    AD.page_title(f, "المستخدمون والعائلات")

    # Read-only Banner
    A.rect(f, "Banner", 32, 140, 949, 44, fill="feedback/info-bg", stroke="feedback/info-border", sw=1, r=8)
    A.icon(f, "Banner icon", "lock", 955, 153, 18, "feedback/info-icon")
    AD.rt(f, "عرض للقراءة فقط — بيانات المستخدمين محمية بموجب سياسة الخصوصية ولا تظهر كلمات المرور أو رموز الوصول.",
          945, 152, 13, 500, "feedback/info-text", lh=1.4)

    AD.card(f, 32, 196, 949, 574)
    AD.toolbar_search(f, 212, 960, "ابحث باسم المستخدم أو البريد الإلكتروني...")
    AD.field_box(f, 408, 212, 170)
    AD.rt(f, "الدور: الكل", 562, 222, 13, 400, "text/secondary")
    AD.field_box(f, 226, 212, 170)
    AD.rt(f, "حالة الربط: الكل", 380, 222, 13, 400, "text/secondary")

    AD.hline(f, 33, 268, 947)
    AD.th(f, ["المستخدم", "الدور", "الولاية", "الأطفال", "حالة الربط", "الطرف الآخر", "تاريخ الانضمام", "آخر نشاط"],
          269, [979, 830, 750, 670, 580, 470, 350, 200])

    users_rows = [
        ("أمينة بن علي", "amina@example.com", "أم", "16 - الجزائر", "2", "مرتبط", "ياسين مراد", "10 نوفمبر 2026", "قبل 15 دقيقة"),
        ("ياسين مراد", "yassine@example.com", "أب", "16 - الجزائر", "2", "مرتبط", "أمينة بن علي", "10 نوفمبر 2026", "قبل ساعتين"),
        ("فاطمة زهراء", "fatima@example.com", "أم", "31 - وهران", "1", "غير مرتبط", "—", "14 نوفمبر 2026", "أمس"),
        ("كريم سعدي", "karim@example.com", "أب", "25 - قسنطينة", "3", "غير مرتبط", "—", "15 نوفمبر 2026", "قبل 3 أيام"),
        ("سعاد علام", "souad@example.com", "أم", "06 - بجاية", "1", "مرتبط", "محمد علام", "12 نوفمبر 2026", "قبل 5 أيام"),
    ]

    y = 311
    for i, (name, email, role, wilaya, children, linked, partner, joined, last_active) in enumerate(users_rows):
        h = 66
        AD.rt(f, name, 959, y + 14, 14, 600, "text/primary", lh=1.4)
        AD.rt(f, email, 959, y + 36, 12, 400, "text/secondary", direction="ltr")
        AD.badge(f, 810, y + 21, role, "info" if role == "أم" else "warn")
        AD.rt(f, wilaya, 730, y + 22, 13, 400, "text/primary")
        AD.rt(f, children, 650, y + 22, 13, 500, "text/primary")
        AD.badge(f, 560, y + 21, linked, "ok" if linked == "مرتبط" else "gray")
        AD.rt(f, partner, 450, y + 22, 13, 500, "text/primary" if partner != "—" else "text/tertiary")
        AD.rt(f, joined, 330, y + 22, 13, 400, "text/secondary")
        AD.rt(f, last_active, 180, y + 22, 13, 400, "text/primary")
        if i < 4:
            AD.hline(f, 33, y + h - 1, 947)
        y += h

    AD.hline(f, 33, 715, 947)
    AD.rt(f, "عرض 1 – 5 من 36 مستخدم", 960, 730, 14, 400, "text/secondary")
    AD.lt(f, "الصفحة 1 من 8", 52, 730, 14, 400, "text/secondary")


# ----------------------------------------------------------------------------- 15 Admin Visits
def screen_visits_table(f):
    AD.shell(f, "visits", "العمليات", "الزيارات")
    AD.page_title(f, "سجل الزيارات المشتركة")

    # Read-only banner
    A.rect(f, "Banner", 32, 140, 949, 44, fill="surface/sunken", stroke="border/default", sw=1, r=8)
    A.icon(f, "Banner icon", "cal", 955, 153, 18, "text/secondary")
    AD.rt(f, "عرض للقراءة فقط — متابعة جدول الزيارات المتفق عليها بين الأولياء لضمان سيرها بسلاسة وبما يخدم مصلحة الطفل.",
          945, 152, 13, 500, "text/secondary", lh=1.4)

    AD.card(f, 32, 196, 949, 574)
    AD.toolbar_search(f, 212, 960, "ابحث بأسماء الوالدين...")
    AD.field_box(f, 408, 212, 170)
    AD.rt(f, "الحالة: الكل", 562, 222, 13, 400, "text/secondary")
    AD.field_box(f, 226, 212, 170)
    AD.rt(f, "الفترة: هذا الشهر", 380, 222, 13, 400, "text/secondary")

    AD.hline(f, 33, 268, 947)
    AD.th(f, ["تاريخ الزيارة", "التوقيت", "العائلة (الوالدان)", "المقترح من", "الحالة", "آخر تحديث"],
          269, [979, 780, 640, 480, 360, 180])

    # 4 Status Badges per spec: proposed info, accepted warning, declined danger, confirmed success
    visits_rows = [
        ("الجمعة 20 نوفمبر 2026", "10:00 – 14:00", "أمينة / ياسين", "الأب", "info", "مقترحة", "قبل يوم"),
        ("الجمعة 13 نوفمبر 2026", "10:00 – 16:00", "أمينة / ياسين", "الأم", "ok", "مؤكدة", "14 نوفمبر 2026"),
        ("السبت 07 نوفمبر 2026", "14:00 – 18:00", "سعاد / محمد", "الأب", "warn", "مقبولة", "06 نوفمبر 2026"),
        ("الجمعة 31 أكتوبر 2026", "09:00 – 13:00", "فاطمة / رشيد", "الأم", "bad", "مرفوضة", "30 أكتوبر 2026"),
        ("الجمعة 24 أكتوبر 2026", "10:00 – 15:00", "أمينة / ياسين", "الأب", "ok", "مؤكدة", "25 أكتوبر 2026"),
    ]

    y = 311
    for i, (date, time_slot, family, proposed_by, st, stlabel, updated) in enumerate(visits_rows):
        h = 66
        AD.rt(f, date, 959, y + 22, 14, 600, "text/primary", lh=1.4)
        AD.rt(f, time_slot, 760, y + 22, 13, 500, "text/primary", direction="ltr")
        AD.rt(f, family, 620, y + 22, 13, 500, "text/primary")
        AD.rt(f, proposed_by, 460, y + 22, 13, 400, "text/secondary")
        AD.badge(f, 340, y + 21, stlabel, st, "check" if st == "ok" else ("clock" if st == "info" else None))
        AD.rt(f, updated, 160, y + 22, 13, 400, "text/secondary")
        if i < 4:
            AD.hline(f, 33, y + h - 1, 947)
        y += h

    AD.hline(f, 33, 715, 947)
    AD.rt(f, "عرض 1 – 5 من 28 زيارة", 960, 730, 14, 400, "text/secondary")
    AD.lt(f, "الصفحة 1 من 6", 52, 730, 14, 400, "text/secondary")


# ----------------------------------------------------------------------------- 16 Admin Activity Log
def screen_activity_table(f):
    AD.shell(f, "activity", "الحسابات", "سجل النشاط")
    AD.page_title(f, "سجل نشاط الإدارة")

    # Integrity Notice Banner
    A.rect(f, "Banner", 32, 140, 949, 44, fill="feedback/info-bg", stroke="feedback/info-border", sw=1, r=8)
    A.icon(f, "Banner icon", "shield", 955, 153, 18, "feedback/info-icon")
    AD.rt(f, "سجل غير قابل للتعديل أو الحذف لضمان نزاهة الأدلة والمراجعة الرقابية وفق المعايير القانونية.",
          945, 152, 13, 500, "feedback/info-text", lh=1.4)

    AD.card(f, 32, 196, 949, 574)
    AD.toolbar_search(f, 212, 960, "ابحث في السجل أو نوع الإجراء...")
    AD.field_box(f, 408, 212, 170)
    AD.rt(f, "الإجراء: الكل", 562, 222, 13, 400, "text/secondary")
    AD.field_box(f, 226, 212, 170)
    AD.rt(f, "المسؤول: مسؤول النظام", 380, 222, 13, 400, "text/secondary")

    AD.hline(f, 33, 268, 947)
    AD.th(f, ["المسؤول", "الإجراء المتخذ", "السجل / الهدف", "عنوان IP", "التوقيت"],
          269, [979, 810, 560, 340, 180])

    activity_rows = [
        ("مسؤول النظام (م)", "تعليم البلاغ كتمت المراجعة", "RIA-2026-0138 (بلاغ)", "192.168.1.10", "قبل 10 دقائق"),
        ("مسؤول النظام (م)", "تنزيل تقرير البلاغ PDF", "RIA-2026-0142 (بلاغ)", "192.168.1.10", "قبل 25 دقيقة"),
        ("مسؤول النظام (م)", "فتح مرفق ملف أدلة", "فيديو 1 · RIA-2026-0142", "192.168.1.10", "قبل 28 دقيقة"),
        ("مسؤول النظام (م)", "تعديل محتوى تعليمي", "قانون الأسرة · المادة 64", "192.168.1.10", "قبل ساعتين"),
        ("مسؤول النظام (م)", "إضافة مركز دعم جديد", "الهيئة الوطنية لحماية الطفولة", "192.168.1.10", "أمس · 16:40"),
    ]

    y = 311
    for i, (admin_user, action_desc, record_target, ip_addr, log_time) in enumerate(activity_rows):
        h = 66
        AD.rt(f, admin_user, 959, y + 22, 14, 600, "text/primary", lh=1.4)
        AD.rt(f, action_desc, 790, y + 22, 13, 500, "text/primary")
        AD.badge(f, 540, y + 21, record_target, "gray")
        AD.rt(f, ip_addr, 320, y + 22, 13, 400, "text/secondary", direction="ltr")
        AD.rt(f, log_time, 160, y + 22, 13, 400, "text/secondary")
        if i < 4:
            AD.hline(f, 33, y + h - 1, 947)
        y += h

    AD.hline(f, 33, 715, 947)
    AD.rt(f, "عرض 1 – 5 من 142 عملية مسجلة", 960, 730, 14, 400, "text/secondary")
    AD.lt(f, "الصفحة 1 من 29", 52, 730, 14, 400, "text/secondary")


# ----------------------------------------------------------------------------- Page Builders
def _build_admin_section_page(pid, page_header, page_title_str, page_desc, screens, made):
    saved = (A.FONT, A.DISPLAY, A.SERIF)
    A.FONT = A.DISPLAY = A.SERIF = WEB_FONT
    try:
        A.ex("page.select", id=pid)
        A.ex("page.setBackground", id=pid, color="#E9EDE5")
        page_header(page_title_str, page_desc)
        short = page_title_str.split(" ", 1)[1]
        for r, mode in enumerate(("Light", "Dark")):
            ids = []
            for i, (name, fn) in enumerate(screens):
                fid = AD.new_frame(f"{name} / {mode}", i * (AW + 80), r * (AH + 140))
                fn(fid)
                if mode == "Dark":
                    A.ex("variable.setMode", ids=[fid], collection=A.COLL, mode="Dark")
                fname = f"{page_title_str.replace(' ', '-')}_{name.replace(' ', '-')}_{mode}.png"
                A.ex("file.export", ids=[fid], format="png", scale=1,
                     path=os.path.join(A.OUT, fname))
                ids.append(fid)
                made.append(f"{short} / {name} / {mode}")
                print("built", short, "/", name, "/", mode, flush=True)
            A.ex("object.wrapInSection", ids=ids, name=f"{short} · {mode}")
    finally:
        A.FONT, A.DISPLAY, A.SERIF = saved


def build_admin_home_page(pid, page_header, made):
    screens = [("Dashboard home", screen_dashboard_home)]
    _build_admin_section_page(pid, page_header, "11 Admin Home",
                              "Admin dashboard home: statistics, reports per week chart, status distribution doughnut, and latest reports.",
                              screens, made)


def build_admin_content_page(pid, page_header, made):
    screens = [("Content list", screen_content_list), ("Content edit", screen_content_edit)]
    _build_admin_section_page(pid, page_header, "12 Admin Content",
                              "Educational content library: articles, laws, Supreme Court rulings, and guides management.",
                              screens, made)


def build_admin_centers_page(pid, page_header, made):
    screens = [("Centers list", screen_centers_list), ("Centers edit", screen_centers_edit)]
    _build_admin_section_page(pid, page_header, "13 Admin Centers",
                              "Support centers directory: judicial, legal aid, child protection, and psychological support centers.",
                              screens, made)


def build_admin_users_page(pid, page_header, made):
    screens = [("Users table", screen_users_table)]
    _build_admin_section_page(pid, page_header, "14 Admin Users",
                              "Users and families overview: read-only list with linked status and role information.",
                              screens, made)


def build_admin_visits_page(pid, page_header, made):
    screens = [("Visits table", screen_visits_table)]
    _build_admin_section_page(pid, page_header, "15 Admin Visits",
                              "Shared visit calendar overview: read-only table with proposed, accepted, declined, and confirmed statuses.",
                              screens, made)


def build_admin_activity_page(pid, page_header, made):
    screens = [("Activity log table", screen_activity_table)]
    _build_admin_section_page(pid, page_header, "16 Admin Activity log",
                              "Immutable admin activity log for evidence integrity and administrative auditing.",
                              screens, made)
