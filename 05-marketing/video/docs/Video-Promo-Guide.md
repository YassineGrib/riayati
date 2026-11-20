# Riayati (رعايتي) — Video & Promo Guide

Complete guide to the video, promo-images, and motion assets for Riayati (رعايتي).

---

## 1. Technical Specifications

| Parameter | Value |
|---|---|
| **Frame rate** | 30 fps, progressive |
| **Video Codec** | H.264 High Profile, yuv420p, CRF 18 (visually lossless, < 9 MB per video) |
| **Audio Codec** | AAC 192 kbps, stereo, 44.1 kHz |
| **Loudness Normalization** | Target: −15.0 LUFS, True Peak ≤ −1.5 dBTP (ITU-R BS.1770-4 / EBU R128) |
| **Promo (22 s)** | 660 frames, 16:9 (1920×1080) and 9:16 (1080×1920) |
| **How-To (32 s)** | 960 frames, 9:16 (1080×1920) |
| **Problem → Solution (30 s)** | 900 frames, 9:16 (1080×1920) |
| **Story Film (40 s)** | 1200 frames, 16:9 (1920×1080) and 9:16 (1080×1920) |
| **Logo Sting (5 s)** | 150 frames, 1:1 (1080×1080), light and dark variants |
| **Feed Posts** | 1080×1350 (4:5 aspect ratio) PNG |
| **Stories / Status** | 1080×1920 (9:16 aspect ratio) PNG, safe area respected (top ≥ 260px, bottom ≥ 220px) |
| **Display Font** | `Thmanyah Serif Display` (headlines, brand name, bold/black) |
| **Body / UI Font** | `Thmanyah Sans` (body, captions, pills, buttons) |
| **Color Palette** | Olive `#658E3F`, Lime `#C5E76C`, Dark `#406A05`, Tints `#F3F8EC` / `#E4EFD3`, Ink `#1B2418`, SOS `#DC2626` |

---

## 2. Promo (22 s) — Storyboard & Narration

One single responsive codebase drives both 16:9 (`Promo`) and 9:16 (`PromoVertical`) using the `pick(v, landscape, vertical)` helper.

### Storyboard

| Scene | Time | Background | Visual Layout | Key Features Shown |
|---|---|---|---|---|
| **1. Open** | 0.0–2.6 s | Ink (`#1B2418`) | Concentric rings expand, animated SVG emblem reveals, wordmark «رعايتي» | Brand logo & identity |
| **2. Intro** | 2.2–5.6 s | Dark Olive (`#406A05`) | Large 3D phone rises showing Home screen | Home screen, app overview |
| **3. Accounts & Link** | 5.2–9.0 s | Tint Light (`#F3F8EC`) | Phone with Link screen + floating invite code card (`CROPS.linkCode`) | Independent accounts, invite code |
| **4. Report & PDF** | 8.6–12.4 s | Ink (`#1B2418`) | SOS red accent, report summary screen + structured PDF card | Incident documentation, un-deletable PDF |
| **5. Shared Calendar** | 12.0–15.6 s | Olive (`#658E3F`) | Calendar screen + floating visit proposal card (`CROPS.calendarVisit`) | Propose, confirm, and coordinate visits |
| **6. Library & Centers** | 15.2–18.2 s | Tint Dark (`#E4EFD3`) | Dual phones (Library list + Centers directory) | Educational library, court directory |
| **7. Finale** | 17.8–22.0 s | Ink (`#1B2418`) | Logo emblem, wordmark, CTA button, mandatory legal disclaimer | Brand closing, download CTA, disclaimer |

### Narration Table

| Start (s) | End (s) | Scene | Arabic Narration |
|---|---|---|---|
| 0.30 | 2.20 | Open | هذه هي رعايتي. |
| 2.30 | 5.15 | Intro | مساحة آمنة لحماية الطفل. |
| 5.40 | 8.55 | Accounts | حسابات مستقلة وربط برمز دعوة. |
| 8.70 | 11.95 | Report | توثيق رسمي غير قابل للحذف. |
| 12.00 | 15.15 | Calendar | تقويم مشترك لتنسيق الزيارات باحترام. |
| 15.20 | 17.85 | Library | مكتبة توعوية ودليل للهيئات المتخصصة. |
| 17.90 | 21.60 | Finale | رعايتي، بيئة هادئة لرعاية طفلك. |

---

## 3. How-To (32 s, Vertical 9:16) — Step-by-Step

A vertical tutorial featuring an intro, 6 numbered steps with an active 6-segment progress indicator, floating UI fragments, and an outro.

