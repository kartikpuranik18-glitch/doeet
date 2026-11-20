// lib/features/auth/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/gradient_button.dart';

// ─── Data ───────────────────────────────────────────────────────────────────

enum UserRole {
  student('Student / Learner', '🎓', 'Learn new skills and grow your knowledge'),
  jobSeeker('Job Seeker', '💼', 'Prepare for your dream career'),
  professional('Working Professional', '🚀', 'Level up your existing skills'),
  company('Company / Recruiter', '🏢', 'Find and train top talent');

  const UserRole(this.label, this.emoji, this.description);
  final String label;
  final String emoji;
  final String description;
}

const _allInterests = [
  'Programming',
  'Electronics',
  'AI/ML',
  'Data Science',
  'Web Dev',
  'Cybersecurity',
  'Cloud',
  'IoT',
  'Design',
  'Business',
];

const _industries = [
  'Technology',
  'Finance',
  'Healthcare',
  'Education',
  'Manufacturing',
  'Retail',
  'Media',
  'Consulting',
  'Government',
  'Other',
];

// ─── Screen ─────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _step = 0;
  UserRole _selectedRole = UserRole.student;
  final Set<String> _selectedInterests = {};
  String? _selectedIndustry;
  bool _nameError = false;

  static const int _totalSteps = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      _goToStep(_step + 1);
    }
  }

  void _back() {
    if (_step > 0) {
      _goToStep(_step - 1);
    }
  }

  bool get _isInterestsStep => _step == 2;

  void _handleGetStarted() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    setState(() => _nameError = false);

    final extra = <String, dynamic>{
      'displayName': name,
      'role': _selectedRole.name,
      'interests': _selectedInterests.toList(),
      if (_selectedIndustry != null) 'industry': _selectedIndustry,
    };
    context.go('/register', extra: extra);
  }

  void _handleSignIn() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar ───────────────────────────────────────────────
            _ProgressHeader(
              step: _step,
              totalSteps: _totalSteps,
              onBack: _step > 0 ? _back : null,
            ),

            // ── Page content ───────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1Welcome(onNext: _next),
                  _Step2Role(
                    selected: _selectedRole,
                    onChanged: (r) => setState(() => _selectedRole = r),
                    onNext: _next,
                  ),
                  _Step3Interests(
                    role: _selectedRole,
                    selectedInterests: _selectedInterests,
                    selectedIndustry: _selectedIndustry,
                    onInterestToggled: (i) => setState(() {
                      if (_selectedInterests.contains(i)) {
                        _selectedInterests.remove(i);
                      } else {
                        _selectedInterests.add(i);
                      }
                    }),
                    onIndustryChanged: (v) =>
                        setState(() => _selectedIndustry = v),
                    onNext: _next,
                  ),
                  _Step4Profile(
                    nameController: _nameController,
                    hasError: _nameError,
                    onNameChanged: (_) {
                      if (_nameError) setState(() => _nameError = false);
                    },
                    onGetStarted: _handleGetStarted,
                    onSignIn: _handleSignIn,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress header ────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.step,
    required this.totalSteps,
    this.onBack,
  });

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textSecondary, size: 22),
                )
              else
                const SizedBox(width: 22),
              const Spacer(),
              Text(
                'Step ${step + 1} of $totalSteps',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          // Progress dots
          Row(
            children: List.generate(
              totalSteps,
              (i) => Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i <= step ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Welcome ────────────────────────────────────────────────────────

class _Step1Welcome extends StatelessWidget {
  const _Step1Welcome({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primaryLight.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 64)),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1.0, 1.0),
                duration: 700.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(height: AppSizes.xxl),
          const Text(
            'Welcome to\nDOEET',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.5,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: AppSizes.md),
          const Text(
            'Your AI-powered learning companion.\nLet\'s personalise your experience.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          )
              .animate(delay: 350.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: AppSizes.xxxl),
          GradientButton(
            label: 'Get Started',
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

// ─── Step 2: Choose Role ────────────────────────────────────────────────────

class _Step2Role extends StatelessWidget {
  const _Step2Role({
    required this.selected,
    required this.onChanged,
    required this.onNext,
  });

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.lg),
          const Text(
            'What describes\nyou best?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'We\'ll personalise your learning path based on your role.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: AppSizes.xl),
          ...UserRole.values.asMap().entries.map((entry) {
            final i = entry.key;
            final role = entry.value;
            final isSelected = selected == role;
            return _RoleCard(
              role: role,
              isSelected: isSelected,
              onTap: () => onChanged(role),
            )
                .animate(delay: (100 + i * 80).ms)
                .fadeIn(duration: 350.ms)
                .slideX(begin: 0.1, end: 0);
          }),
          const SizedBox(height: AppSizes.xl),
          GradientButton(
            label: 'Continue',
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.bgCard,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Center(
                child: Text(role.emoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Interests ──────────────────────────────────────────────────────

class _Step3Interests extends StatelessWidget {
  const _Step3Interests({
    required this.role,
    required this.selectedInterests,
    required this.selectedIndustry,
    required this.onInterestToggled,
    required this.onIndustryChanged,
    required this.onNext,
  });

  final UserRole role;
  final Set<String> selectedInterests;
  final String? selectedIndustry;
  final ValueChanged<String> onInterestToggled;
  final ValueChanged<String?> onIndustryChanged;
  final VoidCallback onNext;

  bool get _isCompany => role == UserRole.company;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.lg),
          Text(
            _isCompany ? 'Your Industry' : 'Your Interests',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: AppSizes.sm),
          Text(
            _isCompany
                ? 'Select the industry your company operates in.'
                : 'Pick topics you\'re interested in. We\'ll curate relevant content for you.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: AppSizes.xl),
          if (_isCompany)
            _IndustrySelector(
              selected: selectedIndustry,
              onChanged: onIndustryChanged,
            )
          else
            _InterestChips(
              allInterests: _allInterests,
              selected: selectedInterests,
              onToggled: onInterestToggled,
            ),
          const SizedBox(height: AppSizes.xl),
          GradientButton(
            label: 'Continue',
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(height: AppSizes.sm),
          Center(
            child: TextButton(
              onPressed: onNext,
              child: const Text(
                'Skip for now',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }
}

class _InterestChips extends StatelessWidget {
  const _InterestChips({
    required this.allInterests,
    required this.selected,
    required this.onToggled,
  });

  final List<String> allInterests;
  final Set<String> selected;
  final ValueChanged<String> onToggled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: allInterests.asMap().entries.map((entry) {
        final i = entry.key;
        final interest = entry.value;
        final isSelected = selected.contains(interest);
        return GestureDetector(
          onTap: () => onToggled(interest),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: AppSizes.sm),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.bgCard,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              interest,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        )
            .animate(delay: (i * 40).ms)
            .fadeIn(duration: 300.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              duration: 250.ms,
            );
      }).toList(),
    );
  }
}

class _IndustrySelector extends StatelessWidget {
  const _IndustrySelector({
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _industries.asMap().entries.map((entry) {
        final i = entry.key;
        final industry = entry.value;
        final isSelected = selected == industry;
        return GestureDetector(
          onTap: () => onChanged(industry),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: AppSizes.xs),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : AppColors.bgCard,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              borderRadius:
                  BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    industry,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20),
              ],
            ),
          ),
        )
            .animate(delay: (i * 40).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.1, end: 0);
      }).toList(),
    );
  }
}

// ─── Step 4: Create Profile ─────────────────────────────────────────────────

class _Step4Profile extends StatelessWidget {
  const _Step4Profile({
    required this.nameController,
    required this.hasError,
    required this.onNameChanged,
    required this.onGetStarted,
    required this.onSignIn,
  });

  final TextEditingController nameController;
  final bool hasError;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.lg),
          const Text(
            'Create your\nprofile',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
              height: 1.15,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'What should we call you?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: AppSizes.xl),
          TextField(
            controller: nameController,
            onChanged: onNameChanged,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Your display name',
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  color: AppColors.textMuted),
              errorText: hasError ? 'Please enter your name' : null,
              filled: true,
              fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLg),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLg),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.radiusLg),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.md),
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSizes.xxl),
          GradientButton(
            label: 'Create Account',
            onPressed: onGetStarted,
            icon: const Icon(Icons.rocket_launch_rounded,
                color: Colors.white, size: 20),
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: AppSizes.md),
          Center(
            child: TextButton(
              onPressed: onSignIn,
              child: const Text(
                'Already have an account? Sign In',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }
}
