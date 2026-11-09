import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

class ContentArticle {
  final String id;
  final String titleEn;
  final String titleTe;
  final String category; // "ARCHAEOLOGY", "DISCOVERY", "DEVOTIONAL", "YFC FELLOWSHIP", "SCRIPTURE STUDY", "BIBLICAL NEWS"
  final String sourceName;
  final String summaryEn;
  final String summaryTe;
  final String fullContentEn;
  final String fullContentTe;
  final String publishDate;
  final String imageUrl;

  const ContentArticle({
    required this.id,
    required this.titleEn,
    required this.titleTe,
    required this.category,
    required this.sourceName,
    required this.summaryEn,
    required this.summaryTe,
    required this.fullContentEn,
    required this.fullContentTe,
    required this.publishDate,
    required this.imageUrl,
  });
}

class ContentService {
  static final HtmlUnescape _unescape = HtmlUnescape();

  static const List<ContentArticle> articles = [
    // 1. ARCHAEOLOGY / BIBLICAL NEWS
    ContentArticle(
      id: "news-1",
      titleEn: "Ancient Olive Trees of Gethsemane Dated to Biblical Times",
      titleTe: "గెత్సెమనేలోని ప్రాచీన ఒలీవ చెట్లు బైబిల్ కాలానికి చెందినవని పురావస్తు పరిశోధనలు వెల్లడి",
      category: "ARCHAEOLOGY",
      sourceName: "Israel Antiquities Authority",
      summaryEn: "Scientific carbon-dating of ancient olive trees in the Mount of Olives confirms root systems tracing directly to the Second Temple era.",
      summaryTe: "ఒలీవల కొండపై ఉన్న ఒలీవ చెట్ల కార్బన్ డేటింగ్ పరీక్షలు అవి రెండో దేవాలయ కాలానికి చెందినవని నిర్ధారించాయి.",
      fullContentEn: '''
JERUSALEM — Botanical and radio-carbon research conducted by the National Research Council of Italy has confirmed that the ancient olive trees in the Garden of Gethsemane on the Mount of Olives date back nearly two millennia.

Genetic testing of the root systems revealed that all eight ancient trees share identical DNA, indicating they were cultivated from a single parent tree lineage preserved since biblical times.

This remarkable scientific confirmation brings tangible connection to the sacred events recorded in the Gospels.
''',
      fullContentTe: '''
యెరూషలేము — ఒలీవల కొండపై గెత్సెమనే తోటలో ఉన్న ప్రాచీన ఒలీవ చెట్లు రెండు వేల సంవత్సరాల నాటివని ఇటలీ జాతీయ పరిశోధనా మండలి నిర్ధారించింది.

ఈ చెట్ల వేరు వ్యవస్థల డీఎన్ఏ పరీక్షల ద్వారా ఇవన్నీ ఒకే ప్రాచీన తల్లి చెట్టు నుండి పెరిగినవని తేలింది.
''',
      publishDate: "Today • Archaeology Update",
      imageUrl: "assets/images/news_olive_trees.jpg",
    ),

    // 2. DISCOVERY
    ContentArticle(
      id: "news-2",
      titleEn: "2,000-Year-Old Coin Found in Jerusalem Temple Mount Sifting Project",
      titleTe: "యెరూషలేము దేవాలయ పర్వతం వద్ద 2,000 సంవత్సరాల నాటి ప్రాచీన నాణెం కనుగొనబడింది",
      category: "DISCOVERY",
      sourceName: "Temple Mount Sifting Project",
      summaryEn: "Volunteers discovered a rare silver half-shekel coin inscribed with 'Holy Jerusalem' dating back to the Jewish Great Revolt era.",
      summaryTe: "యెరూషలేము తవ్వకాలలో 'పరిశుద్ధ యెరూషలేము' అని చెక్కబడిన ప్రాచీన వెండి నాణెం వెలికితీశారు.",
      fullContentEn: '''
JERUSALEM — Archaeologists and volunteers with the Temple Mount Sifting Project revealed a pristine silver coin minted in Jerusalem over two thousand years ago.

The coin features ancient Hebrew inscription reading "Half Shekel" on one side and "Holy Jerusalem" surrounding a branch of three pomegranates on the reverse.

Dr. Gabriel Barkay remarked: "Coins of this caliber were used to pay the annual Temple tribute during the time of Christ and the Apostles."
''',
      fullContentTe: '''
యెరూషలేము — ప్రాచీన దేవాలయ పర్వత ప్రాంత తవ్వకాలలో రెండు వేల సంవత్సరాల క్రితం ముద్రించిన అరుదైన వెండి నాణెం బయటపడింది.
''',
      publishDate: "Today • Jerusalem Discovery",
      imageUrl: "assets/images/news_ancient_coin.jpg",
    ),

    // 3. DEVOTIONAL
    ContentArticle(
      id: "news-3",
      titleEn: "The Power of Midnight Prayers: Acts 16 Breakthrough",
      titleTe: "అర్ధరాత్రి ప్రార్థనల శక్తి: అపొస్తలుల కార్యములు 16 లో అద్భుత రక్షణ",
      category: "DEVOTIONAL",
      sourceName: "YFC Daily Devotional",
      summaryEn: "How Paul and Silas turned a Roman dungeon into a sanctuary of praise at midnight, opening prison doors and transforming lives.",
      summaryTe: "అర్ధరాత్రి వేళ పౌలు మరియు సీలల ప్రార్థన కీర్తనలు చెరసాల తలుపులను ఎలా తెరిచాయో వివరించే దైవిక వర్తమానం.",
      fullContentEn: '''
PHILIPPI — "About midnight Paul and Silas were praying and singing hymns to God, and the other prisoners were listening to them" (Acts 16:25).

Key Spiritual Lessons:
1. Praise in Darkness: True spiritual strength is praised not when circumstances are easy, but when midnight trials test our faith.
2. Earthshaking Breakthrough: Divine intervention broke every chain, not only setting the apostles free but saving the jailer and his household.
3. Eternal Impact: Unshakeable faith in hardship serves as a powerful witness to those watching around us.
''',
      fullContentTe: '''
ఫిలిప్పి — "అర్ధరాత్రి వేళ పౌలును సీలయు ప్రార్థించుచు దేవుని సంకీర్తనలు పాడుచునుండిరి... భూకంపము కలిగి చెరసాల పునాదులు అదిరెను."
''',
      publishDate: "Acts 16 • Daily Devotional",
      imageUrl: "assets/images/news_prayer.jpg",
    ),

    // 4. YFC FELLOWSHIP
    ContentArticle(
      id: "news-4",
      titleEn: "Weekly Youth Bible Quiz Champions Announced",
      titleTe: "వారాంతపు యువత బైబిల్ క్విజ్ విజేతల ప్రకటన",
      category: "YFC FELLOWSHIP",
      sourceName: "Youth For Christ Fellowship",
      summaryEn: "Congratulations to the winners of this week's Bilingual Scripture Challenge on Genesis & Matthew chapters!",
      summaryTe: "ఈ వారం జరిగిన ఆదికాండము మరియు మత్తయి సువార్త క్విజ్ విజేతలకు శుభాకాంక్షలు!",
      fullContentEn: '''
YFC FELLOWSHIP NEWS — Youth For Christ announced the top scorers of the weekly scripture quiz. Hundreds of young believers participated across Telugu and English fellowships.

Highlights:
- 1st Place: David Raju (100% Score)
- 2nd Place: Ruth Grace (98% Score)
- 3rd Place: Emmanuel Paul (95% Score)

"Thy word have I hid in mine heart, that I might not sin against thee" (Psalm 119:11).
''',
      fullContentTe: '''
YFC వార్తలు — ఈ వారం బైబిల్ క్విజ్ పోటీలో పాల్గొని విజేతలుగా నిలిచిన యువతకు YFC టీమ్ శుభాకాంక్షలు తెలియజేస్తోంది.
''',
      publishDate: "YFC • Youth Fellowship",
      imageUrl: "assets/images/news_jerusalem.jpg",
    ),

    // 5. SCRIPTURE STUDY
    ContentArticle(
      id: "news-5",
      titleEn: "Understanding the Septuagint & Hebrew Roots",
      titleTe: "సెప్టువ్యాజింట్ (LXX) మరియు హెబ్రీ మూలాల అధ్యయనం",
      category: "SCRIPTURE STUDY",
      sourceName: "Biblical Languages Academy",
      summaryEn: "Discovering how the ancient Greek Septuagint translation bridged the Old and New Testaments during the Apostolic Age.",
      summaryTe: "పాత నిబంధన హెబ్రీ గ్రంథములు గ్రీకు భాషలోకి తర్జుమా చేయబడిన సెప్టువ్యాజింట్ ప్రాముఖ్యత.",
      fullContentEn: '''
SCRIPTURE STUDY — The Septuagint (LXX) represents the earliest Greek translation of the Hebrew Old Testament, translated in Alexandria, Egypt during the 3rd century BC.

Key Historical Facts:
1. Apostolic Usage: The Apostles and New Testament writers frequently quoted directly from the Septuagint.
2. Bridge of Nations: It opened the treasures of Hebrew Scriptures to the entire Greco-Roman world.
3. Messianic Clarity: Prophecies such as Isaiah 7:14 ('virgin shall conceive') were preserved with clear theological precision.
''',
      fullContentTe: '''
వాక్య అధ్యయనం — సెప్టువ్యాజింట్ (LXX) క్రీస్తుపూర్వం 3వ శతాబ్దంలో హెబ్రీ పాత నిబంధన నుండి గ్రీకు భాషలోకి అనువదించబడిన ప్రాచీన గ్రంథం.
''',
      publishDate: "Biblical Hermeneutics",
      imageUrl: "assets/images/news_scroll.jpg",
    ),
  ];

