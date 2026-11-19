# Riayati (رعايتي) — project context

Digital platform for child protection within custody (Algerian family law). Quote ref **RIA-MVP-001** (`00-admin/`), 50,000 DA, 30–40 days, delivered by Yassine for client Shayma (graduation / startup project, ministerial decision 1275).

## Scope (from the quote)
1. Mobile MVP: father/mother accounts, secure login, legal chatbot, incident report form (text/photo/video) with structured PDF export, shared visit calendar (propose / accept / decline / confirm).
2. Admin dashboard: receive and manage incident reports; manage legal texts and Supreme Court rulings.
3. AI + RAG: answers only from provided sources, cite articles, say so when sources are insufficient, auto re-index after admin edits.
4. Brand, UI/UX, one-page landing page, promo video.
Deliverables also include: ZIP source, CD for ONDA, docs, demo accounts (father, mother, admin), QR code.

## Decisions (settled)
- **Language**: Arabic only, RTL, for the MVP.
- **Font**: thmanyah family (`01-brand/fonts/thmanyah/`): Sans for UI, Serif Display for large titles and the wordmark, Serif Text for long legal text. IBM Plex Sans Arabic stays as fallback and as the font for web surfaces. Per the font license: never redistribute the font files (not in the ZIP, the ONDA CD or any repo; the client downloads them from font.thmanyah.com), never serve them from a website (landing page, Filament admin), no kashida or swash letters in UI text. Embedding in the compiled Flutter app is allowed. Details: `01-brand/fonts/thmanyah/README.md`.
- **Palette**: derived from the logo (olive `#658E3F`, lime `#C5E76C`), based on the "Sage" palette. Fixed semantic colors: SOS `#DC2626` / `#FEE2E2`, success `#16A34A`, warning `#D97706`. Other palettes in `01-brand/colors/` are unused alternates.
- **Mobile**: Flutter, Android first.
- **Backend**: Laravel + Sanctum token auth. Roles: father, mother, admin, enforced with policies. A parent sees only their own data and the shared calendar.
- **Admin**: Filament.
- **Database**: SQLite (no pgvector).
- **RAG**: embeddings stored in a SQLite table, cosine similarity computed in PHP. Gemini embedding model (supports Arabic).
- **AI**: Gemini via Google AI Studio. Send only the user's question and retrieved legal excerpts, never incident reports or personal data. UI shows a notice not to type names or case details. Move Shayma to a paid-tier key at handover (free tier may use data for product improvement).
- **Hosting**: Hostinger shared hosting with PHP and SSH (Composer, PHP 8.2+). No permanent queue worker: a cron job runs `queue:work --stop-when-empty` every minute for re-indexing.
- **Evidence**: private storage, short-lived signed URLs, admin sees all reports, parents see only their own, parents cannot delete submitted reports. Caps: ~30 MB per file, 5 files per report, compress video on the phone before upload.
- **Legal corpus**: not delivered yet. Build against a small placeholder set of public articles. The real corpus blocks only the chatbot.
- **Design tool**: FigCraft via `tools/figcraft-connector/AGENTS.md`. Work **headless** (no window): set `FIGCRAFT_HEADLESS=1`, then `python 02-design/figcraft/build_doc.py` rebuilds the whole document from the tokens and saves `02-design/figcraft/riayati-design.figcraft` (the earlier `riayati-app` files are in `archive/`). The file is organised in pages (00 Cover, 01 Foundations, 02 Auth, 03 Home, 04 Reports, 05 Calendar, 06 Assistant, 07 Profile, 08 Admin), each with Light and Dark sections. To look at it without the app: `figcraft-cli render|export <file> --page "<name>"`. Anyone opening the file in the app must first install the thmanyah fonts on Windows, or some text falls back to another font. The previous single-page file is kept in `02-design/figcraft/archive/`.

## Build status
Backend in `03-app/backend` (Laravel 13, SQLite, Sanctum): auth, password reset, parent linking, incident reports with attachments, Arabic PDF export, shared visit calendar, and Filament admin panel (`/admin`: dashboard, content library, incident reports, read-only users/families, and read-only visits) are completed and tested. Flutter app built in `03-app/mobile` (all screens, light/dark, tokens generated from `01-brand/tokens`, plan in `docs/superpowers/plans/2026-11-17-flutter-app.md`) and tested on a real phone. Backend also has change password and an editable profile (phone, wilaya, children). Remaining: dark-mode and RTL polish, release APK, chatbot, landing page and video. Plan and API contract: `03-app/PLAN.md`. Run backend tests with `php artisan test`, app tests with `flutter test` in `03-app/mobile`; dev server for the phone: `03-app/backend/serve-lan.ps1` (never edit Arabic or PHP files with PowerShell Get-Content/Set-Content: it adds a BOM or corrupts UTF-8).

## Design status
Done: brand tokens, 25 screens (mobile app and admin panel) in HTML and in FigCraft, light and dark. Index of the HTML versions: `02-design/index.html`.

## Order of work
Brand tokens → UI/UX screens → MVP (auth, calendar, incidents) → admin dashboard → AI/RAG chatbot → landing page and video.

## RTL rules
- Layouts mirror: use start/end, never left/right (Flutter `EdgeInsetsDirectional`, `AlignmentDirectional`).
- Directional icons (back, chevrons, progress) flip. Logo, numbers and media do not.
- Test every screen with long Arabic strings and mixed Arabic/Latin/digits.
- In FigCraft, set `text.direction` to `rtl` and mirror coordinates.

## Folder layout
- `00-admin/` quote and contracts
- `01-brand/` logo, colors, fonts
- `02-design/` UI/UX screens, landing, video
- `03-app/` Flutter app and Laravel backend
- `tools/figcraft-connector/` design-tool bridge

## Skills to use
UI/UX: `impeccable` (app and admin screens), `design-taste-frontend` (landing), `design-tokens`, `apply-aesthetic`, `figcraft`. Flutter: `dart-flutter-patterns` and the `flutter-*` skills. Laravel: `laravel-best-practices`, `laravel-specialist`, `laravel-security`, `laravel-tdd`, `filament-pro`. Also: `security-and-hardening`, `a11y-audit`, `ux-writing`, `writing-plans`, `test-driven-development`, `context7-cli` (Laravel, Filament, Gemini docs), `hyperframes` (promo video).
