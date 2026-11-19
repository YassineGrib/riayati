# Build plan and API notes

Work order (from the decisions in `CLAUDE.md`): brand tokens (done) → UI/UX (done) → **MVP backend** → Flutter app → Filament admin → AI/RAG chatbot → landing page and video.

## Status
| Step | State |
|---|---|
| 1. Laravel scaffold, SQLite, Sanctum | done |
| 2. Auth (register, login, logout, me), roles, consent | done, tested |
| 3. Password reset by emailed link (web page) | done, tested |
| 4. Link the two parents with an invite code | done, tested |
| 5. Incident reports + attachments (private storage, signed URLs, caps) | done, tested |
| 6. PDF export of a report (Arabic, RTL) | done, tested, checked visually |
| 7. Visit calendar (propose, accept, decline, confirm) | done, tested |
| 8. Flutter app against this API | next |
| 9. Filament admin | done, tested |
| 10. Legal texts, embeddings, Gemini chatbot | blocked on the client's documents for real data |

## Run it
```bash
cd 03-app/backend
composer install
php artisan key:generate
php artisan migrate
php artisan test
php artisan serve
```
Create accounts (random passwords, printed once): `php artisan riayati:create-admin you@example.com` and `php artisan riayati:demo-accounts`.

## API (all JSON, prefix `/api`, Arabic messages)
Public, rate-limited to 6 requests per minute:
- `POST /register` `{name, email, password (8+), role: father|mother, terms: true, device_name?}` → `201 {user, token}`. Admins can never be created here.
- `POST /login` `{email, password}` → `{user, token}`. Wrong email and wrong password give the **same** error.
- `POST /forgot-password` `{email}` → always the same answer. The email links to a web page (`/reset-password/{token}`).
- `POST /reset-password` `{token, email, password, password_confirmation}` → signs out all sessions.

With `Authorization: Bearer <token>`:
- `GET /me` → `{user: {id, name, email, role, linked, partner_role, phone, wilaya, children_count}}`. Login/register return the same user shape; optional details default to null. Never includes the other parent's private details.
- `PUT /me` `{name, email, phone?, wilaya?, children_count?, current_password?}` → `{user}`. Name: 2–80 characters; email unique except self (normalized to lowercase); changing email requires the correct current password and clears email verification. Phone: `0` or `+213` followed by nine digits, with whitespace/dashes removed. Wilaya: nullable name up to 60 characters; children count: nullable integer 0–20. Unknown fields (including role) ignored; Sanctum required, 6 requests/minute. Run migrations to add the nullable user columns.
- `POST /logout`
- `PUT /password` `{current_password, password (8–128 characters), password_confirmation}` → `{message}`. Checks the current password; returns Arabic field errors with 422. Revokes all other tokens, keeping this device's current token. Limited to 6 requests per minute; requires Sanctum authentication.
- `GET /family` → `{linked, partner_role}`
- `POST /family/invite` → `201 {code: "K7M-4Q2", expires_at}` (48 h; a new code replaces the previous unused one)
- `POST /family/link` `{code}` → `{linked: true, partner_role}`; limited to 10 per minute

Incident reports (parents only; author and admins can read):
- `POST /reports` multipart: `description` (3–5000), `incident_at` (not in the future), `files[]` (up to **5**, **30 MB** each; JPEG, PNG, WebP, MP4, MOV, PDF, checked by real content type) → `201 {report}` with reference `RIA-2026-0001`, status `under_review`, and a SHA-256 fingerprint per file.
- `GET /reports?status=under_review|reviewed` (own reports), `GET /reports/{id}`. Someone else's report, including the linked parent's, answers **404**.
- `GET /reports/{id}/pdf` → the structured Arabic PDF (details, description, attachment table with fingerprints, shrunk photos).
- `GET /reports/{id}/attachments/{attachment}/link` → `{url, expires_at}`: a signed link valid for **5 minutes**. The file itself is served only from that link (`/attachments/{id}/download`, `signed` middleware); storage paths are never exposed.
- **No update or delete route exists** (PUT, PATCH, DELETE return 405) because a submitted report is evidence. Admin review is `IncidentReport::markReviewed($admin)`, to be used by the Filament panel.
- Hosting: `public/.user.ini` raises PHP's upload limits (32M per file, 170M per request). If Hostinger ignores it, set the same values in hPanel.
- PDF font: IBM Plex Sans Arabic in `resources/fonts/` (open license). The thmanyah font is not used on the server.

Visit calendar (the two linked parents only; an unlinked parent gets `403 {code: "not_linked"}` so the app can show the link screen; admins get 403):
- `GET /visits?month=2026-11` (calendar grid), `GET /visits/upcoming` (next open or agreed visits, sorted), `GET /visits/{id}`.
- `POST /visits` `{date: "2026-11-27", from: "10:00", to: "14:00", note?}` → `201`. Must be in the future, end after start, note up to 300 characters, and must not overlap another open or agreed visit (back to back is fine).
- Flow: the **other parent** calls `POST /visits/{id}/accept` or `/decline`; after acceptance the **proposer** calls `POST /visits/{id}/confirm`. A declined visit is final and frees its slot. A proposal cannot be accepted or confirmed once its start time has passed.
- Each visit says `proposed_by_me`, `needs_my_response`, `can_confirm` and carries a `timeline` (proposed, accepted or declined, confirmed). It never includes the other parent's name or email.
- Statuses: `proposed` (بانتظار الرد), `accepted` (تم القبول), `declined` (مرفوضة), `confirmed` (مؤكدة).
- Not in this step: push notifications ("you will get their answer" is delivered by the app refreshing, since the quote has no notification service).

Rules enforced and tested: a family holds exactly two parents; they must be one father and one mother; a code works once; unknown, expired, used and own codes return the same error; a parent already linked elsewhere gets 409.

## Notes
- Profile editing: `lib/features/profile/edit_profile_screen.dart` uses the profile page frame, Arabic field errors, a searchable numbered 58-wilaya picker, and a nullable children-count stepper. Saving through `AuthController.updateProfile` replaces the signed-in user with the server response so profile details refresh immediately. Missing details show `غير محدد`.
- Router integration is reserved for the orchestrator: register `/profile/edit` with `EditProfileScreen`; the profile's `تعديل` entry already pushes that path. No router/shared-widget/dependency changes are part of this task.
- Profile tests: `tests/Feature/Api/ProfileTest.php` and mobile `test/profile/{edit_profile_screen,profile_screen,profile_repository}_test.dart`. Backend full gate passed locally; Flutter gates require the orchestrator because this sandbox denies Flutter SDK cache lockfile access and Dart analysis child-process creation.
- Local PHP is 8.5 but Hostinger may be older: `composer.json` pins `platform.php` to 8.3.0.
- `.env` is not shared: copy `.env.example`, set `APP_KEY` (run `key:generate`), mail settings and the Gemini key later.
- The scaffold's own `CLAUDE.md` and `AGENTS.md` ask for Laravel Boost to be installed. It was not installed because it was not requested; decide whether to add it.
