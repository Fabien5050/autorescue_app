import 'package:flutter/material.dart';

/// One weekday's opening schedule for a workshop.
class DayHours {
  DayHours({
    required this.day,
    this.isOpen = true,
    this.openTime = const TimeOfDay(hour: 8, minute: 0),
    this.closeTime = const TimeOfDay(hour: 18, minute: 0),
  });

  final String day;
  bool isOpen;
  TimeOfDay openTime;
  TimeOfDay closeTime;

  String label(BuildContext context) {
    if (!isOpen) return 'Closed';
    return '${openTime.format(context)} - ${closeTime.format(context)}';
  }
}

/// Standard Mon-Sun week, Sunday closed by default — matches the demo
/// workshop's schedule.
List<DayHours> demoWeeklyHours() => <DayHours>[
      DayHours(day: 'Monday'),
      DayHours(day: 'Tuesday'),
      DayHours(day: 'Wednesday'),
      DayHours(day: 'Thursday'),
      DayHours(day: 'Friday'),
      DayHours(day: 'Saturday', openTime: const TimeOfDay(hour: 9, minute: 0), closeTime: const TimeOfDay(hour: 15, minute: 0)),
      DayHours(day: 'Sunday', isOpen: false),
    ];
