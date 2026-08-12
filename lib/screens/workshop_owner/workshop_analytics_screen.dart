import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../models/assistance_request.dart';
import '../../models/workshop_owner_profile.dart';
import '../../services/assistance_request_api.dart';
import '../../widgets/stat_card.dart';

/// "Analytics" tab — real counts derived from the workshop's request
/// history and its aggregate rating. There's no dedicated analytics
/// endpoint (and no time-series data to chart), so this stays a summary
/// rather than trend charts.
class WorkshopAnalyticsScreen extends StatefulWidget {
  const WorkshopAnalyticsScreen({super.key});

  @override
  State<WorkshopAnalyticsScreen> createState() => _WorkshopAnalyticsScreenState();
}

class _WorkshopAnalyticsScreenState extends State<WorkshopAnalyticsScreen> {
  late Future<List<AssistanceRequest>> _requests;

  @override
  void initState() {
    super.initState();
    _requests = AssistanceRequestApi.listForMyWorkshop();
  }

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
              'Overview of your workshop performance.',
              style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 18),
            FutureBuilder<List<AssistanceRequest>>(
              future: _requests,
              builder: (BuildContext context, AsyncSnapshot<List<AssistanceRequest>> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  final String message = snapshot.error is ApiException
                      ? (snapshot.error! as ApiException).message
                      : 'Failed to load analytics.';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(message, style: const TextStyle(color: AppColors.secondaryText)),
                  );
                }

                final List<AssistanceRequest> requests = snapshot.data ?? const <AssistanceRequest>[];
                final int completed = requests.where((AssistanceRequest r) => r.status == 'COMPLETED').length;
                final Map<int, int> completedByDriver = <int, int>{};
                for (final AssistanceRequest r in requests) {
                  if (r.status == 'COMPLETED') {
                    completedByDriver[r.driverId] = (completedByDriver[r.driverId] ?? 0) + 1;
                  }
                }
                final int repeatCustomers = completedByDriver.values.where((int count) => count > 1).length;

                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisExtent: 138,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  children: <Widget>[
                    StatCard(icon: Icons.build_circle_outlined, label: 'Completed Jobs', value: '$completed', color: AppColors.primaryBlue),
                    StatCard(icon: Icons.list_alt_outlined, label: 'Total Requests', value: '${requests.length}', color: AppColors.secondaryCyan),
                    StatCard(
                      icon: Icons.star_outline,
                      label: 'Avg. Rating',
                      value: demoWorkshopOwnerProfile.rating.toStringAsFixed(1),
                      color: AppColors.warningOrange,
                    ),
                    StatCard(icon: Icons.repeat, label: 'Repeat Customers', value: '$repeatCustomers', color: AppColors.accentGreen),
                  ],
                );
              },
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
