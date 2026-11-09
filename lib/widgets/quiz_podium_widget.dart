import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quiz_model.dart';
import '../providers/app_state.dart';
import '../services/gemini_quiz_service.dart';
import '../services/quiz_service.dart';
import '../theme/app_theme.dart';

import 'package:yfc_app/services/daily_study_service.dart';

class QuizPodiumWidget extends StatefulWidget {
  const QuizPodiumWidget({super.key});

  @override
  State<QuizPodiumWidget> createState() => _QuizPodiumWidgetState();
}

class _QuizPodiumWidgetState extends State<QuizPodiumWidget> with SingleTickerProviderStateMixin {
  final GeminiQuizService _quizService = GeminiQuizService();
  DailyQuiz? _quiz;
  DailyPortionData? _activePortion;
  bool _isLoading = true;

  // Spin animation controller for refresh button
  late AnimationController _refreshSpinController;

  // Active quiz attempt state
  bool _isQuizActive = false;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _elapsedSeconds = 0;
  Timer? _quizTimer;
  int? _selectedOptionIndex;
  bool _showExplanation = false;
  bool _quizCompleted = false;

  // Leaderboard Champions
  final List<ChampionLeaderboardUser> _podiumUsers = [];

  StreamSubscription? _leaderboardSubscription;
  StreamSubscription? _studySubscription;

  @override
  void initState() {
    super.initState();
    _refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadDailyQuiz();
    _listenToDailyStudyStream();
    _listenToLeaderboardFirestore();
  }

