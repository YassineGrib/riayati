# Riayati Flutter App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Android Flutter app (Arabic, RTL, light and dark) that matches the FigCraft/HTML designs and talks to the existing Laravel API.

**Architecture:** Feature folders (`auth`, `family`, `home`, `reports`, `calendar`, `profile`, `assistant`) over a shared `core` (theme, widgets, API client). Design tokens are generated into Dart from the same JSON files that produce the CSS, so the app and the designs cannot drift. State with Riverpod, navigation with go_router (redirect guard on auth and link state), HTTP with Dio. No code generation (plain classes) to keep the build simple.

**Tech Stack:** Flutter 3.47 / Dart 3.13, flutter_riverpod, go_router, dio, flutter_secure_storage, image_picker, file_picker, intl, open_filex, flutter_test (+ goldens).

**Spec:** `CLAUDE.md` (decisions, RTL rules), `03-app/PLAN.md` (API contract), designs in `02-design/figcraft/riayati-design.figcraft` (PNG exports in `02-design/figcraft/output/`) and HTML boards in `02-design/*/index.html`.

## Global Constraints
- Location: `03-app/mobile`, package name `riayati`, Android only.
- Arabic only, RTL forced: `Directionality.rtl`, `locale ar`. Use `EdgeInsetsDirectional` / `AlignmentDirectional`, never left/right. Directional icons flip; logo, numbers and media do not. Western digits.
- Arabic letter-spacing is always 0. No kashida, no swash.
- Fonts: thmanyah (Sans UI, Serif Display titles and wordmark, Serif Text for legal text) embedded in the app only. Font files are git-ignored and never committed (`.gitignore` already blocks `*.otf`). Fallback: IBM Plex Sans Arabic (`03-app/backend/resources/fonts/`, OFL, may be committed).
- Colors, spacing, radii, shadows, motion come only from generated tokens; no hard-coded hex or magic numbers in widgets. Light/dark by swapping the semantic tokens.
- SOS color `#DC2626` / `#FEE2E2`, success `#16A34A`, warning `#D97706`.
- API base URL comes from `--dart-define=API_URL` (default `http://10.0.2.2:8000/api` for the Android emulator). Token only in `flutter_secure_storage`.
- Upload limits mirror the server: 5 files, 30 MB each, JPEG/PNG/WebP/MP4/MOV/PDF.
- Never put the other parent's name or email on screen (the API does not return them). Never type case details to the assistant: the assistant screen shows the notice.
- Each task ends with a progress line and a commit. Progress is reported to the user as a percentage after every task.

## Review Focus
1. No network / server down: every screen shows a retry state with an Arabic message, never a spinner forever or a crash.
2. Token rejected (401) mid-session: app clears the token and returns to login.
3. Unlinked parent calling calendar/reports-with-partner: `403 not_linked` routes to the link screen.
4. Very long Arabic names and mixed Arabic/Latin/digits text: no overflow in cards, headers, tabs.
5. File rules: 6th file, file over 30 MB, wrong type and a future incident time are blocked on the phone before upload, with the server's message shown if it still rejects.

---

## Progress map
| Task | Part | Cumulative |
|---|---|---|
| 1 | Project, tokens, theme, fonts, RTL | 8% |
| 2 | Shared widgets (buttons, fields, cards, watermark, floating nav) | 18% |
| 3 | API client, token storage, auth state, router guard | 28% |
| 4 | Welcome, login, register, forgot password | 40% |
| 5 | Link co-parent + shell with 5 tabs + home (SOS first) | 52% |
| 6 | New report (form, files, upload) | 64% |
| 7 | Reports list, detail, PDF, attachments | 74% |
| 8 | Visit calendar (month, propose, respond, confirm) | 86% |
| 9 | Profile + assistant screen (UI only) | 93% |
| 10 | Polish: dark mode, RTL stress, a11y, release APK | 100% |

---

### Task 1: Project, tokens, theme (→ 8%)

**Files:**
- Create: `03-app/mobile/` (via `flutter create --org dz.riayati --platforms android riayati`, moved to `mobile`), `01-brand/tokens/generate_dart.py`, `03-app/mobile/lib/core/theme/tokens.g.dart`, `.../theme/app_theme.dart`, `.../theme/riayati_colors.dart`, `lib/main.dart`, `lib/app.dart`
- Modify: `03-app/mobile/pubspec.yaml` (deps + font families), root `.gitignore` (`/03-app/mobile/assets/fonts/thmanyah/`)
- Test: `03-app/mobile/test/theme_test.dart`

**Interfaces:**
- Produces: `class RColors extends ThemeExtension<RColors>` with one field per semantic color token (`bg`, `surface`, `textPrimary`, `textSecondary`, `primary`, `onPrimary`, `accentSoft`, `border`, `sos`, `sosSoft`, `success`, `warning`, … exactly the names in `colors.json` semantic tier, camelCased), `RColors.light`, `RColors.dark`; `RSpace` (`s1…`), `RRadius`, `RShadow`, `RMotion` const classes; `ThemeData buildTheme(Brightness b)`; `extension on BuildContext { RColors get c; }`.

