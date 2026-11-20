# Hostinger deployment (riayati.site)

Deployed on 2026-11-20. This is what is actually on the server.

## Layout
- Code: `/home/u514106451/riayati-app` (Laravel, outside the web root).
- Web root: `/home/u514106451/domains/riayati.site/public_html` is a symlink to `riayati-app/public`. The original parked page is in `public_html.bak`.
- PHP: the command line default is 7.4, so every command uses `/opt/alt/php83/usr/bin/php` (8.3). The website itself already runs PHP 8.3.
- Composer: `php83 /usr/local/bin/composer`.
- Database: SQLite at `riayati-app/database/database.sqlite` (mode 600). Evidence files: `riayati-app/storage/app/private`.
- `.env` (mode 600) is production: `APP_ENV=production`, `APP_DEBUG=false`, `APP_URL=https://riayati.site`, secure cookies. It is never overwritten by a deploy.
- HTTPS: Hostinger certificate; `http` redirects to `https`. `.env`, `composer.json`, the database and logs answer 403/404 from the web.

## Update the server
```
powershell -File tools\deploy-hostinger.ps1
```
Uploads the backend, keeps `.env`, the database and uploads, runs `composer install --no-dev`, `migrate --force` and the caches. It pins the server host key and needs `~\.ssh\riayati_deploy` (its public key is added in hPanel, SSH Access).

## Accounts
The admin and the two demo parents were created on 2026-11-20 with random passwords shown once to the owner. To change a password: `php83 artisan tinker`, then `User::where('email', '...')->first()->update(['password' => '...'])`.

## Still to do on the server
- Cron for the queue (needed once the chatbot re-indexes legal texts): hPanel, Cron Jobs, every minute: `cd /home/u514106451/riayati-app && /opt/alt/php83/usr/bin/php artisan queue:work --stop-when-empty`.
- Mail: no mail driver is set, so password-reset emails are not sent yet.
- Gemini key (chatbot) goes in `.env` when that part is built; use a paid-tier key at handover.
- The placeholder library and centers are seeded unpublished; publish only real content.

## Mobile app
Release build: `flutter build apk --release --dart-define=API_URL=https://riayati.site/api` in `03-app/mobile`. Release builds block plain HTTP, and they are signed with the debug key until a real signing key is made.
