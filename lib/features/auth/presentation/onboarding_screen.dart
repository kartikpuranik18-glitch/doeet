// lib/features/auth/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardSlide(
      emoji: '📚',
      title: 'Learn Without\nLimits',
      subtitle:
          'Import any YouTube playlist and turn it into a structured course with progress tracking, notes, and AI assistance.',
      gradientColors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
    ),
    _OnboardSlide(
      emoji: '🤖',
      title: 'AI-Powered\nInsights',
      subtitle:
          'Get instant summaries, flashcards, quizzes, and a personal AI tutor for every video you watch.',
      gradientColors: [Color(0xFF00D4AA), Color(0xFF00B890)],
    ),
    _OnboardSlide(
      emoji: '🔥',
      title: 'Stay Consistent.\nLevel Up.',
      subtitle:
          'Build daily streaks, earn XP, unlock achievement badges, and climb the global leaderboard.',
      gradientColors: [Color(0xFFFF6B35), Color(0xFFFF4500)],
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Page content
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (context, i) {
              final slide = _slides[i];
              return _OnboardPage(slide: slide, index: i);
            },
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                AppSizes.lg,
                AppSizes.screenPadding,
                MediaQuery.of(context).padding.bottom + AppSizes.lg,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.bg],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.textMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Next / Get Started button
                  GradientButton(
                    label: _currentPage == _slides.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    onPressed: _next,
                    gradient: LinearGradient(
                      colors: _slides[_currentPage].gradientColors,
                    ),
                    icon: Icon(
                      _currentPage == _slides.length - 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Skip / Login
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      _currentPage == _slides.length - 1
                          ? 'Already have an account? Login'
                          : 'Skip',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
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
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({required this.slide, required this.index});
  final _OnboardSlide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          // Emoji illustration
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradientColors
                    .map((c) => c.withOpacity(0.15))
                    .toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                slide.emoji,
                style: const TextStyle(fontSize: 72),
              ),
            ),
          )
              .animate(key: ValueKey('emoji_$index'))
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 48),
          // Title
          Text(
            slide.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.5,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('title_$index'), delay: 200.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 20),
          // Subtitle
          Text(
            slide.subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('sub_$index'), delay: 350.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}

class _OnboardSlide {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  const _OnboardSlide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });
}
