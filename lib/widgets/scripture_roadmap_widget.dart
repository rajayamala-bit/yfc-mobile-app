import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/bible_service.dart';
import '../theme/app_theme.dart';

class BookRoadmapSection {
  final String title;
  final String description;
  final String chaptersTag;
  final int targetChapter;

  const BookRoadmapSection({
    required this.title,
    required this.description,
    required this.chaptersTag,
    required this.targetChapter,
  });
}

class ScriptureRoadmapWidget extends StatefulWidget {
  const ScriptureRoadmapWidget({super.key});

  @override
  State<ScriptureRoadmapWidget> createState() => _ScriptureRoadmapWidgetState();
}

class _ScriptureRoadmapWidgetState extends State<ScriptureRoadmapWidget> {
  late BibleBook _selectedBook;

  @override
  void initState() {
    super.initState();
    _selectedBook = BibleService.getBookById(1); // Genesis default
  }

  List<BookRoadmapSection> _getRoadmapSectionsForBook(BibleBook book) {
    switch (book.nameEn) {
      case "Genesis":
        return const [
          BookRoadmapSection(
            title: "Chapters 1–11: Primeval History",
            description: "Creation Week, Eden, The Fall, Cain & Abel, Noah's Ark & Tower of Babel",
            chaptersTag: "Ch 1",
            targetChapter: 1,
          ),
          BookRoadmapSection(
            title: "Chapters 12–25: Abraham's Covenant",
            description: "Call of Abram, Promised Land, Melchizedek, Isaac & Sacrifice at Moriah",
            chaptersTag: "Ch 12",
            targetChapter: 12,
          ),
          BookRoadmapSection(
            title: "Chapters 25–36: Jacob & Israel",
            description: "Esau's Birthright, Bethel Ladder, Rachel & Leah, Wrestling with God at Peniel",
            chaptersTag: "Ch 31",
            targetChapter: 31,
          ),
          BookRoadmapSection(
            title: "Chapters 37–50: Joseph in Egypt",
            description: "Coat of Colors, Potiphar, Pharaoh's Dreams, Family Reunion & Blessing of Tribes",
            chaptersTag: "Ch 37",
            targetChapter: 37,
          ),
        ];
      case "Exodus":
        return const [
          BookRoadmapSection(
            title: "Chapters 1–18: Deliverance from Egypt",
            description: "Moses at Bush, 10 Plagues, Passover Lamb, Red Sea Crossing & Manna in Desert",
            chaptersTag: "Ch 1",
            targetChapter: 1,
          ),
          BookRoadmapSection(
            title: "Chapters 19–24: Covenant at Sinai",
            description: "10 Commandments, Law of Israel, Divine Glory on Mountain",
            chaptersTag: "Ch 19",
            targetChapter: 19,
          ),
          BookRoadmapSection(
            title: "Chapters 25–31: Tabernacle Design",
            description: "Ark of Covenant, Mercy Seat, Golden Lampstand & Priestly Vestments",
            chaptersTag: "Ch 25",
            targetChapter: 25,
          ),
          BookRoadmapSection(
            title: "Chapters 32–40: Golden Calf & Glory",
            description: "Idol Sin, Moses' Intercession & Divine Glory Filling the Tabernacle",
            chaptersTag: "Ch 32",
            targetChapter: 32,
          ),
        ];
      case "Psalms":
        return const [
          BookRoadmapSection(
            title: "Book I (Psalms 1–41): Davidic Hymns",
            description: "The Blessed Man, Shepherd Psalm (Ps 23) & Penitential Prayers (Ps 32)",
            chaptersTag: "Ch 23",
            targetChapter: 23,
          ),
          BookRoadmapSection(
            title: "Book II (Psalms 42–72): Songs of Zion",
            description: "As Deer Pants for Water, God Our Refuge (Ps 46) & Psalm of Repentance (Ps 51)",
            chaptersTag: "Ch 46",
            targetChapter: 46,
          ),
          BookRoadmapSection(
            title: "Book III (Psalms 73–89): Sanctuary Worship",
            description: "Asaph's Meditations, Sanctuary Glory & Covenant Promises",
            chaptersTag: "Ch 73",
            targetChapter: 73,
          ),
          BookRoadmapSection(
            title: "Book IV & V (Psalms 90–150): Hallelujah Praises",
            description: "Under Secret Place (Ps 91), Great Word Psalm (Ps 119) & Final Praise",
            chaptersTag: "Ch 119",
            targetChapter: 119,
          ),
        ];
      case "Isaiah":
        return const [
          BookRoadmapSection(
            title: "Chapters 1–12: Vision of Holy One",
            description: "Throne Room Calling (Isa 6), Immanuel Prophecy (Isa 7, 9) & Branch of Jesse",
            chaptersTag: "Ch 6",
            targetChapter: 6,
          ),
          BookRoadmapSection(
            title: "Chapters 13–39: Oracles & Hezekiah",
            description: "Nations Judged, Chief Cornerstone & King Hezekiah's Deliverance",
            chaptersTag: "Ch 30",
            targetChapter: 30,
          ),
          BookRoadmapSection(
            title: "Chapters 40–55: Servant Songs",
            description: "Comfort My People, Everlasting God & The Suffering Servant (Isa 53)",
            chaptersTag: "Ch 53",
            targetChapter: 53,
          ),
          BookRoadmapSection(
            title: "Chapters 56–66: New Heavens & Earth",
            description: "Spirit of Sovereign LORD, Glorious Zion & New Creation Hope",
            chaptersTag: "Ch 61",
            targetChapter: 61,
          ),
        ];
      case "Matthew":
        return const [
          BookRoadmapSection(
            title: "Chapters 1–7: King Introduced & Sermon",
            description: "Royal Genealogy, Virgin Birth, Baptism & Sermon on the Mount (Matt 5–7)",
            chaptersTag: "Ch 1",
            targetChapter: 1,
          ),
          BookRoadmapSection(
            title: "Chapters 8–13: Miracles & Parables",
            description: "Healing Lepers, Calming Storm, Apostles Called & Kingdom Parables",
            chaptersTag: "Ch 8",
            targetChapter: 8,
          ),
          BookRoadmapSection(
            title: "Chapters 14–20: Transfiguration",
            description: "Feeding 5000, Walking on Water, Peter's Confession & Transfiguration",
            chaptersTag: "Ch 14",
            targetChapter: 14,
          ),
          BookRoadmapSection(
            title: "Chapters 21–28: Passion & Great Commission",
            description: "Triumphal Entry, Last Supper, Gethsemane, Cross, Resurrection & Great Commission",
            chaptersTag: "Ch 28",
            targetChapter: 28,
          ),
        ];
      case "Revelation":
        return const [
          BookRoadmapSection(
            title: "Chapters 1–3: Vision of Risen Christ & 7 Churches",
            description: "Son of Man among Lampstands & Prophetic Messages to 7 Asian Churches",
            chaptersTag: "Ch 1",
            targetChapter: 1,
          ),
          BookRoadmapSection(
            title: "Chapters 4–7: Heavenly Throne & 7 Seals",
            description: "24 Elders, Worthy Lamb with Scroll, 144,000 Sealed & White-Robed Multitude",
            chaptersTag: "Ch 4",
            targetChapter: 4,
          ),
          BookRoadmapSection(
            title: "Chapters 8–18: Trumpets, Bowls & Babylon",
            description: "7 Trumpets, Woman & Dragon, 7 Bowls of Wrath & Fall of Babylon",
            chaptersTag: "Ch 8",
            targetChapter: 8,
          ),
          BookRoadmapSection(
            title: "Chapters 19–22: New Jerusalem",
            description: "Rider on White Horse, Millennium, River of Water of Life & Come Lord Jesus!",
            chaptersTag: "Ch 22",
            targetChapter: 22,
          ),
        ];
      default:
        return [
          const BookRoadmapSection(
            title: "Part 1: Divine Calling & Foundations",
            description: "God's initial revelation, calling of leadership, and covenant establishment",
            chaptersTag: "Ch 1",
            targetChapter: 1,
          ),
          BookRoadmapSection(
            title: "Part 2: Spiritual Journey & Trials",
            description: "Faith tested through trials, wilderness journey, and divine preservation",
            chaptersTag: "Ch ${book.totalChapters ~/ 4}",
            targetChapter: (book.totalChapters ~/ 4).clamp(1, book.totalChapters),
          ),
          BookRoadmapSection(
            title: "Part 3: Covenant Promises & Prophecy",
            description: "Scriptural fulfillment, covenant renewal, and worship in God's presence",
            chaptersTag: "Ch ${book.totalChapters ~/ 2}",
            targetChapter: (book.totalChapters ~/ 2).clamp(1, book.totalChapters),
          ),
          BookRoadmapSection(
            title: "Part 4: Victory & Future Hope",
            description: "Final triumph of God's kingdom, blessings for the faithful, and divine heritage",
            chaptersTag: "Ch ${book.totalChapters}",
            targetChapter: book.totalChapters,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;
    final isDark = appState.isDarkMode;

    final featuredBooks = [
      BibleService.getBookById(1),  // Genesis
      BibleService.getBookById(2),  // Exodus
      BibleService.getBookById(19), // Psalms
      BibleService.getBookById(23), // Isaiah
      BibleService.getBookById(40), // Matthew
      BibleService.getBookById(45), // Romans
      BibleService.getBookById(66), // Revelation
    ];

    final sections = _getRoadmapSectionsForBook(_selectedBook);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCardDark : const Color(0xFFFFF5F7), // Blush pink container
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shiningRed.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Book Selector Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore_rounded, color: AppTheme.shiningRed, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isTelugu ? "వాక్య అధ్యయన ప్రయాణ మార్గం" : "Journey Through Scriptures",
                    style: GoogleFonts.cinzel(
                      color: AppTheme.shiningRed,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Interactive Book Selector Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldAccent, width: 1.2),
                ),
                child: DropdownButton<BibleBook>(
                  value: _selectedBook,
                  dropdownColor: isDark ? AppTheme.surfaceCardDark : Colors.white,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.goldAccent, size: 20),
                  items: featuredBooks.map((b) {
                    return DropdownMenuItem(
                      value: b,
                      child: Text(
                        isTelugu ? b.nameTe : b.nameEn,
                        style: const TextStyle(
                          color: Color(0xFFB8860B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newBook) {
                    if (newBook != null) {
                      setState(() => _selectedBook = newBook);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            isTelugu
                ? "${_selectedBook.nameTe} లోని ప్రధాన అధ్యాయాలు మరియు సత్యాలు (${_selectedBook.totalChapters} అధ్యాయాలు):"
                : "Journey Through ${_selectedBook.nameEn} — All ${_selectedBook.totalChapters} chapters organized by major sections:",
            style: TextStyle(
              color: isDark ? AppTheme.textMutedDark : const Color(0xFF555555),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // 2x2 Grid Narrative Roadmap Cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sections.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, idx) {
              final sec = sections[idx];
              return InkWell(
                onTap: () {
                  appState.openBibleToPassage(_selectedBook.id, sec.targetChapter);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgPrimaryDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF2ECC71), size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sec.title,
                              style: TextStyle(
                                color: isDark ? AppTheme.textLight : const Color(0xFF111111),
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      Text(
                        sec.description,
                        style: TextStyle(
                          color: isDark ? AppTheme.textMutedDark : const Color(0xFF666666),
                          fontSize: 10,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.shiningRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sec.chaptersTag,
                              style: const TextStyle(
                                color: AppTheme.shiningRed,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Row(
                            children: [
                              Text(
                                "Read",
                                style: TextStyle(
                                  color: AppTheme.goldAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward_rounded, color: AppTheme.goldAccent, size: 12),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
