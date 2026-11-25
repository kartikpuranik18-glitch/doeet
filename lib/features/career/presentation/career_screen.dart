import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        toolbarHeight: 76,
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          _CareerMark(),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dooet Careers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
            Text('Your professional space', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ]),
        ]),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/learn'),
            icon: const Icon(Icons.school_outlined, size: 17),
            label: const Text('Back to learning'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'My profile'),
            Tab(text: 'Certificates'),
            Tab(text: 'Resume'),
            Tab(text: 'Job search'),
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

class _CareerMark extends StatelessWidget {
  const _CareerMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.work_outline_rounded, color: Colors.white, size: 20),
      );
}

class _CareerOverview extends StatelessWidget {
  const _CareerOverview({required this.uid});
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
        final readiness = (data['readinessScore'] as num?)?.toInt() ?? 42;
        final skills = List<String>.from(data['skills'] ?? const <String>[]);
        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 30, 28, 48),
          children: [
            const Text('Professional profile', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -.7)),
            const SizedBox(height: 7),
            const Text('Show employers the skills and proof you are building.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.verified_user_outlined, color: Color(0xFFFFC4D5)), SizedBox(width: 9), Text('CAREER READINESS', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1))]),
                const SizedBox(height: 16),
                Text('$readiness%', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: readiness / 100, minHeight: 8, backgroundColor: Colors.white24, color: const Color(0xFFFF9BBB))),
                const SizedBox(height: 10),
                const Text('Complete your profile, add skills and showcase certificates.', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 30),
            Text('Skills', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.isEmpty
                  ? const [Chip(label: Text('Complete a course to add skills'))]
                  : skills.map((skill) => Chip(label: Text(skill))).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _saveCareerProfile(context, uid),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Complete professional profile'),
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
      'readinessScore': 42,
      'applicationConsent': applicationConsent,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    title.dispose();
    skills.dispose();
  }
}

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

class _ResumeTab extends StatelessWidget {
  const _ResumeTab({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final resumes = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('resumes')
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: resumes,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FilledButton.icon(
              onPressed: () => _createResume(context, uid),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create resume'),
            ),
            const SizedBox(height: 16),
            if (docs.isEmpty)
              const Text('Create a role-specific resume from your DOEET profile.')
            else
              for (final doc in docs)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(doc.data()['title'] as String? ?? 'Resume'),
                    subtitle: Text(doc.data()['status'] as String? ?? 'Draft'),
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<void> _createResume(BuildContext context, String uid) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New resume'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(labelText: 'Resume title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('resumes')
          .add({
        'title': controller.text.trim(),
        'status': 'Draft',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    controller.dispose();
  }
}

class _JobsTab extends StatefulWidget {
  const _JobsTab({required this.uid});
  final String uid;

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final jobs = FirebaseFirestore.instance
        .collectionGroup('jobs')
        .where('status', isEqualTo: 'published')
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: jobs,
      builder: (context, snapshot) {
        final docs = (snapshot.data?.docs ?? const [])
            .where((doc) {
              final data = doc.data();
              final searchable = [
                data['title'],
                data['location'],
                data['employmentType'],
                ...(data['skills'] as List<dynamic>? ?? const []),
              ].join(' ').toLowerCase();
              return searchable.contains(_query.toLowerCase().trim());
            })
            .toList();
        if (snapshot.hasError) {
          return const Center(child: Text('Jobs are unavailable.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.isEmpty ? 2 : docs.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search by role, skill, location, or work type',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              );
            }
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 36),
                child: Center(child: Text('No matching published jobs yet.')),
              );
            }
            final doc = docs[index - 1];
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
                  onPressed: () => _apply(context, widget.uid, companyId, doc.id),
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
            return Card(
              child: ListTile(
                leading: const Icon(Icons.send_outlined),
                title: Text(data['status'] as String? ?? 'Applied'),
                subtitle: Text('Application ${docs[index].id}'),
              ),
            );
          },
        );
      },
    );
  }
}
