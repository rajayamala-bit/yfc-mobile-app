import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/bible_service.dart';
import '../services/content_service.dart';
import '../theme/app_theme.dart';

class OTBibleStudyExplorer extends StatefulWidget {
  const OTBibleStudyExplorer({super.key});

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimaryLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const OTBibleStudyExplorer(),
    );
  }

  @override
  State<OTBibleStudyExplorer> createState() => _OTBibleStudyExplorerState();
}

class _OTBibleStudyExplorerState extends State<OTBibleStudyExplorer> {
  final TextEditingController _searchController = TextEditingController();
  late List<BibleBook> _otBooks;
  late BibleBook _selectedBook;
  int _selectedChapter = 1;
  int _selectedVerse = 1;

  @override
  void initState() {
    super.initState();
    _otBooks = BibleService.getOldTestamentBooks();
    _selectedBook = _otBooks.firstWhere((b) => b.nameEn == "Genesis", orElse: () => _otBooks.first);
    _selectedChapter = 31;
    _selectedVerse = 3;
  }

  void _parseSearchQuery(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return;

    for (final book in _otBooks) {
      final nameEnLower = book.nameEn.toLowerCase();
      final nameTeLower = book.nameTe.toLowerCase();
      // Handle abbreviations e.g. Gen -> Genesis, Isa -> Isaiah, Ps -> Psalms
      final shortName = nameEnLower.length >= 3 ? nameEnLower.substring(0, 3) : nameEnLower;

      if (trimmed.contains(nameEnLower) || trimmed.contains(nameTeLower) || trimmed.startsWith(shortName)) {
        setState(() {
          _selectedBook = book;
        });

        // Extract chapter & verse numbers (e.g. "Isaiah 53:5" -> 53, 5)
        final regExp = RegExp(r'(\d+)[:\s]*(\d+)?');
        final match = regExp.firstMatch(trimmed.replaceAll(nameEnLower, '').replaceAll(shortName, ''));
        if (match != null) {
          final ch = int.tryParse(match.group(1) ?? '1') ?? 1;
          final v = int.tryParse(match.group(2) ?? '1') ?? 1;
          final versesList = BibleService.getVersesForChapter(book, ch);
          setState(() {
            _selectedChapter = ch.clamp(1, _selectedBook.totalChapters);
            _selectedVerse = v.clamp(1, versesList.isEmpty ? 1 : versesList.length);
          });
        }
        break;
      }
    }
  }

