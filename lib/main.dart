import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:quran/quran.dart' as quran;
import 'surah_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuranSadaApp());
}

const languages = ['prs', 'fa', 'ps', 'en'];
const languageNames = {'prs': 'دری', 'fa': 'فارسی', 'ps': 'پښتو', 'en': 'English'};
const reciters = ['Mishary Rashid Alafasy', 'Mahmoud Khalil Al-Husary', 'Maher Al-Muaiqly'];

class QuranSadaApp extends StatefulWidget {
  const QuranSadaApp({super.key});
  @override State<QuranSadaApp> createState() => _QuranSadaAppState();
}
class _QuranSadaAppState extends State<QuranSadaApp> {
  String lang = 'prs';
  bool dark = false;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() { lang = p.getString('lang') ?? 'prs'; dark = p.getBool('dark') ?? false; });
  }
  Future<void> setLang(String v) async {
    final p = await SharedPreferences.getInstance(); await p.setString('lang', v);
    if (mounted) setState(() => lang = v);
  }
  Future<void> setDark(bool v) async {
    final p = await SharedPreferences.getInstance(); await p.setBool('dark', v);
    if (mounted) setState(() => dark = v);
  }
  @override Widget build(BuildContext context) => MaterialApp(
    title: 'QuranSada', debugShowCheckedModeBanner: false,
    locale: Locale(lang == 'prs' ? 'fa' : lang),
    supportedLocales: const [Locale('fa'), Locale('ps'), Locale('en')],
    localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E68)), scaffoldBackgroundColor: const Color(0xFFF4FAF6)),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E68), brightness: Brightness.dark)),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: QuranHome(lang: lang, onLanguage: setLang, dark: dark, onDark: setDark),
  );
}

