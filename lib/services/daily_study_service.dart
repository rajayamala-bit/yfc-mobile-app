import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_model.dart';
import 'gemini_quiz_service.dart';

class DailyPortionData {
  final String title;
  final String passage;
  final String bookName;
  final int startChapter;
  final int startVerse;
  final int endChapter;
  final int endVerse;
  final String studyNotesEn;
  final String studyNotesTe;
  final List<QuizQuestion> quizQuestions;
  final String publishedDate;

  const DailyPortionData({
    required this.title,
    required this.passage,
    required this.bookName,
    required this.startChapter,
    required this.startVerse,
    required this.endChapter,
    required this.endVerse,
    required this.studyNotesEn,
    required this.studyNotesTe,
    required this.quizQuestions,
    required this.publishedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'passage': passage,
      'passage_range': passage,
      'book_name': bookName,
      'start_chapter': startChapter,
      'chapter': startChapter,
      'start_verse': startVerse,
      'end_chapter': endChapter,
      'end_verse': endVerse,
      'verses': '$startVerse-$endVerse',
      'study_notes_en': studyNotesEn,
      'study_notes_te': studyNotesTe,
      'study_sheet': studyNotesEn,
      'published_date': publishedDate,
      'quiz_questions': quizQuestions.map((q) => {
        'id': q.id,
        'question_en': q.questionEn,
        'question_te': q.questionTe,
        'options_en': q.optionsEn,
        'options_te': q.optionsTe,
        'correct_index': q.correctIndex,
        'explanation_en': q.explanationEn,
        'explanation_te': q.explanationTe,
      }).toList(),
    };
  }

  factory DailyPortionData.fromJson(Map<String, dynamic> json) {
    final book = json['book_name']?.toString() ?? json['book']?.toString() ?? 'Genesis';
    final startCh = json['start_chapter'] is int
        ? json['start_chapter'] as int
        : (json['chapter'] is int ? json['chapter'] as int : 39);
    final startV = json['start_verse'] is int ? json['start_verse'] as int : 1;
    final endCh = json['end_chapter'] is int ? json['end_chapter'] as int : startCh;
    final endV = json['end_verse'] is int ? json['end_verse'] as int : 24;

    final passageStr = json['passage']?.toString() ??
        json['passage_range']?.toString() ??
        "$book $startCh:$startV–$endCh:$endV";

    final questionsRaw = (json['quiz_questions'] ?? json['questions']) as List? ?? [];
    final List<QuizQuestion> questions = questionsRaw.map((q) {
      return QuizQuestion(
        id: q['id'] is int ? q['id'] as int : int.tryParse(q['id']?.toString() ?? '1') ?? 1,
        questionEn: q['question_en']?.toString() ?? q['question']?.toString() ?? '',
        questionTe: q['question_te']?.toString() ?? q['question']?.toString() ?? '',
        optionsEn: List<String>.from(q['options_en'] ?? q['options'] ?? []),
        optionsTe: List<String>.from(q['options_te'] ?? q['options'] ?? []),
        correctIndex: q['correct_index'] is int ? q['correct_index'] as int : 0,
        explanationEn: q['explanation_en']?.toString() ?? q['explanation']?.toString() ?? '',
        explanationTe: q['explanation_te']?.toString() ?? q['explanation']?.toString() ?? '',
      );
    }).where((q) => q.questionEn.trim().isNotEmpty || q.questionTe.trim().isNotEmpty).toList();

    // Ensure 5 valid questions are always guaranteed
    if (questions.length < 5) {
      final fallbackList = GeminiQuizService().generateFallbackQuestions(
        book: book,
        chapter: startCh,
        verses: "$startV-$endV",
      );
      for (final fb in fallbackList) {
        if (questions.length >= 5) break;
        questions.add(fb);
      }
    }

    final notesEn = json['study_notes_en']?.toString() ??
        json['study_sheet']?.toString() ??
        "Detailed study notes for scripture passage $passageStr.";
    final notesTe = json['study_notes_te']?.toString() ?? notesEn;

    return DailyPortionData(
      title: json['title']?.toString() ?? "$passageStr Study Notes",
      passage: passageStr,
      bookName: book,
      startChapter: startCh,
      startVerse: startV,
      endChapter: endCh,
      endVerse: endV,
      studyNotesEn: notesEn,
      studyNotesTe: notesTe,
      quizQuestions: questions,
      publishedDate: json['published_date']?.toString() ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
  }
}

class DailyStudyService {
  static DailyPortionData? _cachedPortion;

