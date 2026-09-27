// lib/features/ai/presentation/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import 'ai_provider.dart';

class QuizScreen extends ConsumerWidget {
  final String topic;
  final String content;

  const QuizScreen({super.key, required this.topic, required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizNotifierProvider);

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(backgroundColor: AppColors.bgPrimary, title: const Text('Quiz')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accentPurple),
              SizedBox(height: 16),
              Text('Generating quiz…', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (state.isCompleted) return _ResultScreen(state: state, ref: ref, topic: topic, content: content);

    if (state.questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(backgroundColor: AppColors.bgPrimary, title: const Text('Quiz')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🧠', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text('Test Your Knowledge', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('AI will generate 5 questions about $topic', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                GradientButton(
                  label: 'Start Quiz',
                  onPressed: () => ref.read(quizNotifierProvider.notifier).generateQuiz(topic: topic, content: content),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Text(state.error!, style: const TextStyle(color: AppColors.error, fontSize: 12), textAlign: TextAlign.center),
                ],
              ],
            ).animate().fadeIn(duration: 400.ms),
          ),
        ),
      );
    }

    final question = state.questions[state.currentIndex];
    final selectedAnswer = state.answers[state.currentIndex];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text('Question ${state.currentIndex + 1} of ${state.questions.length}'),
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (state.currentIndex + 1) / state.questions.length,
            backgroundColor: AppColors.bgCard,
            valueColor: const AlwaysStoppedAnimation(AppColors.accentPurple),
            minHeight: 3,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Question
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Text(
                      question.question,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600, height: 1.5),
                    ),
                  ).animate().fadeIn().slideY(begin: -0.05),

                  const SizedBox(height: 24),
                  const Text('Choose the correct answer:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),

                  // Options
                  ...question.options.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final option = entry.value;
                    final isSelected = selectedAnswer == idx;
                    final isCorrect = idx == question.correctIndex;
                    final showResult = selectedAnswer != null;

                    Color borderColor = AppColors.border;
                    Color bgColor = AppColors.bgCard;
                    Color textColor = AppColors.textPrimary;

                    if (showResult) {
                      if (isCorrect) {
                        borderColor = AppColors.accentGreen;
                        bgColor = AppColors.accentGreen.withOpacity(0.1);
                        textColor = AppColors.accentGreen;
                      } else if (isSelected && !isCorrect) {
                        borderColor = AppColors.error;
                        bgColor = AppColors.error.withOpacity(0.1);
                        textColor = AppColors.error;
                      }
                    } else if (isSelected) {
                      borderColor = AppColors.accentPurple;
                      bgColor = AppColors.accentPurple.withOpacity(0.1);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: selectedAnswer == null
                            ? () => ref.read(quizNotifierProvider.notifier).answerQuestion(state.currentIndex, idx)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: borderColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    ['A', 'B', 'C', 'D'][idx],
                                    style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(option, style: TextStyle(color: textColor, fontSize: 14))),
                              if (showResult)
                                Icon(
                                  isCorrect ? Icons.check_circle_rounded : (isSelected ? Icons.cancel_rounded : null),
                                  color: isCorrect ? AppColors.accentGreen : AppColors.error,
                                  size: 20,
                                ),
                            ],
                          ),
                        ).animate(delay: Duration(milliseconds: idx * 80)).fadeIn().slideX(begin: 0.05),
                      ),
                    );
                  }),

                  // Explanation
                  if (selectedAnswer != null && question.explanation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question.explanation,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  const _ResultScreen({required this.state, required this.ref, required this.topic, required this.content});
  final QuizState state;
  final WidgetRef ref;
  final String topic;
  final String content;

  @override
  Widget build(BuildContext context) {
    final percent = state.score / state.questions.length;
    final emoji = percent >= 0.8 ? '🏆' : percent >= 0.6 ? '👍' : '📚';
    final message = percent >= 0.8 ? 'Excellent work!' : percent >= 0.6 ? 'Good job!' : 'Keep studying!';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 80)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(message, style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${state.score}',
                      style: const TextStyle(color: AppColors.accentPurple, fontSize: 48, fontWeight: FontWeight.w900),
                    ),
                    TextSpan(
                      text: ' / ${state.questions.length}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 32),
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(),
              const SizedBox(height: 8),
              Text(
                '${(percent * 100).toStringAsFixed(0)}% score',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => ref.read(quizNotifierProvider.notifier).generateQuiz(topic: topic, content: content),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
