# Marketing kit

| Folder | What it is | How to rebuild |
|---|---|---|
| `screens/` | Design exports at 3x (phones 1080x2400, admin 1280x800). Git-ignored (reproducible). | `cd 02-design/figcraft` then `FIGCRAFT_HEADLESS=1 FIGCRAFT_SCALE=3 FIGCRAFT_OUT=<repo>/05-marketing/screens python build_doc.py` |
| `landing/` | The landing + APK download page for https://riayati.site (one HTML file, IBM Plex Sans Arabic only, no thmanyah). | Preview: `powershell -File landing/serve.ps1`. Publish: `powershell -File tools/deploy-landing.ps1 -Apk <signed apk>` |
| `video/` | Remotion project: promo (16:9, 9:16), how-to, problem and solution, story film, logo animation, 12 social images. See `video/README.md`. | `cd video && npm install && npm run ...` (commands in its README) |
| `kit/` | The prompt kit these were built from. | |
| `_ref/` | Local copy of a reference page from another project. Git-ignored. | |

Rules that apply to everything here
- The AI assistant is not live: never show or mention it (the Home design screen has a card for it, crop it out).
- No statistics, testimonials, awards, or "approved by" claims. The app is not on Google Play.
- Fonts: thmanyah may appear inside rendered video frames only; never on the website, never as files in a deliverable.
- Screens are design exports, not captures of the running app.
- The mandatory line for videos and the page footer: "محتوى تعريفي للإرشاد الأولي، ولا يغني عن استشارة مختص أو عن نص القانون الرسمي".