  static ContentArticle getArticleById(String id) {
    return articles.firstWhere((a) => a.id == id, orElse: () => articles.first);
  }

  static Future<List<ContentArticle>> fetchBiblicalNewsRss() async {
    try {
      final feedUrls = [
        'https://israel365news.com/category/biblical-news/feed/',
        'https://theisraelbible.com/feed/',
      ];

      for (final url in feedUrls) {
        try {
          final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
          if (res.statusCode == 200 && res.body.contains('<item>')) {
            final parsedItems = _parseRssXml(res.body);
            if (parsedItems.isNotEmpty) {
              return parsedItems;
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return articles;
  }

  static List<ContentArticle> _parseRssXml(String xmlString) {
    final List<ContentArticle> list = [];
    final itemMatches = RegExp(r'<item>(.*?)</item>', dotAll: true).allMatches(xmlString);

    int count = 0;
    for (final match in itemMatches) {
      if (count >= 5) break;
      final itemBlock = match.group(1) ?? '';

      final titleMatch = RegExp(r'<title>(.*?)</title>', dotAll: true).firstMatch(itemBlock);
      final rawTitle = sanitizeText(titleMatch?.group(1) ?? 'Biblical News Update');

      final pubDateMatch = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true).firstMatch(itemBlock);
      final rawPubDate = _formatDate(sanitizeText(pubDateMatch?.group(1) ?? 'Latest'));

      final descMatch = RegExp(r'<description>(.*?)</description>', dotAll: true).firstMatch(itemBlock);
      final rawDesc = sanitizeText(descMatch?.group(1) ?? '');

      final contentMatch = RegExp(r'<content:encoded>(.*?)</content:encoded>', dotAll: true).firstMatch(itemBlock);
      final rawContent = sanitizeText(contentMatch?.group(1) ?? rawDesc);

      String imgUrl = _extractImageUrl(itemBlock);

      final cleanSummary = rawDesc.isNotEmpty
          ? (rawDesc.length > 140 ? "${rawDesc.substring(0, 140)}..." : rawDesc)
          : (rawContent.length > 140 ? "${rawContent.substring(0, 140)}..." : rawContent);

      list.add(ContentArticle(
        id: "rss-$count",
        titleEn: rawTitle,
        titleTe: rawTitle,
        category: "BIBLICAL NEWS",
        sourceName: "Israel365 News",
        summaryEn: cleanSummary,
        summaryTe: cleanSummary,
        fullContentEn: rawContent.isNotEmpty ? rawContent : cleanSummary,
        fullContentTe: rawContent.isNotEmpty ? rawContent : cleanSummary,
        publishDate: rawPubDate,
        imageUrl: imgUrl,
      ));
      count++;
    }

    return list;
  }

  static String _extractImageUrl(String itemBlock) {
    final mediaContentMatch = RegExp('<media:content[^>]+url=["\']([^"\']+)["\']', caseSensitive: false).firstMatch(itemBlock);
    if (mediaContentMatch != null && mediaContentMatch.group(1) != null) return mediaContentMatch.group(1)!;

    final mediaThumbMatch = RegExp('<media:thumbnail[^>]+url=["\']([^"\']+)["\']', caseSensitive: false).firstMatch(itemBlock);
    if (mediaThumbMatch != null && mediaThumbMatch.group(1) != null) return mediaThumbMatch.group(1)!;

    final enclosureMatch = RegExp('<enclosure[^>]+url=["\']([^"\']+)["\']', caseSensitive: false).firstMatch(itemBlock);
    if (enclosureMatch != null && enclosureMatch.group(1) != null) return enclosureMatch.group(1)!;

    final imgTagMatch = RegExp('<img[^>]+src=["\']([^"\']+)["\']', caseSensitive: false).firstMatch(itemBlock);
    if (imgTagMatch != null && imgTagMatch.group(1) != null) return imgTagMatch.group(1)!;

    final fallbackMatch = RegExp(r'https?://[^\s"<>]+\.(?:jpg|jpeg|png|webp)', caseSensitive: false).firstMatch(itemBlock);
    if (fallbackMatch != null) return fallbackMatch.group(0)!;

    return "https://images.unsplash.com/photo-1544967082-d9d25d867d66?w=600";
  }

  static String sanitizeText(String text) {
    if (text.isEmpty) return '';

    // 1. Strip CDATA wrappers (<![CDATA[...]]>)
    var s = text.replaceAll(RegExp(r'<!\[CDATA\[|\]\]>', caseSensitive: false), '');

    // 2. Unescape HTML entities (&amp;, &quot;, &#39;, &nbsp;, &lt;, &gt;, etc.)
    s = _unescape.convert(s);

    s = s
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&ndash;', '-')
        .replaceAll('&mdash;', '—');

    // Decimal numeric HTML entities &#123;
    s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1) ?? '');
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    });

    // Hex numeric HTML entities &#x1F600;
    s = s.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      final code = int.tryParse(match.group(1) ?? '', radix: 16);
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    });

    // 3. Completely strip all HTML tags & residual entity markers with RegExp(r'<[^>]*>|&[^;]+;')
    s = s.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');

    // 4. Strip standalone URLs and normalize whitespace
    s = s.replaceAll(RegExp(r'https?://[^\s]+'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  static String _formatDate(String rawDate) {
    if (rawDate.length > 16) {
      return rawDate.substring(0, 16);
    }
    return rawDate;
  }

  static const List<DailyPromiseVerse> promises = [
    DailyPromiseVerse(
      reference: "Jeremiah 29:11",
      textEn: "For I know the plans I have for you,” declares the LORD, “plans to prosper you and not to harm you, plans to give you hope and a future.",
      textTe: "ఏలననగా నేను మిమ్మునుగూర్చి ఉద్దేశించిన తలంపులను నేనెరుగుదును, అవి సమాధానకరమైన తలంపులే గాని హానికరమైనవి కావు, మీకు భావికాలమునందు నిరీక్షణకలుగునట్లుగా—యెహోవా సెలవిచ్చుచున్నాడు.",
    ),
    DailyPromiseVerse(
      reference: "Isaiah 41:10",
      textEn: "Fear thou not; for I am with thee: be not dismayed; for I am thy God: I will strengthen thee; yea, I will help thee; yea, I will uphold thee with the right hand of my righteousness.",
      textTe: "నీవు భయపడకుము నేను నీకు తోడైయున్నాను, దిగులుపడకుము నేను నీ దేవుడనై యున్నాను; నేను నిన్ను బలపరచుదును నీకు సహాయము చేయువాడను నేనే.",
    ),
    DailyPromiseVerse(
      reference: "Philippians 4:19",
      textEn: "But my God shall supply all your need according to his riches in glory by Christ Jesus.",
      textTe: "కాగా దేవుడు తన ఐశ్వర్యము చొప్పున క్రీస్తుయేసునందు మహిమలో మీ ప్రతి అవసరమును తీర్చును.",
    ),
    DailyPromiseVerse(
      reference: "Psalm 23:1",
      textEn: "The LORD is my shepherd; I shall not want.",
      textTe: "యెహోవా నా కాపరి, నాకు ఏ కొదువా కలుగదు.",
    ),
    DailyPromiseVerse(
      reference: "Proverbs 3:5-6",
      textEn: "Trust in the LORD with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths.",
      textTe: "నీ పూర్ణహృదయముతో యెహోవాయందు నమ్మకముంచుము, నీ స్వబుద్ధిని ఆధారము చేసుకొన‌కుము; నీ ప్రవర్తన అంతటియందు ఆయన అధికారమునకు ఒప్పుకొనుము.",
    ),
    DailyPromiseVerse(
      reference: "Joshua 1:9",
      textEn: "Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.",
      textTe: "నిబ్బరముగలిగి ధైర్యముగా నుండుము; భయపడకుము దిగులుపడకుము, నీవు వెళ్లు ప్రతిస్థలమున నీ దేవుడైన యెహోవా నీకు తోడైయుండును.",
    ),
    DailyPromiseVerse(
      reference: "Romans 8:28",
      textEn: "And we know that all things work together for good to them that love God, to them who are the called according to his purpose.",
      textTe: "దేవుని ప్రేమించువారికి, అనగా ఆయన సంకల్పముచొప్పున పిలువబడినవారికి, సమస్తమును సమకూడి మేలుకలుగుటకై జరుగుచున్నవని యెరుగుదుము.",
    ),
    DailyPromiseVerse(
      reference: "Psalm 46:1",
      textEn: "God is our refuge and strength, a very present help in trouble.",
      textTe: "దేవుడు మనకు ఆశ్రయమును బలమునై యున్నాడు, ఆపత్కాలములో ఆయన నమ్మకమైన సహాయకుడు.",
    ),
    DailyPromiseVerse(
      reference: "Matthew 11:28",
      textEn: "Come unto me, all ye that labour and are heavy laden, and I will give you rest.",
      textTe: "ప్రయాసపడి భారము మోసుకొనుచున్న సమస్తజనులారా, నా యొద్దకు రండి, నేను మీకు విశ్రాంతి కలుగజేతును.",
    ),
    DailyPromiseVerse(
      reference: "Isaiah 40:31",
      textEn: "But they that wait upon the LORD shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary; and they shall walk, and not faint.",
      textTe: "యెహోవాకొరకు ఎదురుచూచువారు నూతన బలము పొందుదురు, వారు పక్షిరాజులవలె రెక్కలు చాచి పైకి ఎగురుదురు, అలయక పరుగెత్తుదురు సొమ్మసిల్లక నడిచిపోవుదురు.",
    ),
  ];

  static DailyPromiseVerse getTodayPromise() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return promises[dayOfYear % promises.length];
  }
}

class DailyPromiseVerse {
  final String reference;
  final String textEn;
  final String textTe;

  const DailyPromiseVerse({
    required this.reference,
    required this.textEn,
    required this.textTe,
  });
}
