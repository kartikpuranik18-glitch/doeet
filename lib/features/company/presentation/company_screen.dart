import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/data/user_role.dart';

class CompanyScreen extends ConsumerWidget {
  const CompanyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userModelProvider);
    return profile.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Company workspace unavailable')),
      ),
      data: (user) {
        final canUseCompany = user?.roles
                .any((role) => role.canUseCompanyWorkspace) ??
            false;
        if (!canUseCompany) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Company access requires employer or recruiter verification.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return _CompanyWorkspace(uid: user!.uid);
      },
    );
  }
}

class _CompanyWorkspace extends ConsumerStatefulWidget {
  const _CompanyWorkspace({required this.uid});
  final String uid;

  @override
  ConsumerState<_CompanyWorkspace> createState() => _CompanyWorkspaceState();
}

class _CompanyWorkspaceState extends ConsumerState<_CompanyWorkspace>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Company hiring'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Jobs'),
            Tab(text: 'Applications'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _CompanyProfile(uid: widget.uid),
          _CompanyJobs(uid: widget.uid),
          _CompanyApplications(uid: widget.uid),
          const _CompanyAnalytics(),
        ],
      ),
    );
  }
}

class _CompanyProfile extends StatelessWidget {
  const _CompanyProfile({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .where('ownerUid', isEqualTo: uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return Center(
            child: FilledButton.icon(
              onPressed: () => _createCompany(context),
              icon: const Icon(Icons.business_outlined),
              label: const Text('Create verified company'),
            ),
          );
        }
        final data = docs.first.data();
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(data['name'] as String? ?? 'Company',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(data['industry'] as String? ?? 'Industry'),
            const SizedBox(height: 18),
            _StatusRow(
              label: 'Verification',
              value: data['verificationStatus'] as String? ?? 'pending',
            ),
          ],
        );
      },
    );
  }

  Future<void> _createCompany(BuildContext context) async {
    final name = TextEditingController();
    final industry = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Company profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Company name'),
            ),
            TextField(
              controller: industry,
              decoration: const InputDecoration(labelText: 'Industry'),
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
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      try {
        await FirebaseFunctions.instance
            .httpsCallable('createCompany')
            .call({
          'name': name.text.trim(),
          'industry': industry.text.trim(),
        });
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
      }
    }
    name.dispose();
    industry.dispose();
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label)),
          Chip(
            label: Text(value),
            backgroundColor: value == 'verified'
                ? AppColors.success.withOpacity(.15)
                : AppColors.warning.withOpacity(.15),
          ),
        ],
      );
}

class _CompanyJobs extends StatelessWidget {
  const _CompanyJobs({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .where('ownerUid', isEqualTo: uid)
          .limit(1)
          .snapshots(),
      builder: (context, companySnapshot) {
        final companies = companySnapshot.data?.docs ?? const [];
        if (companies.isEmpty) {
          return const Center(child: Text('Create a company profile first.'));
        }
        final companyId = companies.first.id;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('jobs')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, jobsSnapshot) {
            final jobs = jobsSnapshot.data?.docs ?? const [];
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                FilledButton.icon(
                  onPressed: () => _createJob(context, companyId),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Post job'),
                ),
                const SizedBox(height: 16),
                if (jobs.isEmpty)
                  const Text('No jobs posted yet.')
                else
                  for (final job in jobs)
                    Card(
                      child: ListTile(
                        title: Text(job.data()['title'] as String? ?? 'Job'),
                        subtitle: Text(
                            job.data()['status'] as String? ?? 'draft'),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createJob(BuildContext context, String companyId) async {
    final title = TextEditingController();
    final location = TextEditingController();
    final skills = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Job title'),
            ),
            TextField(
              controller: location,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: skills,
              decoration:
                  const InputDecoration(labelText: 'Required skills'),
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
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      try {
        await FirebaseFunctions.instance
            .httpsCallable('createJob')
            .call({
          'companyId': companyId,
          'title': title.text.trim(),
          'location': location.text.trim(),
          'skills': skills.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
        });
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
      }
    }
    title.dispose();
    location.dispose();
    skills.dispose();
  }
}

class _CompanyApplications extends StatelessWidget {
  const _CompanyApplications({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .where('ownerUid', isEqualTo: uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final companies = snapshot.data?.docs ?? const [];
        if (companies.isEmpty) {
          return const Center(child: Text('No company applications yet.'));
        }
        final companyId = companies.first.id;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .collection('applications')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, appsSnapshot) {
            final apps = appsSnapshot.data?.docs ?? const [];
            if (apps.isEmpty) {
              return const Center(
                  child: Text('Applications will appear here.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: apps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = apps[index].data();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(data['status'] as String? ?? 'Applied'),
                    subtitle: Text(
                        'Candidate ${data['applicantUid'] as String? ?? ''}'),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Move stage',
                      onSelected: (status) async {
                        try {
                          await FirebaseFunctions.instance
                              .httpsCallable('updateApplicationStage')
                              .call({
                            'companyId': companyId,
                            'applicationId': apps[index].id,
                            'status': status,
                          });
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'screening', child: Text('Screening')),
                        PopupMenuItem(
                            value: 'shortlisted', child: Text('Shortlisted')),
                        PopupMenuItem(
                            value: 'assessment', child: Text('Assessment')),
                        PopupMenuItem(
                            value: 'interview', child: Text('Interview')),
                        PopupMenuItem(
                            value: 'offer', child: Text('Offer')),
                        PopupMenuItem(
                            value: 'hired', child: Text('Hired')),
                        PopupMenuItem(
                            value: 'rejected', child: Text('Rejected')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CompanyAnalytics extends StatelessWidget {
  const _CompanyAnalytics();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Recruitment analytics are calculated from persisted applications and hiring stages.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
