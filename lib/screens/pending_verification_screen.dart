import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/verification_timeline.dart';
import 'login_screen.dart';

const List<VerificationStep> _steps = <VerificationStep>[
  VerificationStep(
    title: 'Submit Application',
    description: 'Credentials & map location uploaded.',
  ),
  VerificationStep(
    title: 'Admin Review',
    description:
        'Our admin team will review your business documents within 24 hours.',
  ),
  VerificationStep(
    title: 'Approval & Platform Fee Payment',
    description:
        'Once approved, you will receive an email notification and a '
        'payment link to pay your platform fee and activate your account.',
  ),
];

/// Shown right after a workshop submits its registration for review.
class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  void _backToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<void> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.indigoSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 34,
                  color: AppColors.indigo,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Application Submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your workshop is now in "Pending Verification" status. '
                "We'll email you as soon as an administrator reviews your "
                'documents.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.slate),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const VerificationTimeline(steps: _steps),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Back to Login',
                trailingIcon: null,
                onPressed: () => _backToLogin(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
