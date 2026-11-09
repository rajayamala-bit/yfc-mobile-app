import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/bible_engine_service.dart';
import '../services/bible_service.dart';
import '../theme/app_theme.dart';
import 'berean_ai_widget.dart';
import 'floating_bubbles_background.dart';
import 'status_card_generator.dart';

enum BibleTranslationMode { teluguBsi, englishKjv, parallel, interlinear }

class BibleReaderWidget extends StatefulWidget {
  const BibleReaderWidget({super.key});

  @override
  State<BibleReaderWidget> createState() => _BibleReaderWidgetState();
}

class _BibleReaderWidgetState extends State<BibleReaderWidget> {
  BibleBook _selectedBook = BibleService.books.first; // Genesis / ఆదికాండము
  int _selectedChapter = 1;
  double _fontSize = 17.0; // Reading Font Size
  int? _selectedVerseNum; // Highlighted Verse Number
  BibleTranslationMode _translationMode = BibleTranslationMode.teluguBsi;

  final ScrollController _scrollController = ScrollController();
  late Future<List<BibleEngineVerse>> _versesFuture;
  bool _isLoading = false;
  List<Map<String, dynamic>> _currentVerses = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get currentVerses => _currentVerses;

  Future<void> _loadChapterVerses(int bookId, int chapter) async {
    setState(() => _isLoading = true);
    final verses = await BibleEngineService.getVerses(bookId, chapter);
    if (!mounted) return;
    setState(() {
      _currentVerses = verses;
      _isLoading = false;
    });
  }

  void _loadVerses() {
    _versesFuture = BibleEngineService.getChapterVerses(_selectedBook.id, _selectedChapter);
    _loadChapterVerses(_selectedBook.id, _selectedChapter);
  }

