import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';

class CareerScreen extends ConsumerStatefulWidget {
  const CareerScreen({super.key});

  @override
  ConsumerState<CareerScreen> createState() => _CareerScreenState();
}

class _CareerScreenState extends ConsumerState<CareerScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
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
        title: const Text('Career'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Certificates'),
            Tab(text: 'Resume'),
            Tab(text: 'Jobs'),
            Tab(text: 'Applications'),
          ],
        ),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _CareerOverview(uid: uid),
                _CertificatesTab(uid: uid),
                _ResumeTab(uid: uid),
                _JobsTab(uid: uid),
                _ApplicationsTab(uid: uid),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task 1: Job Readiness — calls Cloud Function for real score
// ─────────────────────────────────────────────────────────────────────────────

class _CareerOverview extends StatefulWidget {
  const _CareerOverview({required this.uid});
  final String uid;

  @override
  State<_CareerOverview> createState() => _CareerOverviewState();
}

class _CareerOverviewState extends State<_CareerOverview> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  Future<void> _calculate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('calculateJobReadiness');
      final res = await callable.call<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _result = Map<String, dynamic>.from(res.data as Map);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('DOEET Job Readiness',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          _ErrorCard(message: _error!, onRetry: _calculate)
        else if (_result != null)
          _ReadinessContent(result: _result!, onRecalculate: _calculate)
        else
          const SizedBox.shrink(),
        const SizedBox(height: 24),
        // Career profile section stays intact
        _CareerProfileSection(uid: widget.uid),
      ],
    );
  }
}

class _ReadinessContent extends StatelessWidget {
  const _ReadinessContent({
    required this.result,
    required this.onRecalculate,
  });

  final Map<String, dynamic> result;
  final VoidCallback onRecalculate;

