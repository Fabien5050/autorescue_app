import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// "Requests" tab — incoming roadside-assistance requests. No request
/// backend exists yet, so this is a clear, functional empty state rather
/// than a broken placeholder.
class WorkshopRequestsScreen extends StatelessWidget {
  const WorkshopRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Requests',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryText),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.badgeSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.build_outlined, size: 32, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No roadside assistance requests.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "New requests from drivers nearby will show up here.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
