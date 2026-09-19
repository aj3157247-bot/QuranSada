import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'surah_data.dart';

void main() => runApp(const QuranSadaApp());
const languages = ['prs','fa','ps','en'];
const languageNames = {'prs':'دری','fa':'فارسی','ps':'پښتو','en':'English'};
const reciters = ['Mishary Rashid Alafasy','Abdul Rahman Al-Sudais','Maher Al-Muaiqly'];

class QuranSadaApp extends StatefulWidget {
 const QuranSadaApp({super.key});
 @override State<QuranSadaApp> createState()=>_QuranSadaAppState();
}
class _QuranSadaAppState extends State<QuranSadaApp>{
 String lang='prs';
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{final p=await SharedPreferences.getInstance();if(mounted)setState(()=>lang=p.getString('lang')??'prs');}
 Future<void> setLang(String v)async{final p=await SharedPreferences.getInstance();await p.setString('lang',v);if(mounted)setState(()=>lang=v);}
 @override Widget build(BuildContext context)=>MaterialApp(
  title:'QuranSada',debugShowCheckedModeBanner:false,locale:Locale(lang=='prs'?'fa':lang),
  supportedLocales:const [Locale('fa'),Locale('ps'),Locale('en')],
  localizationsDelegates:const [GlobalMaterialLocalizations.delegate,GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate],
  theme:ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF087E68)),scaffoldBackgroundColor:const Color(0xFFF4FAF6)),
  home:QuranHome(lang:lang,onLanguage:setLang));
}

