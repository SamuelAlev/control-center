import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/cron_execution_ledger.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_scheduler_service.dart';
import 'package:test/test.dart';

/// Holds one trigger and applies `setSchedule` the way the DAO does: a null
/// argument leaves that column alone.
class _Triggers implements PipelineTriggerRepository {
  _Triggers(this.trigger);

  PipelineTrigger trigger;

  @override
  Future<List<PipelineTrigger>> scheduled() async => [trigger];

  @override
  Future<void> setSchedule(
    String workspaceId,
    String id, {
    DateTime? nextRunAt,
    DateTime? lastFiredAt,
  }) async {
    trigger = trigger.copyWith(nextRunAt: nextRunAt, lastFiredAt: lastFiredAt);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Ledger implements CronExecutionLedger {
  final Set<String> slots = {};

  String _key(String triggerId, DateTime plannedAt) =>
      '$triggerId:${plannedAt.toUtc().toIso8601String()}';

  @override
  Future<bool> claimSlot({
    required String id,
    required String workspaceId,
    required String triggerId,
    required DateTime plannedAt,
  }) async => slots.add(_key(triggerId, plannedAt));

  @override
  Future<void> releaseSlot({
    required String workspaceId,
    required String triggerId,
    required DateTime plannedAt,
  }) async {
    slots.remove(_key(triggerId, plannedAt));
  }
}

/// Records each started run's dedup key; throws while [failures] is positive.
class _Engine implements PipelineEngine {
  final List<String> started = [];
  int failures = 0;
  bool templateDeleted = false;
  int attempts = 0;

  @override
  Future<PipelineRun?> start(
    String templateId, {
    required String workspaceId,
    String? triggerEventType,
    Map<String, dynamic>? triggerPayload,
    String? dedupKey,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
  }) async {
    attempts++;
    if (templateDeleted) {
      throw PipelineTemplateNotFoundError('template deleted');
    }
    if (failures > 0) {
      failures--;
      throw StateError('database is locked');
    }
    started.add(dedupKey!);
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PipelineTrigger _trigger({
  required String schedule,
  DateTime? nextRunAt,
  DateTime? lastFiredAt,
  CronCatchUpPolicy catchUpPolicy = CronCatchUpPolicy.catchUpLatestOnly,
}) => PipelineTrigger(
  id: 't1',
  eventType: PipelineTrigger.scheduleEventType,
  templateId: 'workspace_backup',
  workspaceId: 'ws1',
  enabled: true,
  cronExpression: schedule,
  nextRunAt: nextRunAt,
  lastFiredAt: lastFiredAt,
  catchUpPolicy: catchUpPolicy,
  createdAt: DateTime.utc(2026, 9, 27),
);

void main() {
  late _Ledger ledger;
  late _Engine engine;

  PipelineSchedulerService service(_Triggers triggers) =>
      PipelineSchedulerService(
        triggerRepository: triggers,
        engine: engine,
        ledger: ledger,
        idGenerator: () => 'id',
      );

  setUp(() {
    ledger = _Ledger();
    engine = _Engine();
  });

  // 2026-10-25 and 2026-11-01 are Sundays.
  final sundaySlot = DateTime.utc(2026, 10, 25, 3);
  final mondayBoot = DateTime.utc(2026, 10, 26, 12);
  final nextSundaySlot = DateTime.utc(2026, 11, 1, 3);

  test(
    'a slot missed while the server was off fires at the next boot',
    () async {
      final triggers = _Triggers(
        _trigger(schedule: '0 3 * * 0', nextRunAt: sundaySlot),
      );
      final scheduler = service(triggers);

      await scheduler.tick(mondayBoot);
      await scheduler.tick(mondayBoot.add(const Duration(minutes: 1)));

      expect(engine.started, ['t1:${sundaySlot.toIso8601String()}']);
      expect(triggers.trigger.nextRunAt, nextSundaySlot);
    },
  );

  test('several missed slots collapse into one fire', () async {
    final triggers = _Triggers(
      _trigger(
        schedule: '0 3 * * 0',
        nextRunAt: sundaySlot.subtract(const Duration(days: 14)),
      ),
    );
    final scheduler = service(triggers);

    await scheduler.tick(mondayBoot);
    await scheduler.tick(mondayBoot.add(const Duration(minutes: 1)));

    expect(engine.started, hasLength(1));
    expect(triggers.trigger.nextRunAt, nextSundaySlot);
  });

  test('a run that fails to start is retried on the next tick', () async {
    engine.failures = 1;
    final triggers = _Triggers(
      _trigger(schedule: '0 3 * * 0', nextRunAt: sundaySlot),
    );
    final scheduler = service(triggers);

    await scheduler.tick(mondayBoot);
    expect(engine.started, isEmpty);
    expect(triggers.trigger.nextRunAt, sundaySlot);

    await scheduler.tick(mondayBoot.add(const Duration(minutes: 1)));
    await scheduler.tick(mondayBoot.add(const Duration(minutes: 2)));

    expect(engine.started, ['t1:${sundaySlot.toIso8601String()}']);
    expect(triggers.trigger.nextRunAt, nextSundaySlot);
  });

  test('a trigger left behind by a deleted template is not retried', () async {
    engine.templateDeleted = true;
    final triggers = _Triggers(
      _trigger(schedule: '0 3 * * 0', nextRunAt: sundaySlot),
    );
    final scheduler = service(triggers);

    await scheduler.tick(mondayBoot);
    await scheduler.tick(mondayBoot.add(const Duration(minutes: 1)));
    await scheduler.tick(mondayBoot.add(const Duration(minutes: 2)));

    expect(engine.attempts, 1);
    expect(triggers.trigger.nextRunAt, nextSundaySlot);
  });

  test('a skipped interval trigger resumes one period later', () async {
    const period = Duration(hours: 1);
    final lastFired = mondayBoot.subtract(const Duration(days: 3));
    final triggers = _Triggers(
      _trigger(
        schedule: 'every:3600',
        lastFiredAt: lastFired,
        nextRunAt: lastFired.add(period),
        catchUpPolicy: CronCatchUpPolicy.skip,
      ),
    );
    final scheduler = service(triggers);

    await scheduler.tick(mondayBoot);
    expect(engine.started, isEmpty, reason: 'skip drops the missed run');

    for (var minute = 1; minute < 60; minute++) {
      await scheduler.tick(mondayBoot.add(Duration(minutes: minute)));
    }
    expect(engine.started, isEmpty, reason: 'not due before the resume slot');

    await scheduler.tick(mondayBoot.add(period));
    expect(engine.started, hasLength(1));
  });
}