- [ ] **Step 1: Write failing test** `theme_test.dart`: `buildTheme(Brightness.light).extension<RColors>()!.primary == Color(0xFF658E3F)`-equivalent to the token value; dark theme's `bg` differs from light's; `textTheme.bodyMedium!.letterSpacing == 0`; font family of body is `ThmanyahSans`.
- [ ] **Step 2:** Run `flutter test test/theme_test.dart` → FAIL (file missing).
- [ ] **Step 3:** `flutter create`, add deps, write `generate_dart.py` reading `01-brand/tokens/*.json` (same resolution logic as `generate_tokens.py`) and emitting `tokens.g.dart`; run it. Register font families `ThmanyahSans`, `ThmanyahSerifDisplay`, `ThmanyahSerifText` (assets copied locally from `01-brand/fonts/thmanyah/`, git-ignored) with `IBMPlexSansArabic` as `fontFamilyFallback`.
- [ ] **Step 4:** Implement `buildTheme`; `app.dart` forces `locale: Locale('ar')`, `Directionality`, and a `MaterialApp.router` placeholder home that prints the wordmark.
- [ ] **Step 5:** `flutter test` → PASS; `flutter run` on emulator shows the wordmark in thmanyah Serif Display (visual check).
- [ ] **Step 6: Commit** `feat(mobile): project, generated tokens and theme`. Report: **8%**.

### Task 2: Shared widgets (→ 18%)

**Files:**
- Create: `lib/core/widgets/{r_button,r_text_field,r_card,status_chip,watermark,floating_nav,app_scaffold,state_views}.dart`, `assets/images/riayati-mark.svg` (from `01-brand/logo/riayati-mark-abstract.svg`)
- Test: `test/widgets/*_test.dart`, `test/goldens/*.png`

**Interfaces:**
- Produces: `RButton({required String label, VoidCallback? onPressed, RButtonKind kind = primary|secondary|sos|text, bool loading = false, IconData? icon})`; `RTextField({label, controller, validator, obscure, keyboardType, helper})`; `RCard({child, onTap})`; `StatusChip({required String label, required StatusTone tone})`; `Watermark({double opacity = .08, AlignmentDirectional align})`; `FloatingNav({required int index, required ValueChanged<int> onTap})` with the five tabs الرئيسية، التقارير، التقويم، المساعد، حسابي; `AppScaffold({title, body, showWatermark, bottom})`; `ErrorView({message, onRetry})`, `LoadingView()`, `EmptyView({title, body, action})`.

- [ ] **Step 1:** Write widget tests: button disabled while `loading`; text field shows validator message; `FloatingNav` highlights the tapped index; `ErrorView` calls `onRetry`; golden for each widget in light and dark.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement each widget from tokens only, copying measurements from the FigCraft Auth/Home pages (heights, radii, paddings). **Step 4:** Run → PASS; compare each golden against `02-design/figcraft/output/*.png` by eye and fix differences.
- [ ] **Step 5: Commit** `feat(mobile): shared widgets`. Report: **18%**.

### Task 3: API client, auth state, router guard (→ 28%)

**Files:**
- Create: `lib/core/api/{api_client,api_error,token_store}.dart`, `lib/features/auth/{auth_repository,auth_controller,user.dart}`, `lib/core/router.dart`
- Test: `test/api/api_client_test.dart`, `test/auth/auth_controller_test.dart`

**Interfaces:**
- Produces: `class ApiClient { Future<T> get/post(...); }` with Bearer interceptor; `class ApiError { String message; int? status; String? code; Map<String,List<String>> fields; }` mapped from Laravel JSON (message in Arabic) and a fixed Arabic text for network failure; `User {id,name,email,role,linked,partnerRole}`; `AuthState = unknown | signedOut | signedIn(User)`; `authControllerProvider` with `signIn, register, signOut, refresh`; router redirects: signedOut → `/welcome`, signedIn and `!linked` → `/link`, else `/home`.
- Consumes: API contract in `03-app/PLAN.md`.

- [ ] **Step 1:** Tests with a fake Dio adapter: login stores the token; a 401 on any call clears it and sets `signedOut`; `ApiError` takes `403 {code:"not_linked"}` and exposes `code`; network failure yields the Arabic offline message; `422` field errors map into `fields`.
- [ ] **Steps 2–4:** run (FAIL) → implement → run (PASS).
- [ ] **Step 5: Commit** `feat(mobile): api client and auth state`. Report: **28%**.

### Task 4: Welcome, login, register, forgot password (→ 40%)

**Files:** `lib/features/auth/screens/{welcome,login,register,forgot_password}_screen.dart`; tests `test/auth/*_screen_test.dart`.

**Interfaces:** Consumes `authControllerProvider`, `RButton`, `RTextField`, `Watermark`. Routes `/welcome /login /register /forgot`.

- [ ] **Step 1:** Widget tests: login with empty fields shows required messages; server error text appears under the form; register needs role choice (أب / أم) and terms ticked before the button enables; forgot password always shows the same success message.
- [ ] **Steps 2–4:** FAIL → implement matching the Auth page of the design file (hero with watermark, one calm welcome screen) → PASS.
- [ ] **Step 5:** Manual: run against `php artisan serve` with a demo account (`php artisan riayati:demo-accounts`); login, wrong password, register all behave. **Step 6: Commit.** Report: **40%**.

