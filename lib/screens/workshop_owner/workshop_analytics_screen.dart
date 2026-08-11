import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/stat_card.dart';

/// "Analytics" tab — a lightweight summary of workshop performance. Full
/// charting is out of scope for this build; this surfaces the same demo
/// metrics as the dashboard in a dedicated, more detailed layout.
class WorkshopAnalyticsScreen extends StatelessWidget {
  const WorkshopAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: <Widget>[
            const Text(
              'Analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryText),
            ),
            const SizedBox(height: 4),
            const Text(
              'Overview of your workshop performance this month.',
              style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: const <Widget>[
                StatCard(icon: Icons.build_circle_outlined, label: 'Jobs This Month', value: '21', color: AppColors.primaryBlue),
                StatCard(icon: Icons.payments_outlined, label: 'Est. Earnings', value: '340,000 FCFA', color: AppColors.accentGreen),
                StatCard(icon: Icons.star_outline, label: 'Avg. Rating', value: '4.8', color: AppColors.warningOrange),
                StatCard(icon: Icons.repeat, label: 'Repeat Customers', value: '17', color: AppColors.secondaryCyan),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.insights_outlined, color: AppColors.secondaryCyan),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Detailed trend charts will appear here once request '
                      'history is available.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
