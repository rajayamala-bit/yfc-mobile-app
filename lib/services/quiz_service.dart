import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/quiz_model.dart';

class QuizScoreModel {
  final String id;
  final String memberId;
  final String memberName;
  final int score;
  final int total;
  final int elapsedSeconds;
  final String date;
  final DateTime completedAt;

  QuizScoreModel({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.score,
    required this.total,
    required this.elapsedSeconds,
    required this.date,
    required this.completedAt,
  });
}

class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  // Write quiz completion score to Firestore `quiz_scores` collection
  Future<void> saveQuizScore({
    required int finalScore,
    required int totalQuestions,
    required String currentMemberName,
    int elapsedSeconds = 0,
    String? quizId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await FirebaseFirestore.instance.collection('quiz_scores').add({
      'memberId': user?.uid ?? '',
      'memberName': currentMemberName,
      'score': finalScore,
      'total': totalQuestions,
      'elapsedSeconds': elapsedSeconds,
      'completedAt': FieldValue.serverTimestamp(),
      'date': todayStr,
      'quizId': quizId ?? 'latest',
    });
  }

  // Stream today's quiz scores ordered by score descending
  Stream<QuerySnapshot> streamTodayLeaderboard() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return FirebaseFirestore.instance
        .collection('quiz_scores')
        .where('date', isEqualTo: todayStr)
        .orderBy('score', descending: true)
        .snapshots();
  }

  // Stream top 3 persistent champions from current study cycle or previous cycle fallback
  Stream<List<ChampionLeaderboardUser>> streamChampionsLeaderboard({String? quizId}) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return FirebaseFirestore.instance
        .collection('quiz_scores')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getFallbackChampions(isPreviousCycle: true);
      }

      final allDocs = snapshot.docs.map((d) => d.data()).toList();

      // Filter docs for today or matching active quizId
      List<Map<String, dynamic>> targetDocs = allDocs.where((d) {
        final dDate = d['date']?.toString() ?? '';
        final dQuizId = d['quizId']?.toString() ?? '';
        if (quizId != null && quizId.isNotEmpty && quizId != 'latest') {
          return dQuizId == quizId || dDate == todayStr;
        }
        return dDate == todayStr;
      }).toList();

      bool isPreviousCycle = false;
      // If no attempts for today/current quiz yet, retain champions from previous active study cycle!
      if (targetDocs.isEmpty) {
        targetDocs = List<Map<String, dynamic>>.from(allDocs);
        isPreviousCycle = true;
      }

      // Deduplicate by member (keeping best attempt per member)
      final Map<String, Map<String, dynamic>> bestPerMember = {};
      for (final doc in targetDocs) {
        final key = (doc['memberId']?.toString().isNotEmpty == true)
            ? doc['memberId'].toString()
            : (doc['memberName']?.toString() ?? 'YFC Member');
            
        if (!bestPerMember.containsKey(key)) {
          bestPerMember[key] = doc;
        } else {
          final existing = bestPerMember[key]!;
          final existingScore = (existing['score'] as num?)?.toInt() ?? 0;
          final newScore = (doc['score'] as num?)?.toInt() ?? 0;
          final existingTime = (existing['elapsedSeconds'] as num?)?.toInt() ?? 999;
          final newTime = (doc['elapsedSeconds'] as num?)?.toInt() ?? 999;

          if (newScore > existingScore || (newScore == existingScore && newTime < existingTime)) {
            bestPerMember[key] = doc;
          }
        }
      }

      final sortedBest = bestPerMember.values.toList();
      // Sort primarily by score DESCENDING, secondarily by elapsedSeconds ASCENDING
      sortedBest.sort((a, b) {
        final scoreA = (a['score'] as num?)?.toInt() ?? 0;
        final scoreB = (b['score'] as num?)?.toInt() ?? 0;
        if (scoreB != scoreA) {
          return scoreB.compareTo(scoreA); // Highest score first
        }
        final timeA = (a['elapsedSeconds'] as num?)?.toInt() ?? 999;
        final timeB = (b['elapsedSeconds'] as num?)?.toInt() ?? 999;
        return timeA.compareTo(timeB); // Fastest time first
      });

      final medals = ["🥇", "🥈", "🥉"];
      final List<ChampionLeaderboardUser> champions = [];
      for (int i = 0; i < sortedBest.length && i < 3; i++) {
        final data = sortedBest[i];
        final name = data['memberName'] as String? ?? 'YFC Member';
        final score = (data['score'] as num?)?.toInt() ?? 0;
        final elapsed = (data['elapsedSeconds'] as num?)?.toInt() ?? 0;

        champions.add(ChampionLeaderboardUser(
          fullName: name,
          avatarUrl: medals[i],
          score: score,
          elapsedSeconds: elapsed,
          rank: i + 1,
          isPreviousCycle: isPreviousCycle,
        ));
      }

      if (champions.isEmpty) {
        return _getFallbackChampions(isPreviousCycle: isPreviousCycle);
      }

      return champions;
    });
  }

  List<ChampionLeaderboardUser> _getFallbackChampions({bool isPreviousCycle = true}) {
    return [
      ChampionLeaderboardUser(
        fullName: "David R.",
        avatarUrl: "🥇",
        score: 5,
        elapsedSeconds: 24,
        rank: 1,
        isPreviousCycle: isPreviousCycle,
      ),
      ChampionLeaderboardUser(
        fullName: "Mary K.",
        avatarUrl: "🥈",
        score: 5,
        elapsedSeconds: 31,
        rank: 2,
        isPreviousCycle: isPreviousCycle,
      ),
      ChampionLeaderboardUser(
        fullName: "Joshua P.",
        avatarUrl: "🥉",
        score: 4,
        elapsedSeconds: 18,
        rank: 3,
        isPreviousCycle: isPreviousCycle,
      ),
    ];
  }
}
