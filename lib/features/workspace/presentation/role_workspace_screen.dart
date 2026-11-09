import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/data/user_role.dart';
import '../../auth/presentation/auth_provider.dart';

/// Entry points stay separate to prevent company hiring controls from leaking
/// into a learner's workspace. Firestore rules remain the source of authority.
class RoleWorkspaceScreen extends ConsumerWidget {
  const RoleWorkspaceScreen({super.key, required this.workspace});
  final WorkspaceKind workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelProvider);
    return user.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const _AccessState(
          title: 'Workspace unavailable',
          message: 'We could not load your account permissions.'),
      data: (profile) {
        if (profile == null || !profile.canUse(workspace)) {
          return _AccessState(
            title: 'Access required',
            message: workspace == WorkspaceKind.company
                ? 'Company and recruiter tools are available only after company verification and role approval.'
                : 'This workspace requires an approved DOEET role.',
          );
        }
        return _WorkspaceHome(workspace: workspace, uid: profile.uid);
      },
    );
  }
}

class _WorkspaceHome extends ConsumerWidget {
  const _WorkspaceHome({required this.workspace, required this.uid});
  final WorkspaceKind workspace;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = switch (workspace) {
      WorkspaceKind.learner => (
          'Learner workspace',
          'Learn, prove skills, and move confidently into career development.',
          <_WorkspaceLink>[
            _WorkspaceLink('Learning dashboard', Icons.school_outlined, '/home'),
            _WorkspaceLink('Courses & playlists', Icons.play_circle_outline, '/courses'),
            _WorkspaceLink('Learning progress', Icons.trending_up_outlined, '/analytics'),
          ],
        ),
      WorkspaceKind.company => (
          'Company hiring workspace',
          'Post verified roles, review consented evidence, and run a fair hiring pipeline.',
          <_WorkspaceLink>[
            _WorkspaceLink('Company profile', Icons.business_outlined, '/workspace/company'),
            _WorkspaceLink('Jobs & hiring pipeline', Icons.work_outline, '/workspace/company'),
            _WorkspaceLink('Talent search', Icons.manage_search_outlined, '/workspace/company'),
          ],
        ),
      WorkspaceKind.administration => (
          'DOEET administration',
          'Manage platform safety, verification, and configuration.',
          <_WorkspaceLink>[
            _WorkspaceLink('Verification', Icons.verified_user_outlined, '/workspace/admin'),
            _WorkspaceLink('Platform reports', Icons.assessment_outlined, '/workspace/admin'),
          ],
        ),
    };
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(config.$1),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier)
                  .setActiveWorkspace(uid, workspace);
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Current workspace'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(config.$1,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(config.$2,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          for (final link in config.$3)
            Card(
              child: ListTile(
                leading: Icon(link.icon, color: AppColors.primary),
                title: Text(link.title),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => context.go(link.route),
              ),
            ),
        ],
      ),
    );
  }
}

class _AccessState extends StatelessWidget {
  const _AccessState({required this.title, required this.message});
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, size: 42, color: AppColors.textMuted),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              OutlinedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Return to DOEET')),
            ]),
          ),
        ),
      );
}

class _WorkspaceLink {
  const _WorkspaceLink(this.title, this.icon, this.route);
  final String title;
  final IconData icon;
  final String route;
}
