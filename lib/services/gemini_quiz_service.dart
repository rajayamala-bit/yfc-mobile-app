import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_model.dart';

class GeminiQuizService {
  static const String _geminiApiKey = "YOUR_GEMINI_API_KEY"; // Configurable environment key
  static const String _geminiEndpoint = 
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent";

  /// Generates 5 bilingual (English + Telugu script) multiple choice questions based on scriptural passage context
  Future<DailyQuiz> generateDailyQuiz({
    required String book,
    required int chapter,
    required String verses,
  }) async {
    final prompt = '''
You are a scriptural Bible scholar for the Youth For Christ (YFC) fellowship.
Generate 5 multiple choice questions based strictly and exclusively on the Bible passage:
Book: $book, Chapter: $chapter, Verses: $verses.

CRITICAL MANDATE 1: Generate questions strictly and exclusively from the text between Chapter $chapter:$verses. Under no circumstances generate questions or citations from earlier or later chapters.
CRITICAL MANDATE 2: Ensure the correct answer is randomly distributed across options A, B, C, and D (correct_index 0, 1, 2, or 3). Do NOT always place the correct answer as option A/first option.

Return ONLY a valid raw JSON array containing exactly 5 question objects. No markdown formatting, no code block backticks.
JSON Format required:
[
  {
    "id": 1,
    "question_en": "English question text?",
    "question_te": "తెలుగు ప్రశ్న పాఠం?",
    "options_en": ["Option A", "Option B", "Option C", "Option D"],
    "options_te": ["ఎంపిక A", "ఎంపిక B", "ఎంపిక C", "ఎంపిక D"],
    "correct_index": 0,
    "explanation_en": "English scriptural explanation of the answer.",
    "explanation_te": "తెలుగులో వచన వివరణ."
  }
]
''';

    try {
      if (_geminiApiKey == "YOUR_GEMINI_API_KEY") {
        return generateFallbackQuiz(book: book, chapter: chapter, verses: verses);
      }

      final response = await http.post(
        Uri.parse("$_geminiEndpoint?key=$_geminiApiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'responseMimeType': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final String rawText = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        final List<dynamic> parsedList = jsonDecode(rawText);

        final questions = parsedList
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList();

        if (questions.length < 5) {
          return generateFallbackQuiz(book: book, chapter: chapter, verses: verses);
        }

        return DailyQuiz(
          id: "quiz-${DateTime.now().millisecondsSinceEpoch}",
          quizDate: DateTime.now().toIso8601String().substring(0, 10),
          book: book,
          chapter: chapter,
          verses: verses,
          questions: questions,
        );
      } else {
        return generateFallbackQuiz(book: book, chapter: chapter, verses: verses);
      }
    } catch (e) {
      return generateFallbackQuiz(book: book, chapter: chapter, verses: verses);
    }
  }

  DailyQuiz generateFallbackQuiz({
    required String book,
    required int chapter,
    required String verses,
  }) {
    return DailyQuiz(
      id: "quiz-${book.toLowerCase()}-$chapter",
      quizDate: DateTime.now().toIso8601String().substring(0, 10),
      book: book,
      chapter: chapter,
      verses: verses,
      questions: generateFallbackQuestions(book: book, chapter: chapter, verses: verses),
    );
  }

  List<QuizQuestion> generateFallbackQuestions({
    required String book,
    required int chapter,
    required String verses,
  }) {
    final passageRef = "$book $chapter:$verses";
    return [
        QuizQuestion(
          id: 1,
          questionEn: "What is the primary spiritual insight revealed in $passageRef?",
          questionTe: "$passageRef లో బయలుపరచబడిన ప్రధాన ఆత్మీయ పాఠము ఏమిటి?",
          optionsEn: [
            "Human traditions and customs",
            "God's faithful covenant love and guidance",
            "Historical timelines only",
            "Geographical terrain details"
          ],
          optionsTe: [
            "మానవ సాంప్రదాయాలు",
            "దేవుని విశ్వసనీయమైన నిబంధన ప్రేమ మరియు నడిపింపు",
            "చారిత్రక వివరాలు మాత్రమే",
            "భౌగోళిక సరిహద్దులు"
          ],
          correctIndex: 1,
          explanationEn: "[$passageRef] - Scripture reveals God's unchanging covenant faithfulness and guiding grace.",
          explanationTe: "[$passageRef] - పరిశుద్ధ గ్రంథము దేవుని మార్పులేని నిబంధన నమ్మకత్వాన్ని బయలుపరుస్తుంది.",
        ),
        QuizQuestion(
          id: 2,
          questionEn: "According to $passageRef, how should believers respond to God's direction?",
          questionTe: "$passageRef ప్రకారము విశ్వాసులు దేవుని నడిపింపుకు ఎలా స్పందించాలి?",
          optionsEn: [
            "With hesitation and doubt",
            "By relying on human wisdom",
            "With obedient faith and sincere prayer",
            "By following crowd opinion"
          ],
          optionsTe: [
            "అనుమానము మరియు సంకోచముతో",
            "మానవ జ్ఞానముపై ఆధారపడటం ద్వారా",
            "విధేయత కలిగిన విశ్వాసము మరియు ప్రార్థనతో",
            "లోక అభిప్రాయాలను అనుసరించడం ద్వారా"
          ],
          correctIndex: 2,
          explanationEn: "[$passageRef] - True faith responds to divine truth through willing obedience and prayer.",
          explanationTe: "[$passageRef] - నిజమైన విశ్వాసము దైవిక సత్యమునకు విధేయత చూపుతుంది.",
        ),
        QuizQuestion(
          id: 3,
          questionEn: "What divine attribute is highlighted in the text of $passageRef?",
          questionTe: "$passageRef వాక్య భాగములో దేవుని ఏ పరిశుద్ధ గుణలక్షణము స్పష్టమవుతోంది?",
          optionsEn: [
            "God's holiness, protection, and mercy",
            "Indifference toward His people",
            "Uncertain guidance",
            "Temporary promises"
          ],
          optionsTe: [
            "దేవుని పరిశుద్ధత, సంరక్షణ మరియు కనికరము",
            "తన ప్రజల పట్ల నిర్లక్ష్యము",
            "అస్పష్టమైన నడిపింపు",
            "తాత్కాలిక వాగ్దానాలు"
          ],
          correctIndex: 0,
          explanationEn: "[$passageRef] - God's divine protection and merciful grace encompass His covenant children.",
          explanationTe: "[$passageRef] - దేవుని దయా కనికరములు మరియు రక్షణ తన పిల్లలకు తోడుగా ఉంటాయి.",
        ),
        QuizQuestion(
          id: 4,
          questionEn: "What key takeaway in $passageRef strengthens a youth's fellowship walk?",
          questionTe: "$passageRef లోని ఏ ఆత్మీయ అంశము యౌవనస్థుల విశ్వాస జీవితాన్ని బలపరుస్తుంది?",
          optionsEn: [
            "Seeking immediate worldly success",
            "Avoiding spiritual accountability",
            "Comparing oneself with others",
            "Trusting God's promises in every trial"
          ],
          optionsTe: [
            "లోకసంబంధమైన విజయాన్ని మాత్రమే కోరుకోవడం",
            "ఆత్మీయ బాధ్యతలను విస్మరించడం",
            "ఇతరులతో పోల్చుకోవడం",
            "శోధనలలో దేవుని వాగ్దానాలను విశ్వసించడం"
          ],
          correctIndex: 3,
          explanationEn: "[$passageRef] - Standing firm upon scripture promises provides spiritual victory.",
          explanationTe: "[$passageRef] - దేవుని వాగ్దానాలపై నిలబడటం ఆత్మీయ విజయాన్ని ఇస్తుంది.",
        ),
        QuizQuestion(
          id: 5,
          questionEn: "How does $passageRef point toward Christ's redemptive work?",
          questionTe: "$passageRef క్రీస్తు రక్షణ కార్యాన్ని ఏ విధంగా ముందుగానే సూచిస్తోంది?",
          optionsEn: [
            "By promoting ritual sacrifices only",
            "By demonstrating God's grace and salvation plan",
            "By focusing on earthly dominion",
            "By emphasizing human merit"
          ],
          optionsTe: [
            "ఆచారాలను మాత్రమే ప్రాముఖ్యపరచడం ద్వారా",
            "దేవుని కృపను మరియు రక్షణ ప్రణాళికను బయలుపరచడం ద్వారా",
            "లౌకిక పరిపాలనపై దృష్టి పెట్టడం ద్వారా",
            "మానవ ప్రయత్నాలను హెచ్చించడం ద్వారా"
          ],
          correctIndex: 1,
          explanationEn: "[$passageRef] - All scripture points to the eternal salvation offered through Jesus Christ.",
          explanationTe: "[$passageRef] - సమస్త పరిశుద్ధ గ్రంథము క్రీస్తు ద్వారా లభించే నిత్య రక్షణను సూచిస్తుంది.",
        ),
      ];
  }
}