  @override
  Widget build(BuildContext context) {
    final score = (result['score'] as num?)?.toInt() ?? 0;
    final breakdown = result['breakdown'] as Map<String, dynamic>? ?? {};
    final tips = List<String>.from(result['tips'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Circular score ────────────────────────────────
        Center(
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: AppColors.border,
                    color: _scoreColor(score),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score%',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: _scoreColor(score),
                          ),
                    ),
                    Text(
                      _scoreLabel(score),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Breakdown ─────────────────────────────────────
        Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _BreakdownRow(
          emoji: '🏆',
          label: 'Certificates',
          score: (breakdown['certificates'] as num?)?.toInt() ?? 0,
          max: 30,
        ),
        _BreakdownRow(
          emoji: '🧠',
          label: 'Skills',
          score: (breakdown['skills'] as num?)?.toInt() ?? 0,
          max: 20,
        ),
        _BreakdownRow(
          emoji: '📚',
          label: 'Completed Courses',
          score: (breakdown['completedCourses'] as num?)?.toInt() ?? 0,
          max: 20,
        ),
        _BreakdownRow(
          emoji: '📄',
          label: 'Resume',
          score: (breakdown['resume'] as num?)?.toInt() ?? 0,
          max: 15,
        ),
        _BreakdownRow(
          emoji: '🎯',
          label: 'Career Goal',
          score: (breakdown['careerGoal'] as num?)?.toInt() ?? 0,
          max: 10,
        ),
        _BreakdownRow(
          emoji: '✅',
          label: 'Application Ready',
          score: (breakdown['applicationReady'] as num?)?.toInt() ?? 0,
          max: 5,
        ),
        const SizedBox(height: 24),

        // ── Recommended actions ───────────────────────────
        if (tips.isNotEmpty) ...[
          Text('Recommended Actions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final tip in tips.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],

        // ── Recalculate button ────────────────────────────
        OutlinedButton.icon(
          onPressed: onRecalculate,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Recalculate'),
        ),
      ],
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _scoreLabel(int score) {
    if (score >= 75) return 'Job Ready';
    if (score >= 50) return 'Almost There';
    if (score >= 25) return 'Getting Started';
    return 'Build Your Profile';
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.emoji,
    required this.label,
    required this.score,
    required this.max,
  });

  final String emoji;
  final String label;
  final int score;
  final int max;

  @override
  Widget build(BuildContext context) {
    final fraction = max > 0 ? (score / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(label,
                style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 4,
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              color: fraction >= 0.7
                  ? AppColors.success
                  : fraction >= 0.4
                      ? AppColors.warning
                      : AppColors.error,
              backgroundColor: AppColors.border,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$score/$max',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Could not calculate readiness score.',
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 4),
            Text(message,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Career profile editing section (kept from original)
class _CareerProfileSection extends StatelessWidget {
  const _CareerProfileSection({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final profile = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('careerProfiles')
        .doc('primary')
        .snapshots();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profile,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final skills = List<String>.from(data['skills'] ?? const <String>[]);
        final goal = data['careerGoal'] as String? ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skills', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.isEmpty
                  ? const [Chip(label: Text('Complete a course to add skills'))]
                  : skills.map((skill) => Chip(label: Text(skill))).toList(),
            ),
            if (goal.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Goal: $goal',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _saveCareerProfile(context, uid),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Complete career profile'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCareerProfile(BuildContext context, String uid) async {
    final title = TextEditingController();
    final skills = TextEditingController();
    var applicationConsent = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Career profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Career goal'),
              ),
              TextField(
                controller: skills,
                decoration: const InputDecoration(
                  labelText: 'Skills (comma separated)',
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: applicationConsent,
                onChanged: (value) =>
                    setDialogState(() => applicationConsent = value ?? false),
                title: const Text(
                  'Allow DOEET to submit applications on my behalf',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) {
      title.dispose();
      skills.dispose();
      return;
    }
    final skillList = skills.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('careerProfiles')
        .doc('primary')
        .set({
      'careerGoal': title.text.trim(),
      'skills': skillList,
      'applicationConsent': applicationConsent,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    title.dispose();
    skills.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Certificates Tab (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _CertificatesTab extends StatelessWidget {
  const _CertificatesTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final certificates = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('certificates')
        .orderBy('issuedAt', descending: true)
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: certificates,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Certificates are unavailable.'));
        }
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No certificates yet. Complete every course requirement and pass the final assessment.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final id = data['certificateId'] as String? ?? docs[index].id;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.verified_rounded,
                    color: AppColors.success),
                title: Text(data['courseTitle'] as String? ?? 'DOEET course'),
                subtitle: Text('Verified certificate · $id'),
                trailing: TextButton(
                  onPressed: () => context.push('/certificate/$id'),
                  child: const Text('View'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task 3: Resume Builder — full multi-section form
// ─────────────────────────────────────────────────────────────────────────────

class _ResumeTab extends StatelessWidget {
  const _ResumeTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final resumes = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('resumes')
        .orderBy('createdAt', descending: true)
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: resumes,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FilledButton.icon(
              onPressed: () => _openResumeBuilder(context, uid),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create resume'),
            ),
            const SizedBox(height: 16),
            if (docs.isEmpty)
              const Text(
                  'Create a role-specific resume from your DOEET profile.')
            else
              for (final doc in docs)
                _ResumeCard(doc: doc, uid: uid),
          ],
        );
      },
    );
  }

  Future<void> _openResumeBuilder(BuildContext context, String uid) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ResumeBuilderScreen(uid: uid),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.doc, required this.uid});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final title = data['title'] as String? ?? 'Resume';
    final status = data['status'] as String? ?? 'Draft';
    final completion = _completion(data);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            '$completion%',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
        ),
        title: Text(title),
        subtitle: Text(status),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) =>
                  ResumeBuilderScreen(uid: uid, resumeId: doc.id, existing: data),
            ),
          ),
        ),
      ),
    );
  }

  int _completion(Map<String, dynamic> data) {
    var filled = 0;
    if ((data['summary'] as String? ?? '').isNotEmpty) filled++;
    if ((data['education'] as List? ?? []).isNotEmpty) filled++;
    if ((data['skills'] as List? ?? []).isNotEmpty) filled++;
    if ((data['projects'] as List? ?? []).isNotEmpty) filled++;
    if ((data['experience'] as List? ?? []).isNotEmpty) filled++;
    return ((filled / 5) * 100).round();
  }
}

// ── Resume Builder Screen ──────────────────────────────────────────────────

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({
    super.key,
    required this.uid,
    this.resumeId,
    this.existing,
  });

