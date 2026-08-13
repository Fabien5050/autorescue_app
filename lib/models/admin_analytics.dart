/// One point on the "requests over the last 7 days" line chart.
class DailyStat {
  const DailyStat({required this.date, required this.count});

  final DateTime date;
  final int count;

  factory DailyStat.fromJson(Map<String, dynamic> json) =>
      DailyStat(date: DateTime.parse(json['date'] as String), count: (json['count'] as num).toInt());
}

/// One point on "today's requests by hour" — hour is 0-23, UTC.
class HourlyStat {
  const HourlyStat({required this.hour, required this.count});

  final int hour;
  final int count;

  factory HourlyStat.fromJson(Map<String, dynamic> json) =>
      HourlyStat(hour: json['hour'] as int, count: (json['count'] as num).toInt());
}

/// One bar on the "Top 5 Workshops by Rating" chart.
class WorkshopStat {
  const WorkshopStat({required this.name, required this.avgRating, required this.reviewCount});

  final String name;
  final double avgRating;
  final int reviewCount;

  factory WorkshopStat.fromJson(Map<String, dynamic> json) => WorkshopStat(
    name: json['name'] as String,
    avgRating: (json['avgRating'] as num).toDouble(),
    reviewCount: json['reviewCount'] as int,
  );
}

/// Wire keys match the backend's `AssistanceRequest.Status` enum exactly.
class StatusCounts {
  const StatusCounts({
    required this.pending,
    required this.accepted,
    required this.enRoute,
    required this.completed,
    required this.cancelled,
  });

  final int pending;
  final int accepted;
  final int enRoute;
  final int completed;
  final int cancelled;

  int get total => pending + accepted + enRoute + completed + cancelled;

  factory StatusCounts.fromJson(Map<String, dynamic> json) => StatusCounts(
    pending: (json['PENDING'] as num?)?.toInt() ?? 0,
    accepted: (json['ACCEPTED'] as num?)?.toInt() ?? 0,
    enRoute: (json['EN_ROUTE'] as num?)?.toInt() ?? 0,
    completed: (json['COMPLETED'] as num?)?.toInt() ?? 0,
    cancelled: (json['CANCELLED'] as num?)?.toInt() ?? 0,
  );
}