class QuranHome extends StatefulWidget{
 final String lang; final ValueChanged<String> onLanguage;
 const QuranHome({super.key,required this.lang,required this.onLanguage});
 @override State<QuranHome> createState()=>_QuranHomeState();
}
class _QuranHomeState extends State<QuranHome>{
 int tab=0; String query=''; String reciter=reciters.first; final player=AudioPlayer();
 Set<int> favorites={}; int lastSurah=1;
 bool get rtl=>widget.lang!='en';
 String tr(String prs,String fa,String ps,String en)=>switch(widget.lang){'fa'=>fa,'ps'=>ps,'en'=>en,_=>prs};
 @override void initState(){super.initState();_loadPrefs();}
 Future<void> _loadPrefs()async{
  final p=await SharedPreferences.getInstance();if(!mounted)return;
  setState(()=>{favorites=(p.getStringList('favorites')??[]).map(int.parse).toSet(),lastSurah=p.getInt('lastSurah')??1,reciter=p.getString('reciter')??reciters.first});
 }
 Future<void> _toggleFavorite(int id)async{
  setState(()=>favorites.contains(id)?favorites.remove(id):favorites.add(id));
  final p=await SharedPreferences.getInstance();await p.setStringList('favorites',favorites.map((e)=>'$e').toList());
 }
 Future<void> _openSurah(Surah s)async{
  final p=await SharedPreferences.getInstance();await p.setInt('lastSurah',s.number);
  if(!mounted)return;
  Navigator.push(context,MaterialPageRoute(builder:(_)=>SurahScreen(surah:s,lang:widget.lang,reciter:reciter,player:player,isFavorite:favorites.contains(s.number),onFavorite:()=>_toggleFavorite(s.number))));
 }
 Future<void> _chooseReciter(String? v)async{if(v==null)return;setState(()=>reciter=v);final p=await SharedPreferences.getInstance();await p.setString('reciter',v);}
 @override void dispose(){player.dispose();super.dispose();}
 @override Widget build(BuildContext context){
  final shown=allSurahs.where((s)=>s.arabic.contains(query)||s.transliteration.toLowerCase().contains(query.toLowerCase())||s.number.toString()==query).toList();
  final list=tab==2?allSurahs.where((s)=>favorites.contains(s.number)).toList():shown;
  return Directionality(textDirection:rtl?TextDirection.rtl:TextDirection.ltr,child:Scaffold(
   appBar:AppBar(title:const Text('QuranSada • قرآن صدا',style:TextStyle(fontWeight:FontWeight.bold)),actions:[
    PopupMenuButton<String>(icon:const Icon(Icons.language),onSelected:widget.onLanguage,itemBuilder:(_)=>languages.map((l)=>PopupMenuItem(value:l,child:Text(languageNames[l]!))).toList())]),
   body:tab==3?_settings():tab==0?_home():_surahList(list),
   bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:[
    NavigationDestination(icon:const Icon(Icons.home_outlined),label:tr('خانه','خانه','کور','Home')),
    NavigationDestination(icon:const Icon(Icons.menu_book),label:tr('سوره‌ها','سوره‌ها','سورتونه','Surahs')),
    NavigationDestination(icon:const Icon(Icons.favorite_border),label:tr('علاقه‌مندی‌ها','علاقه‌مندی‌ها','خوښې','Favorites')),
    NavigationDestination(icon:const Icon(Icons.settings_outlined),label:tr('تنظیمات','تنظیمات','امستنې','Settings'))])));
 }
 Widget _home()=>ListView(padding:const EdgeInsets.all(16),children:[
  Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[Color(0xFF064E3B),Color(0xFF0D9675)])),child:Column(children:[
   const Icon(Icons.nightlight_round,color:Color(0xFFFFD66B),size:34),const SizedBox(height:8),
   const Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',style:TextStyle(color:Colors.white,fontSize:22),textAlign:TextAlign.center),
   const SizedBox(height:12),Text(tr('قرآن را با دل و جان بشنوید','قرآن را با دل و جان بشنوید','قرآن په مینه واورئ','Listen to the Holy Quran'),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:19)),
   Text(tr('تلاوت و ترجمه صوتی آفلاین','تلاوت و ترجمه صوتی آفلاین','آفلاین تلاوت او ژباړه','Offline recitation & translation'),style:const TextStyle(color:Colors.white70))])),
  const SizedBox(height:18),Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.play_arrow)),title:Text(tr('ادامه گوش‌دادن','ادامه گوش‌دادن','اورېدلو ته دوام','Continue listening')),subtitle:Text('${allSurahs[lastSurah-1].arabic} • ${allSurahs[lastSurah-1].transliteration}'),trailing:const Icon(Icons.chevron_right),onTap:()=>_openSurah(allSurahs[lastSurah-1]))),
  const SizedBox(height:14),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(tr('سوره‌ها','سوره‌ها','سورتونه','Surahs'),style:Theme.of(context).textTheme.titleLarge),TextButton(onPressed:()=>setState(()=>tab=1),child:Text(tr('همه سوره‌ها','همه سوره‌ها','ټول سورتونه','View all')))]),
  ...allSurahs.take(6).map(_surahTile),
  Text(tr('برای پخش، بسته صوتی مجاز باید در برنامه موجود باشد.','برای پخش، بسته صوتی مجاز باید در برنامه موجود باشد.','د غږیز پلې بیک لپاره باید مجاز آډیو بسته موجوده وي.','Licensed audio packs must be installed for playback.'),textAlign:TextAlign.center,style:const TextStyle(color:Colors.grey))
 ]);
 Widget _surahList(List<Surah> list)=>Column(children:[
  Padding(padding:const EdgeInsets.fromLTRB(16,8,16,4),child:TextField(textDirection:rtl?TextDirection.rtl:TextDirection.ltr,decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:tr('جستجوی سوره یا شماره','جستجوی سوره یا شماره','د سورت لټون','Search surah or number'),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14))),onChanged:(v)=>setState(()=>query=v.trim()))),
  Expanded(child:list.isEmpty?Center(child:Text(tr('موردی پیدا نشد','موردی پیدا نشد','څه ونه موندل شول','No results'))):ListView.builder(padding:const EdgeInsets.all(12),itemCount:list.length,itemBuilder:(_,i)=>_surahTile(list[i])))
 ]);
 Widget _surahTile(Surah s)=>Card(margin:const EdgeInsets.symmetric(vertical:5),child:ListTile(
  leading:CircleAvatar(backgroundColor:const Color(0xFFE0F2E9),child:Text('${s.number}',style:const TextStyle(color:Color(0xFF087E68)))),
  title:Text(s.arabic,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w600)),
  subtitle:Text('${s.transliteration} • ${s.ayahs} ${tr('آیه','آیه','آیتونه','ayahs')}'),
  trailing:Icon(favorites.contains(s.number)?Icons.favorite:Icons.chevron_right,color:favorites.contains(s.number)?Colors.redAccent:const Color(0xFF087E68)),
  onTap:()=>_openSurah(s),onLongPress:()=>_toggleFavorite(s.number)));
 Widget _settings()=>ListView(padding:const EdgeInsets.all(18),children:[
  Text(tr('تنظیمات','تنظیمات','امستنې','Settings'),style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:16),
  Text(tr('زبان رابط کاربری','زبان رابط کاربری','د اپ ژبه','Interface language')),
  ...languages.map((l)=>RadioListTile<String>(value:l,groupValue:widget.lang,title:Text(languageNames[l]!),onChanged:(v){if(v!=null)widget.onLanguage(v);})),
  const Divider(),Text(tr('قاری تلاوت','قاری تلاوت','د تلاوت قاري','Reciter')),
  DropdownButtonFormField<String>(value:reciter,items:reciters.map((r)=>DropdownMenuItem(value:r,child:Text(r))).toList(),onChanged:_chooseReciter),
  const SizedBox(height:18),Text(tr('زبان ترجمه صوتی مستقل از زبان منوها انتخاب می‌شود. فایل‌های صوتی ترجمه انسانی باید به‌صورت بسته‌های مجاز اضافه شوند.','زبان ترجمه صوتی مستقل از زبان منوها انتخاب می‌شود. فایل‌های صوتی ترجمه انسانی باید به‌صورت بسته‌های مجاز اضافه شوند.','د ژباړې ژبه له مینو څخه جلا ټاکل کېږي. د انساني غږ ژباړې باید د جواز لرونکو آډیو بستو په توګه ورزیاتې شي.','Translation language is selected separately from menus. Licensed human-voice translation packs still need to be added.'))
 ]);
}