| Step | Time | On-Screen Title | On-Screen Subtitle | Screen & Crop | Narration |
|---|---|---|---|---|---|
| **Intro** | 0.0–3.0 s | كيف تبدأ مع تطبيق رعايتي؟ | ٦ خطوات مبسطة لتنظيم الحضانة | Logo reveal | كيف تبدأ مع تطبيق رعايتي؟ |
| **Step 1** | 3.0–7.2 s | حمّل التطبيق | حمّل النسخة التجريبية لأندرويد مباشرة من موقعنا | Welcome screen | الخطوة الأولى: حمّل النسخة التجريبية من الموقع. |
| **Step 2** | 7.2–11.4 s | أنشئ حسابك | أنشئ حسابك كأب أو كأم لحماية حقوق طفلك | Profile screen (`CROPS.profileCard`) | الخطوة الثانية: أنشئ حسابك كأب أو أم. |
| **Step 3** | 11.4–15.6 s | اربط الطرف الآخر | تبادلا رمز دعوة آمن لتفعيل التقويم المشترك | Link screen (`CROPS.linkCode`) | الخطوة الثالثة: اربط الطرف الآخر برمز دعوة. |
| **Step 4** | 15.6–19.8 s | وثّق أي واقعة | سجّل الوقائع بالصور والمرفقات بتقرير لا يُحذف | Report summary (`CROPS.reportPdfCard`) | الخطوة الرابعة: وثّق أي واقعة مع المرفقات. |
| **Step 5** | 19.8–24.0 s | نظّم الزيارات | اقترح مواعيد الزيارة وأكدها لتفادي الخلافات | Calendar screen (`CROPS.calendarVisit`) | الخطوة الخامسة: نسّق مواعيد الزيارة عبر التقويم. |
| **Step 6** | 24.0–28.2 s | المكتبة ودليل المراكز | إرشادات قانونية ودليل للهيئات المتخصصة حسب ولايتك | Centers directory (`CROPS.centerCard`) | الخطوة السادسة: تصفح المكتبة التوعوية ودليل الهيئات. |
| **Outro** | 28.2–32.0 s | رعايتي | مساحة آمنة لحماية الطفل في إطار الحضانة | Outro with CTA & disclaimer | رعايتي، مساحة آمنة لحماية الطفل. |

---

## 4. Problem → Solution (30 s, Vertical 9:16)

Fast-paced social advertising format: Intro (2.5 s) → 4 pairs of dark question card (2 s) followed by solution demo (3.8 s) → Outro with CTA.

| # | Question Frame (Dark, 2 s) | Solution Headline & Subtitle | Visual Assets | Narration |
|---|---|---|---|---|
| **Intro** | — | تساؤلات حول تنظيم الحضانة؟ | Logo & Rings | مشكلة في تنظيم الحضانة؟ |
| **01** | كيف أوثّق ما حدث بشكل منظم؟ | توثيق رسمي غير قابل للحذف<br>سجّل الوقائع بالمرفقات واستخرج تقرير PDF منظم | Report Summary + PDF Card | وثّق الوقائع بتقرير رسمي غير قابل للحذف. |
| **02** | كيف ننسّق الزيارات دون خلاف؟ | تقويم مشترك لتأكيد المواعيد<br>اقتراح وتأكيد مواعيد الزيارة لتفادي أي خلاف | Calendar + Visit Card | تقويم مشترك لتأكيد المواعيد بوضوح واحترام. |
| **03** | أين أجد الجهات المختصة؟ | دليل المحاكم والهيئات المتخصصة<br>دليل شامل حسب ولايتك مع إمكانية الاتصال المباشر | Centers Directory + Phone Card | دليل شامل للمحاكم والهيئات مع اتصال مباشر. |
| **04** | من يرى بياناتي؟ | خصوصية تامة وعزل كامل للبيانات<br>كل والد يطّلع على تقاريره الخاصة فقط وبكل سرية | Link Screen + Invite Code | خصوصية تامة، وكل والد يرى تقاريره فقط. |
| **Outro** | — | رعايتي · حمّل النسخة التجريبية من riayati.site | Outro CTA & disclaimer | رعايتي، لحماية الطفل واستقرار الأسرة. |

---

## 5. Story Film (40 s, 16:9 & 9:16) — Emotional Narrative

A calm, dignified emotional narrative highlighting child protection, respectful parental cooperation, and civilized structure. No drama, no blame, no photos of minors.

