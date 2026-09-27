// lib/features/ai/presentation/flashcards_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'ai_provider.dart';

class FlashcardsScreen extends ConsumerWidget {
  final String topic;
  final String content;

  const FlashcardsScreen({super.key, required this.topic, required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flashcardNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: const Text('Flashcards'),
        actions: [
          if (state.cards.isNotEmpty)
            TextButton.icon(
              onPressed: () => ref.read(flashcardNotifierProvider.notifier).reset(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Regenerate'),
              style: TextButton.styleFrom(foregroundColor: AppColors.accentPurple),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.accentPurple),
                  SizedBox(height: 16),
                  Text('Generating flashcards…', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : state.cards.isEmpty
              ? _GenerateView(
                  onGenerate: () => ref
                      .read(flashcardNotifierProvider.notifier)
                      .generate(topic: topic, content: content),
                )
              : _FlashcardView(state: state, ref: ref),
    );
  }
}

class _GenerateView extends StatelessWidget {
  const _GenerateView({required this.onGenerate});
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🗂️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('Generate Flashcards', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('AI will create study cards for this topic', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Generate with AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _FlashcardView extends StatefulWidget {
  const _FlashcardView({required this.state, required this.ref});
  final FlashcardState state;
  final WidgetRef ref;

  @override
  State<_FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<_FlashcardView> with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipCtrl.isCompleted) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    widget.ref.read(flashcardNotifierProvider.notifier).flipCurrent();
  }

  void _next() {
    _flipCtrl.reset();
    widget.ref.read(flashcardNotifierProvider.notifier).next();
  }

  void _prev() {
    _flipCtrl.reset();
    widget.ref.read(flashcardNotifierProvider.notifier).previous();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final card = state.cards[state.currentIndex];
    final progress = (state.currentIndex + 1) / state.cards.length;

    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${state.currentIndex + 1} / ${state.cards.length}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const Text('Tap card to flip', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.bgCard,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accentPurple),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),

        // Flashcard
        Expanded(
          child: GestureDetector(
            onTap: _flip,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (_, __) {
                  final angle = _flipAnim.value * pi;
                  final isBack = angle > pi / 2;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: isBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _CardFace(
                              label: 'ANSWER',
                              content: card.back,
                              color: AppColors.bgElevated,
                              accentColor: AppColors.accentGreen,
                            ),
                          )
                        : _CardFace(
                            label: 'QUESTION',
                            content: card.front,
                            color: AppColors.bgElevated,
                            accentColor: AppColors.accentPurple,
                          ),
                  );
                },
              ),
            ),
          ),
        ),

        // Navigation
        Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.currentIndex > 0 ? _prev : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.currentIndex < state.cards.length - 1 ? _next : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.label,
    required this.content,
    required this.color,
    required this.accentColor,
  });

  final String label;
  final String content;
  final Color color;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 24, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              const Text('Tap to flip', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