  String _getBiblicalInsightCommentary(BibleBook book, int chapter, int verse, bool isTelugu) {
    if (book.nameEn == "Genesis" && chapter == 1) {
      return isTelugu
          ? "ఆదికాండము 1:1 'ఆదియందు దేవుడు భూమ్యాకాశములను సృజించెను.' దేవుడు సమస్త సృష్టికి ఆదియై శూన్యము నుండి సృష్టిని సంకల్పించాడు. శూన్యతను వెలుగుతో నింపిన దేవుడు మీ జీవితాల్లో కూడా నూతన ప్రారంభాన్ని అనుగ్రహించును."
          : "Genesis 1:1 establishes God as the sovereign Creator of the universe. 'In the beginning God created the heavens and the earth.' God speaks light into darkness, establishing order, purpose, and divine design from eternity.";
    } else if (book.nameEn == "Genesis" && chapter == 31) {
      return isTelugu
          ? "ఆదికాండము 31:3 లో దేవుడు యాకోబుకు ప్రత్యక్షమై తన పితరుల దేశానికి తిరిగి వెళ్ళమని ఆజ్ఞాపించాడు. లాబాను హెచ్చరికను స్వప్నంలో ఇచ్చి యాకోబును రక్షించాడు. మిస్పా ఒడంబడిక ద్వారా దైవిక కాపలా నిరూపించబడింది."
          : "Genesis 31:3 reveals God's explicit covenant call to Jacob to return home. Even amidst Laban's hostility, God intervened in a dream by night to shield Jacob, sealing the Mizpah covenant: 'The LORD watch between me and thee when we are absent one from another.'";
    } else if (book.nameEn == "Isaiah" && chapter == 53) {
      return isTelugu
          ? "యెషయా 53వ అధ్యాయం మెస్సీయ రక్షణ త్యాగాన్ని ప్రవచించింది. 'మన అతిక్రమములనుబట్టి ఆయన గాయపరచబడెను, మన దౌర్జన్యములనుబట్టి నలుగగొట్టబడెను.' ఇది క్రీస్తు సిలువ త్యాగానికి ముందస్తు వాక్య నిదర్శనం."
          : "Isaiah 53 is the supreme Old Testament prophecy of the Suffering Servant. 'He was wounded for our transgressions, he was bruised for our iniquities.' It anticipates Christ's substitutionary atonement on the Cross.";
    } else if (book.nameEn == "Psalms" && chapter == 23) {
      return isTelugu
          ? "కీర్తన 23 దేవుని నమ్మకమైన కాపరిత్వానికి ప్రతీక. 'యెహోవా నా కాపరి, నాకు ఏ కొదువా కలుగదు.' క్లిష్టమైన పరిస్థితులలో కూడా దేవుని రక్షణ మరియు ఆశీర్వాదం నిరంతరం లభిస్తాయి."
          : "Psalm 23 depicts the intimacy of God's pastoral care. 'The LORD is my shepherd; I shall not want.' It reassures believers that even through dark valleys, His staff and rod provide divine comfort.";
    } else if (book.nameEn == "Proverbs" && chapter == 3) {
      return isTelugu
          ? "సామెతలు 3:5-6 'నీ పూర్ణహృదయముతో యెహోవాయందు నమ్మకముంచుము... అప్పుడు ఆయన నీ త్రోవలను సరాళము చేయును.' స్వబుద్ధిని ఆధారము చేసుకొనక దేవుని జ్ఞానమును ఆశ్రయించుటయే విజయం."
          : "Proverbs 3:5-6 presents the cornerstone of biblical guidance: 'Trust in the LORD with all thine heart; and lean not unto thine own understanding.' Acknowledge Him in all ways, and He shall direct thy paths.";
    } else {
      return isTelugu
          ? "${book.nameTe} $chapter:$verse — పాతనిబంధన గ్రంథ పరిశోధన ప్రకారం, ఈ వాక్యం దేవుని నిబంధన సంకల్పాన్ని మరియు రక్షణ ప్రణాళికను స్పష్టంగా తెలియజేస్తుంది. విశ్వాసులు దేవుని వాక్యమందు నమ్మకముంచవలెను."
          : "${book.nameEn} $chapter:$verse — In Old Testament Biblical scholarship, this passage underscores God's covenant sovereignty, calling youth to walk in righteousness, trust, and divine alignment.";
    }
  }

