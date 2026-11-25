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
    _tabs = TabController(length: 7, vsync: this);
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
            Tab(text: 'Interview prep'),
            Tab(text: 'Career insights'),
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
                const _InterviewPrepTab(),
                const _CareerInsightsTab(),
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

class _InterviewPrepTab extends StatelessWidget {
  const _InterviewPrepTab();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
        children: [
          const Text('Interview preparation', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.6)),
          const SizedBox(height: 7),
          const Text('Practice the conversations and technical rounds that help you get hired.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(18)),
            child: const Row(children: [
              Icon(Icons.record_voice_over_outlined, color: Color(0xFFFFC4D5), size: 30), SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Mock interview simulator', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('A guided prototype for practicing role-specific questions.', style: TextStyle(color: Colors.white70, fontSize: 13))])),
              Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ]),
          ),
          const SizedBox(height: 26),
          const _CareerFeature(icon: Icons.people_outline_rounded, title: 'HR & behavioural questions', detail: 'Tell me about yourself, strengths, teamwork and salary discussions.', stat: '36 questions'),
          const _CareerFeature(icon: Icons.code_rounded, title: 'Technical rounds', detail: 'Programming, SQL, frontend, Java and data fundamentals.', stat: '128 questions'),
          const _CareerFeature(icon: Icons.calculate_outlined, title: 'Aptitude round', detail: 'Practice quantitative, reasoning and communication assessments.', stat: '18 tests'),
          const _CareerFeature(icon: Icons.fact_check_outlined, title: 'Interview checklist', detail: 'Prepare your resume, projects, portfolio and research before the call.', stat: 'Open'),
        ],
      );
}

class _CareerInsightsTab extends StatelessWidget {
  const _CareerInsightsTab();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
        children: [
          const Text('Career insights', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.6)),
          const SizedBox(height: 7),
          const Text('A live-market style view of popular tech roles and the skills behind them.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Wrap(spacing: 14, runSpacing: 14, children: const [
            _InsightMetric(value: '1,284', label: 'Tech roles indexed', icon: Icons.work_outline_rounded),
            _InsightMetric(value: '46%', label: 'Remote or hybrid roles', icon: Icons.home_work_outlined),
            _InsightMetric(value: '78%', label: 'Roles asking for projects', icon: Icons.folder_copy_outlined),
          ]),
          const SizedBox(height: 28),
          const Text('In-demand roles', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          const _CareerFeature(icon: Icons.web_rounded, title: 'Frontend Developer', detail: 'React · TypeScript · JavaScript · CSS', stat: '342 roles'),
          const _CareerFeature(icon: Icons.query_stats_rounded, title: 'Data Analyst', detail: 'SQL · Excel · Power BI · Python', stat: '268 roles'),
          const _CareerFeature(icon: Icons.storage_rounded, title: 'Backend Developer', detail: 'Java · Spring Boot · APIs · SQL', stat: '224 roles'),
          const _CareerFeature(icon: Icons.design_services_outlined, title: 'UI/UX Designer', detail: 'Figma · Research · Prototyping', stat: '154 roles'),
          const SizedBox(height: 22),
          Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFFFFF2F6), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFF8D6E2))), child: const Row(children: [Icon(Icons.auto_awesome_outlined, color: AppColors.brandPink), SizedBox(width: 11), Expanded(child: Text('Prototype insight: add React, SQL and one portfolio project to improve your job match.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))])),
        ],
      );
}

class _InsightMetric extends StatelessWidget {
  const _InsightMetric({required this.value, required this.label, required this.icon});
  final String value; final String label; final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: 210, child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.bgCard, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(15)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppColors.primary), const SizedBox(height: 15), Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))])));
}

class _CareerFeature extends StatelessWidget {
  const _CareerFeature({required this.icon, required this.title, required this.detail, required this.stat});
  final IconData icon; final String title; final String detail; final String stat;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.border)), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primary)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(detail, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))])), Text(stat, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800))])));
}