  final String uid;
  final String? resumeId;
  final Map<String, dynamic>? existing;

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  bool _saving = false;

  // Education
  final List<Map<String, String>> _education = [];
  // Skills
  final List<String> _skills = [];
  final _skillInputCtrl = TextEditingController();
  // Projects
  final List<Map<String, String>> _projects = [];
  // Experience
  final List<Map<String, String>> _experience = [];
  // Certificates (read-only)
  List<Map<String, dynamic>> _certificates = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e['title'] as String? ?? '';
      _summaryCtrl.text = e['summary'] as String? ?? '';
      _education.addAll(
        (e['education'] as List? ?? [])
            .map((item) => Map<String, String>.from(item as Map))
            .toList(),
      );
      _skills.addAll(List<String>.from(e['skills'] ?? []));
      _projects.addAll(
        (e['projects'] as List? ?? [])
            .map((item) => Map<String, String>.from(item as Map))
            .toList(),
      );
      _experience.addAll(
        (e['experience'] as List? ?? [])
            .map((item) => Map<String, String>.from(item as Map))
            .toList(),
      );
    }
    _loadPreFill();
  }

  Future<void> _loadPreFill() async {
    // Pre-fill skills from career profile
    if (_skills.isEmpty) {
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('careerProfiles')
          .doc('primary')
          .get();
      final profileSkills =
          List<String>.from(profileDoc.data()?['skills'] ?? []);
      if (profileSkills.isNotEmpty && mounted) {
        setState(() => _skills.addAll(profileSkills));
      }
    }

    // Pull projects
    if (_projects.isEmpty) {
      final projectsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('projects')
          .get();
      if (projectsSnap.docs.isNotEmpty && mounted) {
        setState(() {
          for (final d in projectsSnap.docs) {
            final data = d.data();
            _projects.add({
              'title': data['title'] as String? ?? '',
              'description': data['description'] as String? ?? '',
              'technologies': data['technologies'] as String? ?? '',
              'url': data['url'] as String? ?? '',
            });
          }
        });
      }
    }

    // Pull certificates (read-only)
    final certsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('certificates')
        .get();
    if (mounted) {
      setState(() {
        _certificates = certsSnap.docs
            .map((d) => d.data())
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _skillInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a resume title.')),
      );
      return;
    }
    setState(() => _saving = true);

    final filled = [
      _summaryCtrl.text.isNotEmpty,
      _education.isNotEmpty,
      _skills.isNotEmpty,
      _projects.isNotEmpty,
      _experience.isNotEmpty,
    ].where((b) => b).length;
    final status = filled >= 4 ? 'Complete' : 'Draft';

    final data = {
      'title': _titleCtrl.text.trim(),
      'status': status,
      'summary': _summaryCtrl.text.trim(),
      'education': _education,
      'skills': _skills,
      'projects': _projects,
      'experience': _experience,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('resumes');

    if (widget.resumeId != null) {
      await col.doc(widget.resumeId).update(data);
    } else {
      await col.add({...data, 'createdAt': FieldValue.serverTimestamp()});
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.resumeId != null ? 'Edit Resume' : 'New Resume'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Title
          _SectionHeader(title: 'Resume Title', icon: Icons.title),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Embedded Systems Engineer Resume',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Summary
          _SectionHeader(title: 'Professional Summary', icon: Icons.person_outline),
          const SizedBox(height: 8),
          TextField(
            controller: _summaryCtrl,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText:
                  'Write a brief professional summary highlighting your skills and experience...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Education
          _SectionHeader(
            title: 'Education',
            icon: Icons.school_outlined,
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addEducation(context),
            ),
          ),
          const SizedBox(height: 8),
          if (_education.isEmpty)
            _EmptyHint(text: 'No education added yet. Tap + to add.')
          else
            for (var i = 0; i < _education.length; i++)
              _ListItemCard(
                title: _education[i]['degree'] ?? '',
                subtitle:
                    '${_education[i]['institution'] ?? ''} · ${_education[i]['year'] ?? ''}',
                detail: _education[i]['grade'] ?? '',
                onDelete: () => setState(() => _education.removeAt(i)),
              ),
          const SizedBox(height: 24),

          // Skills
          _SectionHeader(title: 'Skills', icon: Icons.psychology_outlined),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillInputCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add skill',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addSkill,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _skills.length; i++)
                Chip(
                  label: Text(_skills[i]),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _skills.removeAt(i)),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Projects
          _SectionHeader(
            title: 'Projects',
            icon: Icons.code_outlined,
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addProject(context),
            ),
          ),
          const SizedBox(height: 8),
          if (_projects.isEmpty)
            _EmptyHint(text: 'No projects added yet. Tap + to add.')
          else
            for (var i = 0; i < _projects.length; i++)
              _ListItemCard(
                title: _projects[i]['title'] ?? '',
                subtitle: _projects[i]['technologies'] ?? '',
                detail: _projects[i]['url'] ?? '',
                onDelete: () => setState(() => _projects.removeAt(i)),
              ),
          const SizedBox(height: 24),

          // Certificates (read-only)
          _SectionHeader(
              title: 'Certificates', icon: Icons.verified_outlined),
          const SizedBox(height: 8),
          if (_certificates.isEmpty)
            _EmptyHint(
                text: 'Complete courses to earn certificates shown here.')
          else
            for (final cert in _certificates)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.verified_rounded,
                      color: AppColors.success),
                  title: Text(cert['courseTitle'] as String? ?? 'Certificate'),
                  subtitle:
                      Text(cert['certificateId'] as String? ?? ''),
                ),
              ),
          const SizedBox(height: 24),

          // Experience
          _SectionHeader(
            title: 'Experience',
            icon: Icons.work_history_outlined,
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addExperience(context),
            ),
          ),
          const SizedBox(height: 8),
          if (_experience.isEmpty)
            _EmptyHint(text: 'No experience added yet. Tap + to add.')
          else
            for (var i = 0; i < _experience.length; i++)
              _ListItemCard(
                title: _experience[i]['role'] ?? '',
                subtitle:
                    '${_experience[i]['company'] ?? ''} · ${_experience[i]['duration'] ?? ''}',
                detail: _experience[i]['description'] ?? '',
                onDelete: () => setState(() => _experience.removeAt(i)),
              ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _addSkill() {
    final text = _skillInputCtrl.text.trim();
    if (text.isEmpty) return;
    final parts = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    setState(() {
      for (final p in parts) {
        if (!_skills.contains(p)) _skills.add(p);
      }
      _skillInputCtrl.clear();
    });
  }

  Future<void> _addEducation(BuildContext context) async {
    final result = await _showEntryDialog<Map<String, String>>(
      context: context,
      title: 'Add Education',
      fields: const [
        _FieldSpec('degree', 'Degree', 'e.g. B.Tech in Electronics'),
        _FieldSpec('institution', 'Institution', 'e.g. IIT Bombay'),
        _FieldSpec('year', 'Year', 'e.g. 2024'),
        _FieldSpec('grade', 'Grade / CGPA', 'e.g. 8.5'),
      ],
    );
    if (result != null && mounted) {
      setState(() => _education.add(result));
    }
  }

  Future<void> _addProject(BuildContext context) async {
    final result = await _showEntryDialog<Map<String, String>>(
      context: context,
      title: 'Add Project',
      fields: const [
        _FieldSpec('title', 'Project Title', 'e.g. Smart Irrigation System'),
        _FieldSpec('description', 'Description', 'What it does'),
        _FieldSpec('technologies', 'Technologies', 'e.g. C, Arduino, Python'),
        _FieldSpec('url', 'URL / GitHub', 'https://github.com/...'),
      ],
    );
    if (result != null && mounted) {
      setState(() => _projects.add(result));
    }
  }

  Future<void> _addExperience(BuildContext context) async {
    final result = await _showEntryDialog<Map<String, String>>(
      context: context,
      title: 'Add Experience',
      fields: const [
        _FieldSpec('role', 'Role', 'e.g. Software Intern'),
        _FieldSpec('company', 'Company', 'e.g. Bosch'),
        _FieldSpec('duration', 'Duration', 'e.g. Jun–Aug 2024'),
        _FieldSpec('description', 'Description', 'What you did'),
      ],
    );
    if (result != null && mounted) {
      setState(() => _experience.add(result));
    }
  }

  Future<T?> _showEntryDialog<T extends Map<String, String>>({
    required BuildContext context,
    required String title,
    required List<_FieldSpec> fields,
  }) {
    final controllers = {
      for (final f in fields) f.key: TextEditingController(),
    };
    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: controllers[f.key],
                    decoration: InputDecoration(
                      labelText: f.label,
                      hintText: f.hint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              for (final c in controllers.values) {
                c.dispose();
              }
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final result = {
                for (final f in fields)
                  f.key: controllers[f.key]!.text.trim(),
              };
              for (final c in controllers.values) {
                c.dispose();
              }
              Navigator.pop(context, result as T);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _FieldSpec {
  const _FieldSpec(this.key, this.label, this.hint);
  final String key;
  final String label;
  final String hint;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
    );
  }
}

class _ListItemCard extends StatelessWidget {
  const _ListItemCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty) Text(subtitle),
            if (detail.isNotEmpty)
              Text(detail,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        isThreeLine: detail.isNotEmpty,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Jobs Tab (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _JobsTab extends StatelessWidget {
  const _JobsTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final jobs = FirebaseFirestore.instance
        .collectionGroup('jobs')
        .where('status', isEqualTo: 'published')
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: jobs,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        if (snapshot.hasError) {
          return const Center(child: Text('Jobs are unavailable.'));
        }
        if (docs.isEmpty) {
          return const Center(child: Text('No published jobs yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final companyId = doc.reference.parent.parent!.id;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(data['title'] as String? ?? 'Job'),
                subtitle: Text(
                  '${data['employmentType'] as String? ?? 'Full-time'} · ${data['location'] as String? ?? 'Remote'}',
                ),
                trailing: FilledButton(
                  onPressed: () => _apply(context, uid, companyId, doc.id),
                  child: const Text('Apply'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _apply(
    BuildContext context,
    String uid,
    String companyId,
    String jobId,
  ) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('submitApplication')
          .call({'companyId': companyId, 'jobId': jobId});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task 2: Applications Tab — enriched with job title, company, badge, date
// ─────────────────────────────────────────────────────────────────────────────

class _ApplicationsTab extends StatelessWidget {
  const _ApplicationsTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final apps = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('applications')
        .orderBy('createdAt', descending: true)
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: apps,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const Center(child: Text('No applications yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return _ApplicationCard(appId: docs[index].id, data: data);
          },
        );
      },
    );
  }
}

class _ApplicationCard extends StatefulWidget {
  const _ApplicationCard({required this.appId, required this.data});
  final String appId;
  final Map<String, dynamic> data;

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard> {
  String? _jobTitle;
  String? _companyName;
  bool _loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final companyId = widget.data['companyId'] as String?;
    final jobId = widget.data['jobId'] as String?;
    if (companyId == null || jobId == null) {
      setState(() => _loadingDetails = false);
      return;
    }
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .get(),
        FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .collection('jobs')
            .doc(jobId)
            .get(),
      ]);
      if (mounted) {
        setState(() {
          _companyName =
              results[0].data()?['name'] as String? ?? 'Unknown Company';
          _jobTitle = results[1].data()?['title'] as String? ?? 'Unknown Job';
          _loadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] as String? ?? 'applied';
    final createdAt = (widget.data['createdAt'] as Timestamp?)?.toDate();
    final dateStr = createdAt != null
        ? 'Applied on ${DateFormat('MMM d, yyyy').format(createdAt)}'
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.send_outlined, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loadingDetails)
                    const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    Text(
                      _jobTitle ?? 'Job',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (_companyName != null)
                      Text(_companyName!,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                  ],
                  const SizedBox(height: 6),
                  if (dateStr.isNotEmpty)
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    final Color color;
    final String label;

    if (lower == 'hired' || lower == 'offer') {
      color = AppColors.success;
      label = lower == 'hired' ? 'Hired' : 'Offer';
    } else if (lower == 'shortlisted' || lower == 'interview') {
      color = AppColors.warning;
      label = lower == 'shortlisted' ? 'Shortlisted' : 'Interview';
    } else if (lower == 'rejected') {
      color = AppColors.error;
      label = 'Rejected';
    } else {
      color = AppColors.info;
      label = 'Applied';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
