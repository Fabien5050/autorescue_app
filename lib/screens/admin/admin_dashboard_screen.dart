import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/app_colors.dart';
import '../../core/websocket_service.dart';
import '../../models/admin_analytics.dart';
import '../../models/admin_dashboard_summary.dart';
import '../../services/admin_dashboard_api.dart';
import '../../widgets/admin_charts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.onReviewRequested});

  /// Switches the shell to the Mechanic Verification tab — the Dashboard
  /// only surfaces pending applications, review actually happens there.
  final VoidCallback onReviewRequested;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminDashboardSummary> _summaryFuture;
  late Future<List<DailyStat>> _dailyFuture;
  late Future<StatusCounts> _statusFuture;
  late Future<List<WorkshopStat>> _topWorkshopsFuture;
  late Future<List<HourlyStat>> _hourlyFuture;

  /// Overrides [_summaryFuture]'s result once a live push arrives, so the
  /// stat tiles update every 30s without the admin touching "Refresh Data".
  AdminDashboardSummary? _liveSummary;
  StreamSubscription<AdminDashboardSummary>? _liveStatsSub;

  @override
  void initState() {
    super.initState();
    _fetchAll();

    WebSocketService.instance.connect();
    _liveStatsSub = WebSocketService.instance.liveStats.listen((AdminDashboardSummary summary) {
      if (!mounted) return;
      setState(() => _liveSummary = summary);
      // The hourly chart is the one piece the brief calls out as
      // real-time — refetch it on the same 30s cadence the summary
      // pushes arrive on, rather than a separate timer.
      setState(() => _hourlyFuture = AdminDashboardApi.getHourlyToday());
    });
  }

  @override
  void dispose() {
    _liveStatsSub?.cancel();
    super.dispose();
  }

  void _fetchAll() {
    _summaryFuture = AdminDashboardApi.getSummary();
    _dailyFuture = AdminDashboardApi.getRequestsLast7Days();
    _statusFuture = AdminDashboardApi.getRequestsByStatus();
    _topWorkshopsFuture = AdminDashboardApi.getTopWorkshops();
    _hourlyFuture = AdminDashboardApi.getHourlyToday();
  }

  void _refresh() => setState(() {
    _liveSummary = null;
    _fetchAll();
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _DashboardHeader(onRefresh: _refresh),
            const SizedBox(height: 22),
            FutureBuilder<AdminDashboardSummary>(
              future: _summaryFuture,
              builder: (BuildContext context, AsyncSnapshot<AdminDashboardSummary> snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _StatTilesShimmer();
                }
                if (snapshot.hasError) {
                  final String message = snapshot.error is ApiException
                      ? (snapshot.error! as ApiException).message
                      : 'Failed to load dashboard data.';
                  return _RetryBlock(message: message, onRetry: _refresh);
                }

                final AdminDashboardSummary summary = _liveSummary ?? snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _StatTilesRow(summary: summary),
                    const SizedBox(height: 26),
                    _RecentApplicationsCard(
                      applications: summary.recentApplications,
                      onReviewRequested: widget.onReviewRequested,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            _ChartCard(
              title: 'Breakdown Requests — Last 7 Days',
              child: FutureBuilder<List<DailyStat>>(
                future: _dailyFuture,
                builder: (BuildContext context, AsyncSnapshot<List<DailyStat>> snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const ChartShimmer();
                  if (snapshot.hasError) {
                    return _RetryBlock(message: _errorMessage(snapshot.error), onRetry: _refresh, compact: true);
                  }
                  return RequestsTrendChart(data: snapshot.data!);
                },
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool wide = constraints.maxWidth >= 720;
                final Widget statusChart = _ChartCard(
                  title: 'Requests by Status',
                  child: FutureBuilder<StatusCounts>(
                    future: _statusFuture,
                    builder: (BuildContext context, AsyncSnapshot<StatusCounts> snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) return const ChartShimmer();
                      if (snapshot.hasError) {
                        return _RetryBlock(message: _errorMessage(snapshot.error), onRetry: _refresh, compact: true);
                      }
                      return RequestsByStatusChart(counts: snapshot.data!);
                    },
                  ),
                );
                final Widget workshopsChart = _ChartCard(
                  title: 'Top 5 Workshops by Rating',
                  child: FutureBuilder<List<WorkshopStat>>(
                    future: _topWorkshopsFuture,
                    builder: (BuildContext context, AsyncSnapshot<List<WorkshopStat>> snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) return const ChartShimmer();
                      if (snapshot.hasError) {
                        return _RetryBlock(message: _errorMessage(snapshot.error), onRetry: _refresh, compact: true);
                      }
                      return TopWorkshopsChart(data: snapshot.data!);
                    },
                  ),
                );

                if (!wide) {
                  return Column(children: <Widget>[statusChart, const SizedBox(height: 20), workshopsChart]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: statusChart),
                    const SizedBox(width: 20),
                    Expanded(child: workshopsChart),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _ChartCard(
              title: "Today's Requests by Hour",
              child: FutureBuilder<List<HourlyStat>>(
                future: _hourlyFuture,
                builder: (BuildContext context, AsyncSnapshot<List<HourlyStat>> snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) return const ChartShimmer();
                  if (snapshot.hasError) {
                    return _RetryBlock(message: _errorMessage(snapshot.error), onRetry: _refresh, compact: true);
                  }
                  return HourlyRequestsChart(data: snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _errorMessage(Object? error) =>
      error is ApiException ? error.message : 'Failed to load chart data.';
}

class _RetryBlock extends StatelessWidget {
  const _RetryBlock({required this.message, required this.onRetry, this.compact = false});

  final String message;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 24 : 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, style: const TextStyle(color: AppColors.slate), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _StatTilesShimmer extends StatelessWidget {
  const _StatTilesShimmer();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List<Widget>.generate(
        5,
        (_) => const ShimmerBox(width: 240, height: 118, borderRadius: 14),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'System Overview',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -0.3),
              ),
              SizedBox(height: 4),
              Text(
                'Live operational status and metrics.',
                style: TextStyle(fontSize: 13.5, color: AppColors.slate),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 17, color: AppColors.primaryBlue),
          label: const Text('Refresh Data', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            backgroundColor: AppColors.card,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

class _StatTilesRow extends StatelessWidget {
  const _StatTilesRow({required this.summary});

  final AdminDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: <Widget>[
        _StatTile(
          icon: Icons.sos_outlined,
          iconColor: AppColors.dangerRed,
          iconBg: const Color(0xFFFDECEC),
          label: 'Active Requests',
          value: summary.activeRequests.toString(),
          badge: const _Badge(text: 'Live', color: AppColors.dangerRed),
        ),
        _StatTile(
          icon: Icons.storefront_outlined,
          iconColor: AppColors.primaryBlue,
          iconBg: AppColors.badgeSoft,
          label: 'Total Workshops',
          value: summary.totalWorkshops.toString(),
        ),
        _StatTile(
          icon: Icons.shield_outlined,
          iconColor: AppColors.warningOrange,
          iconBg: AppColors.warningSoft,
          label: 'Pending Verifications',
          value: summary.pendingVerifications.toString(),
          badge: summary.pendingVerifications > 0
              ? const _Badge(text: 'Action Required', color: AppColors.warningOrange)
              : null,
        ),
        _StatTile(
          icon: Icons.people_outline,
          iconColor: AppColors.secondaryCyan,
          iconBg: AppColors.indigoSoft,
          label: 'Total Users',
          value: summary.totalUsers.toString(),
        ),
        _StatTile(
          icon: Icons.task_alt_outlined,
          iconColor: AppColors.accentGreen,
          iconBg: AppColors.successSoft,
          label: 'Resolved Today',
          value: summary.resolvedToday.toString(),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.slate, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2),
      ),
    );
  }
}

class _RecentApplicationsCard extends StatelessWidget {
  const _RecentApplicationsCard({required this.applications, required this.onReviewRequested});

  final List<AdminWorkshopSummary> applications;
  final VoidCallback onReviewRequested;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Recent Workshop Applications',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              TextButton(
                onPressed: onReviewRequested,
                child: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (applications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text('No pending applications right now.', style: TextStyle(color: AppColors.slate)),
              ),
            )
          else
            // Each row needs a realistic minimum width to lay out icon +
            // name/ID + address + status badge + Review button without
            // wrapping — on a narrower viewport than that, scroll
            // horizontally rather than overflow.
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth < 640 ? 640 : constraints.maxWidth,
                    child: Column(
                      children: <Widget>[
                        for (final AdminWorkshopSummary application in applications)
                          _ApplicationRow(application: application, onReview: onReviewRequested),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  const _ApplicationRow({required this.application, required this.onReview});

  final AdminWorkshopSummary application;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.badgeSoft, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.build_outlined, size: 18, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  application.name,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.navy),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: W${application.id.toString().padLeft(4, '0')}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.slateLight),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              application.address ?? '—',
              style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Badge(text: 'Pending Review', color: AppColors.warningOrange),
            ),
          ),
          TextButton(
            onPressed: onReview,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Review', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