class QuranHome extends StatefulWidget {
  final String lang; final ValueChanged<String> onLanguage; final bool dark; final ValueChanged<bool> onDark;
  const QuranHome({super.key, required this.lang, required this.onLanguage, required this.dark, required this.onDark});
  @override State<QuranHome> createState() => _QuranHomeState();
}
class _QuranHomeState extends State<QuranHome> {
  int tab = 0; String query = ''; String reciter = reciters.first; final player = AudioPlayer();
  Set<int> favorites = {}; int lastSurah = 1; int lastAyah = 1;
  bool get rtl => widget.lang != 'en';
  String tr(String prs, String fa, String ps, String en) => switch (widget.lang) {'fa' => fa, 'ps' => ps, 'en' => en, _ => prs};
  @override void initState() { super.initState(); _loadPrefs(); }
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance(); if (!mounted) return;
    setState(() { favorites = (p.getStringList('favorites') ?? []).map(int.parse).toSet(); lastSurah = p.getInt('lastSurah') ?? 1; lastAyah = p.getInt('lastAyah') ?? 1; reciter = p.getString('reciter') ?? reciters.first; });
  }
  Future<void> _toggleFavorite(int id) async {
    setState(() => favorites.contains(id) ? favorites.remove(id) : favorites.add(id));
    final p = await SharedPreferences.getInstance(); await p.setStringList('favorites', favorites.map((e) => '$e').toList());
  }
  Future<void> _openSurah(Surah s) async {
    final p = await SharedPreferences.getInstance(); await p.setInt('lastSurah', s.number);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => SurahScreen(surah: s, lang: widget.lang, reciter: reciter, player: player, isFavorite: favorites.contains(s.number), onFavorite: () => _toggleFavorite(s.number), initialAyah: lastAyah)))
      .then((_) => _loadPrefs());
  }
  Future<void> _chooseReciter(String? v) async { if (v == null) return; setState(() => reciter = v); final p = await SharedPreferences.getInstance(); await p.setString('reciter', v); }
  @override void dispose() { player.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final shown = allSurahs.where((s) => s.arabic.contains(query) || s.transliteration.toLowerCase().contains(query.toLowerCase()) || s.number.toString() == query).toList();
    final list = tab == 2 ? allSurahs.where((s) => favorites.contains(s.number)).toList() : shown;
    return Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: Scaffold(
      appBar: AppBar(title: const Text('QuranSada • قرآن صدا', style: TextStyle(fontWeight: FontWeight.bold)), actions: [
        PopupMenuButton<String>(icon: const Icon(Icons.language), onSelected: widget.onLanguage, itemBuilder: (_) => languages.map((l) => PopupMenuItem(value: l, child: Text(languageNames[l]!))).toList()),
      ]),
      body: tab == 3 ? _settings() : tab == 0 ? _home() : _surahList(list),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: [
        NavigationDestination(icon: const Icon(Icons.home_outlined), label: tr('خانه','خانه','کور','Home')),
        NavigationDestination(icon: const Icon(Icons.menu_book), label: tr('سوره‌ها','سوره‌ها','سورتونه','Surahs')),
        NavigationDestination(icon: const Icon(Icons.favorite_border), label: tr('علاقه‌مندی‌ها','علاقه‌مندی‌ها','خوښې','Favorites')),
        NavigationDestination(icon: const Icon(Icons.settings_outlined), label: tr('تنظیمات','تنظیمات','امستنې','Settings')),
      ]),
    ));
  }
  Widget _home() => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF0D9675)])), child: Column(children: [
      const Icon(Icons.nightlight_round, color: Color(0xFFFFD66B), size: 34), const SizedBox(height: 8),
      const Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', style: TextStyle(color: Colors.white, fontSize: 22), textAlign: TextAlign.center), const SizedBox(height: 12),
      Text(tr('قرآن را با دل و جان بشنوید','قرآن را با دل و جان بشنوید','قرآن په مینه واورئ','Listen to the Holy Quran'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
      Text(tr('متن قرآن آفلاین • تلاوت قابل دانلود','متن قرآن آفلاین • تلاوت قابل دانلود','آفلاین قرآن • ښکته کېدونکې تلاوت','Offline Quran text • downloadable recitation'), style: const TextStyle(color: Colors.white70)),
    ])),
    const SizedBox(height: 18), Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.play_arrow)), title: Text(tr('ادامه مطالعه','ادامه مطالعه','لوستلو ته دوام','Continue reading')), subtitle: Text('${allSurahs[lastSurah-1].arabic} • آیه $lastAyah'), trailing: const Icon(Icons.chevron_right), onTap: () => _openSurah(allSurahs[lastSurah-1]))),
    const SizedBox(height: 14), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(tr('سوره‌ها','سوره‌ها','سورتونه','Surahs'), style: Theme.of(context).textTheme.titleLarge), TextButton(onPressed: () => setState(() => tab = 1), child: Text(tr('همه سوره‌ها','همه سوره‌ها','ټول سورتونه','View all')))]),
    ...allSurahs.take(6).map(_surahTile),
    Text(tr('متن عربی و ترجمه دری/انگلیسی داخل برنامه آفلاین است. برای صوت، سوره را یک‌بار دانلود کنید.','متن عربی و ترجمه دری/انگلیسی داخل برنامه آفلاین است. برای صوت، سوره را یک‌بار دانلود کنید.','عربي متن او دري/انګلیسي ژباړه آفلاین ده؛ د غږ لپاره سورت یو ځل ښکته کړئ.','Arabic text and Dari/English translation are offline. Download a surah once for offline audio.'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
  ]);
  Widget _surahList(List<Surah> list) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16,8,16,4), child: TextField(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: tr('جستجوی سوره یا شماره','جستجوی سوره یا شماره','د سورت لټون','Search surah or number'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))), onChanged: (v) => setState(() => query = v.trim()))),
    Expanded(child: list.isEmpty ? Center(child: Text(tr('موردی پیدا نشد','موردی پیدا نشد','څه ونه موندل شول','No results'))) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: list.length, itemBuilder: (_, i) => _surahTile(list[i]))),
  ]);
  Widget _surahTile(Surah s) => Card(margin: const EdgeInsets.symmetric(vertical: 5), child: ListTile(
    leading: CircleAvatar(backgroundColor: const Color(0xFFE0F2E9), child: Text('${s.number}', style: const TextStyle(color: Color(0xFF087E68)))),
    title: Text(s.arabic, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)), subtitle: Text('${s.transliteration} • ${s.ayahs} ${tr('آیه','آیه','آیتونه','ayahs')}'),
    trailing: Icon(favorites.contains(s.number) ? Icons.favorite : Icons.chevron_right, color: favorites.contains(s.number) ? Colors.redAccent : const Color(0xFF087E68)),
    onTap: () => _openSurah(s), onLongPress: () => _toggleFavorite(s.number)));
  Widget _settings() => ListView(padding: const EdgeInsets.all(18), children: [
    Text(tr('تنظیمات','تنظیمات','امستنې','Settings'), style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 16),
    Text(tr('زبان رابط کاربری','زبان رابط کاربری','د اپ ژبه','Interface language')),
    ...languages.map((l) => RadioListTile<String>(value: l, groupValue: widget.lang, title: Text(languageNames[l]!), onChanged: (v) { if (v != null) widget.onLanguage(v); })),
    SwitchListTile(value: widget.dark, onChanged: widget.onDark, title: Text(tr('حالت شب','حالت شب','شپه‌نی حالت','Dark mode'))),
    const Divider(), Text(tr('قاری تلاوت','قاری تلاوت','د تلاوت قاري','Reciter')),
    DropdownButtonFormField<String>(value: reciter, items: reciters.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: _chooseReciter),
    const SizedBox(height: 16), Text(tr('متن کامل عربی و ترجمه دری و انگلیسی به‌صورت آفلاین فراهم است. ترجمه پشتو و ترجمه‌های صوتی انسانی هنوز به بسته‌های معتبر جداگانه نیاز دارند.','متن کامل عربی و ترجمه دری و انگلیسی به‌صورت آفلاین فراهم است. ترجمه پشتو و ترجمه‌های صوتی انسانی هنوز به بسته‌های معتبر جداگانه نیاز دارند.','عربي متن او دري/انګلیسي ژباړه آفلاین دي؛ پښتو ژباړه او انساني غږیزې ژباړې جلا باوري بستو ته اړتیا لري.','Full Arabic text and Dari/English text translation work offline. Pashto text and human-voice translations still require separate verified data/audio packs.')),
  ]);
}