| Scene | Time | Atmosphere | Visual Focus | Narration |
|---|---|---|---|---|
| **1. Reflection** | 0–6 s | Deep Ink (`#1B2418`), slow contracting concentric rings | Typography focus on calm reflection | تنظيم رعاية الطفل بعد الانفصال يحتاج إلى الكثير من الهدوء. |
| **2. The Principle** | 6–12 s | Warm Olive (`#406A05`), expanding rings | Gentle opening motion, respectful tone | فمصلحة الطفل تبدأ بحوار واضح وبيئة يسودها الاحترام. |
| **3. Agreement** | 12–20 s | Soft Light (`#F3F8EC`), 3D phone + floating card | Calendar screen showing agreed visit schedule | تقويم مشترك يتيح للوالدين الاتفاق على المواعيد دون تصادم. |
| **4. Protection** | 20–27 s | Deep Ink, structured documentation | Report summary screen + structured PDF badge | وتوثيق منظم يحفظ الوقائع بملفات رسمية واضحة. |
| **5. Support** | 27–33 s | Tint Dark (`#E4EFD3`), directory | Centers directory screen + tap-to-call card | مع إرشاد توعوي ودليل شامل للهيئات القضائية والمراكز. |
| **6. Closing** | 33–40 s | Brand finale, emblem, CTA, disclaimer | Wordmark, tagline, `riayati.site` CTA | رعايتي، مساحة آمنة لحماية الطفل في إطار الحضانة. |

---

## 6. Social Media Kit (Posts & Stories)

Six targeted designs covering the core features, each delivered as a 1080×1350 feed post (4:5) and a 1080×1920 story (9:16).
In stories, all text is kept strictly inside platform safe areas (top ≥ 260px, bottom ≥ 220px).

| # | Topic | Headline | Caption | Suggested Caption Copy |
|---|---|---|---|---|
| **01** | Brand & Mission | مساحة آمنة، لحماية حقوق الطفل | تطبيق ينظم شؤون الحضانة بروح المسؤولية والاحترام | مساحة آمنة لتنظيم رعاية الطفل وحفظ الحقوق في إطار الحضانة. حمّل النسخة التجريبية: riayati.site |
| **02** | Reports & PDF | توثيق منظم، بتقرير رسمي موثق | إرفاق الصور والمستندات واستخراج PDF غير قابل للتعديل | وثّق أي واقعة مع إرفاق الملفات واستخراج تقرير منظم لا يُحذف بعد الإرسال. حمّل النسخة التجريبية: riayati.site |
| **03** | Shared Calendar | تقويم مشترك، لتنسيق الزيارات | اقتراح وتأكيد مواعيد الزيارة لتفادي الخلافات اليومية | نسّقا مواعيد الزيارة بكل وضوح واحترام لتجنب الخلافات. حمّل النسخة التجريبية: riayati.site |
| **04** | Legal Library | مكتبة توعوية، لإرشاد الوالدين | معلومات قانونية وأحكام قضائية مبسطة لحماية مصلحة الطفل | نصوص قانونية مبسطة ومعلومات موثوقة لإرشاد الوالدين. حمّل النسخة التجريبية: riayati.site |
| **05** | Centers Directory | دليل الهيئات، والمحاكم المختصة | عناوين وأرقام الهيئات والمراكز حسب ولايتك مع اتصال مباشر | دليل شامل للهيئات القضائية والمراكز المتخصصة بالولاية مع اتصال فوري. حمّل النسخة التجريبية: riayati.site |
| **06** | Privacy | خصوصية تامة، وعزل كامل للبيانات | كل والد يطّلع على تقاريره الخاصة فقط، وبسرية تامة | خصوصية تامة؛ كل طرف يطّلع على بياناته وتقاريره الخاصة فقط. حمّل النسخة التجريبية: riayati.site |

*Every social post caption must conclude with the mandatory disclaimer:*
«محتوى تعريفي للإرشاد الأولي، ولا يغني عن استشارة مختص أو عن نص القانون الرسمي»

---

## 7. How to Modify Content & Adjust Timings

### Wording & UI Copy
- **Headlines & Captions:** In `src/Promo.tsx`, `src/HowTo.tsx`, `src/Problems.tsx`, `src/Story.tsx`, and `src/Social.tsx` (`DESIGNS`).
- **Brand Info & Disclaimer:** In `src/theme.ts` (`APP_INFO`).

### Speech Speed & Re-timing
- In `scripts/voice.py`, `WORD_DURATION_SEC` is set to `0.75` seconds per Arabic word.
- If real recorded voice runs faster or slower, update `WORD_DURATION_SEC` and adjust line end timestamps accordingly in `NARRATION`.
- `scripts/voice.py` automatically flags any line that exceeds its scene window with `TIGHT / TOO LONG`.

### Audio & Music Mixing
- Ambient music chords and timing are defined in `scripts/music.py`.
- Run `python scripts/music.py` to re-generate the WAV files.
- Run `python scripts/build_audio.py all` to re-mux audio onto the silent video renders.
