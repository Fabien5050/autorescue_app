import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/app_colors.dart';
import '../models/admin_analytics.dart';

const List<String> _weekdayLabels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// A single shimmering placeholder block, used for both the stat tiles and
/// (via [ChartShimmer]) the chart bodies while their data is loading.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, required this.width, required this.height, this.borderRadius = 10});

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.screenBackground,
      highlightColor: AppColors.card,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: AppColors.screenBackground, borderRadius: BorderRadius.circular(borderRadius)),
      ),
    );
  }
}

/// Standard-size placeholder for a chart card's body while its data loads.
class ChartShimmer extends StatelessWidget {
  const ChartShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 220, child: ShimmerBox(width: double.infinity, height: 220));
  }
}

/// "Breakdown Requests — Last 7 Days" — smooth blue line with a gradient
/// fill, animated on load (fl_chart's `LineChart` widget animates size/data
/// changes implicitly).
class RequestsTrendChart extends StatelessWidget {
  const RequestsTrendChart({super.key, required this.data});

  final List<DailyStat> data;

  @override
  Widget build(BuildContext context) {
    final double maxCount = data.map((DailyStat d) => d.count).fold(0, (int a, int b) => a > b ? a : b).toDouble();
    final double maxY = maxCount <= 0 ? 4 : (maxCount * 1.25).ceilToDouble();

    return SizedBox(
      height: 220,
      child: LineChart(
        duration: const Duration(milliseconds: 500),
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
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
                  style: const TextStyle(fontSize: 10.5, color: AppColors.slateLight),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _weekdayLabels[data[index].date.weekday - 1],
                      style: const TextStyle(fontSize: 10.5, color: AppColors.slateLight),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.navy,
              getTooltipItems: (List<LineBarSpot> spots) => spots
                  .map((LineBarSpot s) => LineTooltipItem(
                        '${s.y.toInt()} requests',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ))
                  .toList(),
            ),
          ),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: <FlSpot>[
                for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].count.toDouble()),
              ],
              isCurved: true,
              color: AppColors.primaryBlue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[AppColors.primaryBlue.withValues(alpha: 0.28), AppColors.primaryBlue.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Requests by Status" donut with a percentage label per slice.
class RequestsByStatusChart extends StatelessWidget {
  const RequestsByStatusChart({super.key, required this.counts});

  final StatusCounts counts;

  static const List<(String, Color)> _slices = <(String, Color)>[
    ('Pending', AppColors.warningOrange),
    ('Accepted', AppColors.primaryBlue),
    ('In Progress', AppColors.secondaryCyan),
    ('Resolved', AppColors.accentGreen),
    ('Cancelled', AppColors.dangerRed),
  ];

  @override
  Widget build(BuildContext context) {
    final List<int> values = <int>[counts.pending, counts.accepted, counts.enRoute, counts.completed, counts.cancelled];
    final int total = counts.total;

    if (total == 0) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No requests yet.', style: TextStyle(color: AppColors.slate))),
      );
    }

    return SizedBox(
      height: 220,
      child: Row(
        children: <Widget>[
          Expanded(
            child: PieChart(
              duration: const Duration(milliseconds: 500),
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: <PieChartSectionData>[
                  for (int i = 0; i < _slices.length; i++)
                    if (values[i] > 0)
                      PieChartSectionData(
                        value: values[i].toDouble(),
                        color: _slices[i].$2,
                        radius: 46,
                        title: '${(values[i] / total * 100).round()}%',
                        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < _slices.length; i++) _LegendRow(label: _slices[i].$1, color: _slices[i].$2, value: values[i]),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.label, required this.color, required this.value});

  final String label;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('$label ($value)', style: const TextStyle(fontSize: 12, color: AppColors.slate)),
        ],
      ),
    );
  }
}

/// "Top 5 Workshops by Rating" — gradient bars, names truncated to 10 chars.
class TopWorkshopsChart extends StatelessWidget {
  const TopWorkshopsChart({super.key, required this.data});

  final List<WorkshopStat> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('No rated workshops yet.', style: TextStyle(color: AppColors.slate))),
      );
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        duration: const Duration(milliseconds: 500),
        BarChartData(
          minY: 0,
          maxY: 5,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.navy,
              getTooltipItem: (BarChartGroupData group, int i, BarChartRodData rod, int j) => BarTooltipItem(
                rod.toY.toStringAsFixed(1),
                const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 1),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  final String name = data[index].name;
                  final String truncated = name.length > 10 ? '${name.substring(0, 10)}…' : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      truncated,
                      style: const TextStyle(fontSize: 10, color: AppColors.slateLight),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: <BarChartGroupData>[
            for (int i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: data[i].avgRating,
                    width: 26,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: <Color>[AppColors.primaryBlue, AppColors.secondaryCyan],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// "Today's Requests by Hour" — updates live via [WebSocketService]'s
/// `liveStats` push (the parent screen refetches and rebuilds this widget).
class HourlyRequestsChart extends StatelessWidget {
  const HourlyRequestsChart({super.key, required this.data});

  final List<HourlyStat> data;

  @override
  Widget build(BuildContext context) {
    final double maxCount = data.map((HourlyStat d) => d.count).fold(0, (int a, int b) => a > b ? a : b).toDouble();
    final double maxY = maxCount <= 0 ? 4 : (maxCount * 1.25).ceilToDouble();

    return SizedBox(
      height: 220,
      child: LineChart(
        duration: const Duration(milliseconds: 400),
        LineChartData(
          minX: 0,
          maxX: 23,
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
                  style: const TextStyle(fontSize: 10.5, color: AppColors.slateLight),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 4,
                getTitlesWidget: (double value, TitleMeta meta) => Text(
                  '${value.toInt()}h',
                  style: const TextStyle(fontSize: 10, color: AppColors.slateLight),
                ),
              ),
            ),
          ),
          lineBarsData: <LineChartBarData>[
            LineChartBarData(
              spots: <FlSpot>[for (final HourlyStat h in data) FlSpot(h.hour.toDouble(), h.count.toDouble())],
              isCurved: true,
              color: AppColors.secondaryCyan,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    AppColors.secondaryCyan.withValues(alpha: 0.22),
                    AppColors.secondaryCyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