  static void resetCache() {
    _cachedPortion = null;
  }

  // Stream real-time daily study & quiz questions from Firestore `daily_studies` collection
  static Stream<DailyPortionData?> streamDailyStudy([String? dateStr]) {
    final targetDoc = (dateStr != null && dateStr.isNotEmpty)
        ? dateStr
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    return FirebaseFirestore.instance
        .collection('daily_studies')
        .doc(targetDoc)
        .snapshots()
        .asyncMap((snap) async {
      if (snap.exists && snap.data() != null) {
        final portion = DailyPortionData.fromJson(snap.data()!);
        _cachedPortion = portion;
        return portion;
      }
      // If today's document is not yet published, fall back to streaming 'latest' doc
      if (targetDoc != 'latest') {
        final latestSnap = await FirebaseFirestore.instance
            .collection('daily_studies')
            .doc('latest')
            .get();
        if (latestSnap.exists && latestSnap.data() != null) {
          final portion = DailyPortionData.fromJson(latestSnap.data()!);
          _cachedPortion = portion;
          return portion;
        }
      }
      return null;
    });
  }

  static Future<DailyPortionData> getActiveDailyPortion() async {
    if (_cachedPortion != null) return _cachedPortion!;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 0a. Try fetching today's doc from Cloud Firestore `daily_studies`
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('daily_studies')
          .doc(todayStr)
          .get();
      if (docSnap.exists && docSnap.data() != null) {
        _cachedPortion = DailyPortionData.fromJson(docSnap.data()!);
        return _cachedPortion!;
      }
    } catch (_) {}

    // 0b. Try fetching 'latest' doc from Cloud Firestore `daily_studies`
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('daily_studies')
          .doc('latest')
          .get();
      if (docSnap.exists && docSnap.data() != null) {
        _cachedPortion = DailyPortionData.fromJson(docSnap.data()!);
        return _cachedPortion!;
      }
    } catch (_) {}

    // 1. Try fetching from Supabase database table `daily_portions`
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('daily_portions')
          .select()
          .eq('published_date', todayStr)
          .maybeSingle();

      if (res != null) {
        _cachedPortion = DailyPortionData.fromJson(res);
        return _cachedPortion!;
      }
    } catch (_) {}

    // 2. Try fetching from SharedPreferences persistent local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('custom_daily_portion');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        _cachedPortion = DailyPortionData.fromJson(data);
        return _cachedPortion!;
      }
    } catch (_) {}

    // 3. Fallback default daily portion
    _cachedPortion = DailyPortionData.fromJson({});
    return _cachedPortion!;
  }

  static Future<bool> publishDailyPortion(DailyPortionData portion) async {
    _cachedPortion = portion;
    final todayDoc = portion.publishedDate.isNotEmpty
        ? portion.publishedDate
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    final data = portion.toJson();

    // 1. Save to Cloud Firestore `daily_studies` collection (both date key AND 'latest')
    try {
      await FirebaseFirestore.instance
          .collection('daily_studies')
          .doc(todayDoc)
          .set(data, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('daily_studies')
          .doc('latest')
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("[DailyStudyService] Firestore publish error: $e");
    }

    // 2. Save to SharedPreferences locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_daily_portion', jsonEncode(data));
    } catch (_) {}

    // 3. Publish to Supabase table `daily_portions`
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('daily_portions').upsert(data);
    } catch (_) {}

    return true;
  }
}
