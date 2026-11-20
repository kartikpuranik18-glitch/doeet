// lib/features/ai/presentation/ai_notes_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';

// ── Note type options ────────────────────────────────────────────────────────

const _kNoteTypes = <String>[
  'Detailed Notes',
  'Revision Notes',
  'Exam Notes',
  'Interview Notes',
  'Flashcard Set',
  'Summary',
];

// ── Saved Note model ─────────────────────────────────────────────────────────

class _SavedNote {
  final String id;
  final String title;
  final String noteType;
  final String content;
  final DateTime createdAt;

  const _SavedNote({
    required this.id,
    required this.title,
    required this.noteType,
    required this.content,
    required this.createdAt,
  });

  factory _SavedNote.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return _SavedNote(
      id: doc.id,
      title: d['title'] as String? ?? 'Untitled',
      noteType: d['type'] as String? ?? 'Notes',
      content: d['content'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ── Main Screen ──────────────────────────────────────────────────────────────

class AiNotesScreen extends ConsumerStatefulWidget {
  const AiNotesScreen({super.key});

  @override
  ConsumerState<AiNotesScreen> createState() => _AiNotesScreenState();
}

class _AiNotesScreenState extends ConsumerState<AiNotesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(firebaseAuthStateProvider).value?.uid;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        title: const Text('AI Notes'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Generate'),
            Tab(text: 'Saved Notes'),
          ],
        ),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _GenerateTab(uid: uid),
                _SavedNotesTab(uid: uid),
              ],
            ),
    );
  }
}

// ── Generate Tab ─────────────────────────────────────────────────────────────

class _GenerateTab extends StatefulWidget {
  const _GenerateTab({required this.uid});
  final String uid;

  @override
  State<_GenerateTab> createState() => _GenerateTabState();
}

class _GenerateTabState extends State<_GenerateTab> {
  final _topicCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  String _noteType = _kNoteTypes.first;
  bool _generating = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _topicCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a topic.')),
      );
      return;
    }
    setState(() {
      _generating = true;
      _result = null;
      _error = null;
    });
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('generateAiNotes');
      final res = await callable.call<Map<String, dynamic>>({
        'topic': topic,
        'noteType': _noteType,
        'sourceContent': _sourceCtrl.text.trim(),
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      if (mounted) {
        setState(() {
          _result = data['notes'] as String? ?? '';
          _generating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _generating = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final topic = _topicCtrl.text.trim();
    final content = _result;
    if (content == null || content.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('notes')
          .add({
        'title': topic,
        'content': content,
        'source': 'ai_generated',
        'type': _noteType,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Topic ────────────────────────────────────────────────────────
        _SectionLabel('Topic'),
        const SizedBox(height: 8),
        TextField(
          controller: _topicCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. RTOS task scheduling, React hooks, Transformers...',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLength: 200,
        ),

        const SizedBox(height: 16),

        // ── Note type ────────────────────────────────────────────────────
        _SectionLabel('Note Type'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kNoteTypes.map((type) {
            final selected = type == _noteType;
            return FilterChip(
              label: Text(type),
              selected: selected,
              selectedColor: AppColors.primary.withOpacity(0.18),
              checkmarkColor: AppColors.primary,
              onSelected: (_) => setState(() => _noteType = type),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // ── Optional source content ───────────────────────────────────────
        _SectionLabel('Source Content (optional)'),
        const SizedBox(height: 4),
        const Text(
          'Paste lecture notes, article text, or any content to base the notes on.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _sourceCtrl,
          decoration: const InputDecoration(
            hintText: 'Paste source text here...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          maxLength: 4000,
        ),

        const SizedBox(height: 20),

        // ── Generate button ───────────────────────────────────────────────
        FilledButton.icon(
          onPressed: _generating ? null : _generate,
          icon: _generating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.auto_awesome_rounded),
          label: Text(_generating ? 'Generating…' : 'Generate Notes'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),

        // ── Error ─────────────────────────────────────────────────────────
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Text(
              'Error: $_error',
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],

        // ── Result ────────────────────────────────────────────────────────
        if (_result != null && _result!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Generated Notes',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Copy to clipboard',
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _result!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Save to Notes'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: MarkdownBody(
              data: _result!,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 14, height: 1.6),
                h1: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
                h2: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
                h3: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                code: const TextStyle(
                    backgroundColor: Color(0xFF1E1E2E), fontSize: 13),
                blockquoteDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  border:
                      Border(left: BorderSide(color: AppColors.primary, width: 3)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),
        ],
      ],
    );
  }
}

// ── Saved Notes Tab ───────────────────────────────────────────────────────────

class _SavedNotesTab extends StatelessWidget {
  const _SavedNotesTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes')
        .where('source', isEqualTo: 'ai_generated')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notes_rounded, size: 64, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text('No AI notes yet',
                    style: TextStyle(color: AppColors.textSecondary)),
                SizedBox(height: 4),
                Text('Generate and save notes from the Generate tab.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          );
        }

        final notes = docs.map(_SavedNote.fromDoc).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return _NoteCard(note: note, uid: uid)
                .animate()
                .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                .slideY(begin: 0.05, end: 0);
          },
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.uid});
  final _SavedNote note;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: const Icon(Icons.auto_awesome_rounded,
              size: 20, color: AppColors.primary),
        ),
        title: Text(note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          note.noteType,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fmtDate(note.createdAt),
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'view', child: Text('View')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (action) async {
                if (action == 'view') {
                  _viewNote(context, note);
                } else if (action == 'delete') {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('notes')
                      .doc(note.id)
                      .delete();
                }
              },
            ),
          ],
        ),
        onTap: () => _viewNote(context, note),
      ),
    );
  }

  void _viewNote(BuildContext context, _SavedNote note) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _NoteViewScreen(note: note),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final now = DateTime.now();
    if (now.difference(d).inDays == 0) return 'Today';
    if (now.difference(d).inDays == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _NoteViewScreen extends StatelessWidget {
  const _NoteViewScreen({required this.note});
  final _SavedNote note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        title: Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: note.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: Markdown(
        data: note.content,
        padding: const EdgeInsets.all(20),
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 14.5, height: 1.7),
          h1: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
          h2: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
          h3: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      );
}
