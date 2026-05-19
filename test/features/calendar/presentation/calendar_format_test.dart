import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarEvent _event({
  required DateTime start,
  Duration duration = const Duration(minutes: 30),
  bool isAllDay = false,
}) {
  return CalendarEvent(
    id: 'e',
    workspaceId: 'ws',
    accountId: 'acc',
    externalEventId: 'x',
    calendarId: 'primary',
    title: 'Event',
    startTime: start,
    endTime: start.add(duration),
    isAllDay: isAllDay,
    updatedAt: start,
  );
}

void main() {
  group('startOfWeek', () {
    test('returns the Monday of the containing week', () {
      // 2026-06-10 is a Wednesday.
      final monday = startOfWeek(DateTime(2026, 6, 10));
      expect(monday.weekday, DateTime.monday);
      expect(monday, DateTime(2026, 6, 8));
    });

    test('is idempotent on a Monday', () {
      final monday = startOfWeek(DateTime(2026, 6, 8, 15));
      expect(monday, DateTime(2026, 6, 8));
    });
  });

  group('startOfMonthGrid', () {
    test('starts on a Monday on or before the 1st', () {
      final gridStart = startOfMonthGrid(DateTime(2026, 6, 17));
      expect(gridStart.weekday, DateTime.monday);
      expect(gridStart.isAfter(DateTime(2026, 6)), isFalse);
      expect(DateTime(2026, 6).difference(gridStart).inDays, lessThan(7));
    });
  });

  group('isoWeekNumber', () {
    test('matches the calendar week label (2026-06-11 → 24)', () {
      expect(isoWeekNumber(DateTime(2026, 6, 11)), 24);
    });

    test('is stable across every day of a week', () {
      // Mon 2026-06-08 … Sun 2026-06-14 are all week 24.
      for (var d = 8; d <= 14; d++) {
        expect(isoWeekNumber(DateTime(2026, 6, d)), 24);
      }
    });

    test('attributes a year-boundary week to its Thursday year', () {
      // 2025-12-31 (Wed) belongs to ISO week 1 of 2026 (Thursday is Jan 1).
      expect(isoWeekNumber(DateTime(2025, 12, 31)), 1);
      // 2023-01-01 (Sun) belongs to ISO week 52 of 2022.
      expect(isoWeekNumber(DateTime(2023, 1, 1)), 52);
    });
  });

  group('isStartingSoon', () {
    final now = DateTime(2026, 6, 11, 10);
    test('true inside the window', () {
      expect(isStartingSoon(_event(start: now.add(const Duration(minutes: 3))), now), isTrue);
    });
    test('true within the grace period after start', () {
      expect(isStartingSoon(_event(start: now.subtract(const Duration(minutes: 2))), now), isTrue);
    });
    test('false well in the future', () {
      expect(isStartingSoon(_event(start: now.add(const Duration(minutes: 30))), now), isFalse);
    });
    test('false long after start', () {
      expect(isStartingSoon(_event(start: now.subtract(const Duration(minutes: 30))), now), isFalse);
    });
    test('false for all-day events', () {
      expect(
        isStartingSoon(_event(start: now.add(const Duration(minutes: 3)), isAllDay: true), now),
        isFalse,
      );
    });
  });

  group('groupEventsByDay', () {
    test('buckets by date-only and sorts each bucket by start', () {
      final events = [
        _event(start: DateTime(2026, 6, 11, 14)),
        _event(start: DateTime(2026, 6, 11, 9)),
        _event(start: DateTime(2026, 6, 12, 10)),
      ];
      final grouped = groupEventsByDay(events);
      expect(grouped.keys.toList(), [DateTime(2026, 6, 11), DateTime(2026, 6, 12)]);
      final day1 = grouped[DateTime(2026, 6, 11)]!;
      expect(day1.first.startTime.hour, 9); // sorted earliest-first
      expect(day1.last.startTime.hour, 14);
    });
  });

  group('occursOnDay', () {
    test('true on the event day, false on adjacent days', () {
      final e = _event(start: DateTime(2026, 6, 11, 10));
      expect(occursOnDay(e, DateTime(2026, 6, 11)), isTrue);
      expect(occursOnDay(e, DateTime(2026, 6, 12)), isFalse);
    });
  });
}
