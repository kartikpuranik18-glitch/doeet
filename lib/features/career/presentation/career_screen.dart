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
          padding: const EdgeInsets.all(24),
          children: [
            Text('DOEET job readiness',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: readiness / 100,
              minHeight: 12,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text('$readiness% overall readiness',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
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
