// lib/features/ai/data/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// OpenAI GPT-4o integration for Doeet AI features
/// Replace [_apiKey] with your OpenAI API key from platform.openai.com
class AiService {
  static const String _configuredApiKey =
      String.fromEnvironment('OPENAI_API_KEY');
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o';

  final http.Client _client;
  final String _apiKey;

  AiService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ?? _configuredApiKey;

  /// Core completion method
  Future<String> _complete({
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.7,
    int maxTokens = 1500,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError(
          'AI is not configured. Set OPENAI_API_KEY or use a backend proxy.');
    }
    final language =
      (await SharedPreferences.getInstance()).getString('aiLanguage');
    final localizedPrompt = language == null || language == 'English'
      ? systemPrompt
      : '$systemPrompt Respond in $language.';
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': localizedPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      final err = jsonDecode(response.body);
      throw Exception('OpenAI error ${response.statusCode}: ${err['error']['message']}');
    }
  }

  /// Summarize a YouTube video transcript or description into key points
  Future<String> summarizeVideo({
    required String videoTitle,
    required String videoDescription,
  }) async {
    return _complete(
      systemPrompt: '''You are an expert learning assistant for Doeet, an AI-powered learning platform.
Summarize educational video content into concise, structured notes.
Format with: Brief overview (2-3 sentences), Key Concepts (bullet list), Takeaways (3 bullets).
Use markdown formatting. Be concise and student-friendly.''',
      userMessage: '''Video Title: $videoTitle

Description / Transcript:
$videoDescription

Generate structured study notes from this content.''',
    );
  }

  /// Generate comprehensive study notes for a course/topic
  Future<String> generateNotes({
    required String topic,
    required String context,
  }) async {
    return _complete(
      systemPrompt: '''You are an expert tutor creating detailed study notes.
Format notes with: Introduction, Main Concepts (with sub-bullets), Examples, Summary.
Use markdown. Include emojis for section headers to make notes engaging.
Focus on clarity and memorability.''',
      userMessage: '''Generate comprehensive study notes for:
Topic: $topic
Context: $context''',
      maxTokens: 2000,
    );
  }

  /// Generate a quiz with multiple-choice questions
  Future<List<QuizQuestion>> generateQuiz({
    required String topic,
    required String content,
    int questionCount = 5,
  }) async {
    final raw = await _complete(
      systemPrompt: '''You are a quiz generator. Create multiple-choice questions from educational content.
ALWAYS respond with valid JSON array, no other text.
Format: [{"question": "...", "options": ["A", "B", "C", "D"], "correct": 0, "explanation": "..."}]
correct is 0-indexed position of the correct answer.''',
      userMessage: '''Generate $questionCount multiple-choice questions about:
Topic: $topic
Content: $content''',
      temperature: 0.5,
      maxTokens: 2000,
    );

    try {
      // Extract JSON from response
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']') + 1;
      final jsonStr = raw.substring(jsonStart, jsonEnd);
      final List<dynamic> data = jsonDecode(jsonStr);
      return data.map((q) => QuizQuestion.fromJson(q)).toList();
    } catch (_) {
      throw Exception('Failed to parse quiz response');
    }
  }

  /// Generate flashcards (term/definition pairs)
  Future<List<Flashcard>> generateFlashcards({
    required String topic,
    required String content,
    int count = 8,
  }) async {
    final raw = await _complete(
      systemPrompt: '''You are a flashcard generator for students.
ALWAYS respond with valid JSON array only.
Format: [{"front": "Term or Question", "back": "Definition or Answer"}]
Keep fronts concise (under 10 words) and backs clear (1-3 sentences).''',
      userMessage: '''Generate $count flashcards for:
Topic: $topic
Content: $content''',
      temperature: 0.4,
      maxTokens: 1500,
    );

    try {
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']') + 1;
      final jsonStr = raw.substring(jsonStart, jsonEnd);
      final List<dynamic> data = jsonDecode(jsonStr);
      return data.map((f) => Flashcard.fromJson(f)).toList();
    } catch (_) {
      throw Exception('Failed to parse flashcards response');
    }
  }

  /// AI doubt assistant — answer a student's question in context
  Future<String> answerDoubt({
    required String question,
    required String courseContext,
    required List<Map<String, String>> history,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError(
          'AI is not configured. Set OPENAI_API_KEY or use a backend proxy.');
    }
    final language =
        (await SharedPreferences.getInstance()).getString('aiLanguage');
    final localizedContext = language == null || language == 'English'
        ? courseContext
        : '$courseContext\nRespond in $language.';
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': '''You are Doeet AI, a patient and knowledgeable learning assistant.
You help students understand concepts from their courses.
Course context: $localizedContext
Be concise, use examples, and encourage curiosity. Use markdown formatting.''',
      },
      ...history.map((m) => {'role': m['role']!, 'content': m['content']!}),
      {'role': 'user', 'content': question},
    ];

    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('AI request failed: ${response.statusCode}');
    }
  }

  void dispose() => _client.close();
}

// ── Data models ──────────────────────────────────────────────────────────────

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        question: j['question'] as String,
        options: List<String>.from(j['options']),
        correctIndex: j['correct'] as int,
        explanation: j['explanation'] as String? ?? '',
      );
}

class Flashcard {
  final String front;
  final String back;
  bool isFlipped;

  Flashcard({required this.front, required this.back, this.isFlipped = false});

  factory Flashcard.fromJson(Map<String, dynamic> j) =>
      Flashcard(front: j['front'] as String, back: j['back'] as String);
}