  String _getTopicImageForBook(BibleBook book) {
    switch (book.nameEn) {
      case "Genesis":
        return "https://images.unsplash.com/photo-1519817650390-64a93db51149?w=600";
      case "Exodus":
      case "Leviticus":
      case "Numbers":
      case "Deuteronomy":
        return "https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?w=600";
      case "Psalms":
      case "Proverbs":
        return "https://images.unsplash.com/photo-1447069387593-a5de0862481e?w=600";
      case "Isaiah":
      case "Jeremiah":
      case "Ezekiel":
      case "Daniel":
        return "https://images.unsplash.com/photo-1544967082-d9d25d867d66?w=600";
      default:
        return "https://images.unsplash.com/photo-1507499739999-097706ad8914?w=600";
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;
    final isDark = appState.isDarkMode;

    final safeBook = _selectedBook;
    final safeChapter = _selectedChapter.clamp(1, safeBook.totalChapters);
    final versesList = BibleService.getVersesForChapter(safeBook, safeChapter);

    BibleVerseData currentVerseData;
    if (versesList.isNotEmpty) {
      final safeIndex = (_selectedVerse - 1).clamp(0, versesList.length - 1);
      currentVerseData = versesList[safeIndex];
    } else {
      currentVerseData = const BibleVerseData(
        verseNumber: 1,
        textKjv: "In the beginning God created the heaven and the earth.",
        textNiv: "In the beginning God created the heavens and the earth.",
        textEsv: "In the beginning God created the heavens and the earth.",
        textTeBsi: "ఆదియందు దేవుడు భూమ్యాకాశములను సృజించెను.",
      );
    }

    final rawCommentary = _getBiblicalInsightCommentary(_selectedBook, _selectedChapter, _selectedVerse, isTelugu);
    final commentary = ContentService.sanitizeText(rawCommentary);
    final topicImgUrl = _getTopicImageForBook(_selectedBook);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modal Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.travel_explore_rounded, color: AppTheme.shiningRed, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    isTelugu ? "పాతనిబంధన అధ్యయన శోధన" : "OT Bible Study Explorer",
                    style: GoogleFonts.cinzel(
                      color: AppTheme.goldAccent,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Search Input Bar
          TextField(
            controller: _searchController,
            onSubmitted: _parseSearchQuery,
            style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 14),
            decoration: InputDecoration(
              hintText: isTelugu ? "ఉదా: యెషయా 53:5, ఆదికాండము 1:1 శోధించండి..." : "Quick search (e.g. Isaiah 53:5, Genesis 1:1)...",
              hintStyle: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.goldAccent),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.shiningRed),
                onPressed: () => _parseSearchQuery(_searchController.text),
              ),
              filled: true,
              fillColor: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Dropdowns Row: Book, Chapter, Verse
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Book Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
                  ),
                  child: DropdownButton<BibleBook>(
                    value: _selectedBook,
                    dropdownColor: isDark ? AppTheme.surfaceCardDark : Colors.white,
                    underline: const SizedBox(),
                    items: _otBooks.map((b) {
                      return DropdownMenuItem(
                        value: b,
                        child: Text(
                          isTelugu ? b.nameTe : b.nameEn,
                          style: TextStyle(
                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (book) {
                      if (book != null) {
                        setState(() {
                          _selectedBook = book;
                          _selectedChapter = 1;
                          _selectedVerse = 1;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Chapter Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedChapter,
                    dropdownColor: isDark ? AppTheme.surfaceCardDark : Colors.white,
                    underline: const SizedBox(),
                    items: List.generate(_selectedBook.totalChapters, (i) => i + 1).map((ch) {
                      return DropdownMenuItem(
                        value: ch,
                        child: Text("Ch $ch", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.shiningRed)),
                      );
                    }).toList(),
                    onChanged: (ch) {
                      if (ch != null) {
                        setState(() {
                          _selectedChapter = ch;
                          _selectedVerse = 1;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Verse Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedVerse,
                    dropdownColor: isDark ? AppTheme.surfaceCardDark : Colors.white,
                    underline: const SizedBox(),
                    items: List.generate(versesList.length, (i) => i + 1).map((v) {
                      return DropdownMenuItem(
                        value: v,
                        child: Text("Ver $v", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.goldAccent)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedVerse = v);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scripture & Commentary Body Card
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.goldAccent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shiningRed.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topic Featured Banner Image
                    Image.network(
                      topicImgUrl,
                      height: 135,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: isDark ? Colors.grey[850] : Colors.pink[50],
                        child: const Center(
                          child: Icon(Icons.menu_book_rounded, color: AppTheme.goldAccent, size: 40),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Portion Header Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.goldAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.goldAccent, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bookmark_rounded, color: AppTheme.goldAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "${isTelugu ? _selectedBook.nameTe : _selectedBook.nameEn} $_selectedChapter:$_selectedVerse",
                                  style: GoogleFonts.cinzel(
                                    color: const Color(0xFFB8860B), // Bold metallic gold
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Scripture Box (Indented Devotional Quote Block with Light Gold Border)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2219) : const Color(0xFFFFF9E6), // Light warm gold quote box
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.goldAccent, width: 1.4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldAccent.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.format_quote_rounded, color: AppTheme.goldAccent, size: 22),
                                    const SizedBox(width: 6),
                                    Text(
                                      isTelugu ? "గ్రంథ వాక్యం" : "HOLY SCRIPTURE",
                                      style: GoogleFonts.cinzel(
                                        color: AppTheme.shiningRed,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // English Scripture (Italicized Devotional Quote)
                                Text(
                                  "“${currentVerseData.textKjv}”",
                                  style: GoogleFonts.inter(
                                    color: isDark ? AppTheme.textLight : const Color(0xFF111111),
                                    fontSize: 14.5,
                                    fontStyle: FontStyle.italic,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Telugu Scripture
                                Text(
                                  "“${currentVerseData.textTeBsi}”",
                                  style: GoogleFonts.notoSansTelugu(
                                    color: const Color(0xFFB8860B),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          Divider(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                          const SizedBox(height: 14),

                          // 3. BIBLICAL INSIGHTS Commentary Header & Body
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: AppTheme.goldAccent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isTelugu ? "బైబిల్ వ్యాఖ్యాన సత్యాలు" : "BIBLICAL INSIGHTS",
                                style: GoogleFonts.cinzel(
                                  color: const Color(0xFFB8860B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // High-contrast clean commentary prose
                          Text(
                            commentary,
                            style: TextStyle(
                              color: isDark ? AppTheme.textLight : const Color(0xFF000000), // High-contrast deep black in light mode
                              fontSize: 14,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
