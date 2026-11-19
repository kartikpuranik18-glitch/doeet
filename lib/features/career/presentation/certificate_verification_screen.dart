import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CertificateVerificationScreen extends StatelessWidget {
  const CertificateVerificationScreen({super.key, required this.certificateId});
  final String certificateId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('certificateVerifications')
                .doc(certificateId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              final data = snapshot.data?.data();
              if (data == null) {
                return const _VerificationState(
                  valid: false,
                  title: 'Certificate not found',
                  message: 'This verification ID does not exist.',
                );
              }
              return _VerificationState(
                valid: data['status'] == 'valid',
                title: data['status'] == 'valid'
                    ? 'Verified DOEET certificate'
                    : 'Certificate unavailable',
                message:
                    '${data['courseTitle'] as String? ?? 'DOEET course'} · $certificateId',
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VerificationState extends StatelessWidget {
  const _VerificationState({
    required this.valid,
    required this.title,
    required this.message,
  });
  final bool valid;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              valid ? Icons.verified_rounded : Icons.error_outline_rounded,
              size: 56,
              color: valid ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
