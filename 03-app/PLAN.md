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
| 9. Filament admin | |
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
- `GET /me` → `{user: {id, name, email, role, linked, partner_role}}` (never any detail of the other parent)
- `POST /logout`
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
- Local PHP is 8.5 but Hostinger may be older: `composer.json` pins `platform.php` to 8.3.0.
- `.env` is not shared: copy `.env.example`, set `APP_KEY` (run `key:generate`), mail settings and the Gemini key later.
- The scaffold's own `CLAUDE.md` and `AGENTS.md` ask for Laravel Boost to be installed. It was not installed because it was not requested; decide whether to add it.
