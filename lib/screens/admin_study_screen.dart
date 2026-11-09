import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_model.dart';
import '../providers/app_state.dart';
import '../services/berean_ai_service.dart';
import '../services/bible_service.dart';
import '../services/daily_study_service.dart';
import '../theme/app_theme.dart';

class AdminStudyScreen extends StatefulWidget {
  const AdminStudyScreen({super.key});

  @override
  State<AdminStudyScreen> createState() => _AdminStudyScreenState();
}

class _AdminStudyScreenState extends State<AdminStudyScreen> {
  final TextEditingController _titleController = TextEditingController(text: "Genesis 3: The Fall & The Divine Promise");
  final TextEditingController _notesEnController = TextEditingController(text: '''
### Genesis 3 Study Breakdown:
1. **The Temptation & Fall (Verses 1-7):** Satan questions God's truthfulness ("Did God really say?"). Sin enters human history through disobedience.
2. **The Divine Search (Verses 8-13):** God calls out to man: "Where are you?" - showing God's persistent grace even in judgment.
3. **Protoevangelium - First Gospel Promise (Verse 15):** The seed of the woman shall crush the serpent's head - pointing directly to Jesus Christ's victory on the cross!
''');
  final TextEditingController _notesTeController = TextEditingController(text: '''
### ఆదికాండము 3వ అధ్యాయము ఆత్మీయ పాఠములు:
1. **పాపము యొక్క ప్రవేశము (1-7 వాక్యాలు):** దేవుని వాక్యమును అనుమానించడం ద్వారా సర్పము మానవుని శోధించింది.
2. **దేవుని విచారణ (8-13 వాక్యాలు):** "నీవు ఎక్కడ ఉన్నావు?" అని దేవుడు యాకోబును, ఆదామును పిలిచి తన దయా కనికరములను బయలుపరచాడు.
3. **తొలి సువార్త వాగ్దానము (15వ వాక్యము):** స్త్రీ సంతానము సర్పము తలను చితకతొక్కును — ఇది క్రీస్తు సిలువ విజయాన్ని ముందుగానే ప్రకటిస్తోంది!
''');

  BibleBook _selectedBook = BibleService.books.first;
  int _startChapter = 3;
  int _startVerse = 1;
  int _endChapter = 3;
  int _endVerse = 24;

  @override
  void initState() {
    super.initState();
    _loadSavedPassageState();
  }

  Future<void> _loadSavedPassageState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBookId = prefs.getInt('admin_study_book_id');
    final savedStartCh = prefs.getInt('admin_study_start_ch');
    final savedStartV = prefs.getInt('admin_study_start_v');
    final savedEndCh = prefs.getInt('admin_study_end_ch');
    final savedEndV = prefs.getInt('admin_study_end_v');

