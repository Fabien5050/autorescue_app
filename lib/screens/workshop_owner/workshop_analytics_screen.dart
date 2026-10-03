import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../models/assistance_request.dart';
import '../../models/workshop_owner_profile.dart';
import '../../services/assistance_request_api.dart';
import '../../widgets/stat_card.dart';

const List<String> _dayNames = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Analytics" tab — performance counts and interactive 7-day request trend charts
/// derived live from the workshop's request history.
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

  void _refresh() {
    setState(() {
      _requests = AssistanceRequestApi.listForMyWorkshop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Analytics',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryText),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Overview of your workshop performance.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
                    onPressed: _refresh,
                    tooltip: 'Refresh analytics',
                  ),
                ],
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

                  return Column(
                    children: <Widget>[
                      GridView(
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
                      ),
                      const SizedBox(height: 20),
                      _WorkshopTrendChartCard(requests: requests),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive 7-day request trend chart for the workshop analytics tab.
class _WorkshopTrendChartCard extends StatelessWidget {
  const _WorkshopTrendChartCard({required this.requests});

  final List<AssistanceRequest> requests;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<DateTime> days = List<DateTime>.generate(
      7,
      (int i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)),
    );

    final Map<String, int> totalByDay = <String, int>{};
    final Map<String, int> completedByDay = <String, int>{};

    for (final AssistanceRequest r in requests) {
      final String key = '${r.createdAt.year}-${r.createdAt.month}-${r.createdAt.day}';
      totalByDay[key] = (totalByDay[key] ?? 0) + 1;
      if (r.status == 'COMPLETED') {
        completedByDay[key] = (completedByDay[key] ?? 0) + 1;
      }
    }

    final List<double> totalValues = <double>[];
    final List<double> completedValues = <double>[];

    for (final DateTime day in days) {
      final String key = '${day.year}-${day.month}-${day.day}';
      totalValues.add((totalByDay[key] ?? 0).toDouble());
      completedValues.add((completedByDay[key] ?? 0).toDouble());
    }

    double maxVal = 0;
    for (final double v in totalValues) {
      if (v > maxVal) maxVal = v;
    }
    final double maxY = maxVal <= 0 ? 5 : (maxVal * 1.3).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Request Trend (Last 7 Days)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryText),
              ),
              Row(
                children: <Widget>[
                  _LegendDot(color: AppColors.primaryBlue, label: 'Total'),
                  const SizedBox(width: 12),
                  _LegendDot(color: AppColors.accentGreen, label: 'Completed'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 4).clamp(1, double.infinity),
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (maxY / 4).clamp(1, double.infinity),
                      getTitlesWidget: (double value, TitleMeta meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int index = value.toInt();
                        if (index < 0 || index >= days.length) return const SizedBox.shrink();
                        final DateTime day = days[index];
                        final String label = _dayNames[day.weekday - 1];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: List<FlSpot>.generate(7, (int i) => FlSpot(i.toDouble(), totalValues[i])),
                    isCurved: true,
                    color: AppColors.primaryBlue,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (FlSpot spot, double xPercentage, LineChartBarData bar, int index) =>
                          FlDotCirclePainter(radius: 3.5, color: AppColors.primaryBlue, strokeColor: Colors.white, strokeWidth: 1.5),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    ),
                  ),
                  LineChartBarData(
                    spots: List<FlSpot>.generate(7, (int i) => FlSpot(i.toDouble(), completedValues[i])),
                    isCurved: true,
                    color: AppColors.accentGreen,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (FlSpot spot, double xPercentage, LineChartBarData bar, int index) =>
                          FlDotCirclePainter(radius: 3.5, color: AppColors.accentGreen, strokeColor: Colors.white, strokeWidth: 1.5),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accentGreen.withValues(alpha: 0.08),
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.secondaryText, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
