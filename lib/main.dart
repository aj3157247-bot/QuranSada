import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const QuranSadaApp());

const supported = ['fa', 'prs', 'ps', 'en'];
const names = {'fa':'فارسی', 'prs':'دری', 'ps':'پښتو', 'en':'English'};

class QuranSadaApp extends StatefulWidget {
  const QuranSadaApp({super.key});
  @override State<QuranSadaApp> createState() => _QuranSadaAppState();
}
class _QuranSadaAppState extends State<QuranSadaApp> {
  Locale _locale = const Locale('prs');
  @override void initState() { super.initState(); _loadLocale(); }
  Future<void> _loadLocale() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString('locale') ?? 'prs';
    if (mounted) setState(() => _locale = Locale(code));
  }
  Future<void> _setLocale(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('locale', code);
    setState(() => _locale = Locale(code));
  }
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'QuranSada',
    locale: _locale,
    supportedLocales: supported.map((e) => Locale(e)),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087E68)), useMaterial3: true),
    home: HomePage(locale: _locale.languageCode, onLocale: _setLocale),
  );
}

class HomePage extends StatelessWidget {
  final String locale;
  final ValueChanged<String> onLocale;
  const HomePage({super.key, required this.locale, required this.onLocale});
  String t(String prs, String fa, String ps, String en) => switch(locale) {
    'fa' => fa, 'ps' => ps, 'en' => en, _ => prs
  };
  @override Widget build(BuildContext context) {
    final rtl = locale != 'en';
    return Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Text('QuranSada • قرآن صدا'), centerTitle: true),
        drawer: Drawer(child: SafeArea(child: Column(children: [
          const ListTile(title: Text('QuranSada', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          const Divider(),
          Padding(padding: const EdgeInsets.all(16), child: Text(t('زبان برنامه','زبان برنامه','د پروګرام ژبه','App language'))),
          ...supported.map((code) => RadioListTile<String>(
            value: code, groupValue: locale, title: Text(names[code]!),
            onChanged: (v) { if (v != null) onLocale(v); Navigator.pop(context); },
          )),
        ]))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(colors: [Color(0xFF075E54), Color(0xFF12A184)])),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(color: Colors.white, fontSize: 23), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Text(t('قرآن را با دل و جان بشنوید','قرآن را با دل و جان بشنوید','قرآن په مینه واورئ','Listen to the Quran'),
                style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(t('تلاوت و ترجمه صوتی آفلاین','تلاوت و ترجمه صوتی آفلاین','آفلاین تلاوت او ژباړه','Offline recitation & translation'),
                style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 18),
          Text(t('ادامه گوش‌دادن','ادامه گوش‌دادن','اورېدلو ته دوام ورکړئ','Continue listening'),
            style: Theme.of(context).textTheme.titleLarge),
          Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.play_arrow)),
            title: Text(t('هنوز چیزی پخش نشده','هنوز چیزی پخش نشده','تر اوسه څه نه دي غږول شوي','Nothing played yet')),
            subtitle: Text(t('پس از پخش، آخرین آیه اینجا ذخیره می‌شود','پس از پخش، آخرین آیه اینجا ذخیره می‌شود','وروسته به وروستی آیت دلته خوندي شي','Your last ayah will appear here')),
          )),
          const SizedBox(height: 12),
          Text(t('سوره‌ها','سوره‌ها','سورتونه','Surahs'), style: Theme.of(context).textTheme.titleLarge),
          ...const [
            ('الفاتحه','Al-Fatihah','الفاتحه',7), ('البقره','Al-Baqarah','البقرة',286),
            ('آل‌عمران','Ali Imran','آل عمران',200), ('النساء','An-Nisa','النساء',176),
          ].map((s) => Card(child: ListTile(
            leading: const Icon(Icons.menu_book, color: Color(0xFF087E68)),
            title: Text(s.$1), subtitle: Text('${s.$2} • ${s.$4} ${t('آیه','آیه','آیتونه','ayahs')}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
              SurahPage(name: s.$1, locale: locale))),
          ))),
          const SizedBox(height: 8),
          Center(child: Text(t('فهرست کامل ۱۱۴ سوره در نسخه بعدی داده‌ها تکمیل می‌شود',
            'فهرست کامل ۱۱۴ سوره در نسخه بعدی داده‌ها تکمیل می‌شود',
            'د ۱۱۴ سورتونو بشپړ لړلیک به د معلوماتو په راتلونکې نسخه کې وي',
            'Full 114-surah catalog will be populated with verified Quran data'),
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey))),
        ]),
      ));
  }
}

class SurahPage extends StatelessWidget {
  final String name, locale;
  const SurahPage({super.key, required this.name, required this.locale});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(name)),
    body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.headphones, size: 64, color: Color(0xFF087E68)),
        const SizedBox(height: 16),
        Text(locale == 'en' ? 'Audio packs are not installed yet' : 'بسته‌های صوتی هنوز اضافه نشده‌اند',
          textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(locale == 'en'
          ? 'Licensed recitation and human-voice translation files will be added as offline packs.'
          : 'فایل‌های مجاز تلاوت و ترجمه با صدای انسان به‌صورت بسته‌های آفلاین اضافه خواهند شد.',
          textAlign: TextAlign.center),
      ],
    ))),
  );
}