class SurahScreen extends StatefulWidget {
  final Surah surah; final String lang, reciter; final AudioPlayer player; final bool isFavorite; final VoidCallback onFavorite; final int initialAyah;
  const SurahScreen({super.key, required this.surah, required this.lang, required this.reciter, required this.player, required this.isFavorite, required this.onFavorite, required this.initialAyah});
  @override State<SurahScreen> createState() => _SurahScreenState();
}
class _SurahScreenState extends State<SurahScreen> {
  bool translation = false, busy = false; String? error;
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _translationPlayer = AudioPlayer();
  bool _speaking = false; String translationLang = 'fa'; double fontSize = 25; int selectedAyah = 1; String ayahQuery = '';
  bool get rtl => widget.lang != 'en';
  String tr(String prs, String en) => widget.lang == 'en' ? en : prs;
  @override void initState() { super.initState(); _configureTts(); selectedAyah = widget.initialAyah.clamp(1, widget.surah.ayahs).toInt(); _loadFont(); }
  Future<void> _configureTts() async {
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    _tts.setStartHandler(() { if (mounted) setState(() => _speaking = true); });
    _tts.setCompletionHandler(() { if (mounted) setState(() => _speaking = false); });
    _tts.setCancelHandler(() { if (mounted) setState(() => _speaking = false); });
  }
  Future<void> _speakTranslation() async {
    try {
      await _translationPlayer.stop();
      await _tts.stop();
      await _tts.setLanguage(translationLang == 'en' ? 'en-US' : 'fa-IR');
      await _tts.speak(_translation(selectedAyah));
    } catch (_) {
      if (mounted) setState(() => error = tr('صدای زبان انتخاب‌شده در گوشی موجود نیست.','The selected language voice is unavailable on this device.'));
    }
  }
  Future<void> _playHumanTranslation() async {
    // Optional verified human recordings: copy files to this app folder using
    // naming SSSAAA.mp3, e.g. 001001.mp3 = surah 1, ayah 1.
    final root = await getApplicationDocumentsDirectory();
    final lang = translationLang == 'en' ? 'en' : 'fa';
    final name = '${widget.surah.number.toString().padLeft(3, '0')}${selectedAyah.toString().padLeft(3, '0')}.mp3';
    final file = File('${root.path}/quransada_translation_audio/$lang/$name');
    if (!await file.exists()) {
      if (mounted) setState(() => error = tr('فایل صوتی انسانی این آیه هنوز نصب/دانلود نشده است.','Human recording for this ayah is not installed/downloaded yet.'));
      return;
    }
    await _tts.stop();
    await _translationPlayer.setFilePath(file.path);
    await _translationPlayer.play();
  }
  Future<void> _loadFont() async { final p = await SharedPreferences.getInstance(); if (mounted) setState(() => fontSize = p.getDouble('quranFontSize') ?? 25); }
  String _audioSlug() => switch (widget.reciter) { 'Abdul Rahman Al-Sudais' => 'sudais', 'Maher Al-Muaiqly' => 'muaiqly', _ => 'alafasy' };
  Future<Directory> _audioDir() async { final d = Directory('${(await getApplicationDocumentsDirectory()).path}/quransada_audio/${_audioSlug()}'); if (!await d.exists()) await d.create(recursive: true); return d; }
  Future<File> _audioFile() async { final d = await _audioDir(); return File('${d.path}/surah_${widget.surah.number.toString().padLeft(3,'0')}.mp3'); }
  Future<void> playOrDownload() async {
    setState(() { busy = true; error = null; });
    try {
      final file = await _audioFile();
      if (!await file.exists() || await file.length() == 0) {
        final quran.Reciter selected = switch (widget.reciter) { 'Mahmoud Khalil Al-Husary' => quran.Reciter.arHusary, 'Maher Al-Muaiqly' => quran.Reciter.arMaherMuaiqly, _ => quran.Reciter.arAlafasy };
        final url = quran.getAudioURLBySurah(widget.surah.number, reciter: selected);
        final response = await http.get(Uri.parse(url)).timeout(const Duration(minutes: 3));
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) throw Exception('Download failed');
        await file.writeAsBytes(response.bodyBytes, flush: true);
      }
      await widget.player.setFilePath(file.path); await widget.player.play();
    } catch (_) { if (mounted) setState(() => error = tr('دانلود/پخش انجام نشد. اینترنت را بررسی کرده و دوباره تلاش کنید.','Could not download/play audio. Check internet and try again.')); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> _saveLastAyah(int ayah) async { selectedAyah = ayah; final p = await SharedPreferences.getInstance(); await p.setInt('lastSurah', widget.surah.number); await p.setInt('lastAyah', ayah); }
  Future<void> _bookmarkAyah(int ayah) async {
    final p = await SharedPreferences.getInstance(); final key = '${widget.surah.number}:$ayah'; final marks = (p.getStringList('ayahBookmarks') ?? []).toSet();
    final added = !marks.contains(key); if (added) { marks.add(key); } else { marks.remove(key); }
    await p.setStringList('ayahBookmarks', marks.toList());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(added ? tr('آیه نشان‌گذاری شد','Ayah bookmarked') : tr('نشان آیه حذف شد','Bookmark removed'))));
  }
  Future<bool> _isBookmarked(int ayah) async { final p = await SharedPreferences.getInstance(); return (p.getStringList('ayahBookmarks') ?? []).contains('${widget.surah.number}:$ayah'); }
  String _arabic(int ayah) => quran.getVerse(widget.surah.number, ayah, verseEndSymbol: true);
  String _translation(int ayah) {
    if (translationLang == 'en') return quran.getVerseTranslation(widget.surah.number, ayah, translation: quran.Translation.enSaheeh);
    return quran.getVerseTranslation(widget.surah.number, ayah, translation: quran.Translation.faHusseinDari);
  }
  @override Widget build(BuildContext context) {
    final verses = List<int>.generate(widget.surah.ayahs, (i) => i + 1).where((a) => ayahQuery.isEmpty || _arabic(a).contains(ayahQuery) || a.toString() == ayahQuery).toList();
    return Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: Scaffold(
      appBar: AppBar(title: Text(widget.surah.arabic), actions: [IconButton(onPressed: widget.onFavorite, icon: Icon(widget.isFavorite ? Icons.favorite : Icons.favorite_border))]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16,8,16,4), child: Column(children: [
          Text(widget.surah.transliteration, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          Text('${widget.surah.ayahs} ${tr('آیه','ayahs')} • ${tr('صفحه','Page')} ${quran.getPageNumber(widget.surah.number, 1)}'),
          const SizedBox(height: 8),
          SegmentedButton<bool>(segments: [ButtonSegment(value: false, label: Text(tr('قرآن','Quran')), icon: const Icon(Icons.menu_book)), ButtonSegment(value: true, label: Text(tr('ترجمه','Translation')), icon: const Icon(Icons.translate))], selected: {translation}, onSelectionChanged: (s) => setState(() => translation = s.first)),
          if (translation) DropdownButton<String>(value: translationLang, items: const [DropdownMenuItem(value:'fa',child:Text('دری / فارسی')),DropdownMenuItem(value:'en',child:Text('English'))], onChanged:(v)=>setState(()=>translationLang=v??'fa')),
          TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: tr('جستجو در آیات','Search ayahs')), onChanged:(v)=>setState(()=>ayahQuery=v.trim())),
        ])),
        Expanded(child: ListView.builder(itemCount: verses.length, itemBuilder: (_, i) {
          final ayah = verses[i];
          return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [CircleAvatar(radius: 15, child: Text('$ayah', style: const TextStyle(fontSize: 12))), const Spacer(), IconButton(tooltip: tr('نشان‌گذاری آیه','Bookmark ayah'), onPressed: () => _bookmarkAyah(ayah), icon: const Icon(Icons.bookmark_add_outlined)), IconButton(tooltip: tr('ذخیره آخرین آیه','Save reading position'), onPressed: () => _saveLastAyah(ayah), icon: const Icon(Icons.my_location))]),
            Text(_arabic(ayah), textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: TextStyle(fontSize: fontSize, height: 1.9, fontFamily: 'serif')),
            if (translation) Padding(padding: const EdgeInsets.only(top: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(_translation(ayah), textAlign: translationLang == 'en' ? TextAlign.left : TextAlign.right, style: const TextStyle(fontSize: 17, height: 1.6)), Align(alignment: AlignmentDirectional.centerEnd, child: TextButton.icon(onPressed: () { _saveLastAyah(ayah); _speakTranslation(); }, icon: const Icon(Icons.record_voice_over), label: Text(tr('خواندن ترجمه','Speak translation'))))])),
            FutureBuilder<bool>(future: _isBookmarked(ayah), builder: (_, snap) => snap.data == true ? Align(alignment: AlignmentDirectional.centerEnd, child: Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primary, size: 18)) : const SizedBox.shrink()),
          ])));
        })),
        SafeArea(top: false, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black12)]), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [IconButton(onPressed: _playHumanTranslation, tooltip: tr('صدای انسانی ترجمه','Human translation audio'), icon: const Icon(Icons.headphones)), IconButton(onPressed: _speaking ? () async { await _tts.stop(); } : _speakTranslation, tooltip: tr('صدای هوشمند ترجمه','Text-to-speech'), icon: Icon(_speaking ? Icons.stop_circle : Icons.record_voice_over)), IconButton(onPressed: busy ? null : playOrDownload, icon: Icon(busy ? Icons.downloading : Icons.download_for_offline_outlined)), Expanded(child: Text(tr('دانلود و پخش آفلاین تلاوت','Download & play offline recitation'))), IconButton(onPressed: () => widget.player.pause(), icon: const Icon(Icons.pause)), IconButton(onPressed: () => widget.player.stop(), icon: const Icon(Icons.stop))]),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
          StreamBuilder<Duration?>(stream: widget.player.durationStream, builder: (_, d) { final duration = d.data ?? Duration.zero; return StreamBuilder<Duration>(stream: widget.player.positionStream, builder: (_, p) { final pos = p.data ?? Duration.zero; final max = duration.inMilliseconds.toDouble(); return Slider(value: max <= 0 ? 0 : pos.inMilliseconds.clamp(0, max.toInt()).toDouble(), max: max <= 0 ? 1 : max, onChanged: max <= 0 ? null : (v) => widget.player.seek(Duration(milliseconds: v.round()))); }); }),
          Row(children: [Text(tr('اندازه متن','Text size')), Expanded(child: Slider(value: fontSize, min: 20, max: 42, divisions: 11, label: fontSize.round().toString(), onChanged: (v) => setState(() => fontSize = v), onChangeEnd: (v) async { final p = await SharedPreferences.getInstance(); await p.setDouble('quranFontSize', v); })), Text('${fontSize.round()}')]),
        ]))),
      ]),
    ));
  }
}
