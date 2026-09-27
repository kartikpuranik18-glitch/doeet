// lib/features/auth/presentation/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 2800), _checkAuth);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _checkAuth() {
    final authState = ref.read(firebaseAuthStateProvider);
    authState.when(
      data: (user) {
        if (!mounted) return;
        if (user != null) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      },
      loading: () {},
      error: (_, __) {
        if (mounted) context.go('/onboarding');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth changes after initial delay
    ref.listen(firebaseAuthStateProvider, (_, next) {});

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background radial glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) => Transform.scale(
                    scale: 1.0 + (_pulseCtrl.value * 0.05),
                    child: child,
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'D',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 24),
                // App name
                const Text(
                  'Doeet',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -2,
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),
                const Text(
                  'Learn Smarter. Go Further.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 60),
                // Loading dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(
                          delay: Duration(milliseconds: 800 + (i * 150)),
                          onPlay: (ctrl) => ctrl.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1.2, 1.2),
                          duration: 600.ms,
                          curve: Curves.easeInOut,
                        )
                        .fadeIn(duration: 300.ms),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
