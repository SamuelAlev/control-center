import 'package:cc_domain/features/pipelines/domain/services/cron_schedule.dart';
import 'package:test/test.dart';

/// Covers the [CronSchedule] cron parser: field syntax (wildcards, steps,
/// ranges, lists, combos), the Sunday=0/7 normalisation, the DOM/DOW union
/// rule, the timezone-agnostic `matches` and `nextAfter` (next-fire
/// computation) across month / day / hour / minute rollovers and unsatisfiable
/// expressions.
void main() {
  group('CronSchedule.tryParse field syntax', () {
    test('parses a simple 5-field expression', () {
      final s = CronSchedule.tryParse('0 9 * * *')!;
      expect(s.expression, '0 9 * * *');
      expect(s.minutes, {0});
      expect(s.hours, {9});
      expect(s.daysOfMonth, List.generate(31, (i) => i + 1).toSet());
      expect(s.months, List.generate(12, (i) => i + 1).toSet());
      expect(s.daysOfWeek, {0, 1, 2, 3, 4, 5, 6});
      expect(s.domRestricted, isFalse);
      expect(s.dowRestricted, isFalse);
    });

    test('parses a wildcard minute/hour as the full range', () {
      final s = CronSchedule.tryParse('* * * * *')!;
      expect(s.minutes.length, 60);
      expect(s.hours.length, 24);
    });

    test('parses a step value (*/n)', () {
      final s = CronSchedule.tryParse('*/15 * * * *')!;
      expect(s.minutes, {0, 15, 30, 45});
    });

    test('parses an explicit range (a-b)', () {
      final s = CronSchedule.tryParse('0 9-17 * * *')!;
      expect(s.hours, {9, 10, 11, 12, 13, 14, 15, 16, 17});
    });

    test('parses a stepped range (a-b/n)', () {
      final s = CronSchedule.tryParse('0 9-17/2 * * *')!;
      expect(s.hours, {9, 11, 13, 15, 17});
    });

    test('parses a comma-separated list mixing literals and ranges', () {
      final s = CronSchedule.tryParse('0,15,30-45 * * * *')!;
      expect(s.minutes, containsAll(<int>{0, 15, 30, 31, 45}));
      expect(s.minutes.contains(1), isFalse);
    });

    test('parses a single literal as a singleton', () {
      final s = CronSchedule.tryParse('5 5 5 5 5')!;
      expect(s.minutes, {5});
      expect(s.hours, {5});
      expect(s.daysOfMonth, {5});
      expect(s.months, {5});
      expect(s.daysOfWeek, {5});
      expect(s.domRestricted, isTrue);
      expect(s.dowRestricted, isTrue);
    });

    test('normalises day-of-week 7 (Sunday) to 0', () {
      final s = CronSchedule.tryParse('0 0 * * 7')!;
      expect(s.daysOfWeek, {0});
    });

    test(
      'accepts a list of weekday names via numeric codes (Mon-Fri = 1-5)',
      () {
        final s = CronSchedule.tryParse('0 0 * * 1-5')!;
        expect(s.daysOfWeek, {1, 2, 3, 4, 5});
      },
    );
  });

  group('CronSchedule.tryParse rejection', () {
    test('returns null for a wrong number of fields', () {
      expect(CronSchedule.tryParse('0 9 * *'), isNull);
      expect(CronSchedule.tryParse('0 9 * * * *'), isNull);
    });

    test('returns null for an out-of-range value', () {
      expect(CronSchedule.tryParse('60 9 * * *'), isNull);
      expect(CronSchedule.tryParse('0 24 * * *'), isNull);
      expect(CronSchedule.tryParse('0 9 0 * *'), isNull);
      expect(CronSchedule.tryParse('0 9 32 * *'), isNull);
      expect(CronSchedule.tryParse('0 9 * 13 *'), isNull);
      expect(CronSchedule.tryParse('0 9 * * 8'), isNull);
    });

    test('returns null for an inverted range (lo > hi)', () {
      expect(CronSchedule.tryParse('10-5 * * * *'), isNull);
    });

    test('returns null for a non-numeric literal', () {
      expect(CronSchedule.tryParse('abc 9 * * *'), isNull);
    });

    test('returns null for a malformed range (three bounds)', () {
      expect(CronSchedule.tryParse('1-2-3 * * * *'), isNull);
    });

    test('returns null for a zero or non-numeric step', () {
      expect(CronSchedule.tryParse('*/0 * * * *'), isNull);
      expect(CronSchedule.tryParse('*/x * * * *'), isNull);
    });

    test('returns null for an empty comma token', () {
      expect(CronSchedule.tryParse('1,,2 * * * *'), isNull);
    });

    test('returns null for a blank field when coerced into one token', () {
      // Single-space split collapses to one empty field → not 5 fields.
      expect(CronSchedule.tryParse(' '), isNull);
    });

    test('trims surrounding whitespace before splitting', () {
      final s = CronSchedule.tryParse('   0 9 * * *   ')!;
      expect(s.minutes, {0});
      expect(s.expression, '0 9 * * *');
    });
  });

  group('CronSchedule.matches', () {
    test('matches an exact minute/hour on any day', () {
      final s = CronSchedule.tryParse('30 14 * * *')!;
      expect(s.matches(DateTime.utc(2026, 7, 13, 14, 30)), isTrue);
      expect(s.matches(DateTime.utc(2026, 7, 13, 14, 31)), isFalse);
      expect(s.matches(DateTime.utc(2026, 7, 13, 15, 30)), isFalse);
    });

    test('respects the month field', () {
      final s = CronSchedule.tryParse('0 0 * 6 *')!;
      expect(s.matches(DateTime.utc(2026, 6, 1, 0, 0)), isTrue);
      expect(s.matches(DateTime.utc(2026, 7, 1, 0, 0)), isFalse);
    });

    test('a restricted day-of-week rejects out-of-window days', () {
      // Every Monday at midnight: cron dow 1.
      final s = CronSchedule.tryParse('0 0 * * 1')!;
      // 2026-07-13 is a Monday.
      expect(s.matches(DateTime.utc(2026, 7, 13, 0, 0)), isTrue);
      // 2026-07-14 is a Tuesday.
      expect(s.matches(DateTime.utc(2026, 7, 14, 0, 0)), isFalse);
    });

    test('a restricted day-of-month rejects out-of-window days', () {
      final s = CronSchedule.tryParse('0 0 15 * *')!;
      expect(s.matches(DateTime.utc(2026, 7, 15, 0, 0)), isTrue);
      expect(s.matches(DateTime.utc(2026, 7, 16, 0, 0)), isFalse);
    });

    test('fires when BOTH DOM and DOW are restricted and EITHER matches', () {
      // Standard union rule: day matches if the 1st OR Mon matches.
      final s = CronSchedule.tryParse('0 0 1 * 1')!;
      // 2026-07-01 is a Wednesday, so DOM=1 matches.
      expect(s.matches(DateTime.utc(2026, 7, 1, 0, 0)), isTrue);
      // 2026-07-13 is a Monday, so DOW=Mon matches (DOM != 1).
      expect(s.matches(DateTime.utc(2026, 7, 13, 0, 0)), isTrue);
      // 2026-07-14 is a Tuesday with day 14 → neither matches.
      expect(s.matches(DateTime.utc(2026, 7, 14, 0, 0)), isFalse);
    });

    test('unrestricted DOM/DOW matches any day', () {
      final s = CronSchedule.tryParse('0 0 * * *')!;
      for (var d = 1; d <= 7; d++) {
        expect(s.matches(DateTime.utc(2026, 7, d, 0, 0)), isTrue);
      }
    });

    test('Sunday (cron 0) matches a Dart Sunday', () {
      // 2026-07-12 is a Sunday.
      final s = CronSchedule.tryParse('0 0 * * 0')!;
      expect(s.matches(DateTime.utc(2026, 7, 12, 0, 0)), isTrue);
    });
  });

  group('CronSchedule.nextAfter', () {
    test('advances only the minute within the same hour', () {
      final s = CronSchedule.tryParse('*/30 * * * *')!;
      expect(
        s.nextAfter(DateTime.utc(2026, 7, 13, 9, 5)),
        DateTime.utc(2026, 7, 13, 9, 30),
      );
    });

    test('rolls the hour forward when the minute window has passed', () {
      final s = CronSchedule.tryParse('15 9 * * *')!;
      expect(
        s.nextAfter(DateTime.utc(2026, 7, 13, 9, 16)),
        DateTime.utc(2026, 7, 14, 9, 15),
      );
    });

    test('rolls the day forward when only a later hour qualifies', () {
      final s = CronSchedule.tryParse('0 0 * * *')!;
      expect(
        s.nextAfter(DateTime.utc(2026, 7, 13, 0, 0)),
        DateTime.utc(2026, 7, 14, 0, 0),
      );
    });

    test('jumps straight to the next allowed day under a weekday filter', () {
      // Mondays only. 2026-07-13 is a Monday; next Monday is 2026-07-20.
      final s = CronSchedule.tryParse('0 0 * * 1')!;
      expect(
        s.nextAfter(DateTime.utc(2026, 7, 13, 0, 0)),
        DateTime.utc(2026, 7, 20, 0, 0),
      );
    });

    test('jumps straight to the next allowed month', () {
      // Run at 00:00 on June 1 each year.
      final s = CronSchedule.tryParse('0 0 1 6 *')!;
      expect(
        s.nextAfter(DateTime.utc(2026, 7, 1, 0, 0)),
        DateTime.utc(2027, 6, 1, 0, 0),
      );
    });

    test('respects the DOM/DOW union rule when advancing', () {
      // Fire at 00:00 on the 1st OR any Monday.
      final s = CronSchedule.tryParse('0 0 1 * 1')!;
      // From 2026-07-02 (Thursday), the next match is the next Monday
      // (2026-07-06) since no 1st-of-month comes sooner.
      expect(
        s.nextAfter(DateTime.utc(2026, 7, 2, 0, 0)),
        DateTime.utc(2026, 7, 6, 0, 0),
      );
      // From the last day before a new month, the 1st wins the union.
      expect(
        s.nextAfter(DateTime.utc(2026, 7, 31, 0, 0)),
        DateTime.utc(2026, 8, 1, 0, 0),
      );
    });

    test('honours the local (non-UTC) zone of the seed DateTime', () {
      final s = CronSchedule.tryParse('30 14 * * *')!;
      final next = s.nextAfter(DateTime(2026, 7, 13, 9, 5));
      expect(next, DateTime(2026, 7, 13, 14, 30));
      expect(next!.isUtc, isFalse);
    });

    test('returns null for an unsatisfiable expression within the cap', () {
      // Feb 30 never exists.
      final s = CronSchedule.tryParse('0 0 30 2 *')!;
      expect(
        s.nextAfter(DateTime.utc(2026, 1, 1, 0, 0), maxIterations: 100),
        isNull,
      );
    });
  });
}
