import 'package:cloud_firestore/cloud_firestore.dart';
import 'content_service.dart';

class NewsItem {
  final String id;
  final String title;
  final String category;
  final String pubDate;
  final String imageUrl;
  final String link;
  final String snippet;
  final String fullContent;
  final String sourceName;

  NewsItem({
    required this.id,
    required this.title,
    required this.category,
    required this.pubDate,
    required this.imageUrl,
    required this.link,
    required this.snippet,
    required this.fullContent,
    required this.sourceName,
  });

  factory NewsItem.fromFirestore(Map<String, dynamic> data, String id) {
    final rawSnippet = data['snippet'] ?? '';
    final rawFullContent = data['fullContent'] ?? rawSnippet;
    return NewsItem(
      id: id,
      title: ContentService.sanitizeText(data['title'] ?? ''),
      category: data['category'] ?? 'ISRAEL & WAR UPDATE',
      pubDate: data['pubDate'] ?? 'Today',
      imageUrl: data['imageUrl'] ?? '',
      link: data['link'] ?? 'https://israel365news.com',
      snippet: ContentService.sanitizeText(rawSnippet),
      fullContent: ContentService.sanitizeText(rawFullContent),
      sourceName: data['sourceName'] ?? 'Israel & Bible Update',
    );
  }
}

class NewsFeedService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final List<NewsItem> localFallbackNews = [
    NewsItem(
      id: 'card-1',
      title: 'Ancient Olive Trees of Gethsemane Dated to Biblical Times',
      category: 'ARCHAEOLOGY',
      pubDate: 'Garden of Gethsemane',
      imageUrl: 'assets/images/carousel/gethsemane.jpg',
      link: 'https://israel365news.com',
      snippet: 'Botanical and carbon dating confirms olive tree roots date directly to Second Temple times.',
      fullContent: 'Botanical research confirms that the ancient olive trees in the Garden of Gethsemane date back nearly two millennia.',
      sourceName: 'Jerusalem Archaeology',
    ),
    NewsItem(
      id: 'card-2',
      title: '2,000-Year-Old Coin Found in Jerusalem Temple Mount Project',
      category: 'DISCOVERY',
      pubDate: 'Temple Mount Sifting Project',
      imageUrl: 'assets/images/carousel/biblical_coin.jpg',
      link: 'https://israel365news.com',
      snippet: 'A pristine silver shekel inscribed with ancient Hebrew script unearthed in Jerusalem.',
      fullContent: 'Archaeologists discovered an authentic ancient silver coin minted in Jerusalem during the Great Revolt era.',
      sourceName: 'Temple Mount Project',
    ),
    NewsItem(
      id: 'card-3',
      title: 'Israel Ingathering & Prophetic Scripture Updates',
      category: 'ISRAEL & WAR UPDATE',
      pubDate: 'Jerusalem Skyline',
      imageUrl: 'assets/images/carousel/jerusalem.jpg',
      link: 'https://israel365news.com',
      snippet: 'Prophetic developments unfold across the historic hills of Judea and Jerusalem.',
      fullContent: 'Communities and pilgrims gather across Jerusalem in fulfillment of ancient prophetic promises.',
      sourceName: 'Israel Heritage',
    ),
    NewsItem(
      id: 'card-4',
      title: 'The Power of Midnight Prayers: Acts 16 Breakthrough',
      category: 'DEVOTIONAL',
      pubDate: 'Daily Word',
      imageUrl: 'assets/images/carousel/prayer.jpg',
      link: 'https://israel365news.com',
      snippet: 'How midnight praise unlocked prison chains and continues to bring spiritual victory.',
      fullContent: 'About midnight Paul and Silas were praying and singing hymns to God, opening prison doors.',
      sourceName: 'YFC Devotional',
    ),
    NewsItem(
      id: 'card-5',
      title: 'Preserving Sacred Scripture & Ancient Hebrew Texts',
      category: 'SCRIPTURE STUDY',
      pubDate: 'Scripture Academy',
      imageUrl: 'assets/images/carousel/scripture.jpg',
      link: 'https://israel365news.com',
      snippet: 'Exploring the historical preservation of ancient Hebrew scrolls and biblical translations.',
      fullContent: 'The Septuagint and ancient scrolls bridged Hebrew Scriptures to the nations.',
      sourceName: 'Biblical Languages',
    ),
  ];

  static Future<List<NewsItem>> getWhatsNew({bool forceRefresh = false}) async {
    try {
      final snapshot = await _firestore
          .collection('whats_new')
          .orderBy('order')
          .limit(5)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 4));

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => NewsItem.fromFirestore(doc.data(), doc.id))
            .toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print("Firestore news fetch failed: $e. Serving local fallback.");
    }
    return localFallbackNews;
  }

  static Future<List<NewsItem>> fetchLatestNews({bool forceRefresh = false}) => getWhatsNew(forceRefresh: forceRefresh);
}