    if (savedBookId != null) {
      final book = BibleService.books.firstWhere(
        (b) => b.id == savedBookId,
        orElse: () => BibleService.books.first,
      );
      if (mounted) {
        setState(() {
          _selectedBook = book;
          if (savedStartCh != null) _startChapter = savedStartCh;
          if (savedStartV != null) _startVerse = savedStartV;
          if (savedEndCh != null) _endChapter = savedEndCh;
          if (savedEndV != null) _endVerse = savedEndV;
          _titleController.text = "${_selectedBook.nameEn} $_startChapter:$_startVerse–$_endChapter:$_endVerse: Study Notes";
        });
      }
    }
  }

  Future<void> _savePassageState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('admin_study_book_id', _selectedBook.id);
    await prefs.setInt('admin_study_start_ch', _startChapter);
    await prefs.setInt('admin_study_start_v', _startVerse);
    await prefs.setInt('admin_study_end_ch', _endChapter);
    await prefs.setInt('admin_study_end_v', _endVerse);
  }

  void _updateTitleFromPassage() {
    _titleController.text = "${_selectedBook.nameEn} $_startChapter:$_startVerse–$_endChapter:$_endVerse: Study Notes & Divine Truths";
    _savePassageState();
  }

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What key question did God ask Adam in the garden after the fall?',
      'options': ['What have you done?', 'Where are you?', 'Why did you eat?', 'Where is Eve?'],
      'correct_index': 1,
      'explanation': 'Genesis 3:9 records God calling to man: "Where are you?"',
    },
    {
      'question': 'What is the "Protoevangelium" or first gospel promise in Genesis 3:15?',
      'options': [
        'Noah\'s ark of safety',
        'The rainbow covenant',
        'The seed of the woman shall crush the serpent\'s head',
        'Abraham\'s call out of Ur'
      ],
      'correct_index': 2,
      'explanation': 'Genesis 3:15 is recognized as the first prophetic announcement of Christ\'s victory over Satan.',
    },
    {
      'question': 'How did God clothe Adam and Eve after they realized their nakedness?',
      'options': ['Garments of animal skin', 'Fig leaves', 'Linen robes', 'Woven wool'],
      'correct_index': 0,
      'explanation': 'Genesis 3:21 - Unto Adam also and to his wife did the LORD God make coats of skins, and clothed them.',
    },
    {
      'question': 'What was placed at the east of Eden to guard the tree of life?',
      'options': ['A wall of fire', 'Archangel Michael', 'A golden barrier', 'Cherubim and a flaming sword'],
      'correct_index': 3,
      'explanation': 'Genesis 3:24 - He placed at the east of the garden of Eden Cherubims, and a flaming sword.',
    },
    {
      'question': 'What primary lie did the serpent tell Eve to tempt her to eat the fruit?',
      'options': ['God does not see', 'Ye shall not surely die', 'You will gain wealth', 'The fruit has healing power'],
      'correct_index': 1,
      'explanation': 'Genesis 3:4 - And the serpent said unto the woman, Ye shall not surely die.',
    },
  ];

  bool _isPublishing = false;
  bool _isGeneratingAi = false;

  void _autoGenerateWithBereanAi() async {
    final passageStr = "${_selectedBook.nameEn} $_startChapter:$_startVerse–$_endChapter:$_endVerse";
    setState(() => _isGeneratingAi = true);

    final aiResult = await BereanAiService.generateDailyStudyAndQuiz(
      passage: passageStr,
      bookName: _selectedBook.nameEn,
    );

    if (mounted) {
      setState(() {
        _isGeneratingAi = false;
        if (aiResult['title'] != null && aiResult['title'].toString().isNotEmpty) {
          _titleController.text = aiResult['title'].toString();
        }
        if (aiResult['notes_en'] != null && aiResult['notes_en'].toString().isNotEmpty) {
          _notesEnController.text = aiResult['notes_en'].toString();
        }
        if (aiResult['notes_te'] != null && aiResult['notes_te'].toString().isNotEmpty) {
          _notesTeController.text = aiResult['notes_te'].toString();
        }

        final List? rawQs = aiResult['questions'] as List?;
        if (rawQs != null && rawQs.isNotEmpty) {
          _questions.clear();
          for (int i = 0; i < rawQs.length; i++) {
            final item = rawQs[i];
            _questions.add({
              'question': item['question']?.toString() ?? 'Question ${i + 1}',
              'options': List<String>.from(item['options'] ?? ['Option A', 'Option B', 'Option C', 'Option D']),
              'correct_index': item['correct_index'] is int ? item['correct_index'] as int : 0,
              'explanation': item['explanation']?.toString() ?? 'Scriptural reference and truth.',
            });
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.shiningRed,
          content: Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFFFFD700)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "✨ Study Notes & 5-Question Quiz Auto-Generated by Berean AI!",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _publishPortion() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid Portion Title")),
      );
      return;
    }

    setState(() => _isPublishing = true);

    final List<QuizQuestion> parsedQuestions = [];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      parsedQuestions.add(QuizQuestion(
        id: i + 1,
        questionEn: q['question']?.toString() ?? '',
        questionTe: q['question']?.toString() ?? '',
        optionsEn: List<String>.from(q['options'] ?? []),
        optionsTe: List<String>.from(q['options'] ?? []),
        correctIndex: q['correct_index'] is int ? q['correct_index'] as int : 0,
        explanationEn: q['explanation']?.toString() ?? '',
        explanationTe: q['explanation']?.toString() ?? '',
      ));
    }

    final passageStr = "${_selectedBook.nameEn} $_startChapter:$_startVerse–$_endChapter:$_endVerse";
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final portion = DailyPortionData(
      title: _titleController.text.trim(),
      passage: passageStr,
      bookName: _selectedBook.nameEn,
      startChapter: _startChapter,
      startVerse: _startVerse,
      endChapter: _endChapter,
      endVerse: _endVerse,
      studyNotesEn: _notesEnController.text.trim(),
      studyNotesTe: _notesTeController.text.trim(),
      quizQuestions: parsedQuestions,
      publishedDate: todayStr,
    );

    await DailyStudyService.publishDailyPortion(portion);

    if (mounted) {
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.shiningRed,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "🚀 Daily Portion & 5-Question Quiz Published Successfully!",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final isTelugu = appState.isTelugu;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.goldAccent),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                isTelugu ? "MANAGE DAILY STUDY" : "MANAGE DAILY STUDY",
                style: GoogleFonts.cinzel(
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Input 1: Daily Portion Title
            _buildSectionLabel(isTelugu ? "1. దినచర్య అధ్యయన శీర్షిక (Title):" : "1. Daily Study Title:"),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark),
              decoration: InputDecoration(
                hintText: "e.g. Genesis 3: The Fall & The Promise",
                filled: true,
                fillColor: isDark ? AppTheme.surfaceCardDark : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Input 2: Passage Selector
            _buildSectionLabel(isTelugu ? "2. వాక్య భాగము ఎంపిక (Passage):" : "2. Scripture Passage Range:"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceCardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  DropdownButton<BibleBook>(
                    value: _selectedBook,
                    isExpanded: true,
                    dropdownColor: isDark ? AppTheme.surfaceCardDark : Colors.white,
                    style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontWeight: FontWeight.bold),
                    items: BibleService.books.map((b) {
                      return DropdownMenuItem(
                        value: b,
                        child: Text("${b.nameEn} (${b.nameTe})"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedBook = val;
                          _updateTitleFromPassage();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Start Ch / Verse", style: TextStyle(fontSize: 11, color: AppTheme.goldAccent)),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButton<int>(
                                    value: _startChapter.clamp(1, _selectedBook.totalChapters),
                                    isExpanded: true,
                                    items: List.generate(_selectedBook.totalChapters, (i) => i + 1)
                                        .map((c) => DropdownMenuItem(value: c, child: Text("Ch $c")))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _startChapter = v;
                                          _updateTitleFromPassage();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: DropdownButton<int>(
                                    value: _startVerse,
                                    isExpanded: true,
                                    items: List.generate(60, (i) => i + 1)
                                        .map((v) => DropdownMenuItem(value: v, child: Text("V $v")))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _startVerse = v;
                                          _updateTitleFromPassage();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("End Ch / Verse", style: TextStyle(fontSize: 11, color: AppTheme.goldAccent)),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButton<int>(
                                    value: _endChapter.clamp(1, _selectedBook.totalChapters),
                                    isExpanded: true,
                                    items: List.generate(_selectedBook.totalChapters, (i) => i + 1)
                                        .map((c) => DropdownMenuItem(value: c, child: Text("Ch $c")))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _endChapter = v;
                                          _updateTitleFromPassage();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: DropdownButton<int>(
                                    value: _endVerse,
                                    isExpanded: true,
                                    items: List.generate(60, (i) => i + 1)
                                        .map((v) => DropdownMenuItem(value: v, child: Text("V $v")))
                                        .toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _endVerse = v;
                                          _updateTitleFromPassage();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // AI Auto-Generation Button for Study Notes & 5-Question Quiz
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingAi ? null : _autoGenerateWithBereanAi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.shiningRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                icon: _isGeneratingAi
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 20),
                label: Text(
                  _isGeneratingAi
                      ? "Berean AI Generating Study Notes & Quiz..."
                      : "[ ✨ Auto-Generate Study Notes & Quiz (Berean AI) ]",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Input 3: Pastor Commentary / Study Notes
            _buildSectionLabel(isTelugu ? "3. పాస్టరు గారి వ్యాఖ్యాన నిధి (English Notes):" : "3. Pastor Study Notes (English):"),
            const SizedBox(height: 6),
            TextField(
              controller: _notesEnController,
              maxLines: 5,
              style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppTheme.surfaceCardDark : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),

            _buildSectionLabel(isTelugu ? "తెలుగు వ్యాఖ్యాన నోట్స్ (Telugu Notes):" : "Pastor Study Notes (Telugu):"),
            const SizedBox(height: 6),
            TextField(
              controller: _notesTeController,
              maxLines: 5,
              style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppTheme.surfaceCardDark : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),

            // Input 4: 5-Question Quiz Builder
            _buildSectionLabel(isTelugu ? "4. 5 ప్రశ్నల క్విజ్ బిల్డర్ (5-Question Quiz Builder):" : "4. Daily 5-Question Quiz Builder:"),
            const SizedBox(height: 10),

            ...List.generate(_questions.length, (idx) {
              final q = _questions[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceCardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Question ${idx + 1}:",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.goldAccent, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: q['question'],
                      style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 13),
                      decoration: const InputDecoration(hintText: "Enter Question text..."),
                      onChanged: (val) => q['question'] = val,
                    ),
                    const SizedBox(height: 10),
                    const Text("Options (Select Correct Choice Radio):", style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ...List.generate(4, (oIdx) {
                      return Row(
                        children: [
                          // ignore: deprecated_member_use
                          Radio<int>(
                            value: oIdx,
                            // ignore: deprecated_member_use
                            groupValue: q['correct_index'],
                            activeColor: AppTheme.shiningRed,
                            // ignore: deprecated_member_use
                            onChanged: (v) => setState(() => q['correct_index'] = v!),
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: q['options'][oIdx],
                              style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 12.5),
                              onChanged: (val) => q['options'][oIdx] = val,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Publish Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isPublishing ? null : _publishPortion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.shiningRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
                icon: _isPublishing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                label: Text(
                  isTelugu ? "🚀 అధ్యయన భాగము & క్విజ్ ప్రచురించు" : "🚀 Publish Daily Portion & Quiz",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.cinzel(
        color: AppTheme.goldAccent,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
