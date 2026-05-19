import 'dart:async';

import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/cron_execution_ledger.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_cron_scheduler.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:uuid/uuid.dart';

/// Drives time-based pipeline triggers: on each tick it asks the
/// [PipelineCronScheduler] which scheduled triggers are due, claims an
/// idempotency slot, starts the run and persists the trigger's next fire time.
///
/// The fire path is idempotent at two levels: the [CronExecutionLedger] claim
/// (one row per `(trigger, plannedAt)` slot) and the engine's own `dedupKey`
/// check — so a missed/duplicated tick, or a restart mid-slot, never
/// double-starts a run. Missed slots collapse into a single fire
/// (CatchUpLatestOnly) because the scheduler advances `nextRunAt` past `now`.
class PipelineSchedulerService {
  /// Creates a [PipelineSchedulerService].
  PipelineSchedulerService({
    required PipelineTriggerRepository triggerRepository,
    required PipelineEngine engine,
    required CronExecutionLedger ledger,
    PipelineCronScheduler? scheduler,
    String Function()? idGenerator,
    Duration tickInterval = const Duration(seconds: 60),
  }) : _triggers = triggerRepository,
       _engine = engine,
       _ledger = ledger,
       _scheduler = scheduler ?? PipelineCronScheduler(),
       _idGenerator = idGenerator ?? (() => const Uuid().v4()),
       _tickInterval = tickInterval;

  final PipelineTriggerRepository _triggers;
  final PipelineEngine _engine;
  final CronExecutionLedger _ledger;
  final PipelineCronScheduler _scheduler;
  final String Function() _idGenerator;
  final Duration _tickInterval;

  Timer? _timer;

  /// Begins ticking on a fixed interval. Idempotent.
  void start() {
    _timer ??= Timer.periodic(_tickInterval, (_) {
      unawaited(tick(DateTime.now().toUtc()));
    });
  }

  /// Stops ticking.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// Evaluates every scheduled trigger against [nowUtc], firing the due ones.
  /// Exposed for tests (call directly instead of waiting on the timer).
  Future<void> tick(DateTime nowUtc) async {
    final List<PipelineTrigger> triggers;
    try {
      triggers = await _triggers.scheduled();
    } on Object catch (e, st) {
      CcDomainLog.error(
        'PipelineScheduler: failed to load scheduled triggers',
        e,
        st,
      );
      return;
    }
    for (final trigger in triggers) {
      try {
        await _evaluate(trigger, nowUtc);
      } on Object catch (e, st) {
        CcDomainLog.error(
          'PipelineScheduler: tick failed for trigger ${trigger.id}',
          e,
          st,
        );
      }
    }
  }

  Future<void> _evaluate(PipelineTrigger trigger, DateTime nowUtc) async {
    final eval = _scheduler.evaluate(trigger, nowUtc);
    if (!eval.shouldFire) {
      if (eval.nextRunAt != null && eval.nextRunAt != trigger.nextRunAt) {
        await _triggers.setSchedule(
          trigger.workspaceId,
          trigger.id,
          nextRunAt: eval.nextRunAt,
        );
      }
      return;
    }
    final plannedAt = (eval.plannedAt ?? nowUtc).toUtc();
    final claimed = await _ledger.claimSlot(
      id: _idGenerator(),
      workspaceId: trigger.workspaceId,
      triggerId: trigger.id,
      plannedAt: plannedAt,
    );
    if (claimed) {
      await _engine.start(
        trigger.templateId,
        workspaceId: trigger.workspaceId,
        triggerEventType: PipelineTrigger.scheduleEventType,
        triggerPayload: {
          'workspaceId': trigger.workspaceId,
          'triggerId': trigger.id,
          'plannedAt': plannedAt.toIso8601String(),
        },
        dedupKey: '${trigger.id}:${plannedAt.toIso8601String()}',
      );
      CcDomainLog.info(
        'PipelineScheduler: fired ${trigger.templateId} for slot '
        '${plannedAt.toIso8601String()} (workspace ${trigger.workspaceId}).',
      );
    }
    await _triggers.setSchedule(
      trigger.workspaceId,
      trigger.id,
      nextRunAt: eval.nextRunAt,
      lastFiredAt: nowUtc,
    );
  }
}
