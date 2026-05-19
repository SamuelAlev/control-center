import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';

/// Pure date/time helpers for the calendar presentation layer.
/// The Monday that starts the week containing [date] (date-only).
DateTime startOfWeek(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  // DateTime.weekday: Monday = 1 … Sunday = 7.
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

/// The first day of the month containing [date] (date-only).
DateTime startOfMonth(DateTime date) =>
    DateTime(date.year, date.month);

/// The first visible day of the month grid (the Monday on/just before the
/// 1st), so the grid always starts on a week boundary.
DateTime startOfMonthGrid(DateTime date) =>
    startOfWeek(startOfMonth(date));

/// Date-only key for bucketing events by day.
DateTime dayKey(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// The ISO-8601 week number (1–53) of the week containing [date]. The week is
/// attributed to the year of its Thursday, matching how calendars label weeks
/// (e.g. 2026-06-11 → week 24).
int isoWeekNumber(DateTime date) {
  // Compute in UTC so day arithmetic isn't thrown off by DST transitions (a
  // local spring-forward day is only 23h, which would undercount `.inDays`).
  final d = DateTime.utc(date.year, date.month, date.day);
  // DateTime.weekday: Monday = 1 … Sunday = 7. The Thursday of this week
  // decides which year (and therefore week-1 anchor) the week belongs to.
  final thursday = d.add(Duration(days: DateTime.thursday - d.weekday));
  final firstDayOfYear = DateTime.utc(thursday.year);
  final daysSinceYearStart = thursday.difference(firstDayOfYear).inDays;
  return (daysSinceYearStart ~/ 7) + 1;
}

/// Whether [event] is starting "soon" relative to [now] — used to surface the
/// inline "Start recording" action. True when start is within
/// `[now - grace, now + window]` (a small grace covers a meeting that just
/// began). All-day events are never "starting soon".
bool isStartingSoon(
  CalendarEvent event,
  DateTime now, {
  Duration window = const Duration(minutes: 10),
  Duration grace = const Duration(minutes: 5),
}) {
  if (event.isAllDay) {
    return false;
  }
  final start = event.startTime.toLocal();
  return start.isAfter(now.subtract(grace)) &&
      start.isBefore(now.add(window));
}

/// Whether [event] overlaps the day [day] (date-only), for agenda grouping.
bool occursOnDay(CalendarEvent event, DateTime day) {
  final dayStart = dayKey(day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final start = event.startTime.toLocal();
  final end = event.endTime.toLocal();
  return start.isBefore(dayEnd) && end.isAfter(dayStart);
}

/// Groups [events] by their start day (date-only, local), each bucket sorted by
/// start time. Returns an ordered map (earliest day first).
Map<DateTime, List<CalendarEvent>> groupEventsByDay(
  List<CalendarEvent> events,
) {
  final byDay = <DateTime, List<CalendarEvent>>{};
  for (final event in events) {
    final key = dayKey(event.startTime.toLocal());
    (byDay[key] ??= []).add(event);
  }
  final sortedKeys = byDay.keys.toList()..sort();
  return {
    for (final key in sortedKeys)
      key: byDay[key]!
        ..sort((a, b) => a.startTime.compareTo(b.startTime)),
  };
}
