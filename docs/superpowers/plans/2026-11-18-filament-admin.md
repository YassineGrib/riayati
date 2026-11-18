# Riayati Filament Admin Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A working Arabic RTL admin panel at `/admin` where the admin reads every incident report and its evidence, marks it reviewed, and downloads its PDF.

**Architecture:** Filament v5 panel inside the existing Laravel app (`03-app/backend`), reading the existing `IncidentReport` / `ReportAttachment` / `User` models. Nothing new in the database. Evidence is opened only through the existing 5-minute signed URLs. The panel is read-only except "mark as reviewed".

**Tech Stack:** Laravel 13, Filament v5 (Livewire v4), SQLite, PHPUnit + Livewire testing, IBM Plex Sans Arabic.

**Spec:** `02-design/admin/FILAMENT-THEME.md` (panel sketch, columns, filters, rules), mockups `02-design/admin/index.html` and the FigCraft page `08 Admin` (PNGs in `02-design/figcraft/output/08-Admin_*`), product rules in `CLAUDE.md`.

## Global Constraints
- Admin role only: `User::canAccessPanel()` is true only for `Role::Admin`; parents get 403 on `/admin`.
- The admin can read every report and attachment; **no create, edit or delete** of reports anywhere (evidence rule). The only write is `IncidentReport::markReviewed(User $admin)`.
- Attachments are never linked by storage path: reuse the existing signed temporary URL route (5 minutes, `config('riayati.link_ttl')`).
- Locale `ar` (RTL). Font: IBM Plex Sans Arabic only. **Never thmanyah** on the web (license).
- Colors from the brand ramp in `FILAMENT-THEME.md` (primary `#406a05`, danger `#dc2626`, success `#16a34a`, warning `#d97706`, info `#2563eb`). Logo watermark in the page background, like the app.
- Status badges: `under_review` info "قيد المراجعة", `reviewed` success "تمت المراجعة".
- Never edit PHP or Arabic files with PowerShell `Get-Content/Set-Content` (adds a BOM and broke the PDF once; `tests/Feature/NoByteOrderMarkTest.php` guards it). Use the Edit tool.
- Confirm exact Filament v5 APIs with `context7-cli` before coding (colors, widgets, infolists changed between versions).
- Out of scope (change request later): legal texts resource, parent account management, report deletion, internal notes, analytics.

## Review Focus
1. A parent (father or mother) opening `/admin` or any admin URL gets 403, and an unauthenticated visitor goes to the login page.
2. A signed attachment link copied from the admin works for 5 minutes and then answers 403; no raw storage path appears in the page source.
3. A report with 0 attachments, with a very long Arabic description, and with a non-image attachment (PDF) renders without errors.
4. Marking an already reviewed report again does not change its reviewer or timestamp.
5. Admin pages in dark mode keep readable contrast (badges, table rows).

## Progress map
| Task | Part | Cumulative |
|---|---|---|
| 1 | Install Filament, panel provider, admin-only access, RTL, theme | 25% |
| 2 | Reports table: columns, filters, stats widget, mark reviewed (single and bulk) | 55% |
| 3 | Report view page: evidence tiles with signed links, reporter card, timeline, PDF download | 80% |
| 4 | Visual match with the design, watermark, dark mode, demo data, Hostinger notes | 100% |

---

### Task 1: Install and secure the panel (→ 25%)

**Files:**
- Modify: `03-app/backend/composer.json` (via `composer require filament/filament`), `app/Models/User.php` (implements `Filament\Models\Contracts\FilamentUser`)
- Create: `app/Providers/Filament/AdminPanelProvider.php`, `public/images/riayati-symbol.svg` (copy of `01-brand/logo/riayati-symbol.svg`)
- Modify: `bootstrap/providers.php` (register provider)
- Test: `tests/Feature/Admin/PanelAccessTest.php`

**Interfaces:**
- Produces: `User::canAccessPanel(Filament\Panel $panel): bool` (true only for admin); panel id `admin`, path `/admin`, login enabled; helper `tests/Feature/Admin/` use `$this->actingAs($admin)` with `User::factory()->admin()` (add the `admin()` factory state if missing).

- [ ] **Step 1 (orchestrator, needs network):** run `composer require filament/filament:"^5.0"` in `03-app/backend` and `php artisan filament:install --panels` answering id `admin`; commit the lock file. Do not let a sandboxed agent do this.
- [ ] **Step 2: Write failing tests** in `PanelAccessTest`: `test_guest_is_redirected_to_admin_login`, `test_father_gets_403_on_admin`, `test_mother_gets_403_on_admin`, `test_admin_sees_dashboard_200`, `test_panel_is_rtl_arabic` (response contains `dir="rtl"` and `lang="ar"`).
- [ ] **Step 3: Run** `php artisan test --filter PanelAccessTest` → FAIL.
- [ ] **Step 4: Implement** `canAccessPanel`, the provider (brandName `رعايتي`, logo, font `IBM Plex Sans Arabic`, colors from the constraints, `sidebarCollapsibleOnDesktop(false)`), and `config/app.php` locale already `ar` (check, edit with the Edit tool only).
- [ ] **Step 5: Run** the filter → PASS, then `php artisan test` (all green, incl. the BOM test).
- [ ] **Step 6: Commit** `feat(admin): Filament panel, admin-only access`. Report **25%**.

