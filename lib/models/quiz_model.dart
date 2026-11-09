import 'dart:math' as math;

class QuizQuestion {
  final int id;
  final String questionEn;
  final String questionTe;
  final List<String> optionsEn;
  final List<String> optionsTe;
  final int correctIndex;
  final String explanationEn;
  final String explanationTe;

  QuizQuestion({
    required this.id,
    required this.questionEn,
    required this.questionTe,
    required this.optionsEn,
    required this.optionsTe,
    required this.correctIndex,
    required this.explanationEn,
    required this.explanationTe,
  });

  /// Shuffles options dynamically while maintaining 100% accurate correctIndex mapping
  QuizQuestion get shuffled {
    if (optionsEn.isEmpty) return this;

    final random = math.Random();
    final List<int> indices = List<int>.generate(optionsEn.length, (i) => i)..shuffle(random);

    final newOptionsEn = indices.map((i) => optionsEn[i]).toList();
    final newOptionsTe = (optionsTe.length == optionsEn.length)
        ? indices.map((i) => optionsTe[i]).toList()
        : optionsTe;

    final validOriginalCorrectIndex = (correctIndex >= 0 && correctIndex < optionsEn.length) ? correctIndex : 0;
    final newCorrectIndex = indices.indexOf(validOriginalCorrectIndex);

    return QuizQuestion(
      id: id,
      questionEn: questionEn,
      questionTe: questionTe,
      optionsEn: newOptionsEn,
      optionsTe: newOptionsTe,
      correctIndex: newCorrectIndex >= 0 ? newCorrectIndex : 0,
      explanationEn: explanationEn,
      explanationTe: explanationTe,
    );
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json, {bool autoShuffle = true}) {
    final parsed = QuizQuestion(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      questionEn: json['question_en']?.toString() ?? json['question']?.toString() ?? '',
      questionTe: json['question_te']?.toString() ?? json['question']?.toString() ?? '',
      optionsEn: List<String>.from(json['options_en'] ?? json['options'] ?? []),
      optionsTe: List<String>.from(json['options_te'] ?? json['options'] ?? []),
      correctIndex: json['correct_index'] is int ? json['correct_index'] as int : 0,
      explanationEn: json['explanation_en']?.toString() ?? json['explanation']?.toString() ?? '',
      explanationTe: json['explanation_te']?.toString() ?? json['explanation']?.toString() ?? '',
    );
    return autoShuffle ? parsed.shuffled : parsed;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_en': questionEn,
      'question_te': questionTe,
      'options_en': optionsEn,
      'options_te': optionsTe,
      'correct_index': correctIndex,
      'explanation_en': explanationEn,
      'explanation_te': explanationTe,
    };
  }
}

class DailyQuiz {
  final String id;
  final String quizDate;
  final String book;
  final int chapter;
  final String verses;
  final List<QuizQuestion> questions;

  DailyQuiz({
    required this.id,
    required this.quizDate,
    required this.book,
    required this.chapter,
    required this.verses,
    required List<QuizQuestion> questions,
    bool shuffleOptions = true,
  }) : questions = shuffleOptions ? questions.map((q) => q.shuffled).toList() : questions;

  factory DailyQuiz.fromJson(Map<String, dynamic> json) {
    var questionsList = (json['questions'] as List? ?? [])
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList();

    return DailyQuiz(
      id: json['id'] ?? '',
      quizDate: json['quiz_date'] ?? '',
      book: json['book'] ?? '',
      chapter: json['chapter'] ?? 1,
      verses: json['verses'] ?? '',
      questions: questionsList,
    );
  }
}

class ChampionLeaderboardUser {
  final String fullName;
  final String avatarUrl;
  final int score;
  final int elapsedSeconds;
  final int rank;
  final bool isPreviousCycle;

  ChampionLeaderboardUser({
    required this.fullName,
    required this.avatarUrl,
    required this.score,
    required this.elapsedSeconds,
    required this.rank,
    this.isPreviousCycle = false,
  });
}
