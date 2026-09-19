QuranSada translation audio patch

Changed files only:
- lib/main.dart
- pubspec.yaml

After replacing these files in the repository:
1) Run flutter pub get (GitHub Actions should resolve flutter_tts automatically).
2) TTS reads the selected Dari/Persian or English translation using a voice installed on the phone. Voice availability depends on Android TTS engine and installed language packs; it may require internet unless the voice is downloaded offline.
3) Human recording playback is wired for per-ayah MP3 files, but recordings are NOT included. Place verified recordings in app documents folder:
   quransada_translation_audio/fa/001001.mp3
   quransada_translation_audio/en/001001.mp3
   Naming is SSSAAA.mp3 (3-digit surah + 3-digit ayah).
   Files must be copied/downloaded into that folder by a future pack downloader; this patch does not fabricate or bundle copyrighted recordings.
