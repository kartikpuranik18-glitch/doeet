// lib/features/ai/presentation/ai_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  final service = AiService();
  ref.onDispose(service.dispose);
  return service;
});

// Chat message model
class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({String? content, bool? isLoading}) => ChatMessage(
        role: role,
        content: content ?? this.content,
        timestamp: timestamp,
        isLoading: isLoading ?? this.isLoading,
      );
}

// Doubt assistant
class DoubtState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const DoubtState({this.messages = const [], this.isLoading = false, this.error});

  DoubtState copyWith({List<ChatMessage>? messages, bool? isLoading, String? error}) =>
      DoubtState(messages: messages ?? this.messages, isLoading: isLoading ?? this.isLoading, error: error);
}

class DoubtNotifier extends StateNotifier<DoubtState> {
  final AiService _ai;
  final String courseContext;

  DoubtNotifier(this._ai, this.courseContext) : super(const DoubtState());

  Future<void> sendMessage(String question) async {
    if (question.trim().isEmpty) return;
    final userMsg = ChatMessage(role: 'user', content: question.trim(), timestamp: DateTime.now());
    final loadingMsg = ChatMessage(role: 'assistant', content: '', timestamp: DateTime.now(), isLoading: true);
    state = state.copyWith(messages: [...state.messages, userMsg, loadingMsg], isLoading: true, error: null);

    try {
      final history = state.messages
          .where((m) => !m.isLoading)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      final reply = await _ai.answerDoubt(question: question, courseContext: courseContext, history: history);
      final newMsgs = List<ChatMessage>.from(state.messages)
        ..removeLast()
        ..add(ChatMessage(role: 'assistant', content: reply, timestamp: DateTime.now()));
      state = state.copyWith(messages: newMsgs, isLoading: false);
    } catch (e) {
      final newMsgs = List<ChatMessage>.from(state.messages)..removeLast();
      state = state.copyWith(messages: newMsgs, isLoading: false, error: e.toString());
    }
  }

  void clear() => state = const DoubtState();
}

final doubtProvider = StateNotifierProvider.family<DoubtNotifier, DoubtState, String>(
  (ref, courseContext) => DoubtNotifier(ref.watch(aiServiceProvider), courseContext),
);

// Quiz
class QuizState {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final Map<int, int?> answers;
  final bool isCompleted;
  final bool isLoading;
  final String? error;

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const {},
    this.isCompleted = false,
    this.isLoading = false,
    this.error,
  });

  int get score => answers.entries.where((e) {
        if (e.value == null || e.key >= questions.length) return false;
        return questions[e.key].correctIndex == e.value;
      }).length;

  QuizState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    Map<int, int?>? answers,
    bool? isCompleted,
    bool? isLoading,
    String? error,
  }) =>
      QuizState(
        questions: questions ?? this.questions,
        currentIndex: currentIndex ?? this.currentIndex,
        answers: answers ?? this.answers,
        isCompleted: isCompleted ?? this.isCompleted,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class QuizNotifier extends StateNotifier<QuizState> {
  final AiService _ai;
  QuizNotifier(this._ai) : super(const QuizState());

  Future<void> generateQuiz({required String topic, required String content}) async {
    state = state.copyWith(isLoading: true, error: null, isCompleted: false, answers: {}, currentIndex: 0);
    try {
      final questions = await _ai.generateQuiz(topic: topic, content: content);
      state = state.copyWith(questions: questions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void answerQuestion(int questionIndex, int optionIndex) {
    final newAnswers = Map<int, int?>.from(state.answers)..[questionIndex] = optionIndex;
    final nextIndex = questionIndex + 1;
    state = state.copyWith(
      answers: newAnswers,
      currentIndex: nextIndex >= state.questions.length ? state.currentIndex : nextIndex,
      isCompleted: nextIndex >= state.questions.length,
    );
  }

  void reset() => state = const QuizState();
}

final quizNotifierProvider = StateNotifierProvider<QuizNotifier, QuizState>(
  (ref) => QuizNotifier(ref.watch(aiServiceProvider)),
);

// Flashcards
class FlashcardState {
  final List<Flashcard> cards;
  final int currentIndex;
  final bool isLoading;
  final String? error;

  const FlashcardState({this.cards = const [], this.currentIndex = 0, this.isLoading = false, this.error});

  FlashcardState copyWith({List<Flashcard>? cards, int? currentIndex, bool? isLoading, String? error}) =>
      FlashcardState(
        cards: cards ?? this.cards,
        currentIndex: currentIndex ?? this.currentIndex,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class FlashcardNotifier extends StateNotifier<FlashcardState> {
  final AiService _ai;
  FlashcardNotifier(this._ai) : super(const FlashcardState());

  Future<void> generate({required String topic, required String content}) async {
    state = state.copyWith(isLoading: true, error: null, currentIndex: 0);
    try {
      final cards = await _ai.generateFlashcards(topic: topic, content: content);
      state = state.copyWith(cards: cards, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void flipCurrent() {
    if (state.cards.isEmpty) return;
    final cards = List<Flashcard>.from(state.cards);
    cards[state.currentIndex].isFlipped = !cards[state.currentIndex].isFlipped;
    state = state.copyWith(cards: cards);
  }

  void next() {
    if (state.currentIndex < state.cards.length - 1) {
      final cards = List<Flashcard>.from(state.cards);
      cards[state.currentIndex].isFlipped = false;
      state = state.copyWith(cards: cards, currentIndex: state.currentIndex + 1);
    }
  }

  void previous() {
    if (state.currentIndex > 0) {
      final cards = List<Flashcard>.from(state.cards);
      cards[state.currentIndex].isFlipped = false;
      state = state.copyWith(cards: cards, currentIndex: state.currentIndex - 1);
    }
  }

  void reset() => state = const FlashcardState();
}

final flashcardNotifierProvider = StateNotifierProvider<FlashcardNotifier, FlashcardState>(
  (ref) => FlashcardNotifier(ref.watch(aiServiceProvider)),
);

// AI Summary
class AiSummaryState {
  final String? summary;
  final bool isLoading;
  final String? error;

  const AiSummaryState({this.summary, this.isLoading = false, this.error});
}

class AiSummaryNotifier extends StateNotifier<AiSummaryState> {
  final AiService _ai;
  AiSummaryNotifier(this._ai) : super(const AiSummaryState());

  Future<void> summarize({required String title, required String description}) async {
    state = const AiSummaryState(isLoading: true);
    try {
      final summary = await _ai.summarizeVideo(videoTitle: title, videoDescription: description);
      state = AiSummaryState(summary: summary);
    } catch (e) {
      state = AiSummaryState(error: e.toString());
    }
  }

  void clear() => state = const AiSummaryState();
}

final aiSummaryProvider = StateNotifierProvider<AiSummaryNotifier, AiSummaryState>(
  (ref) => AiSummaryNotifier(ref.watch(aiServiceProvider)),
);