### Task 2: Reports table (→ 55%)

**Files:**
- Create: `app/Filament/Resources/IncidentReports/IncidentReportResource.php` (+ `Pages/ListIncidentReports.php`, `Tables/IncidentReportsTable.php` as Filament v5 generates), `app/Filament/Widgets/ReportStatsOverview.php`
- Test: `tests/Feature/Admin/IncidentReportListTest.php`

**Interfaces:**
- Consumes: `IncidentReport` (relations `user`, `attachments`; `status` cast to `ReportStatus`; `markReviewed(User $admin): void`).
- Produces: resource with `canCreate() === false`, no edit/delete pages or actions; table actions `view` and `markReviewed` (+ bulk `markReviewed`); stats widget values: under review count, reviewed count, received in the last 7 days.

- [ ] **Step 1: Write failing tests** (Livewire): list shows reference, reporter name + role, incident date, attachments count, status badge; filter by status, by reporter role, by date range; `markReviewed` row action sets status `reviewed` with the acting admin and does nothing on an already reviewed report (Review Focus 4); bulk action marks only under-review records; `canCreate` false and no delete/edit action exists; the stats widget shows the three counts for seeded data.
- [ ] **Step 2: Run** `php artisan test --filter IncidentReportListTest` → FAIL.
- [ ] **Step 3: Implement** the resource (navigation label "البلاغات" with a badge counting `under_review`), the table with columns/filters from `FILAMENT-THEME.md`, the actions (confirmation modal text "تأكيد المراجعة؟"), and the stats widget on the resource list page header.
- [ ] **Step 4: Run** the filter → PASS; run all tests.
- [ ] **Step 5: Commit** `feat(admin): incident reports table, filters, stats, mark reviewed`. Report **55%**.

### Task 3: Report view page (→ 80%)

**Files:**
- Create: `.../IncidentReports/Pages/ViewIncidentReport.php`, `.../Schemas/IncidentReportInfolist.php`, `resources/views/filament/admin/attachment-tile.blade.php`
- Modify: the resource (register the `view` page), reuse `ReportPdf` service and the signed-URL generator from `AttachmentController` (extract a small `AttachmentLinks::for(ReportAttachment $a): string` into `app/Services/AttachmentLinks.php` and use it in both places; app tests must still pass).
- Test: `tests/Feature/Admin/IncidentReportViewTest.php`

**Interfaces:**
- Produces: `AttachmentLinks::for(ReportAttachment): string` returning `URL::temporarySignedRoute('attachments.download', now()->addSeconds(config('riayati.link_ttl')), ...)`; header action "تحميل PDF" streaming `ReportPdf` output with the `%PDF` header.

- [ ] **Step 1: Write failing tests:** view page shows description, reporter card (name, role, never the partner), timeline (received, reviewed with admin and time); each attachment tile has a signed URL that returns 200 now and 403 after `travel(6)->minutes()`; the page source never contains the storage path; report with 0 attachments and a 5000-char Arabic description renders 200; the PDF action returns a body starting with `%PDF`; the app's existing attachment tests still pass.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement** the view page, tiles (image preview for images, file icon for PDF/video, SHA-256 shown shortened with copy), the PDF header action and the "mark as reviewed" header action.
- [ ] **Step 4: Run** `php artisan test` (all green). **Step 5: Commit** `feat(admin): report view with evidence and PDF`. Report **80%**.

### Task 4: Design match, watermark, dark mode, handover (→ 100%)

**Files:**
- Create: `resources/css/filament/admin/theme.css` (compiled Filament theme; watermark `background-image` from `public/images/riayati-mark.svg` at low opacity in the main area), `database/seeders/AdminDemoSeeder.php` (12 reports across statuses with 0-3 attachments, long and short descriptions), `docs/ADMIN.md` (how to create the admin, cron for queue later, Hostinger notes)
- Modify: `AdminPanelProvider` (`->viteTheme(...)`), `vite.config.js`, `package.json` scripts as needed

- [ ] **Step 1:** build the theme (`npm run build`), seed demo data, run the panel with `serve-lan.ps1`, open `/admin` in the browser pane (light and dark, desktop width 1280) and compare against `02-design/figcraft/output/08-Admin_*`; fix visible differences (sidebar, badges, table density, spacing, watermark never reducing text contrast).
- [ ] **Step 2:** check contrast of badges and rows in dark mode with the `a11y-audit` skill; fix failures.
- [ ] **Step 3:** run `php artisan test` (all green) and `php artisan about` (no errors); write `docs/ADMIN.md`.
- [ ] **Step 4: Commit** `feat(admin): theme, watermark, demo data, docs`; update `CLAUDE.md` build status and `03-app/PLAN.md` step 9 to done. Report **100%**.

## Who does what (delegation)
- Task 1 step 1 (composer, network): orchestrator. Codex (sandbox cannot reach Packagist) then continues Tasks 1-3 (PHP, runs `php artisan test` itself).
- Task 4 theme and visual match: Antigravity (full permissions, browser comparison), one bounded brief; orchestrator verifies in the browser pane.
- The orchestrator re-runs every gate and commits after each task, as before.
