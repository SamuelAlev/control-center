import 'package:control_center/features/calendar/presentation/calendar_view_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarViewMode.fromStorage', () {
    test('round-trips each value', () {
      for (final mode in CalendarViewMode.values) {
        expect(
          CalendarViewMode.fromStorage(mode.toStorageString()),
          mode,
        );
      }
    });

    test('defaults unknown / null to month', () {
      expect(CalendarViewMode.fromStorage(null), CalendarViewMode.month);
      expect(CalendarViewMode.fromStorage('nonsense'), CalendarViewMode.month);
    });
  });
}
