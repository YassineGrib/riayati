# PROMPT — Marketing videos + promo images (copy everything below the line into the new project)

Fill the `{{…}}` values first. Keep the rest.

---

You are producing a **video and promo-image kit** for an app, with Remotion (React). Deliver finished MP4s with narration and music, social images, and documentation. Work end to end and **look at the real output** before saying done.

## 1. Inputs (I fill these)
- App: `{{APP_NAME}}` — `{{TAGLINE}}`; language `{{LANG}}` (RTL if Arabic); call to action `{{CTA_URL}}`
- Source of truth for real features and screens: `{{PROJECT_PATH}}` (design exports / screenshots at `{{SCREENS_PATH}}`)
- Brand: colours `{{COLOURS}}`, fonts `{{FONTS}}` (+ files), logo `{{LOGO_PATH}}`
- Claims rules (what must never be said): `{{FORBIDDEN_CLAIMS}}`; mandatory disclaimer line (if any): `{{DISCLAIMER}}`
- Is the app already published? `{{PUBLISHED_YES_NO}}` (decides whether the CTA says "download now")

## 2. Style and code reference — read before writing anything
- Finished project to inspire from: `C:\projects\in progress\forsa\forsa_video` — read `README.md`, `docs/Video-Promo-Guide.md`, `src/theme.ts`, `src/kit.tsx` (Phone 3D mockup, Fragment/FloatCard UI crops cut from real screens, slanted-wipe SceneShell, Rings motif, Headline with word stagger, Mark logo), `src/Promo.tsx`, `src/HowTo.tsx`, `src/Problems.tsx`, `src/Story.tsx`, `src/LogoAnim.tsx`, `src/Social.tsx`, `scripts/music.py`, `scripts/build_audio.py`.
- Original reference (docs, promo images, explainer videos made with Remotion): `C:\projects\OLD\Projects\in progress\AlYusra-Handover`.
Reuse the architecture: one component set drives both 16:9 and 9:16 through a `pick(v, landscape, vertical)` helper; all timings live in one timeline file; UI cards are **cropped from real screens**, never redrawn.

## 3. What to produce
| Item | Spec |
|---|---|
| Promo | 22 s, 16:9 and 9:16, 7 scenes (open, intro, home, assistant/feature, people/roles, privacy, finale with CTA) |
| How-to | ~32 s vertical: intro + 6 numbered steps with progress bar and a floating card, outro |
| Problem → Solution | ~30 s vertical: 4 pairs (dark question frame, then the solution scene) + outro "download now" |
| Story film | ~40 s, 16:9 and 9:16, six scenes, emotional arc, ends with CTA |
| Logo animation | 5 s, 1080×1080, light and dark |
| Social | 6 posts 1080×1350 and 6 stories 1080×1920 (text inside the safe area ≈ 260 px top / 220 px bottom) |
| Audio | per video: **voiceover version, music-only version, silent master** |
| Docs | `README.md` (re-render commands) + `docs/Video-Promo-Guide.md` (storyboards, narration tables, how to change things) |

## 4. Workflow that works (follow this order)
1. **Write the narration first**, one line per scene, in the real language. Generate the voice, **measure each line**, and only then set scene durations in the timeline. (Do not design scenes first and squeeze speech into them.)
2. Build components, render stills at key frames, look at them, fix, then render the full videos (long renders in the background).
3. Music: synthesise a calm ambient bed with numpy (`scripts/music.py`: pads + soft plucks + one end chime). **No transition whooshes or sound effects by default** — the client disliked them. Duck the music under the voice (sidechain) and normalise to about −15 LUFS, true peak ≤ −1.5 dBFS.
4. Voice: use the best available TTS. Free `edge-tts` (`ar-DZ-AminaNeural`, rate +6 %, strip tashkeel) was judged poor; **Gemini TTS** (`gemini-3.8-flash-tts`, voice `Kore`, key in env `GEMINI_API_KEY`, never in a file) sounded better. Mux with ffmpeg onto the silent render.
5. Export, then verify by looking at frames and measuring audio (peaks, loudness, durations), then write the docs.

## 5. Mistakes we already made — avoid them
**Remotion / design**
- `package.json` or `tsconfig.json` saved **with a BOM** breaks Remotion → write UTF-8 without BOM.
- Fonts: load with `FontFace` + `delayRender/continueRender`, or the first frames use a fallback font.
- Arabic dots were clipped in big rise-animated headlines → give the headline line box extra bottom padding (≈ 0.34 × font size).
- Long headlines overflowed → add an auto-shrink rule for long lines.
- Logo mark and pill overlapped on social images; captions overlapped the second phone → check every layout at both aspect ratios with stills.
- Keep text inside the platform safe areas for stories/reels.

**Content**
- Show only features that really exist; no medical/financial claims, no statistics, no testimonials; describe any AI assistant as automated, never as a professional. Keep the disclaimer in the finale.
- The CTA must be real. If the app is not published, do not say "download now".
- Screens come from design exports unless you capture the running app: say so in the docs.

**Audio — the big ones**
- **Gemini TTS clips start with a ~50 ms tick and end with a loud burst** that gets cut off after silence. In the mix this sounded like an annoying pop at every scene change. Run a *declick* on each raw clip (drop a leading blip ≤ 0.1 s before ≥ 100 ms silence; drop a trailing loud tail ≤ 0.4 s after silence, ignoring trailing digital silence) — see `declick()` in `scripts/build_audio.py`. Also add a 50–120 ms fade on each line and use gentle ducking (attack ~80 ms, release ~700 ms).
- **Gemini TTS reads style instructions aloud** — never put "speak warmly…" in the text; pick the voice and nothing else.
- Gemini reads ≈ 0.75 s per Arabic word and varies between takes: if a line must fit a window, generate several takes and keep the shortest, compress internal pauses with `silenceremove`, and allow at most ×1.3 tempo. If it still does not fit, **lengthen the scene** rather than butchering the sentence into fragments (the client dislikes choppy short phrases).
- Free Gemini tier: a *daily* request limit per model (≈ 10) and per-minute limits. Cache every clip (`public/voiceover/`), retry on 429, stop on the daily limit, and do not burn requests on experiments.
- Mixing: `amix` then `loudnorm` in one graph can truncate — pad the voice (`apad=whole_dur`) and set `-t`.
- Verify the **music-only** file and the **voiceover** file separately when a sound bothers someone; this tells you where the problem is.

**Tooling on Windows**
- PowerShell: BOM on piped scripts, quotes stripped when passing arguments, `Remove-Item` wildcard blocked, `tail` missing. Use Python for file chores; run long renders with `run_in_background`.
- Delivering files: the Drive connector accepts ≤ 10,000,000 bytes per request *after* base64 (≈ 7 MB per file) and fails when calls are parallel. For big folders, tell the user to drag-and-drop the folder in the browser instead.

## 6. Verify before saying "done"
Extract frames from every video at several times and look at them; check 16:9 and 9:16; check durations and audio levels with ffprobe/ffmpeg; confirm no clipped Arabic, no overlap, no leftover text. State clearly what you could **not** verify (for example that you did not listen to the voice).

## 7. Deliverables
`deliverables/Videos/{Promo, How-To, Problem and Solution, Story Film, Logo Animation}/`, `deliverables/Social/{Posts,Stories}/`, the docs above, and a short list of re-render commands. File sizes: keep each video under ~9 MB if it must be sent by connectors (CRF/bitrate tuned), full-quality masters stay in `out/`.