  void _listenToDailyStudyStream() {
    _studySubscription?.cancel();
    _studySubscription = DailyStudyService.streamDailyStudy().listen((portion) async {
      if (portion != null && mounted) {
        _activePortion = portion;
        
        // Prevent active quiz gameplay from being interrupted or reset mid-game!
        if (_isQuizActive) return;

        if (portion.quizQuestions.length >= 5) {
          _quiz = DailyQuiz(
            id: portion.publishedDate,
            quizDate: portion.publishedDate,
            book: portion.bookName,
            chapter: portion.startChapter,
            verses: "${portion.startVerse}-${portion.endVerse}",
            questions: portion.quizQuestions,
          );
        } else {
          _quiz = await _quizService.generateDailyQuiz(
            book: portion.bookName,
            chapter: portion.startChapter,
            verses: "${portion.startVerse}-${portion.endVerse}",
          );
        }
        debugPrint('Total loaded quiz questions: ${_quiz?.questions.length}');
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (_) {});
  }

  void _listenToLeaderboardFirestore() {
    _leaderboardSubscription?.cancel();
    try {
      _leaderboardSubscription = QuizService()
          .streamChampionsLeaderboard(quizId: _quiz?.id)
          .listen((champions) {
        if (mounted) {
          setState(() {
            _podiumUsers.clear();
            _podiumUsers.addAll(champions);
          });
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  Future<void> _refreshLeaderboardWithSpin() async {
    _refreshSpinController.forward(from: 0.0);
    await _loadDailyQuiz();
    _listenToLeaderboardFirestore();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: AppTheme.shiningRed,
          content: Row(
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Podium updated", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _loadDailyQuiz() async {
    setState(() => _isLoading = true);
    final activePortion = await DailyStudyService.getActiveDailyPortion();
    _activePortion = activePortion;

    if (activePortion.quizQuestions.length >= 5) {
      _quiz = DailyQuiz(
        id: activePortion.publishedDate,
        quizDate: activePortion.publishedDate,
        book: activePortion.bookName,
        chapter: activePortion.startChapter,
        verses: "${activePortion.startVerse}-${activePortion.endVerse}",
        questions: activePortion.quizQuestions,
      );
    } else {
      final quizData = await _quizService.generateDailyQuiz(
        book: activePortion.bookName,
        chapter: activePortion.startChapter,
        verses: "${activePortion.startVerse}-${activePortion.endVerse}",
      );
      _quiz = quizData;
    }
    debugPrint('Total loaded quiz questions: ${_quiz?.questions.length}');
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _listenToLeaderboardFirestore();
    }
  }

  void _startQuiz() {
    setState(() {
      _isQuizActive = true;
      _quizCompleted = false;
      _currentQuestionIndex = 0;
      _score = 0;
      _elapsedSeconds = 0;
      _selectedOptionIndex = null;
      _showExplanation = false;
    });

    _quizTimer?.cancel();
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _submitAnswer(int index) {
    if (_selectedOptionIndex != null) return; // Prevent double submission

    final q = _quiz!.questions[_currentQuestionIndex];
    setState(() {
      _selectedOptionIndex = index;
      _showExplanation = true;
      if (index == q.correctIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() async {
    if (_currentQuestionIndex + 1 < _quiz!.questions.length) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _showExplanation = false;
      });
    } else {
      _quizTimer?.cancel();
      setState(() {
        _quizCompleted = true;
      });

      final appState = Provider.of<AppState>(context, listen: false);
      final currentMemberName = appState.profileName.trim().isNotEmpty ? appState.profileName.trim() : 'YFC Member';

      await QuizService().saveQuizScore(
        finalScore: _score,
        totalQuestions: _quiz!.questions.length,
        currentMemberName: currentMemberName,
        elapsedSeconds: _elapsedSeconds,
        quizId: _quiz?.id,
      );
    }
  }

  void _returnToLeaderboard() {
    _quizTimer?.cancel();
    setState(() {
      _isQuizActive = false;
      _quizCompleted = false;
      _currentQuestionIndex = 0;
      _score = 0;
    });
  }

  void _showStudyPortionModal(BuildContext context, bool isTelugu) async {
    final portion = _activePortion ?? await DailyStudyService.getActiveDailyPortion();
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimaryLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: AppTheme.shiningRed, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portion.title,
                          style: GoogleFonts.cinzel(
                            color: AppTheme.goldAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Passage: ${portion.passage}",
                          style: const TextStyle(color: AppTheme.shiningRed, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Scripture Text Section
                      _buildSectionHeader("📖 SCRIPTURE PASSAGE & NOTES", isTelugu ? "పాఠ్య భాగము & అధ్యయన అంశాలు" : "Scripture Text & Study Breakdown"),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.surfaceCardDark : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("English Study Notes:", style: TextStyle(color: AppTheme.shiningRed, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              portion.studyNotesEn.isNotEmpty ? portion.studyNotesEn : "Study breakdown for ${portion.passage}",
                              style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 13, height: 1.4),
                            ),
                            const Divider(height: 16),
                            const Text("తెలుగు అధ్యయన అంశాలు:", style: TextStyle(color: AppTheme.shiningRed, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              portion.studyNotesTe.isNotEmpty ? portion.studyNotesTe : "${portion.passage} నందు పరిపూర్ణ దేవుని వాక్య శ్రేష్టత.",
                              style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Historical & Theological Context
                      _buildSectionHeader("🏛️ HISTORICAL & THEOLOGICAL CONTEXT", isTelugu ? "చారిత్రక & దైవశాస్త్ర నేపథ్యం" : "Historical & Theological Context"),
                      const SizedBox(height: 8),
                      Text(
                        isTelugu ? portion.studyNotesTe : portion.studyNotesEn,
                        style: AppTheme.getScriptTextStyle(
                          isTelugu: isTelugu,
                          fontSize: 14,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Key Golden Memory Verse
                      _buildSectionHeader("⭐ GOLDEN MEMORY VERSE", isTelugu ? "ముఖ్యమైన బంగారు వాక్యము" : "Golden Memory Verse"),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.goldAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.goldAccent, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppTheme.goldAccent, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTelugu
                                        ? "\"నా తండ్రి యొక్క దేవుడు నాకు తోడైయున్నాడు — ${portion.passage}\""
                                        : "\"The God of my father hath been with me — ${portion.passage}\"",
                                    style: const TextStyle(
                                      color: AppTheme.goldAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    portion.passage,
                                    style: const TextStyle(color: AppTheme.shiningRed, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Practical Life Application
                      _buildSectionHeader("🌱 PRACTICAL LIFE APPLICATION", isTelugu ? "జీవిత అనువర్తనం" : "Practical Life Application"),
                      const SizedBox(height: 8),
                      _buildApplicationPoint("1. Trust God's Covenant Faithfulness", "Even when facing opposition or change, trust that God is watching over your journey."),
                      const SizedBox(height: 6),
                      _buildApplicationPoint("2. Seek Peace and Reconciliation", "Resolve conflicts with integrity and honour God in all family and professional relationships."),
                      const SizedBox(height: 6),
                      _buildApplicationPoint("3. Daily Spiritual Vigilance", "Prepare your mind through Scripture before attempting daily fellowship quizzes."),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.shiningRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isTelugu ? "మూసివేయి" : "Close Study Sheet",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String tag, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tag,
          style: GoogleFonts.cinzel(
            color: AppTheme.goldAccent,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(color: AppTheme.shiningRed, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildApplicationPoint(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: AppTheme.statusGreen, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.textLight : AppTheme.textDark, fontSize: 13),
              children: [
                TextSpan(text: "$title: ", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.goldAccent)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _studySubscription?.cancel();
    _leaderboardSubscription?.cancel();
    _refreshSpinController.dispose();
    _quizTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.shiningRed),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text(
          appState.isTelugu ? "డేలీ బైబిల్ క్విజ్ & లీడర్‌బోర్డ్" : "Daily Bible Quiz & Champions",
          style: GoogleFonts.cinzel(
            color: isDark ? AppTheme.textLight : AppTheme.textDark,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: _isQuizActive
            ? const EdgeInsets.only(top: 4, left: 14, right: 14, bottom: 16)
            : const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Current Study Pill Banner (Removed when Quiz is Active to pull question card directly to top)
            if (!_isQuizActive) ...[
              _buildStudyContextBanner(appState.isTelugu),
              const SizedBox(height: 16),
            ],

            // Hide Champions Podium when Quiz is Active
            if (!_isQuizActive) ...[
              _buildChampionsPodium(appState.isTelugu),
              const SizedBox(height: 20),
            ],

            // Active Quiz Card OR Start Banner OR Completion Screen
            if (_quizCompleted)
              _buildQuizCompletedCard(appState.isTelugu)
            else if (_isQuizActive)
              _buildActiveQuizCard(appState.isTelugu)
            else
              _buildQuizStartBanner(appState.isTelugu),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyContextBanner(bool isTelugu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passageLabel = _activePortion?.passage ?? "${_quiz?.book ?? 'Genesis'} ${_quiz?.chapter ?? 3}:${_quiz?.verses ?? '1-24'}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCardDark : const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.bookmark_rounded, color: AppTheme.shiningRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTelugu ? "ప్రస్తుత అధ్యయనం: $passageLabel" : "Current Study: $passageLabel",
                    style: TextStyle(
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showStudyPortionModal(context, isTelugu),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.shiningRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.shiningRed.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, size: 14, color: AppTheme.shiningRed),
                  const SizedBox(width: 4),
                  Text(
                    isTelugu ? "భాగం చూడండి" : "View Portion",
                    style: const TextStyle(
                      color: AppTheme.shiningRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Champions Leaderboard Podium (1st 🥇, 2nd 🥈, 3rd 🥉 Place)
  Widget _buildChampionsPodium(bool isTelugu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPrevious = _podiumUsers.isNotEmpty && _podiumUsers.first.isPreviousCycle;

    final titleText = isPrevious
        ? (isTelugu ? "🏆 ఛాంపియన్స్ పోడియం" : "🏆 Champions Podium")
        : (isTelugu ? "🏆 నేటి ఛాంపియన్స్ పోడియం" : "🏆 Today's Champions Podium");

    final subtitleText = isPrevious
        ? (isTelugu ? "ఇటీవలి అధ్యయన ఛాంపియన్లు" : "Latest Active Study Champions")
        : (isTelugu ? "స్కోరు & వేగం ఆధారంగా ర్యాంకులు" : "Ranked by accuracy & completion speed");

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shiningRed.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: GoogleFonts.cinzel(
                        color: AppTheme.goldAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: TextStyle(
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _refreshLeaderboardWithSpin,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.shiningRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.shiningRed.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RotationTransition(
                        turns: _refreshSpinController,
                        child: const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.shiningRed),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTelugu ? "రిఫ్రెష్" : "Refresh",
                        style: const TextStyle(
                          color: AppTheme.shiningRed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildPodiumPillarsRow(isTelugu),
        ],
      ),
    );
  }

  Widget _buildPodiumPillarsRow(bool isTelugu) {
    if (_podiumUsers.isEmpty) return const SizedBox.shrink();

    final hasFirst = _podiumUsers.isNotEmpty;
    final hasSecond = _podiumUsers.length >= 2;
    final hasThird = _podiumUsers.length >= 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hasSecond) _buildPodiumPillar(_podiumUsers[1], height: 80, isTelugu: isTelugu),
        if (hasFirst) _buildPodiumPillar(_podiumUsers[0], height: 110, isTelugu: isTelugu, isFirst: true),
        if (hasThird) _buildPodiumPillar(_podiumUsers[2], height: 65, isTelugu: isTelugu),
      ],
    );
  }

  Widget _buildPodiumPillar(ChampionLeaderboardUser user, {required double height, required bool isTelugu, bool isFirst = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(user.avatarUrl, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          user.fullName.split(' ').last,
          style: TextStyle(
            color: isFirst ? AppTheme.goldAccent : (isDark ? AppTheme.textLight : AppTheme.textDark),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          "${user.score}/5 (${user.elapsedSeconds > 0 ? '${user.elapsedSeconds}s' : 'Done'})",
          style: TextStyle(
            color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isFirst 
                  ? [AppTheme.shiningRed, AppTheme.shiningRed.withValues(alpha: 0.7)]
                  : (isDark ? [AppTheme.surfaceCardDark, AppTheme.bgPrimaryDark] : [Colors.white, AppTheme.surfaceCardLight]),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: isFirst ? AppTheme.shiningRed : AppTheme.goldAccent.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Text(
              "#${user.rank}",
              style: TextStyle(
                color: isFirst ? Colors.white : AppTheme.goldAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizStartBanner(bool isTelugu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shiningRed.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppTheme.shiningRed, size: 28),
              const SizedBox(width: 10),
              Text(
                isTelugu ? "నేటి బైబిల్ క్విజ్" : "Live Daily Bible Quiz",
                style: GoogleFonts.cinzel(
                  color: AppTheme.goldAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Topic: ${_quiz?.book} ${_quiz?.chapter}:${_quiz?.verses}",
            style: const TextStyle(color: AppTheme.shiningRed, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            isTelugu 
                ? "5 బహుళైచ్ఛిక ప్రశ్నలు. అత్యధిక స్కోరు మరియు వేగం ఆధారంగా విజేతలు ఎంపిక చేయబడతారు."
                : "5 Multiple choice questions. Winners ranked by highest accuracy and fastest elapsed seconds.",
            style: TextStyle(
              color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.shiningRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: Text(
                isTelugu ? "క్విజ్ ప్రారంభించండి" : "Start Daily Quiz Now",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuizCard(bool isTelugu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = _quiz!.questions[_currentQuestionIndex];
    final questionText = isTelugu ? q.questionTe : q.questionEn;
    final options = isTelugu ? q.optionsTe : q.optionsEn;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Topic Header & Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_quiz?.book} ${_quiz?.chapter}:${_quiz?.verses}",
                    style: const TextStyle(color: AppTheme.shiningRed, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Question ${_currentQuestionIndex + 1} of ${_quiz?.questions.length ?? 5}",
                    style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgPrimaryDark : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.shiningRed),
                ),
                child: Text(
                  "⏱️ ${_elapsedSeconds}s",
                  style: const TextStyle(color: AppTheme.shiningRed, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Text
          Text(
            questionText,
            style: AppTheme.getScriptTextStyle(
              isTelugu: isTelugu,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Options List
          ...List.generate(options.length, (idx) {
            Color cardColor = isDark ? AppTheme.bgPrimaryDark : Colors.white;
            Color borderColor = AppTheme.goldAccent.withValues(alpha: 0.25);

            if (_selectedOptionIndex != null) {
              if (idx == q.correctIndex) {
                cardColor = AppTheme.statusGreen.withValues(alpha: 0.15);
                borderColor = AppTheme.statusGreen;
              } else if (idx == _selectedOptionIndex) {
                cardColor = AppTheme.shiningRed.withValues(alpha: 0.15);
                borderColor = AppTheme.shiningRed;
              }
            }

            return GestureDetector(
              onTap: () => _submitAnswer(idx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.shiningRed,
                      child: Text(
                        String.fromCharCode(65 + idx),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[idx],
                        style: AppTheme.getScriptTextStyle(
                          isTelugu: isTelugu,
                          fontSize: 14,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Contextual Scriptural Explanation Box
          if (_showExplanation) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.shiningRed.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.shiningRed.withValues(alpha: 0.3)),
              ),
              child: Text(
                isTelugu ? q.explanationTe : q.explanationEn,
                style: AppTheme.getScriptTextStyle(
                  isTelugu: isTelugu,
                  fontSize: 13,
                  color: AppTheme.shiningRed,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.shiningRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentQuestionIndex == 4 ? (isTelugu ? "ఫలితాలు చూడండి" : "View Final Score") : (isTelugu ? "తరువాతి ప్రశ్న" : "Next Question"),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizCompletedCard(bool isTelugu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        children: [
          const Text("🏆", style: TextStyle(fontSize: 48)),
          const SizedBox(height: 10),
          Text(
            isTelugu ? "క్విజ్ పూర్తయింది!" : "Quiz Completed!",
            style: GoogleFonts.cinzel(color: AppTheme.goldAccent, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Score: $_score / 5  |  Time: ${_elapsedSeconds}s",
            style: const TextStyle(color: AppTheme.shiningRed, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isTelugu
                ? "మీ స్కోరు నేటి ఛాంపియన్స్ లీడర్‌బోర్డ్‌లో నమోదు చేయబడింది!"
                : "Your score has been registered on Today's Champions Leaderboard!",
            style: TextStyle(
              color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _returnToLeaderboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.shiningRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.emoji_events_rounded, color: Colors.white),
              label: Text(
                isTelugu ? "లీడర్‌బోర్డ్‌కి తిరిగి వెళ్లండి" : "Return to Champions Leaderboard",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
