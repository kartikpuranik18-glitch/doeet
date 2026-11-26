import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

/// Gemini-backed learning assistant.
///
/// The Gemini key is intentionally held only by the Firebase callable
/// function. No API key is shipped in the mobile or web app.
class AiService {
  AiService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<String> _complete({
    required String systemPrompt,
    required String userMessage,
    List<Map<String, String>> history = const [],
    double temperature = .7,
    int maxTokens = 1500,
  }) async {
    final result = await _functions.httpsCallable('geminiTutor').call({
      'systemPrompt': systemPrompt,
      'message': userMessage,
      'history': history,
      'temperature': temperature,
      'maxTokens': maxTokens,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final text = data['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw StateError('Gemini returned an empty response. Please try again.');
    }
    return text;
  }

  Future<String> summarizeVideo({
    required String videoTitle,
    required String videoDescription,
  }) =>
      _complete(
        systemPrompt: 'You are Dooet Gemini Tutor. Create concise, accurate study notes. Use: Overview, Key concepts, and Takeaways. Use helpful Markdown.',
        userMessage: 'Video title: $videoTitle\n\nContent:\n$videoDescription',
      );

  Future<String> generateNotes({
    required String topic,
    required String context,
  }) =>
      _complete(
        systemPrompt: 'You are Dooet Gemini Tutor. Create clear study notes with an introduction, core concepts, examples, and a concise summary. Use Markdown.',
        userMessage: 'Topic: $topic\n\nContext: $context',
        maxTokens: 2000,
      );

  Future<List<QuizQuestion>> generateQuiz({
    required String topic,
    required String content,
    int questionCount = 5,
  }) async {
    final raw = await _complete(
      systemPrompt: 'You create reliable learning quizzes. Return ONLY a JSON array using this exact shape: [{"question":"...","options":["A","B","C","D"],"correct":0,"explanation":"..."}]. The correct value is zero-indexed.',
      userMessage: 'Create $questionCount multiple-choice questions for $topic using:\n$content',
      temperature: .4,
      maxTokens: 2000,
    );
    return _parseArray(raw).map((item) => QuizQuestion.fromJson(item)).toList();
  }

  Future<List<Flashcard>> generateFlashcards({
    required String topic,
    required String content,
    int count = 8,
  }) async {
    final raw = await _complete(
      systemPrompt: 'You create effective study flashcards. Return ONLY a JSON array using this shape: [{"front":"short question or term","back":"clear answer"}].',
      userMessage: 'Create $count flashcards for $topic using:\n$content',
      temperature: .4,
    );
    return _parseArray(raw).map((item) => Flashcard.fromJson(item)).toList();
  }

  Future<String> answerDoubt({
    required String question,
    required String courseContext,
    required List<Map<String, String>> history,
  }) =>
      _complete(
        systemPrompt: 'You are Dooet Gemini Tutor, a patient learning coach. Help the student understand rather than just giving an answer. Use short explanations, examples, and Markdown. Say clearly when information is uncertain. Course context: $courseContext',
        userMessage: question,
        history: history,
        maxTokens: 1000,
      );

  List<Map<String, dynamic>> _parseArray(String raw) {
    try {
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start < 0 || end < start) throw const FormatException();
      return List<Map<String, dynamic>>.from(
        (jsonDecode(raw.substring(start, end + 1)) as List)
            .map((item) => Map<String, dynamic>.from(item as Map)),
      );
    } catch (_) {
      throw StateError('Gemini returned an unexpected quiz or flashcard format.');
    }
  }

  void dispose() {}
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  const QuizQuestion({required this.question, required this.options, required this.correctIndex, required this.explanation});
  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(question: json['question'] as String, options: List<String>.from(json['options'] as List), correctIndex: json['correct'] as int, explanation: json['explanation'] as String? ?? '');
}

class Flashcard {
  final String front;
  final String back;
  bool isFlipped;
  Flashcard({required this.front, required this.back, this.isFlipped = false});
  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(front: json['front'] as String, back: json['back'] as String);
}
