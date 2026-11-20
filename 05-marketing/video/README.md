# Riayati (رعايتي) — Video, Promo Images & Documentation Kit

Marketing video and promo-image kit for the **Riayati (رعايتي)** platform, built with **Remotion** (React).
Uses real app screen design exports (1080×2400 phone frames), real SVG branding, the Thmanyah typography system, and custom synthesized ambient music.

---

## 1. Deliverables (`deliverables/`)

| Folder | File | Format & Specs | Status | Use Case |
|---|---|---|---|---|
| `Videos/Promo` | `riayati-promo.mp4` | 16:9 (1920×1080), 22 s, silent master | **Final** | Master video / re-mixing |
| `Videos/Promo` | `riayati-promo-music.mp4` | 16:9, 22 s, music-only (−15 LUFS) | **Final** | Website, presentations, YouTube |
| `Videos/Promo` | `riayati-promo-voiceover.mp4` | 16:9, 22 s, voiceover + music | *Awaits GEMINI_API_KEY* | Full marketing promo |
| `Videos/Promo` | `riayati-promo-vertical.mp4` | 9:16 (1080×1920), 22 s, silent master | **Final** | Master vertical |
| `Videos/Promo` | `riayati-promo-vertical-music.mp4` | 9:16, 22 s, music-only (−15 LUFS) | **Final** | Instagram Reels, TikTok, Stories |
| `Videos/Promo` | `riayati-promo-vertical-voiceover.mp4` | 9:16, 22 s, voiceover + music | *Awaits GEMINI_API_KEY* | Full vertical promo |
| `Videos/How-To` | `riayati-howto-vertical.mp4` | 9:16 (1080×1920), 32 s, silent master | **Final** | Master vertical tutorial |
| `Videos/How-To` | `riayati-howto-vertical-music.mp4` | 9:16, 32 s, music-only (−15 LUFS) | **Final** | Onboarding / step-by-step tutorial |
| `Videos/How-To` | `riayati-howto-vertical-voiceover.mp4` | 9:16, 32 s, voiceover + music | *Awaits GEMINI_API_KEY* | Full guided onboarding |
| `Videos/Problem and Solution` | `riayati-problems-vertical.mp4` | 9:16 (1080×1920), 30 s, silent master | **Final** | Master vertical explainer |
| `Videos/Problem and Solution` | `riayati-problems-vertical-music.mp4` | 9:16, 30 s, music-only (−15 LUFS) | **Final** | Social ads / feature explainer |
| `Videos/Problem and Solution` | `riayati-problems-vertical-voiceover.mp4` | 9:16, 30 s, voiceover + music | *Awaits GEMINI_API_KEY* | Full social ads explainer |
| `Videos/Story Film` | `riayati-story.mp4` / `riayati-story-vertical.mp4` | 16:9 and 9:16, 40 s, silent masters | **Final** | Master brand story |
| `Videos/Story Film` | `riayati-story-music.mp4` / `...-vertical-music.mp4` | 16:9 and 9:16, 40 s, music-only | **Final** | Brand narrative film |
| `Videos/Story Film` | `riayati-story-voiceover.mp4` / `...-vertical-voiceover.mp4` | 16:9 and 9:16, 40 s, voiceover + music | *Awaits GEMINI_API_KEY* | Full brand film |
| `Videos/Logo Animation` | `riayati-logo-light.mp4` / `riayati-logo-dark.mp4` | 1080×1080, 5 s, silent | **Final** | Intro / outro video stings |
| `Social/Posts` | `riayati-post-01...06-*.png` | 1080×1350 (4:5 feed), 6 graphics | **Final** | Instagram / Facebook feed |
| `Social/Stories` | `riayati-story-01...06-*.png` | 1080×1920 (9:16 safe area), 6 graphics | **Final** | Instagram Stories / Reels covers |

---

## 2. Important Disclaimers & Rules

1. **Not on Google Play**: The app is currently not distributed through Google Play or app stores. The call to action is strictly:
   `حمّل النسخة التجريبية لأندرويد من riayati.site`
   Never claim it is available on any app store.
2. **Screens are Design Exports**: All screens shown are design exports (1080×2400 phone frames from Figcraft), representing designed MVP features.
3. **No AI Assistant Shown or Claimed**: The AI assistant is not yet live in the product; it is neither shown nor mentioned anywhere in these marketing assets.
4. **No Legal Advice**: The application provides organizational tools and legal information; it does not replace legal counsel.
   Every finale contains the mandatory disclaimer:
   `محتوى تعريفي للإرشاد الأولي، ولا يغني عن استشارة مختص أو عن نص القانون الرسمي`
