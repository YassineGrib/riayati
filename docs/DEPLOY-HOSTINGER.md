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

## Landing page and APK download
- `https://riayati.site/` is the landing + download page (Laravel route `/` serves `public/landing/index.html`; without that file it answers with the app name).
- The signed APK is `public/downloads/riayati.apk`, served with the Android MIME type and `Content-Disposition: attachment` (`.htaccess` in `public/downloads`).
- Publish: `powershell -File tools\deploy-landing.ps1 -Apk <path to the signed APK>` (uploads the production files of `05-marketing/landing`, then compares the APK SHA-256 on the server). After a new APK, run `python 05-marketing/landing/tools/update-facts.py <apk>` first so the page shows the right size and fingerprint.
- Release signing: `03-app/mobile/android/key.properties` (git-ignored) points to `C:\Users\Yassi\keystores\riayati-release.jks`. The keystore password is only in `key.properties` and in the owner's backup email. The keystore itself is also in the owner's Google Drive. Losing it means installed apps can never be updated.
- Build the download file: `flutter build apk --release --split-per-abi --target-platform android-arm64 --dart-define=API_URL=https://riayati.site/api` (arm64 only, about 21.5 MB). Check it with `apksigner verify --print-certs` (certificate SHA-256 must start `3B:0C:67:59`).

## Accounts
The admin and the two demo parents were created on 2026-11-20 with random passwords shown once to the owner. To change a password: `php83 artisan tinker`, then `User::where('email', '...')->first()->update(['password' => '...'])`.

## Still to do on the server
- Cron for the queue (needed once the chatbot re-indexes legal texts): hPanel, Cron Jobs, every minute: `cd /home/u514106451/riayati-app && /opt/alt/php83/usr/bin/php artisan queue:work --stop-when-empty`.
- Mail: no mail driver is set, so password-reset emails are not sent yet.
- Gemini key (chatbot) goes in `.env` when that part is built; use a paid-tier key at handover.
- The placeholder library and centers are seeded unpublished; publish only real content.

## Mobile app
Release build: `flutter build apk --release --dart-define=API_URL=https://riayati.site/api` in `03-app/mobile`. Release builds block plain HTTP, and they are signed with the debug key until a real signing key is made.
