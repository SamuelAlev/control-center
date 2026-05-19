import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('visibleRangeFor', () {
    final selected = DateTime(2026, 6, 17); // a Wednesday

    test('month spans the full 6-week grid from a Monday', () {
      final range = visibleRangeFor(CalendarViewMode.month, selected);
      expect(range.start, startOfMonthGrid(selected));
      expect(range.start.weekday, DateTime.monday);
      expect(range.duration.inDays, 42);
    });

    test('week spans the Monday-started 7-day window', () {
      final range = visibleRangeFor(CalendarViewMode.week, selected);
      expect(range.start, startOfWeek(selected));
      expect(range.start.weekday, DateTime.monday);
      expect(range.duration.inDays, 7);
    });

    test('day spans the single selected day', () {
      final range = visibleRangeFor(CalendarViewMode.day, selected);
      expect(range.start, dayKey(selected));
      expect(range.duration.inDays, 1);
    });

    test('agenda spans the next 30 days from the selected day', () {
      final range = visibleRangeFor(CalendarViewMode.agenda, selected);
      expect(range.start, dayKey(selected));
      expect(range.duration.inDays, 30);
    });
  });
}
