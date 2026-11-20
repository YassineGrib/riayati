1. Host: https://riayati.site on Hostinger LiteSpeed/Apache; keep the existing Laravel document root and root .htaccess.
2. Upload index.html, fonts/, img/, favicon files and site.webmanifest into Laravel public/landing/; retain fonts/OFL.txt.
3. Route only `/` to landing/index.html through Laravel: `Route::get('/', fn () => response()->file(public_path('landing/index.html')));`.
4. Keep existing `/admin`, `/api` and all other Laravel routes working; never replace them with a static catch-all.
5. Put the signed Android arm64 release at public/downloads/riayati.apk; it does not exist in this delivery.
6. Copy this .htaccess to BOTH public/landing/.htaccess and public/downloads/.htaccess; APK MIME and attachment headers apply in downloads/.
7. Before upload, run `python tools/update-facts.py PATH_TO_SIGNED_APK`; update version/platform/pageUrl in the marked config if needed; size is decimal MB.
8. Verify APK release signature, arm64 libraries and production API URL; download from /downloads/riayati.apk and compare SHA-256, byte size and response headers.
9. Assets use /landing/ paths; locally run `powershell -ExecutionPolicy Bypass -File ./serve.ps1` and open http://127.0.0.1:8765/landing/index.html.
10. Upload only production files from lines 2, 5 and 6; exclude tools/, serve.ps1 and this guide; check Android/copy-link behaviour at 375/768/1440 px and refresh caches after asset edits.
