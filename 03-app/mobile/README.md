# Riayati mobile

Arabic-only Android app (Flutter 3.47.9). Run `flutter pub get`, then `flutter run`.

Regenerate theme tokens from the repository root:

```
python 01-brand/tokens/generate_dart.py
```

Before building, obtain the licensed Thmanyah fonts locally and copy the Light,
Regular, Medium, Bold and Black OTFs for Sans, Serif Display and Serif Text into
`assets/fonts/thmanyah/`, using the filenames in pubspec.yaml. Never commit or
redistribute these fonts. Semibold (600) is absent locally; no substitute asset is
registered. IBM Plex Sans Arabic is the bundled fallback (OFL).

Checks: `flutter analyze` and `flutter test`.
