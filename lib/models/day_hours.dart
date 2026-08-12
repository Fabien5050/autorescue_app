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

  factory DayHours.fromJson(Map<String, dynamic> json) {
    final int dayOfWeek = json['dayOfWeek'] as int;
    return DayHours(
      day: weekdayNames[dayOfWeek - 1],
      isOpen: json['isOpen'] as bool? ?? true,
      openTime: _parseWireTime(json['openTime'] as String?) ?? const TimeOfDay(hour: 8, minute: 0),
      closeTime: _parseWireTime(json['closeTime'] as String?) ?? const TimeOfDay(hour: 18, minute: 0),
    );
  }

  /// Reorders a backend `operatingHours` list (possibly partial/unordered)
  /// into a fixed Monday-through-Sunday list, matching every other screen's
  /// expectation of a full 7-entry week.
  static List<DayHours> listFromJson(List<dynamic> json) {
    final Map<int, DayHours> byDay = <int, DayHours>{
      for (final dynamic entry in json)
        (entry as Map<String, dynamic>)['dayOfWeek'] as int: DayHours.fromJson(entry),
    };
    return <DayHours>[
      for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++)
        byDay[dayOfWeek] ?? DayHours(day: weekdayNames[dayOfWeek - 1], isOpen: dayOfWeek != 7),
    ];
  }
}

/// Monday-first weekday names, index 0 = dayOfWeek 1, matching the
/// backend's `1=Monday .. 7=Sunday` convention.
const List<String> weekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

int dayOfWeekFor(String day) => weekdayNames.indexOf(day) + 1;

String timeOfDayToWire(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

TimeOfDay? _parseWireTime(String? value) {
  if (value == null) return null;
  final List<String> parts = value.split(':');
  if (parts.length < 2) return null;
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
