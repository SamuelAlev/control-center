import 'package:cc_domain/features/pipelines/domain/services/cron_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CronSchedule.tryParse', () {
    test('rejects expressions without exactly 5 fields', () {
      expect(CronSchedule.tryParse('* * * *'), isNull);
      expect(CronSchedule.tryParse('0 9 * * 1 7'), isNull);
      expect(CronSchedule.tryParse(''), isNull);
    });

    test('rejects out-of-range and malformed fields', () {
      expect(CronSchedule.tryParse('60 * * * *'), isNull); // minute > 59
      expect(CronSchedule.tryParse('* 24 * * *'), isNull); // hour > 23
      expect(CronSchedule.tryParse('* * 0 * *'), isNull); // dom < 1
      expect(CronSchedule.tryParse('* * * 13 *'), isNull); // month > 12
      expect(CronSchedule.tryParse('*/0 * * * *'), isNull); // step 0
      expect(CronSchedule.tryParse('5-1 * * * *'), isNull); // lo > hi
    });

    test('parses ranges, steps, and lists', () {
      final s = CronSchedule.tryParse('0,30 9-17/4 * * *')!;
      expect(s.minutes, {0, 30});
      expect(s.hours, {9, 13, 17});
    });

    test('normalises Sunday 7 to 0', () {
      final s = CronSchedule.tryParse('0 0 * * 7')!;
      expect(s.daysOfWeek, contains(0));
    });
  });

  group('CronSchedule.nextAfter — every Monday at 09:00', () {
    final schedule = CronSchedule.tryParse('0 9 * * 1')!;

    test('from earlier the same Monday → that Monday 09:00', () {
      // 2026-06-29 is a Monday.
      final next = schedule.nextAfter(DateTime.utc(2026, 6, 29, 8));
      expect(next, DateTime.utc(2026, 6, 29, 9));
      expect(next!.weekday, DateTime.monday);
    });

    test('from after 09:00 Monday → the following Monday 09:00', () {
      final next = schedule.nextAfter(DateTime.utc(2026, 6, 29, 10));
      expect(next, DateTime.utc(2026, 7, 6, 9));
      expect(next!.weekday, DateTime.monday);
    });

    test('is strictly after the input even when the input matches', () {
      final next = schedule.nextAfter(DateTime.utc(2026, 6, 29, 9));
      expect(next, DateTime.utc(2026, 7, 6, 9));
    });
  });

  group('CronSchedule day-of-month / day-of-week union', () {
    test('both restricted → fires when EITHER matches', () {
      // 15th of the month OR any Friday.
      final s = CronSchedule.tryParse('0 0 15 * 5')!;
      expect(s.matches(DateTime.utc(2026, 6, 15)), isTrue); // the 15th
      // 2026-06-19 is a Friday.
      expect(s.matches(DateTime.utc(2026, 6, 19)), isTrue); // a Friday
      expect(s.matches(DateTime.utc(2026, 6, 16)), isFalse); // neither
    });

    test('only DOM restricted → only the day-of-month constrains', () {
      final s = CronSchedule.tryParse('0 0 1 * *')!;
      expect(s.matches(DateTime.utc(2026, 7, 1)), isTrue);
      expect(s.matches(DateTime.utc(2026, 7, 2)), isFalse);
    });
  });

  group('CronSchedule.nextAfter — interval / wildcard', () {
    test('every minute advances by one minute', () {
      final s = CronSchedule.tryParse('* * * * *')!;
      expect(
        s.nextAfter(DateTime.utc(2026, 1, 1, 0, 0)),
        DateTime.utc(2026, 1, 1, 0, 1),
      );
    });

    test('rolls across a month boundary', () {
      final s = CronSchedule.tryParse('0 0 1 * *')!;
      expect(s.nextAfter(DateTime.utc(2026, 1, 15)), DateTime.utc(2026, 2, 1));
    });
  });
}
