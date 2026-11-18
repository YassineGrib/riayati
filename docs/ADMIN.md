# Riayati Admin Panel (`/admin`)

This guide covers setup, administration, theme building, demo data seeding, local LAN development for mobile testing, and production deployment on Hostinger.

---

## 1. Creating Admin Accounts

Admin access to the panel (`/admin`) is restricted to users with the `Role::Admin` role (`User::canAccessPanel()`). Parent accounts (father / mother) receive a 403 Forbidden response.

To create an administrator account, run the dedicated artisan command:

```bash
cd 03-app/backend
php artisan riayati:create-admin admin@riayati.test --name="مسؤول المنصة"
```

The command generates a secure random 16-character password and displays it once in the terminal.

To create the initial linked demo accounts (father, mother, admin) for evaluation:

```bash
php artisan riayati:demo-accounts
```

---

## 2. Building the Filament Theme

The custom Filament v5 theme is located at `resources/css/filament/admin/theme.css` and compiled via Vite with Tailwind CSS v4. It injects:
- The faint abstract logo watermark (`public/images/riayati-mark-abstract.svg`) into the main page and sidebar backgrounds at 6–8% opacity.
- WCAG AA compliant badge styles for report statuses (`قيد المراجعة` info, `تمت المراجعة` success).
- Spacing and table density matching the design system.
- Evidence attachment tile previews with one-click SHA-256 fingerprint copying.

To build the theme assets for production:

```bash
cd 03-app/backend
npm install
npm run build
```

The compiled assets are output to `public/build`. Note that `public/build` is ignored by git (`.gitignore`).

---

## 3. Seeding Demo Incident Reports

To populate the panel with 12 realistic demonstration reports spread over the last 3 weeks with attachments (valid JPEG, PNG, and PDF files written to the private disk `storage/app/private`), run:

```bash
cd 03-app/backend
php artisan db:seed --class=AdminDemoSeeder
```

**Idempotence:** Running `AdminDemoSeeder` multiple times is safe and will not duplicate existing accounts or reports. Existing demo accounts (`father@riayati.test`, `mother@riayati.test`) are reused without altering their passwords.

---

## 4. Running the Dev Server for Mobile Testing

To test the mobile app and admin panel simultaneously over your local Wi-Fi:

```powershell
cd 03-app/backend
powershell -File serve-lan.ps1 -Port 8765
```

This starts PHP's server bound to `0.0.0.0:8765` configured with:
- `upload_max_filesize = 32M`
- `post_max_size = 170M`
- `max_file_uploads = 10`

For separate desktop-only preview without disturbing the mobile session:

```bash
cd 03-app/backend
php artisan serve --port=8099
```

---

## 5. Hostinger Production Deployment Notes

1. **Vite Build (`public/build`):**
   - If Node.js and npm are available on the Hostinger server / cPanel Terminal, run `npm install && npm run build` directly on the server.
   - If Node.js is not installed on the hosting environment, run `npm run build` locally in `03-app/backend` and upload the resulting `public/build/` directory alongside the backend release files.

2. **Filament Upgrade Command:**
   After pulling updates or upgrading Filament packages, always run:
   ```bash
   php artisan filament:upgrade
   ```
   This ensures Filament's published assets and icons are synchronized with the package version.

3. **Storage Symlink (`php artisan storage:link` NOT needed):**
   - `php artisan storage:link` is **not required** because all evidence attachments are strictly stored on the `local` private disk (`storage/app/private/`).
   - Files are never directly accessible by URL or web server alias. They are served exclusively through temporary, cryptographic signed URLs (`/attachments/{id}/download?signature=...`) that expire after 5 minutes.

4. **Background Queue Cron:**
   For asynchronous tasks (such as future legal document re-indexing and mail notifications), configure a cron job in the Hostinger control panel running every minute:
   ```bash
   * * * * * cd /home/u123456789/domains/riayati.dz/public_html/backend && php artisan queue:work --stop-when-empty >> /dev/null 2>&1
   ```
   Alternatively, run the Laravel scheduler cron:
   ```bash
   * * * * * cd /home/u123456789/domains/riayati.dz/public_html/backend && php artisan schedule:run >> /dev/null 2>&1
   ```

---

## 6. Verification and Health Checks

Before pushing releases:
- Verify all unit and feature tests pass:
  ```bash
  php artisan test
  ```
- Ensure no PHP or Blade files have UTF-8 Byte Order Marks (BOMs):
  ```bash
  php artisan test --filter NoByteOrderMarkTest
  ```
