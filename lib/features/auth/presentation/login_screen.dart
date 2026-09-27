// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/gradient_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    final state = ref.read(authNotifierProvider);
    state.whenOrNull(
      error: (e, _) => _showError(authErrorMessage(e)),
      data: (_) {
        if (mounted) context.go('/home');
      },
    );
  }

  Future<void> _googleSignIn() async {
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.signInWithGoogle();
    final state = ref.read(authNotifierProvider);
    state.whenOrNull(
      error: (e, _) => _showError(authErrorMessage(e)),
      data: (_) {
        if (mounted) context.go('/home');
      },
    );
  }

  Future<void> _guestSignIn() async {
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.signInAsGuest();
    final state = ref.read(authNotifierProvider);
    state.whenOrNull(
      error: (e, _) => _showError(authErrorMessage(e)),
      data: (_) {
        if (mounted) context.go('/home');
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    // Logo
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('D',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Inter',
                            )),
                      ),
                    )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 32),
                    // Heading
                    const Text(
                      'Welcome back 👋',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    )
                        .animate(delay: 100.ms)
                        .fadeIn()
                        .slideY(begin: 0.3, end: 0),
                    const SizedBox(height: 8),
                    const Text(
                      'Continue your learning journey',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ).animate(delay: 150.ms).fadeIn(),
                    const SizedBox(height: 40),
                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontFamily: 'Inter'),
                      decoration: const InputDecoration(
                        hintText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined,
                            color: AppColors.textMuted),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your email';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    )
                        .animate(delay: 200.ms)
                        .fadeIn()
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 16),
                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontFamily: 'Inter'),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.textMuted),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Enter your password';
                        if (v.length < 6) return 'Password too short';
                        return null;
                      },
                    )
                        .animate(delay: 250.ms)
                        .fadeIn()
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 12),
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPassword(),
                        child: const Text('Forgot password?',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontFamily: 'Inter',
                                fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sign In
                    GradientButton(
                      label: 'Sign In',
                      onPressed: isLoading ? null : _signIn,
                      isLoading: isLoading,
                    )
                        .animate(delay: 300.ms)
                        .fadeIn()
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 20),
                    // Divider
                    Row(children: [
                      const Expanded(
                          child:
                              Divider(color: AppColors.border, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontFamily: 'Inter',
                                fontSize: 13)),
                      ),
                      const Expanded(
                          child:
                              Divider(color: AppColors.border, thickness: 1)),
                    ]),
                    const SizedBox(height: 20),
                    // Google Sign-In
                    OutlinedButton(
                      onPressed: isLoading ? null : _googleSignIn,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white,
                            ),
                            child: const Center(
                                child: Text('G',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4285F4)))),
                          ),
                          const SizedBox(width: 12),
                          const Text('Continue with Google',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ).animate(delay: 350.ms).fadeIn(),
                    const SizedBox(height: 12),
                    // Guest
                    TextButton(
                      onPressed: isLoading ? null : _guestSignIn,
                      style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44)),
                      child: const Text('Continue as Guest',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontFamily: 'Inter',
                              fontSize: 14)),
                    ).animate(delay: 400.ms).fadeIn(),
                    const SizedBox(height: 32),
                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ",
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                                fontSize: 14)),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: const Text('Register',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ).animate(delay: 450.ms).fadeIn(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        var isSending = false;
        String? errorMessage;
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Reset Password',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('Enter your email to receive a reset link',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                      fontSize: 14)),
              const SizedBox(height: 20),
              TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email address'),
                style: const TextStyle(
                    color: AppColors.textPrimary, fontFamily: 'Inter'),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(errorMessage!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 16),
              GradientButton(
                label: isSending ? 'Sending…' : 'Send Reset Link',
                isLoading: isSending,
                onPressed: isSending
                    ? null
                    : () async {
                        final email = ctrl.text.trim();
                        if (!email.contains('@')) {
                          setModalState(() =>
                              errorMessage = 'Enter a valid email address.');
                          return;
                        }

                        setModalState(() {
                          isSending = true;
                          errorMessage = null;
                        });
                        await ref
                            .read(authNotifierProvider.notifier)
                            .sendPasswordReset(email);
                        final result = ref.read(authNotifierProvider);
                        if (!ctx.mounted) return;
                        final error = result.whenOrNull(
                          error: (e, _) => authErrorMessage(e),
                        );
                        if (error != null) {
                          setModalState(() {
                            isSending = false;
                            errorMessage = error;
                          });
                          return;
                        }
                        Navigator.pop(ctx);
                        _showSuccess('Reset link sent. Check your email.');
                      },
              ),
            ]),
          ),
        );
      },
    ).whenComplete(ctrl.dispose);
  }
}
