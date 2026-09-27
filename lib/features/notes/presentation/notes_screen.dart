// lib/features/notes/presentation/notes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/doeet_error_widget.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../data/note_model.dart';
import 'notes_provider.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(allNotesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: MediaQuery.sizeOf(context).width < 900
          ? AppBar(
              backgroundColor: AppColors.bgPrimary,
              title: const Text('My Notes'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => setState(() {}),
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/notes/editor'),
        backgroundColor: AppColors.accentPurple,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Note'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search notes…',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Notes list
          Expanded(
            child: notesAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShimmerLoader.card(height: 100),
                ),
              ),
              error: (e, _) => DoeetErrorWidget(
                message: 'Failed to load notes',
                onRetry: () => ref.invalidate(allNotesProvider),
              ),
              data: (notes) {
                final filtered = _searchQuery.isEmpty
                    ? notes
                    : notes
                        .where((n) =>
                            n.title.toLowerCase().contains(_searchQuery) ||
                            n.content.toLowerCase().contains(_searchQuery))
                        .toList();

                if (filtered.isEmpty) {
                  return _EmptyState(hasSearch: _searchQuery.isNotEmpty);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _NoteCard(
                    note: filtered[i],
                    index: i,
                    onTap: () =>
                        context.push('/notes/editor', extra: filtered[i]),
                    onDelete: () => ref
                        .read(notesNotifierProvider.notifier)
                        .deleteNote(filtered[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  final NoteModel note;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const cardColors = [
      Color(0xFFFFE4EC),
      Color(0xFFFFECDD),
      Color(0xFFFCE4F2),
      Color(0xFFEAF4E8),
    ];

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColors[index % cardColors.length],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                note.content,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(note.updatedAt),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  if (note.videoId != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.play_circle_outline_rounded,
                        size: 12, color: AppColors.accentPurple),
                    const SizedBox(width: 4),
                    const Text(
                      'From video',
                      style: TextStyle(
                          color: AppColors.accentPurple, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: index * 60))
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.1, end: 0),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📝', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No notes match your search' : 'No notes yet',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try different keywords'
                : 'Tap + to capture your first idea',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
