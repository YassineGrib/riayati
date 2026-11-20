# Admin Panel: More Sections Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Grow the admin panel beyond Reports: a real dashboard home, an educational content library (articles, laws, rulings, guides), read-only users/families, and read-only visits.

**Architecture:** Same Filament v5 panel (`/admin`, admin-only). New sections are Filament resources/widgets over existing models plus one new table (`contents`). Everything except the content library is read-only. Auto-discovery registers resources and widgets; no change to panel rules.

**Tech Stack:** Laravel 13, Filament v5.11, SQLite, PHPUnit + Livewire tests.

**Spec:** `docs/superpowers/plans/2026-11-18-filament-admin.md` (rules and constraints), `02-design/admin/FILAMENT-THEME.md` (legal documents resource: tabs by type, badges, delete confirmation), `CLAUDE.md`.

## Global Constraints
- Admin role only, same as the panel. Parents never see these sections.
- Read-only for users, families, visits and reports: no create, edit or delete actions anywhere. Never show or edit passwords, tokens or emails of other users beyond name, role, phone, wilaya, children count, link status (admin may see names of the two linked parents of a family; the mobile API still never exposes them).
- Content library is the only section with create/edit/delete (delete asks confirmation). Content types: `article` مقال، `law` قانون، `ruling` اجتهاد قضائي، `guide` دليل. A published flag controls visibility; nothing is sent to parents' apps yet (an API for the app is a later, separate task).
- No invented legal text: seed only clearly labelled placeholder items ("نص تجريبي"), never real articles quoted from memory.
- Arabic RTL labels, existing theme and watermark, light and dark. Never edit PHP or Arabic files with PowerShell Get-Content/Set-Content (BOM; `NoByteOrderMarkTest` guards it).
- Confirm Filament v5 APIs from `vendor/filament/*` sources, not memory.

## Review Focus
1. A parent hitting any new admin URL gets 403; a guest is redirected to login.
2. No admin screen exposes a password hash, remember token or API token; the users table never loads them.
3. A family with only one parent, and a parent with no phone/wilaya, render without errors.
4. Content with very long Arabic body and HTML in the body is rendered safely (no script execution).
5. Deleting content asks for confirmation and removes only that row.

## Progress map
| Task | Part | Cumulative |
|---|---|---|
| 1 | Dashboard home: stat cards, reports per week chart, status chart, latest reports | 25% |
| 2 | Content library (articles, laws, rulings, guides) with tabs, publish flag, delete confirmation, placeholder seed | 55% |
| 3 | Users and families (read-only) | 80% |
| 4 | Visits overview (read-only), navigation groups, visual check, docs | 100% |

---

### Task 1: Dashboard home (→ 25%)
**Files:** Create `app/Filament/Pages/Dashboard.php` (override), `app/Filament/Widgets/{DashboardStats,ReportsPerWeekChart,ReportsByStatusChart,LatestReports}.php`; modify `AdminPanelProvider` (pages/widgets); Test `tests/Feature/Admin/DashboardTest.php`.
**Interfaces:** Produces widgets: stats (reports under review, reviewed, parents total, linked families, upcoming visits), line/bar chart of reports created per week for the last 8 weeks (zero-filled), doughnut by status, table of the 5 newest reports linking to the view page.
- [ ] Failing tests: admin sees all widgets with correct numbers from seeded data (zero-filled weeks, status split); parent gets 403; empty database renders. [ ] Run → FAIL. [ ] Implement. [ ] Run all → PASS. [ ] Commit. Report **25%**.

### Task 2: Content library (→ 55%)
**Files:** Create migration `create_contents_table` (id, type string, title, slug unique, category nullable, reference nullable, summary text nullable, body longText, is_published bool default false, published_at nullable, created_by FK users, timestamps), `app/Models/Content.php`, `app/Enums/ContentType.php` (labels, badge colors), `app/Filament/Resources/Contents/ContentResource.php` + pages/forms/tables, `database/seeders/ContentPlaceholderSeeder.php`; Test `tests/Feature/Admin/ContentResourceTest.php`.
**Interfaces:** `ContentType::{Article,Law,Ruling,Guide}` with `label(): string`; `Content::scopePublished()`; resource navigation group "المحتوى", tabs All/Articles/Laws/Rulings/Guides, form: title, type, category, reference, summary, rich body, published toggle (sets `published_at`), delete with confirmation.
- [ ] Failing tests: create/edit/delete as admin (delete asks confirmation), tabs filter by type, publishing sets `published_at`, parent 403, body with `<script>` is not rendered executable in the table/view, slug unique. [ ] Run → FAIL. [ ] Implement + seed 6 labelled placeholder items. [ ] Run all → PASS. [ ] Commit. Report **55%**.

### Task 3: Users and families (→ 80%)
**Files:** Create `app/Filament/Resources/Users/UserResource.php` (+ list/view pages, table/infolist), test `tests/Feature/Admin/UserResourceTest.php`.
**Interfaces:** Query only role in (father, mother); columns name, role badge, phone, wilaya, children count, linked status (family has two parents), partner name (admin only), joined date, last activity (latest `personal_access_tokens.last_used_at`); filters role, linked/unlinked, wilaya; `canCreate/canEdit/canDelete` false; model attributes `password`, `remember_token` never selected.
- [x] Failing tests per Review Focus 1-3 plus filters. [x] Implement. [x] Run all → PASS. [x] Commit. Report **80%**.

