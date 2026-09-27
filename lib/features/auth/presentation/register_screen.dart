// lib/features/auth/presentation/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/gradient_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  final _selectedCategories = <String>{};

  static const _categories = [
    '💻 Programming',
    '📐 Mathematics',
    '🔬 Science',
    '🎨 Design',
    '📈 Business',
    '🗣️ Languages',
    '🎵 Music',
    '🏋️ Health',
    '📱 Mobile Dev',
    '🤖 AI & ML',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
        );
    final state = ref.read(authNotifierProvider);
    state.whenOrNull(
      error: (e, _) => _showSnack(authErrorMessage(e), isError: true),
      data: (_) {
        if (mounted) context.go('/home');
      },
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create Account 🚀',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -1),
                ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),
                const Text(
                  'Start your learning adventure today',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: AppColors.textSecondary),
                ).animate(delay: 100.ms).fadeIn(),
                const SizedBox(height: 32),
                _buildField(
                    _nameCtrl, 'Full name', Icons.person_outline_rounded,
                    delay: 150,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Enter your name' : null),
                const SizedBox(height: 14),
                _buildField(_emailCtrl, 'Email address', Icons.email_outlined,
                    delay: 200,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) =>
                        !v!.contains('@') ? 'Invalid email' : null),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontFamily: 'Inter'),
                  decoration: InputDecoration(
                    hintText: 'Password (min 6 chars)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      v!.length < 6 ? 'At least 6 characters' : null,
                ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2, end: 0),
                const SizedBox(height: 28),
                const Text(
                  'What do you want to learn? 🎯',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ).animate(delay: 300.ms).fadeIn(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final selected = _selectedCategories.contains(cat);
                    return GestureDetector(
                      onTap: () => setState(() {
                        selected
                            ? _selectedCategories.remove(cat)
                            : _selectedCategories.add(cat);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: selected ? 1.5 : 1),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                        ),
                      ),
                    );
                  }).toList(),
                ).animate(delay: 350.ms).fadeIn(),
                const SizedBox(height: 32),
                GradientButton(
                  label: 'Create Account',
                  onPressed: isLoading ? null : _register,
                  isLoading: isLoading,
                  icon: const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 18),
                ).animate(delay: 400.ms).fadeIn(),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Already have an account? ",
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                          fontSize: 14)),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text('Login',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ),
                ]).animate(delay: 450.ms).fadeIn(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon,
      {int delay = 0,
      TextInputType? keyboard,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter'),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted),
      ),
      validator: validator,
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideY(begin: 0.2, end: 0);
  }
}
