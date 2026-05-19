import 'package:control_center/features/meetings/presentation/utils/meeting_format.dart';
import 'package:test/test.dart';

void main() {
  group('MeetingFormat.clock', () {
    test('formats seconds as MM:SS', () {
      expect(MeetingFormat.clock(const Duration(seconds: 0)), '00:00');
      expect(MeetingFormat.clock(const Duration(seconds: 5)), '00:05');
      expect(MeetingFormat.clock(const Duration(seconds: 59)), '00:59');
      expect(MeetingFormat.clock(const Duration(minutes: 3, seconds: 7)), '03:07');
      expect(MeetingFormat.clock(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('formats durations >= 1 hour as H:MM:SS', () {
      expect(MeetingFormat.clock(const Duration(hours: 1)), '1:00:00');
      expect(MeetingFormat.clock(const Duration(hours: 1, minutes: 5, seconds: 3)), '1:05:03');
      expect(MeetingFormat.clock(const Duration(hours: 10, minutes: 42, seconds: 17)), '10:42:17');
    });

    test('handles negative duration by clamping to zero', () {
      expect(MeetingFormat.clock(const Duration(seconds: -5)), '00:00');
      expect(MeetingFormat.clock(const Duration(minutes: -10)), '00:00');
    });
  });

  group('MeetingFormat.totalLabel', () {
    test('formats durations under an hour', () {
      expect(MeetingFormat.totalLabel(Duration.zero), '0m');
      expect(MeetingFormat.totalLabel(const Duration(minutes: 5)), '5m');
      expect(MeetingFormat.totalLabel(const Duration(minutes: 48)), '48m');
      expect(MeetingFormat.totalLabel(const Duration(minutes: 59)), '59m');
    });

    test('formats durations >= 1 hour with padded minutes', () {
      expect(MeetingFormat.totalLabel(const Duration(hours: 1)), '1h 00m');
      expect(MeetingFormat.totalLabel(const Duration(hours: 2, minutes: 5)), '2h 05m');
      expect(MeetingFormat.totalLabel(const Duration(hours: 3, minutes: 42)), '3h 42m');
    });

    test('handles negative duration by clamping to zero', () {
      expect(MeetingFormat.totalLabel(const Duration(minutes: -5)), '0m');
    });
  });

  group('MeetingFormat.stamp', () {
    test('converts ms to MM:SS', () {
      expect(MeetingFormat.stamp(0), '00:00');
      expect(MeetingFormat.stamp(5000), '00:05');
      expect(MeetingFormat.stamp(60000), '01:00');
      expect(MeetingFormat.stamp(3723000), '1:02:03');
    });

    test('handles negative ms by clamping to zero', () {
      expect(MeetingFormat.stamp(-100), '00:00');
    });
  });

  group('MeetingFormat.duration', () {
    test('returns difference when endedAt is provided', () {
      final start = DateTime(2026, 6, 10, 10, 0, 0);
      final end = DateTime(2026, 6, 10, 10, 30, 0);
      final now = DateTime(2026, 6, 10, 11, 0, 0);
      expect(MeetingFormat.duration(start, end, now), const Duration(minutes: 30));
    });

    test('uses now when endedAt is null (recording still in progress)', () {
      final start = DateTime(2026, 6, 10, 10, 0, 0);
      final now = DateTime(2026, 6, 10, 10, 15, 0);
      expect(MeetingFormat.duration(start, null, now), const Duration(minutes: 15));
    });

    test('clamps negative duration to zero', () {
      final start = DateTime(2026, 6, 10, 10, 30, 0);
      final end = DateTime(2026, 6, 10, 10, 0, 0);
      final now = DateTime(2026, 6, 10, 11, 0, 0);
      expect(MeetingFormat.duration(start, end, now), Duration.zero);
    });
  });

  group('MeetingFormat.bucketFor', () {
    test('returns today when when >= start of today', () {
      final now = DateTime(2026, 6, 10, 15, 0, 0);
      expect(
        MeetingFormat.bucketFor(DateTime(2026, 6, 10, 14, 0, 0), now),
        MeetingDayBucket.today,
      );
      expect(
        MeetingFormat.bucketFor(DateTime(2026, 6, 10, 0, 0, 0), now),
        MeetingDayBucket.today,
      );
    });

    test('returns yesterday', () {
      final now = DateTime(2026, 6, 10, 15, 0, 0);
      expect(
        MeetingFormat.bucketFor(DateTime(2026, 6, 9, 14, 0, 0), now),
        MeetingDayBucket.yesterday,
      );
    });

    test('returns earlierThisWeek', () {
      // June 10, 2026 is a Wednesday. Monday is June 8.
      final now = DateTime(2026, 6, 10, 15, 0, 0);
      expect(
        MeetingFormat.bucketFor(DateTime(2026, 6, 8, 14, 0, 0), now),
        MeetingDayBucket.earlierThisWeek,
      );
    });

    test('returns lastWeek', () {
      // June 10, 2026 is a Wednesday. Monday is June 8. Last Monday is June 1.
      final now = DateTime(2026, 6, 10, 15, 0, 0);
      expect(
        MeetingFormat.bucketFor(DateTime(2026, 6, 5, 14, 0, 0), now),
        MeetingDayBucket.lastWeek,
      );
      expect(
        MeetingFormat.bucketFor(DateTime(2026, 6, 1, 0, 0, 0), now),
        MeetingDayBucket.lastWeek,
      );
    });

    test('returns older for dates before last week', () {
      final now = DateTime(2026, 6, 10, 15, 0, 0);
      expect(
        MeetingFormat.bucketFor(DateTime(2026, 5, 31, 23, 59, 59), now),
        MeetingDayBucket.older,
      );
    });
  });
}
