import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_cron_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

PipelineTrigger _trigger({
  String cron = '0 9 * * 1',
  DateTime? nextRunAt,
  DateTime? lastFiredAt,
  CronCatchUpPolicy catchUpPolicy = CronCatchUpPolicy.catchUpLatestOnly,
}) => PipelineTrigger(
  id: 't1',
  eventType: PipelineTrigger.scheduleEventType,
  templateId: 'daily_standup',
  workspaceId: 'ws1',
  enabled: true,
  cronExpression: cron,
  nextRunAt: nextRunAt,
  lastFiredAt: lastFiredAt,
  catchUpPolicy: catchUpPolicy,
);

void main() {
  final scheduler = PipelineCronScheduler(); // UTC (identity converters)

  group('cron triggers', () {
    test('first evaluation schedules nextRunAt without firing', () {
      final eval = scheduler.evaluate(
        _trigger(),
        DateTime.utc(2026, 6, 30, 12),
      );
      expect(eval.shouldFire, isFalse);
      expect(eval.nextRunAt, isNotNull);
      // The next Monday 09:00 after the tick.
      expect(eval.nextRunAt, DateTime.utc(2026, 7, 6, 9));
    });

    test('does not fire while nextRunAt is in the future', () {
      final future = DateTime.utc(2026, 7, 6, 9);
      final eval = scheduler.evaluate(
        _trigger(nextRunAt: future),
        DateTime.utc(2026, 6, 30, 12),
      );
      expect(eval.shouldFire, isFalse);
      expect(eval.nextRunAt, future);
    });

    test('CatchUpLatestOnly: collapses missed slots into one fire', () {
      // nextRunAt points at a Monday two weeks before "now"; two Mondays
      // (June 22 + June 29) have been missed. One evaluate → exactly one fire,
      // and nextRunAt jumps past now to the next future Monday.
      final eval = scheduler.evaluate(
        _trigger(nextRunAt: DateTime.utc(2026, 6, 22, 9)),
        DateTime.utc(2026, 6, 30, 12),
      );
      expect(eval.shouldFire, isTrue);
      expect(eval.plannedAt, DateTime.utc(2026, 6, 22, 9));
      // Collapsed: the next fire is the upcoming Monday, not June 29.
      expect(eval.nextRunAt, DateTime.utc(2026, 7, 6, 9));
    });

    test('skip policy: missed slots do NOT fire, resume at next slot', () {
      // Same missed-slots setup as above, but with skip → no fire and
      // nextRunAt still jumps forward to the next future Monday.
      final eval = scheduler.evaluate(
        _trigger(
          nextRunAt: DateTime.utc(2026, 6, 22, 9),
          catchUpPolicy: CronCatchUpPolicy.skip,
        ),
        DateTime.utc(2026, 6, 30, 12),
      );
      expect(eval.shouldFire, isFalse);
      expect(eval.nextRunAt, DateTime.utc(2026, 7, 6, 9));
    });

    test('skip policy still fires an on-time slot (no whole slot missed)', () {
      // nextRunAt is this Monday 09:00 and "now" is minutes later; the next
      // Monday is still in the future, so this is a normal on-time fire — skip
      // must not suppress it.
      final eval = scheduler.evaluate(
        _trigger(
          nextRunAt: DateTime.utc(2026, 7, 6, 9),
          catchUpPolicy: CronCatchUpPolicy.skip,
        ),
        DateTime.utc(2026, 7, 6, 9, 5),
      );
      expect(eval.shouldFire, isTrue);
      expect(eval.plannedAt, DateTime.utc(2026, 7, 6, 9));
    });
  });

  group('interval triggers (every:<seconds>)', () {
    test('fires immediately when never fired', () {
      final eval = scheduler.evaluate(
        _trigger(cron: 'every:3600'),
        DateTime.utc(2026, 6, 30, 12),
      );
      expect(eval.shouldFire, isTrue);
    });

    test('does not fire before the interval elapses', () {
      final now = DateTime.utc(2026, 6, 30, 12);
      final eval = scheduler.evaluate(
        _trigger(
          cron: 'every:3600',
          lastFiredAt: now.subtract(const Duration(seconds: 100)),
        ),
        now,
      );
      expect(eval.shouldFire, isFalse);
    });

    test('fires once the interval has elapsed', () {
      final now = DateTime.utc(2026, 6, 30, 12);
      final eval = scheduler.evaluate(
        _trigger(
          cron: 'every:3600',
          lastFiredAt: now.subtract(const Duration(seconds: 4000)),
        ),
        now,
      );
      expect(eval.shouldFire, isTrue);
    });

    test('skip policy: does not fire when >1 interval was missed', () {
      // Last fired ~3 periods ago (10800s > 2×3600): downtime caught up.
      final now = DateTime.utc(2026, 6, 30, 12);
      final eval = scheduler.evaluate(
        _trigger(
          cron: 'every:3600',
          lastFiredAt: now.subtract(const Duration(seconds: 10800)),
          catchUpPolicy: CronCatchUpPolicy.skip,
        ),
        now,
      );
      expect(eval.shouldFire, isFalse);
      expect(eval.nextRunAt, now.add(const Duration(seconds: 3600)));
    });

    test('skip policy still fires a single elapsed interval (on time)', () {
      // Just over one period late (< 2 periods) → a normal fire, not a catch-up.
      final now = DateTime.utc(2026, 6, 30, 12);
      final eval = scheduler.evaluate(
        _trigger(
          cron: 'every:3600',
          lastFiredAt: now.subtract(const Duration(seconds: 3700)),
          catchUpPolicy: CronCatchUpPolicy.skip,
        ),
        now,
      );
      expect(eval.shouldFire, isTrue);
    });
  });

  test('non-scheduled trigger is idle', () {
    final eval = scheduler.evaluate(
      PipelineTrigger(
        id: 't2',
        eventType: 'TicketAssigned',
        templateId: 'x',
        workspaceId: 'ws1',
        enabled: true,
      ),
      DateTime.utc(2026, 6, 30, 12),
    );
    expect(eval.shouldFire, isFalse);
  });
}