class SurahScreen extends StatefulWidget{
 final Surah surah;final String lang,reciter;final AudioPlayer player;final bool isFavorite;final VoidCallback onFavorite;
 const SurahScreen({super.key,required this.surah,required this.lang,required this.reciter,required this.player,required this.isFavorite,required this.onFavorite});
 @override State<SurahScreen> createState()=>_SurahScreenState();
}
class _SurahScreenState extends State<SurahScreen>{
 bool translation=false,busy=false;String? error;
 bool get rtl=>widget.lang!='en';String tr(String prs,String en)=>widget.lang=='en'?en:prs;
 Future<void> play()async{
  setState(()=>{busy=true,error=null});
  try{
   final id=widget.surah.number.toString().padLeft(3,'0');
   final slug=switch(widget.reciter){'Abdul Rahman Al-Sudais'=>'sudais','Maher Al-Muaiqly'=>'muaiqly',_=>'alafasy'};
   final path=translation?'assets/audio/translations/${widget.lang}/surah_$id.mp3':'assets/audio/reciters/$slug/surah_$id.mp3';
   await widget.player.setAsset(path);await widget.player.play();
  }catch(_){setState(()=>error=tr('فایل صوتی این سوره هنوز نصب نشده است. بسته صوتی مجاز را اضافه کنید.','This surah audio file is not installed. Add a licensed audio pack.'));}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Directionality(textDirection:rtl?TextDirection.rtl:TextDirection.ltr,child:Scaffold(
  appBar:AppBar(title:Text(widget.surah.arabic),actions:[IconButton(onPressed:widget.onFavorite,icon:Icon(widget.isFavorite?Icons.favorite:Icons.favorite_border))]),
  body:ListView(padding:const EdgeInsets.all(20),children:[
   Text(widget.surah.transliteration,textAlign:TextAlign.center,style:Theme.of(context).textTheme.titleLarge),
   Text('${widget.surah.ayahs} ${tr('آیه','ayahs')}',textAlign:TextAlign.center),const SizedBox(height:24),
   SegmentedButton<bool>(segments:[ButtonSegment(value:false,label:Text(tr('تلاوت قرآن','Recitation')),icon:const Icon(Icons.menu_book)),ButtonSegment(value:true,label:Text(tr('ترجمه صوتی','Translation')),icon:const Icon(Icons.record_voice_over))],selected:{translation},onSelectionChanged:(s)=>setState(()=>translation=s.first)),
   const SizedBox(height:20),Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
    Icon(translation?Icons.record_voice_over:Icons.headphones,size:54,color:const Color(0xFF087E68)),const SizedBox(height:12),
    Text(translation?tr('ترجمه صوتی انسانی','Human-voice translation'):widget.reciter,textAlign:TextAlign.center,style:Theme.of(context).textTheme.titleMedium),
    const SizedBox(height:12),FilledButton.icon(onPressed:busy?null:play,icon:Icon(busy?Icons.hourglass_top:Icons.play_arrow),label:Text(tr('پخش آفلاین','Play offline'))),
    StreamBuilder<PlayerState>(stream:widget.player.playerStateStream,builder:(_,snap)=>IconButton(onPressed:()=>widget.player.pause(),icon:const Icon(Icons.pause_circle_outline,size:38))),
    if(error!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text(error!,textAlign:TextAlign.center,style:const TextStyle(color:Colors.red)))
   ]))),
   const SizedBox(height:14),Text(tr('یادآوری: متن کامل آیات و فایل‌های صوتی دارای مجوز باید در بسته داده‌های قرآن افزوده شوند. این نسخه فعلاً فهرست کامل سوره‌ها و چارچوب پخش را دارد.','Note: verified ayah text and licensed audio files must be added to the Quran data packs. This build currently includes the full surah catalog and audio-player framework.'),textAlign:TextAlign.center)
  ])));
}