5. **No Statistics, Testimonials, or Exaggerations**: No fabricated user counts, ratings, or claims of "100% safe" or "approved by ministry/courts".
6. **Child Welfare**: Calm abstract visual language with rings and shapes; zero distressing imagery and zero photographs of minors.

---

## 3. Re-Rendering Instructions

### Requirements
- Node.js 18+
- Python 3.10+ with `numpy` (`pip install numpy`)
- FFmpeg installed and available on `PATH`

### Commands

```bash
# 1. Preview interactively in Remotion Studio
npm run dev

# 2. Render silent video masters
npm run render:promo            # out/riayati-promo.mp4 (16:9, 22 s)
npm run render:promo-vertical   # out/riayati-promo-vertical.mp4 (9:16, 22 s)
npm run render:howto            # out/riayati-howto-vertical.mp4 (9:16, 32 s)
npm run render:problems         # out/riayati-problems-vertical.mp4 (9:16, 30 s)
npm run render:story            # out/riayati-story.mp4 (16:9, 40 s)
npm run render:story-vertical   # out/riayati-story-vertical.mp4 (9:16, 40 s)
npm run render:logo-light       # out/riayati-logo-light.mp4 (1080x1080, 5 s)
npm run render:logo-dark        # out/riayati-logo-dark.mp4 (1080x1080, 5 s)

# 3. Render social still graphics (6 feed posts + 6 stories)
npm run render:social           # outputs to out/social/ and copies to deliverables/Social/

# 4. Synthesise ambient music bed (numpy, zero sample dependencies)
python scripts/music.py         # generates public/music-*.wav at -15 LUFS

# 5. Build and mux audio onto videos
python scripts/build_audio.py promo     # muxes music-only master and voiceover when ready
python scripts/build_audio.py howto
python scripts/build_audio.py problems
python scripts/build_audio.py story
python scripts/build_audio.py all       # processes all videos and copies to deliverables/
```

### Voiceover Generation (Gemini TTS)
When you have a `GEMINI_API_KEY`:

```bash
# Set your key in your environment (never commit it to files)
$env:GEMINI_API_KEY="your-api-key"      # PowerShell
# or export GEMINI_API_KEY="your-key"    # Bash

# Generate narration voiceover (voice Kore, gemini-3.8-flash-tts with declick)
python scripts/voice.py

# Re-mux videos with voiceover
python scripts/build_audio.py all
```

---

## 4. Codebase Structure

```
video/
├── src/
│   ├── theme.ts          # Brand colours (Olive, Lime, Ink), fonts, CROPS bounding boxes, timeline
│   ├── kit.tsx           # Phone 3D mockup, FloatCard, Fragment, Headline (with dot padding), Mark, Rings
│   ├── Promo.tsx         # 22 s Promo (16:9 and 9:16)
│   ├── HowTo.tsx         # 32 s How-To (9:16, 6 steps with animated progress bar)
│   ├── Problems.tsx      # 30 s Problem -> Solution pairs (4 pairs + outro)
│   ├── Story.tsx         # 40 s Brand film (16:9 and 9:16)
│   ├── LogoAnim.tsx      # 5 s square logo sting (light and dark)
│   ├── Social.tsx        # 6 feed posts (1080x1350) + 6 stories (1080x1920)
│   ├── Root.tsx          # Remotion root registering all compositions and stills
│   └── index.ts          # Remotion entrypoint
├── public/
│   ├── fonts/            # Thmanyah woff2 fonts (git-ignored)
│   ├── screens/          # Real screen exports (1080x2400)
│   ├── riayati-symbol.svg# Brand SVG mark
│   ├── music-*.wav       # Synthesised ambient music beds
│   └── voiceover/        # Cached voiceover audio clips
├── scripts/
│   ├── music.py          # Ambient music synthesis (numpy, -15 LUFS)
│   ├── voice.py          # Narration tables, Gemini TTS caller, and audio declicking
│   ├── build_audio.py    # FFmpeg audio muxer & deployer
│   └── render-social.mjs # Social still batch renderer
├── docs/
│   └── Video-Promo-Guide.md # Full storyboard, narration scripts, and editing guide
└── deliverables/         # Final deliverables folder
```
