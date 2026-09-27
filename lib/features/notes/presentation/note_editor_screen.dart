// lib/features/notes/presentation/note_editor_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../data/note_model.dart';
import 'notes_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final NoteModel? existingNote;
  final String? courseId;
  final String? videoId;
  final int? videoTimestamp;

  const NoteEditorScreen({
    super.key,
    this.existingNote,
    this.courseId,
    this.videoId,
    this.videoTimestamp,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  Timer? _autoSaveTimer;
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.existingNote?.content ?? '');

    _titleCtrl.addListener(_markDirty);
    _contentCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), _save);
  }

  Future<void> _save() async {
    if (!_isDirty) return;
    if (_titleCtrl.text.trim().isEmpty && _contentCtrl.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(notesNotifierProvider.notifier).saveNote(
            id: widget.existingNote?.id,
            courseId: widget.courseId ?? widget.existingNote?.courseId ?? 'general',
            videoId: widget.videoId ?? widget.existingNote?.videoId,
            title: _titleCtrl.text.trim().isEmpty ? 'Untitled Note' : _titleCtrl.text.trim(),
            content: _contentCtrl.text.trim(),
            timestamp: widget.videoTimestamp ?? widget.existingNote?.timestamp,
          );
      setState(() => _isDirty = false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  int get _wordCount {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () async {
            await _save();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isSaving
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPurple),
                    ),
                    SizedBox(width: 8),
                    Text('Saving…', style: TextStyle(fontSize: 14)),
                  ],
                )
              : _isDirty
                  ? const Text('Unsaved', style: TextStyle(fontSize: 14, color: AppColors.textSecondary))
                  : const Text('Saved', style: TextStyle(fontSize: 14, color: AppColors.success)),
        ),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentPurple),
          ),
        ],
      ),
      body: Column(
        children: [
          // Title field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              decoration: const InputDecoration(
                hintText: 'Note title…',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 24, fontWeight: FontWeight.w700),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 2,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),

          // Timestamp tag (if from video)
          if (widget.videoTimestamp != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_circle_outline_rounded, size: 14, color: AppColors.accentPurple),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(widget.videoTimestamp!),
                          style: const TextStyle(color: AppColors.accentPurple, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const Divider(color: AppColors.border, height: 24),

          // Content field
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: TextField(
                controller: _contentCtrl,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.7,
                ),
                decoration: const InputDecoration(
                  hintText: 'Start writing your notes here…',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),

          // Bottom status bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Text(
                  '$_wordCount words',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_contentCtrl.text.length} chars',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const Spacer(),
                // AI formatting hint
                const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.accentPurple),
                const SizedBox(width: 4),
                const Text(
                  'AI notes available in AI tab',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
