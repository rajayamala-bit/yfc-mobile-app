import 'bible_engine_service.dart';

class TeluguBibleService {
  static Future<void> loadBible() async {
    await BibleEngineService.initialize();
  }

  static Future<List<Map<String, dynamic>>> getVerses(int bookId, int chapterNum) async {
    final engineVerses = await BibleEngineService.getChapterVerses(bookId, chapterNum);
    return engineVerses.map((v) => {
      'verse_num': v.verseNumber,
      'text': v.textTelugu,
      'text_en': v.textKjv,
    }).toList();
  }
}
