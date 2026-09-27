// lib/features/gamification/presentation/leaderboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';

final leaderboardProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('leaderboard')
      .orderBy('xp', descending: true)
      .limit(50)
      .get();
  return snap.docs.map((d) => d.data()).toList();
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: MediaQuery.sizeOf(context).width < 900
          ? AppBar(
              backgroundColor: AppColors.bgPrimary,
              title: const Text('Leaderboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => ref.invalidate(leaderboardProvider),
                ),
              ],
            )
          : null,
      body: boardAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPurple)),
        error: (_, __) => const Center(
          child: Text(
            'Couldn’t load the leaderboard. Check your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (users) => CustomScrollView(
          slivers: [
            // Top 3 podium
            if (users.length >= 3)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: _Podium(top3: users.take(3).toList()),
                ).animate().fadeIn(duration: 500.ms),
              ),

            // Rest of leaderboard
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final rank = i + (users.length >= 3 ? 4 : 1);
                    final user = users[i + (users.length >= 3 ? 3 : 0)];
                    final isMe = user['uid'] == currentUser?.uid;

                    return _LeaderboardTile(
                      rank: rank,
                      displayName: user['displayName'] ?? 'Learner',
                      xp: (user['xp'] as num?)?.toInt() ?? 0,
                      streak: (user['streak'] as num?)?.toInt() ?? 0,
                      level: (user['level'] as num?)?.toInt() ?? 1,
                      isMe: isMe,
                      index: i,
                    );
                  },
                  childCount: users.length - (users.length >= 3 ? 3 : 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top3});
  final List<Map<String, dynamic>> top3;

  @override
  Widget build(BuildContext context) {
    final first = top3[0];
    final second = top3[1];
    final third = top3[2];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place
        Expanded(
            child: _PodiumCard(
                user: second,
                rank: 2,
                height: 120,
                color: const Color(0xFFC0C0C0))),
        const SizedBox(width: 8),
        // 1st place
        Expanded(
            child: _PodiumCard(
                user: first,
                rank: 1,
                height: 160,
                color: AppColors.accentGold)),
        const SizedBox(width: 8),
        // 3rd place
        Expanded(
            child: _PodiumCard(
                user: third,
                rank: 3,
                height: 100,
                color: const Color(0xFFCD7F32))),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard(
      {required this.user,
      required this.rank,
      required this.height,
      required this.color});
  final Map<String, dynamic> user;
  final int rank;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final name = (user['displayName'] ?? 'Learner') as String;
    final xp = (user['xp'] as num?)?.toInt() ?? 0;

    return Column(
      children: [
        Text(_rankEmoji(rank), style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Text(name.split(' ').first,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text('$xp XP',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  String _rankEmoji(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    return '🥉';
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.displayName,
    required this.xp,
    required this.streak,
    required this.level,
    required this.isMe,
    required this.index,
  });

  final int rank, xp, streak, level, index;
  final String displayName;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            isMe ? AppColors.accentPurple.withOpacity(0.1) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isMe ? AppColors.accentPurple.withOpacity(0.4) : AppColors.border,
          width: isMe ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank <= 10 ? AppColors.accentGold : AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accentPurple.withOpacity(0.15),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppColors.accentPurple,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('You',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text('Level $level  •  🔥 $streak streak',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$xp',
                  style: const TextStyle(
                      color: AppColors.accentPurple,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const Text('XP',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn()
        .slideX(begin: 0.05);
  }
}
