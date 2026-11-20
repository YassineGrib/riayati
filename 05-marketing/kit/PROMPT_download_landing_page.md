# PROMPT — App download landing page (copy everything below the line into the new project)

Fill the `{{…}}` values first. Everything else can stay.

---

You are building a **single-page download landing page** for a mobile app. Work end to end: design, code, test in a real browser, and prepare the files for upload. Do not stop at a mockup.

## 1. Inputs (I fill these)
- App name / one-line promise: `{{APP_NAME}}` — `{{TAGLINE}}`
- Language and direction: `{{LANG}}` (e.g. Arabic, RTL)
- Source of truth for what the app really does (read it, do not invent): `{{PROJECT_PATH}}` (code, design exports, screens)
- App screenshots to use (real screens only): `{{SCREENS_PATH}}`
- Brand: colours `{{COLOURS}}`, fonts `{{FONTS}}` (font files at `{{FONTS_PATH}}`), logo `{{LOGO_PATH}}`
- Download file and public URL: `{{APK_PATH}}` → `{{DOWNLOAD_URL}}` (e.g. `/downloads/app.apk`)
- Domain / hosting: `{{DOMAIN}}` (`{{HOSTING}}`)
- Things the page must NOT claim: `{{FORBIDDEN_CLAIMS}}` (e.g. medical claims, statistics, testimonials)

## 2. Style reference (inspire, do not copy blindly)
Read these first and reuse the *structure and craft*, with the new brand:
- Finished page for another app: `C:\projects\in progress\forsa\landing_deploy\index.html` (and its `landing/` images, `.htaccess`)
- Earlier reference: `C:\projects\OLD\Projects\in progress\AlYusra-Handover` (landing/promo style)
Structure that worked: sticky nav (brand centred, links, small CTA) → hero with big headline, one-line promise, a huge **primary download button**, file facts (version, size, "Android") → draggable **phone carousel** of real screens (bezel, dots, arrows, swipe) → statement section → **feature cards** in alternating brand colours with outline-ring motifs and a phone crop → **install steps** (numbered cards: download, allow install from this source, open, create account) → closing CTA band → footer with disclaimer → **sticky bottom download bar on mobile**, appearing after the hero. Scroll-reveal animation, respects `prefers-reduced-motion`.

## 3. Rules
1. One static `index.html` + `/fonts`, `/landing` (optimised images, WebP/JPG), favicon set. No frameworks needed. Self-host fonts with `@font-face`, `font-display:swap`, preload the two main weights.
2. Design tokens as CSS variables on `:root`. Flat and calm: generous whitespace, one accent, soft rounded cards. Contrast ≥ 4.5:1 for text.
3. **RTL correctness** if Arabic: `dir="rtl"`, logical properties, Latin tokens (URLs, emails, versions) wrapped in `dir="ltr"`, check the carousel direction and arrow icons are not mirrored wrongly.
4. Real screens only (from `{{SCREENS_PATH}}`), cropped or framed consistently. Never invent features, numbers, ratings, user counts or testimonials. If the app is a support/health/finance product, include a short honest disclaimer in the footer.
5. Mobile-first: test at 375, 768 and 1440 px. No horizontal scroll. Tap targets ≥ 44 px. The hero button must be visible without scrolling on a phone.
6. Platform logic: if the visitor is not on Android (or the platform you ship for), show a calm note ("open this page from your phone") instead of a broken download. Do not claim store availability you do not have.
7. SEO/meta: title, description, `theme-color`, Open Graph image, `lang`, canonical.
8. The download link must be a real file link (`download` attribute) and the server must send the right headers: `AddType application/vnd.android.package-archive .apk` and `Content-Disposition: attachment`.
9. Performance: hero image ≤ 150 KB, total first load ≤ 1 MB, no layout shift, lazy-load below the fold.
10. Accessibility: semantic landmarks, one `h1`, labelled carousel (`role="region"`, `aria-roledescription="carousel"`), visible focus, keyboard control for the carousel.

## 4. Verify before saying "done"
- Open the page in the built-in browser at the three widths and look at screenshots (not only code). Check fonts actually load (no fallback look), images are sharp, the sticky bar behaves, the carousel drags.
- Click the download link and confirm the response headers and file size match the real file (compare SHA-256).
- Grep the page for leftovers: `TODO`, `lorem`, placeholder URLs, `localhost`, `example.com`.

## 5. Mistakes we already made — avoid them
- **Fake or unfinished promises**: the page said things the app could not do yet. Only claim what exists today.
- **Debug-signed APK on the download page**: always sign with a real release keystore and **back the keystore up** (a lost key means no updates for installed users). Build only the architecture you need (`--split-per-abi` → arm64) and **check the file** (`aapt dump badging`, list the `lib/` ABIs) before linking it.
- **API address baked in at build time**: verify the *production* URL is inside the build (search the binary), not a LAN/emulator address.
- **Uploading**: long single transfers get reset by shared hosts. Upload in 2 MB chunks with retries and compare SHA-256 afterwards.
- **Shared hosting**: the account may host many other sites. Touch only your own domain folder, keep an automatic backup of what you overwrite, and never leave test files (`_v.php`, `.bak`) in the public folder.
- **Leaked local files in bundles** (dev logs, `.env`, sqlite, compiled caches, test artefacts). List the archive and delete leftovers *before* uploading.
- **Windows/PowerShell traps**: BOM in JSON/shell files, quotes stripped when passing arguments to `ssh`, `Remove-Item` wildcard blocks. Write files with UTF-8 *without* BOM; send multi-line remote scripts as base64.
- **Secrets pasted into chat** (passwords, API keys): never reuse them, tell me to rotate them, and never write them into any file that gets delivered.
- **Overlong client messages**: the cover message to a client must be short and positive; no "known limitations" lists in it.

## 6. Deliverables
`landing_deploy/` ready to upload (index.html, assets, `.htaccess`), a 10-line `DEPLOY.md` (what goes where, headers needed), and screenshots at 3 widths. Then tell me, in plain words, what you verified and what you could not.
