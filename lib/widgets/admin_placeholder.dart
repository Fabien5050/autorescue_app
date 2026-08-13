import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Shared "not built yet" body for admin sections that are reachable and
/// switchable but don't have real functionality behind them yet.
class AdminPlaceholder extends StatelessWidget {
  const AdminPlaceholder({super.key, required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.badgeSoft, borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, size: 30, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }
}
