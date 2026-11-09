import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_cron_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

PipelineTrigger _trigger({
  String cron = '0 9 * * 1',
  DateTime? nextRunAt,
  DateTime? lastFiredAt,
  CronCatchUpPolicy catchUpPolicy = CronCatchUpPolicy.catchUpLatestOnly,
  DateTime? createdAt,
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
  createdAt: createdAt ?? DateTime.utc(2026, 6, 30, 12),
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
    test('restarts after first missed weekly slot and catches up once', () {
      final now = DateTime.utc(2026, 7, 21, 12);
      final first = scheduler.evaluate(
        _trigger(createdAt: DateTime.utc(2026, 6, 30, 12)),
        now,
      );
      expect(first.shouldFire, isTrue);
      expect(first.plannedAt, DateTime.utc(2026, 7, 6, 9));
      expect(first.nextRunAt, DateTime.utc(2026, 7, 27, 9));

      final afterFire = scheduler.evaluate(
        _trigger(
          createdAt: DateTime.utc(2026, 6, 30, 12),
          nextRunAt: first.nextRunAt,
          lastFiredAt: now,
        ),
        now,
      );
      expect(afterFire.shouldFire, isFalse);
    });

    test('skip policy suppresses missed first slots without nextRunAt', () {
      final eval = scheduler.evaluate(
        _trigger(
          createdAt: DateTime.utc(2026, 6, 30, 12),
          catchUpPolicy: CronCatchUpPolicy.skip,
        ),
        DateTime.utc(2026, 7, 21, 12),
      );
      expect(eval.shouldFire, isFalse);
      expect(eval.nextRunAt, DateTime.utc(2026, 7, 27, 9));
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

    test('does not fire again within the same slot', () {
      final now = DateTime.utc(2026, 6, 30, 12, 30);
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

    test('skip policy holds a skipped interval until its resume slot', () {
      final now = DateTime.utc(2026, 6, 30, 12);
      final resume = now.add(const Duration(seconds: 1800));
      final eval = scheduler.evaluate(
        _trigger(
          cron: 'every:3600',
          lastFiredAt: now.subtract(const Duration(seconds: 10800)),
          nextRunAt: resume,
          catchUpPolicy: CronCatchUpPolicy.skip,
        ),
        now,
      );
      expect(eval.shouldFire, isFalse);
      expect(eval.nextRunAt, resume);
    });

    test('skip policy fires a skipped interval at its resume slot', () {
      final now = DateTime.utc(2026, 6, 30, 12);
      final eval = scheduler.evaluate(
        _trigger(
          cron: 'every:3600',
          lastFiredAt: now.subtract(const Duration(seconds: 10800)),
          nextRunAt: now.subtract(const Duration(seconds: 30)),
          catchUpPolicy: CronCatchUpPolicy.skip,
        ),
        now,
      );
      expect(eval.shouldFire, isTrue);
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

    test('two ticks in one slot plan the same epoch-aligned slot', () {
      // The slot start is the `cron_executions` idempotency key, so ticks at
      // different moments of the same slot must agree on it (audit: stable
      // ledger slots for every:).
      final a = scheduler.evaluate(
        _trigger(cron: 'every:3600'),
        DateTime.utc(2026, 6, 30, 12, 0, 5),
      );
      final b = scheduler.evaluate(
        _trigger(cron: 'every:3600'),
        DateTime.utc(2026, 6, 30, 12, 59, 59),
      );
      expect(a.shouldFire, isTrue);
      expect(b.shouldFire, isTrue);
      expect(a.plannedAt, DateTime.utc(2026, 6, 30, 12));
      expect(b.plannedAt, a.plannedAt);
      expect(a.nextRunAt, DateTime.utc(2026, 6, 30, 13));
    });

    test('a failed setSchedule re-fire claims the same slot', () {
      // The run started but lastFiredAt was never written: the next tick
      // re-evaluates as never-fired and must name the same slot so the ledger
      // dedupes it.
      final first = scheduler.evaluate(
        _trigger(cron: 'every:600'),
        DateTime.utc(2026, 6, 30, 12, 1),
      );
      final retry = scheduler.evaluate(
        _trigger(cron: 'every:600'),
        DateTime.utc(2026, 6, 30, 12, 2),
      );
      expect(retry.plannedAt, first.plannedAt);
    });

    test('fires once per slot after crossing a boundary', () {
      final eval = scheduler.evaluate(
        _trigger(
          cron: 'every:3600',
          lastFiredAt: DateTime.utc(2026, 6, 30, 11, 59, 50),
        ),
        DateTime.utc(2026, 6, 30, 12, 0, 10),
      );
      expect(eval.shouldFire, isTrue);
      expect(eval.plannedAt, DateTime.utc(2026, 6, 30, 12));
    });

    test('a non-positive interval never fires', () {
      for (final cron in ['every:0', 'every:-5']) {
        final eval = scheduler.evaluate(
          _trigger(cron: cron),
          DateTime.utc(2026, 6, 30, 12),
        );
        expect(eval.shouldFire, isFalse, reason: cron);
      }
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