### Task 5: Link co-parent, shell, home (→ 52%)

**Files:** `lib/features/family/{family_repository,link_screen}.dart`, `lib/features/home/home_screen.dart`, `lib/core/shell.dart`; tests `test/family/*`, `test/home/*`.

**Interfaces:** Produces `FamilyRepository { Future<InviteCode> invite(); Future<void> link(String code); }`; `Shell` hosts `FloatingNav` and the five branches via `StatefulShellRoute`. Home shows the SOS card first, then the next visit (from `GET /visits/upcoming`, empty state when unlinked) and last reports.

- [ ] **Step 1:** Tests: link screen shows the code returned by `invite()` and its expiry; entering a bad code shows the server's message; after a successful link the router lands on `/home`; home renders SOS before every other section.
- [ ] **Steps 2–4:** FAIL → implement per the "Link co-parent" and "Home" designs → PASS.
- [ ] **Step 5: Commit.** Report: **52%**.

### Task 6: New report (→ 64%)

**Files:** `lib/features/reports/{report_repository,report.dart,new_report_screen,file_rules}.dart`; tests `test/reports/file_rules_test.dart`, `new_report_screen_test.dart`.

**Interfaces:** Produces `FileRules.check(List<PickedFile> existing, PickedFile candidate) -> String?` (Arabic reason or null); `ReportRepository.create({description, incidentAt, files}) -> Future<Report>` using multipart with progress callback; `Report {id, reference, status, description, incidentAt, attachments}`.

- [ ] **Step 1:** Tests: `FileRules` rejects the 6th file, a 31 MB file and a `.zip`; screen blocks a future date and a 2-character description; upload progress is shown and the success summary screen shows the reference `RIA-…`.
- [ ] **Steps 2–4:** FAIL → implement (form, summary screen per "Report form" and "Report summary" designs) → PASS.
- [ ] **Step 5:** Manual: submit a report with photo and video against the local server; open it in the admin database. **Step 6: Commit.** Report: **64%**.

### Task 7: Reports list, detail, PDF (→ 74%)

**Files:** `lib/features/reports/{reports_screen,report_detail_screen}.dart`, repository additions: `list({status})`, `get(id)`, `pdf(id) -> File`, `attachmentLink(reportId, attachmentId) -> Uri`.

- [ ] **Step 1:** Tests: filter chips (قيد المراجعة / تمت المراجعة) refetch; detail shows fingerprint per file; tapping an attachment requests a fresh signed link each time (never cached); PDF download writes a file and opens it.
- [ ] **Steps 2–4:** FAIL → implement per design → PASS. **Step 5: Commit.** Report: **74%**.

### Task 8: Visit calendar (→ 86%)

**Files:** `lib/features/calendar/{visit_repository,visit.dart,calendar_screen,propose_visit_sheet,visit_detail_screen}.dart`; tests `test/calendar/*`.

**Interfaces:** `VisitRepository { month(String ym), upcoming(), propose({date,from,to,note}), accept(id), decline(id), confirm(id) }`; `Visit` carries `proposedByMe, needsMyResponse, canConfirm, timeline`.

- [ ] **Step 1:** Tests: buttons shown follow the flags (accept/decline only when `needsMyResponse`, confirm only when `canConfirm`); overlap error from the server shows under the form; `not_linked` redirects to `/link`; month grid starts on the correct weekday for RTL (Saturday-first).
- [ ] **Steps 2–4:** FAIL → implement per the Calendar design → PASS. **Step 5: Commit.** Report: **86%**.

### Task 9: Profile and assistant screen (→ 93%)

**Files:** `lib/features/profile/profile_screen.dart`, `lib/features/assistant/assistant_screen.dart`.

- [ ] **Step 1:** Tests: profile shows the user's own name, role and link status only; sign-out clears the token and returns to welcome; assistant screen shows the privacy notice (لا تكتب أسماء أو تفاصيل القضية) and a "قريبًا" state instead of an input that sends anything.
- [ ] **Steps 2–4:** FAIL → implement → PASS. **Step 5: Commit.** Report: **93%**.

### Task 10: Polish and release build (→ 100%)

**Files:** modifications across screens as findings require; `03-app/mobile/README.md`.

- [ ] **Step 1:** Add tests for the Review Focus items not yet covered (offline retry on home, 401 mid-session, 40-character Arabic name in profile and nav).
- [ ] **Step 2:** Run the whole app in dark mode and compare every screen with the design PNGs; fix differences. Check touch targets ≥ 48 dp and contrast with the `a11y-audit` skill.
- [ ] **Step 3:** `flutter analyze` → no issues; `flutter test` → all pass.
- [ ] **Step 4:** `flutter build apk --release` (APK stays out of git); install on the emulator and run the full father → mother flow with two accounts.
- [ ] **Step 5: Commit** and update `CLAUDE.md` build status and `03-app/PLAN.md` step 8 to done. Report: **100%**.