### Task 4: Visits overview and polish (→ 100%)
**Files:** Create `app/Filament/Resources/Visits/VisitResource.php` (+ list/view), test `tests/Feature/Admin/VisitResourceTest.php`; modify navigation groups (Reports and Visits under "العمليات", Content under "المحتوى", Users under "الحسابات"); update `docs/ADMIN.md`, `CLAUDE.md`, `03-app/PLAN.md`.
- [x] Failing tests: list shows date, time range, status badge (proposed info, accepted warning, declined danger, confirmed success), family parents' names, proposed-by role; filters status and date range; no write actions; parent 403. [x] Implement. [x] Visual check in the browser (light and dark) against the theme, fix contrast. [x] Run all tests. [x] Commit. Report **100%**.

## Who does what
Codex: Tasks 1 and 2. Antigravity: Tasks 3 and 4 (read-only resources, navigation, visual check). The orchestrator runs every gate, resolves overlaps in `AdminPanelProvider`, and commits.

---

## Addendum (owner's request: more that enriches the idea)

### Task 5: Centers and bodies directory (after Task 4)
**Files:** migration `create_support_centers_table` (id, name, kind, wilaya nullable, address nullable, phone nullable, hotline nullable, email nullable, website nullable, hours nullable, notes text nullable, is_published bool default false, timestamps), `app/Models/SupportCenter.php`, `app/Enums/CenterKind.php` (court محكمة شؤون الأسرة، legal_aid مساعدة قانونية، child_protection حماية الطفولة، psychological دعم نفسي، social مصالح اجتماعية، ngo جمعية، hotline خط مساعدة), `app/Filament/Resources/SupportCenters/*`, `app/Support/Wilayas.php` (the 58 Algerian wilayas, number + Arabic name, copy the list from the mobile app's `lib/features/profile/wilayas.dart` so both sides agree), `database/seeders/SupportCenterPlaceholderSeeder.php` (labelled "بيانات تجريبية", never real phone numbers), test `tests/Feature/Admin/SupportCenterResourceTest.php`.
Rules: admin CRUD with delete confirmation; filters by kind and wilaya; tabs by kind; "published" flag; phone numbers validated loosely; nothing shown in the app yet (a read API and an app screen "المراكز والهيئات" with search by wilaya and tap-to-call is a later task).
- [ ] Failing tests (CRUD, filters, kind tabs, published flag, parent 403, wilaya list has 58 entries). [ ] Implement. [ ] Run all. [ ] Commit. Cumulative: **+10%**.

### Task 6: Admin activity log (evidence integrity)
**Files:** migration `create_admin_activities_table` (id, admin_id, action string, subject_type, subject_id, meta json nullable, ip nullable, created_at), `app/Models/AdminActivity.php`, `app/Services/AdminActivityLog.php` (`record(User $admin, string $action, Model $subject, array $meta = []): void`), call sites: report marked reviewed, report PDF downloaded, attachment opened from the admin, content/center created/updated/deleted; read-only resource `AdminActivityResource` (group "الحسابات": who, what, which record, when; filters by action and admin; never editable or deletable), test `tests/Feature/Admin/AdminActivityLogTest.php`.
- [ ] Failing tests (each call site writes one row with the right action; the log resource is read-only; parent 403). [ ] Implement. [ ] Run all. [ ] Commit. Cumulative: **+10%**.

### Later ideas (not scheduled, only on request)
FAQ section for parents; emergency numbers editable by the admin and shown on the app's SOS card; read API and app screens for the content library and the directory; announcements to all parents; export of reports to CSV for the client's reporting.
---

## Addendum 2 (owner approved)

### Task 7: Design first, then build in the app (work order: design → build)
**Design (FigCraft, headless, new pages in `02-design/figcraft/riayati-design.figcraft`, light and dark):**
- App: `09 Library` (content list with type chips مقال/قانون/اجتهاد/دليل, search, article detail with serif body, empty/loading/error), `10 Centers` (directory list with wilaya filter sheet, search, kind chips, center card with call and map-free address, center detail with tap-to-call/copy, empty state). Entry points: two shortcut cards on Home under the SOS card ("المحتوى التعليمي" and "مراكز وهيئات") and a Home update screen.
- Admin: `11 Admin Home` (dashboard), `12 Admin Content` (list + edit form), `13 Admin Centers` (list + edit form), `14 Admin Users`, `15 Admin Visits`, `16 Admin Activity log`.
**Build after the design is approved:** read API `GET /api/contents` (published only, filter `type`, search `q`), `GET /api/contents/{slug}`, `GET /api/centers` (published only, filters `kind`, `wilaya`, `q`), `GET /api/centers/{id}` with tests; Flutter `lib/features/library/*` and `lib/features/centers/*` with data layer, screens, tests, routes `/library`, `/library/:slug`, `/centers`, `/centers/:id`, and the two Home shortcut cards. Tap-to-call uses `url_launcher` (`tel:`), copy uses the clipboard.