import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class VerificationStep {
  const VerificationStep({required this.title, required this.description});

  final String title;
  final String description;
}

/// Numbered timeline for the "Verification & Next Steps" card. The first
/// entry is rendered as the current step; the rest are upcoming/muted.
class VerificationTimeline extends StatelessWidget {
  const VerificationTimeline({super.key, required this.steps});

  final List<VerificationStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          _TimelineRow(
            index: i + 1,
            step: steps[i],
            isCurrent: i == 0,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.index,
    required this.step,
    required this.isCurrent,
    required this.isLast,
  });

  final int index;
  final VerificationStep step;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color accent = isCurrent ? AppColors.indigo : AppColors.slateLight;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? AppColors.indigo : AppColors.background,
                  border: Border.all(color: accent, width: 1.4),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? Colors.white : AppColors.slateLight,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.4,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? AppColors.navy : AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.description,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