  @override
  void initState() {
    super.initState();
    _selectedBook = BibleService.getBookById(1);
    _selectedChapter = 1;
    _loadVerses();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // Unified Book & Chapter Selector Modal Bottom Sheet
  void _openBookAndChapterSelectorModal(BuildContext context, bool isTelugu, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimaryLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _BookChapterSelectorSheet(
          initialBook: _selectedBook,
          initialChapter: _selectedChapter,
          isTelugu: isTelugu,
          isDark: isDark,
          onChapterSelected: (book, chapter) {
            setState(() {
              _selectedBook = book;
              _selectedChapter = chapter;
              _selectedVerseNum = null;
              _loadVerses();
            });
            Provider.of<AppState>(context, listen: false).updateBiblePassage(book.id, chapter);
            _scrollToTop();
          },
        );
      },
    );
  }

  void _showVerseQuickActionsModal(BuildContext context, BibleEngineVerse verse, String citation, bool isTelugu, bool isDark) {
    final textToCopy = "$citation\nTelugu: ${verse.textTelugu}\nEnglish (KJV): ${verse.textKjv}";

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.surfaceCardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 12),
                Text(
                  citation,
                  style: GoogleFonts.cinzel(
                    color: AppTheme.goldAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: AppTheme.goldAccent),
                  title: Text(isTelugu ? "వాక్యాన్ని కాపీ చేయండి" : "Copy Verse Text"),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: textToCopy));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isTelugu ? "వాక్యం కాపీ చేయబడింది!" : "Verse copied to clipboard!"),
                        backgroundColor: AppTheme.shiningRed,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_rounded, color: AppTheme.shiningRed),
                  title: Text(isTelugu ? "9:16 సోషల్ పోస్టర్ రూపొందించండి" : "Generate 9:16 Share Poster"),
                  onTap: () {
                    Navigator.pop(context);
                    StatusCardGenerator.show(
                      context,
                      verseReference: citation,
                      verseTextEn: verse.textKjv,
                      verseTextTe: verse.textTelugu,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded, color: AppTheme.goldAccent),
                  title: Text(isTelugu ? "బెరియన్ AI ని వివరణ అడగండి" : "Ask Berean AI about this verse"),
                  onTap: () {
                    Navigator.pop(context);
                    final verseText = isTelugu ? verse.textTelugu : verse.textKjv;
                    final verseQuery = "Explain $citation in depth: \"$verseText\"";
                    _openBereanAiForVerse(
                      context,
                      verseQuery,
                      isTelugu ? 'Telugu' : 'English',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openBereanAiForVerse(BuildContext context, String initialQuery, String preferredLanguage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BereanAiWidget(
              initialQuery: initialQuery,
              preferredLanguage: preferredLanguage,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;
    final isDark = appState.isDarkMode;

    if (appState.selectedBibleBookId != _selectedBook.id || appState.selectedBibleChapter != _selectedChapter) {
      _selectedBook = BibleService.getBookById(appState.selectedBibleBookId);
      _selectedChapter = appState.selectedBibleChapter.clamp(1, _selectedBook.totalChapters);
      _loadVerses();
    }

    final safeBook = _selectedBook;
    final safeChapter = _selectedChapter.clamp(1, safeBook.totalChapters);
    final selectorTitle = "${safeBook.nameTe} (${safeBook.nameEn}) • Ch $safeChapter";

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimaryLight,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _openBookAndChapterSelectorModal(context, isTelugu, isDark),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E0B1B),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFFFFD700), size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  selectorTitle,
                  style: GoogleFonts.notoSansTelugu(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.goldAccent, size: 24),
              ],
            ),
          ),
        ),
      ),
      body: FloatingBubblesBackground(
        child: FutureBuilder<List<BibleEngineVerse>>(
          future: _versesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFD4AF37),
                ),
              );
            }

            final versesList = snapshot.data ?? [];

            return Column(
              children: [
                // Top Control Bar: Unified Translation Switcher Toolbar & Font Resizer (A- / A+)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _modeChip(BibleTranslationMode.teluguBsi, "తెలుగు (BSI)", isDark),
                        const SizedBox(width: 8),
                        _modeChip(BibleTranslationMode.englishKjv, "English (KJV)", isDark),
                        const SizedBox(width: 8),
                        _modeChip(BibleTranslationMode.parallel, "Parallel", isDark),
                        const SizedBox(width: 8),
                        _modeChip(BibleTranslationMode.interlinear, "Interlinear", isDark),
                        const SizedBox(width: 12),
                        // Reading Font Size Adjuster (A- / A+)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.goldAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _fontSize = (_fontSize - 1.5).clamp(13.0, 30.0);
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  child: Text("A-", style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                              Text(
                                "${_fontSize.toInt()}pt",
                                style: TextStyle(
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _fontSize = (_fontSize + 1.5).clamp(13.0, 30.0);
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  child: Text("A+", style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Full-Height Scripture Verses List
                Expanded(
                  child: versesList.isEmpty
                      ? Center(
                          child: Text(
                            isTelugu ? "వాక్యాలు లభించలేదు" : "No verses available",
                            style: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(14),
                          itemCount: versesList.length,
                          itemBuilder: (context, index) {
                            final verse = versesList[index];
                            final isVerseSelected = _selectedVerseNum == verse.verseNumber;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedVerseNum = isVerseSelected ? null : verse.verseNumber;
                                });
                              },
                              onLongPress: () {
                                final citation = "${safeBook.nameTe} $safeChapter:${verse.verseNumber}";
                                _showVerseQuickActionsModal(context, verse, citation, isTelugu, isDark);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isVerseSelected
                                      ? (isDark ? const Color(0xFF33141A) : const Color(0xFFFFF5F6))
                                      : (isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isVerseSelected
                                        ? AppTheme.shiningRed
                                        : AppTheme.goldAccent.withValues(alpha: 0.35),
                                    width: isVerseSelected ? 1.6 : 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.shiningRed.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildVerseBodyText(verse, safeBook, safeChapter, isDark),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.goldAccent, size: 18),
                                          onPressed: () {
                                            final citation = "${safeBook.nameTe} $safeChapter:${verse.verseNumber}";
                                            _showVerseQuickActionsModal(context, verse, citation, isTelugu, isDark);
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),

                                    // Render Interlinear Breakdown Card if in Interlinear Mode
                                    if (_translationMode == BibleTranslationMode.interlinear && verse.interlinearWords.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF141C2E) : const Color(0xFFFFFDF5),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  safeBook.id <= 39 ? Icons.auto_awesome : Icons.g_translate,
                                                  size: 14,
                                                  color: AppTheme.goldAccent,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  safeBook.id <= 39 ? "Hebrew Interlinear (Strong's H)" : "Greek Interlinear (Strong's G)",
                                                  style: GoogleFonts.cinzel(
                                                    color: AppTheme.goldAccent,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: verse.interlinearWords.map((word) {
                                                return _buildInterlinearWordTile(word, isDark);
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _modeChip(BibleTranslationMode mode, String label, bool isDark) {
    final isActive = _translationMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _translationMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.shiningRed : AppTheme.goldAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.shiningRed : AppTheme.goldAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.goldAccent,
            fontWeight: FontWeight.bold,
            fontSize: 11.0,
          ),
        ),
      ),
    );
  }

  Widget _buildVerseBodyText(BibleEngineVerse verse, BibleBook safeBook, int safeChapter, bool isDark) {
    if (_translationMode == BibleTranslationMode.englishKjv) {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "[ ${verse.verseNumber} ]  ",
              style: GoogleFonts.cinzel(color: const Color(0xFFD4AF37), fontSize: _fontSize, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: verse.textKjv,
              style: GoogleFonts.inter(color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000), fontSize: _fontSize, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_translationMode == BibleTranslationMode.parallel) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "[ ${verse.verseNumber} ]  ",
                  style: GoogleFonts.cinzel(color: const Color(0xFFD4AF37), fontSize: _fontSize, fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: verse.textTelugu,
                  style: GoogleFonts.notoSansTelugu(color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000), fontSize: _fontSize, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Divider(color: AppTheme.goldAccent.withValues(alpha: 0.25), height: 1),
          ),
          Text(
            verse.textKjv,
            style: GoogleFonts.inter(
              color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
              fontSize: _fontSize * 0.9,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // Default: Telugu BSI or Interlinear Header
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "[ ${verse.verseNumber} ]  ",
            style: GoogleFonts.cinzel(color: const Color(0xFFD4AF37), fontSize: _fontSize, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: verse.textTelugu,
            style: GoogleFonts.notoSansTelugu(color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000), fontSize: _fontSize, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInterlinearWordTile(InterlinearWord word, bool isDark) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => StrongsDetailSheet(word: word, isDark: isDark),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Original Hebrew / Greek Script
            Text(
              word.originalWord,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),

            // Transliteration
            Text(
              word.transliteration,
              style: const TextStyle(
                color: AppTheme.shiningRed,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),

            // English Gloss
            Text(
              word.englishGloss,
              style: TextStyle(
                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),

            // Strong's Tag Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
              ),
              child: Text(
                word.strongsTag,
                style: GoogleFonts.cinzel(
                  color: AppTheme.goldAccent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Strong's Number Concordance Detail Bottom Sheet (Bible Hub Style)
class StrongsDetailSheet extends StatelessWidget {
  final InterlinearWord word;
  final bool isDark;

  const StrongsDetailSheet({
    super.key,
    required this.word,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final entry = BibleEngineService.getStrongsEntry(word);
    final isHebrew = entry.strongsTag.startsWith('H');
    final testamentLabel = isHebrew ? "Hebrew Concordance (OT)" : "Greek Concordance (NT)";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A26) : const Color(0xFFFBFBFD),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar with Drag Indicator & Close Button
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
            const SizedBox(height: 12),

            Row(
              children: [
                // Strong's ID badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Text(
                    "STRONG'S ${entry.strongsTag.toUpperCase()}",
                    style: GoogleFonts.cinzel(
                      color: AppTheme.goldAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Flexible/Expanded subtitle
                Expanded(
                  child: Text(
                    testamentLabel,
                    style: const TextStyle(
                      color: AppTheme.shiningRed,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                // Close button
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: isDark ? AppTheme.textLight : AppTheme.textDark),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Original Script & Transliteration Featured Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFFFFF0F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  Text(
                    entry.originalWord,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Transliteration: ${entry.transliteration}  •  Phonetic: ${entry.phoneticSpelling}",
                    style: const TextStyle(
                      color: AppTheme.shiningRed,
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lexical Detail Grid Items
            _buildDetailRow(label: "Part of Speech", value: entry.partOfSpeech, isDark: isDark),
            const SizedBox(height: 10),
            _buildDetailRow(label: "Definition", value: entry.definition, isDark: isDark),
            const SizedBox(height: 10),
            _buildDetailRow(label: "Origin / Derivation", value: entry.origin, isDark: isDark),
            const SizedBox(height: 10),
            _buildDetailRow(label: "Biblical Usage", value: entry.usage, isDark: isDark),
            const SizedBox(height: 14),

            // Frequency Translation Count Badges
            const Text(
              "TRANSLATED AS (COUNT IN BIBLE)",
              style: TextStyle(
                color: AppTheme.goldAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.translationCounts.map((item) {
                final word = item['word'] ?? '';
                final count = item['count'] ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    "$word ($count)",
                    style: TextStyle(
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Close Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.shiningRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text(
                  "Close Concordance Sheet",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.goldAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isDark ? AppTheme.textLight : AppTheme.textDark,
            fontSize: 13.0,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// 2-Tab Book and Chapter Selection Bottom Sheet Component
class _BookChapterSelectorSheet extends StatefulWidget {
  final BibleBook initialBook;
  final int initialChapter;
  final bool isTelugu;
  final bool isDark;
  final Function(BibleBook book, int chapter) onChapterSelected;

  const _BookChapterSelectorSheet({
    required this.initialBook,
    required this.initialChapter,
    required this.isTelugu,
    required this.isDark,
    required this.onChapterSelected,
  });

  @override
  State<_BookChapterSelectorSheet> createState() => _BookChapterSelectorSheetState();
}

class _BookChapterSelectorSheetState extends State<_BookChapterSelectorSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BibleBook _currentBook;
  late int _currentChapter;
  String _activeFilter = "ALL";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentBook = widget.initialBook;
    _currentChapter = widget.initialChapter;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.goldAccent.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: widget.isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.shiningRed,
              indicatorWeight: 3,
              labelColor: AppTheme.shiningRed,
              unselectedLabelColor: widget.isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
              labelStyle: GoogleFonts.notoSansTelugu(fontWeight: FontWeight.bold, fontSize: 13.5),
              tabs: [
                Tab(text: widget.isTelugu ? "1. పుస్తకము (Book)" : "1. Book"),
                Tab(text: widget.isTelugu ? "2. అధ్యాయము (Chapter)" : "2. Chapter"),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBooksTab(),
                _buildChaptersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksTab() {
    List<BibleBook> filteredBooks = BibleService.books;
    if (_activeFilter == "OT") {
      filteredBooks = BibleService.getOldTestamentBooks();
    } else if (_activeFilter == "NT") {
      filteredBooks = BibleService.getNewTestamentBooks();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filteredBooks = filteredBooks.where((b) {
        return b.nameEn.toLowerCase().contains(query) ||
               b.nameTe.toLowerCase().contains(query);
      }).toList();
    }

    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: widget.isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: widget.isTelugu ? "గ్రంథం పేరుతో శోధించండి..." : "Search book (e.g. Genesis, కీర్తనలు)...",
            hintStyle: TextStyle(color: widget.isDark ? AppTheme.textMutedDark : AppTheme.textMuted, fontSize: 12.5),
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.goldAccent, size: 20),
            filled: true,
            fillColor: widget.isDark ? AppTheme.bgPrimaryDark : const Color(0xFFFFF5F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _filterButton("ALL", widget.isTelugu ? "అన్నీ (66)" : "All (66)"),
            const SizedBox(width: 6),
            _filterButton("OT", widget.isTelugu ? "పాత నిబంధన (39)" : "OT (39)"),
            const SizedBox(width: 6),
            _filterButton("NT", widget.isTelugu ? "క్రొత్త నిబంధన (27)" : "NT (27)"),
          ],
        ),
        const SizedBox(height: 10),

        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filteredBooks.length,
            itemBuilder: (context, index) {
              final book = filteredBooks[index];
              final isSelected = book.id == _currentBook.id;

              return InkWell(
                onTap: () {
                  setState(() {
                    _currentBook = book;
                    _currentChapter = 1;
                  });
                  _tabController.animateTo(1);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.shiningRed.withValues(alpha: 0.15)
                        : (widget.isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.shiningRed : AppTheme.goldAccent.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: isSelected ? AppTheme.shiningRed : AppTheme.goldAccent.withValues(alpha: 0.2),
                        child: Text(
                          "${book.id}",
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.goldAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.nameTe,
                              style: GoogleFonts.notoSansTelugu(
                                color: widget.isDark ? AppTheme.textLight : AppTheme.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${book.nameEn} • ${book.totalChapters} Ch",
                              style: TextStyle(
                                color: widget.isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChaptersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${_currentBook.nameTe} (${_currentBook.nameEn})",
              style: GoogleFonts.notoSansTelugu(
                color: AppTheme.goldAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.isTelugu ? "అధ్యాయాలు: ${_currentBook.totalChapters}" : "Chapters: ${_currentBook.totalChapters}",
              style: const TextStyle(color: AppTheme.shiningRed, fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1.1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _currentBook.totalChapters,
            itemBuilder: (context, index) {
              final chNum = index + 1;
              final isSelected = _currentBook.id == widget.initialBook.id && chNum == _currentChapter;

              return InkWell(
                onTap: () {
                  setState(() {
                    _currentChapter = chNum;
                  });
                  widget.onChapterSelected(_currentBook, chNum);
                  Navigator.pop(context, chNum);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.goldAccent
                        : (widget.isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.goldAccent : AppTheme.goldAccent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "$chNum",
                      style: TextStyle(
                        color: isSelected ? AppTheme.textDark : (widget.isDark ? AppTheme.textLight : AppTheme.textDark),
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterButton(String value, String label) {
    final isActive = _activeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.shiningRed : AppTheme.goldAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppTheme.shiningRed : AppTheme.goldAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.goldAccent,
            fontWeight: FontWeight.bold,
            fontSize: 10.5,
          ),
        ),
      ),
    );
  }
}
