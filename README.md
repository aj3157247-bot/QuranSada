# QuranSada (قرآن صدا)

Flutter starter for an offline Quran recitation and human-voice translation app.

## Current scaffold
- Four selectable interface languages: Dari (`prs`), Persian (`fa`), Pashto (`ps`), English (`en`)
- RTL/LTR layout switching
- Basic home and surah screens
- GitHub Actions workflow for release APK artifact

## Important
This is a foundation, not a finished Quran product. It does **not** yet contain the verified 114-surah/ayah dataset or licensed human recordings. Offline audio requires actual audio packs with redistribution rights. Do not represent placeholder screens as complete Quran content.

## Build
Open this repository in GitHub, push to `main`, then go to **Actions → QuranSada Android APK → Run workflow**. Download the APK from the workflow artifact.

## Next implementation steps
1. Add a verified Quran text source and translations with attribution.
2. Integrate licensed reciter recordings and human-voice translations for Dari, Persian, Pashto, and English.
3. Add download manager, storage checks, background audio service, bookmarks, repeat-ayah, and audio-pack integrity checks.
4. Test pronunciation, verse alignment, accessibility, and offline behavior before release.
