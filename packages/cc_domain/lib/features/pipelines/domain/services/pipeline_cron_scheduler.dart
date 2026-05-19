import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';

/// Converts a UTC instant to/from a named timezone's wall-clock. Injected so
/// the scheduler stays pure-Dart; the default identity converter treats every
/// schedule as UTC.
typedef ZoneConverter = DateTime Function(DateTime input, String timezone);

DateTime _identity(DateTime input, String timezone) => input;

/// The outcome of evaluating one scheduled trigger against a clock tick.
class CronEvaluation {
  /// Creates a [CronEvaluation].
  const CronEvaluation({
    required this.shouldFire,
    this.plannedAt,
    this.nextRunAt,
  });

  /// Nothing to do this tick (not due, or not a scheduled trigger).
  const CronEvaluation.idle({this.nextRunAt})
    : shouldFire = false,
      plannedAt = null;

  /// Whether the trigger is due and should fire now.
  final bool shouldFire;

  /// The scheduled slot this fire is *for* (UTC) — used as the idempotency key
  /// (`cron_executions(trigger_id, planned_at)`). Set only when [shouldFire].
  final DateTime? plannedAt;

  /// The next slot the trigger should fire (UTC), to persist as
  /// `PipelineTrigger.nextRunAt`. `null` when no future fire is computable.
  final DateTime? nextRunAt;
}

/// Decides which scheduled pipeline triggers are due and computes their next
/// fire time, collapsing any missed fires into a single one
/// (**CatchUpLatestOnly**).
///
/// Handles both schedule forms:
/// * `every:<seconds>` interval triggers (driven by `lastFiredAt`).
/// * standard cron triggers (driven by `nextRunAt`, evaluated in the trigger's
///   timezone via the injected [ZoneConverter]s).
class PipelineCronScheduler {
  /// Creates a [PipelineCronScheduler]. Without converters every schedule is
  /// evaluated in UTC.
  PipelineCronScheduler({ZoneConverter? toLocal, ZoneConverter? toUtc})
    : _toLocal = toLocal ?? _identity,
      _toUtc = toUtc ?? _identity;

  final ZoneConverter _toLocal;
  final ZoneConverter _toUtc;

  /// Evaluates [trigger] against [nowUtc].
  CronEvaluation evaluate(PipelineTrigger trigger, DateTime nowUtc) {
    final now = nowUtc.toUtc();
    final interval = trigger.intervalSeconds;
    if (interval != null) {
      return _evaluateInterval(trigger, now, interval);
    }
    if (trigger.cronSchedule != null) {
      return _evaluateCron(trigger, now);
    }
    return const CronEvaluation.idle();
  }

  CronEvaluation _evaluateInterval(
    PipelineTrigger trigger,
    DateTime now,
    int intervalSeconds,
  ) {
    final period = Duration(seconds: intervalSeconds);
    final last = trigger.lastFiredAt?.toUtc();
    final next = last == null ? now : last.add(period);
    if (last == null || !now.isBefore(next)) {
      // We've fallen a whole extra period behind (≥ 2 periods since the last
      // fire) only after downtime. Under the skip policy, don't run late —
      // resume at the next future slot.
      final caughtUp = last != null && now.isAfter(last.add(period * 2));
      if (caughtUp && trigger.catchUpPolicy == CronCatchUpPolicy.skip) {
        return CronEvaluation.idle(nextRunAt: now.add(period));
      }
      return CronEvaluation(
        shouldFire: true,
        plannedAt: now,
        nextRunAt: now.add(period),
      );
    }
    return CronEvaluation.idle(nextRunAt: next);
  }

  CronEvaluation _evaluateCron(PipelineTrigger trigger, DateTime now) {
    final existing = trigger.nextRunAt?.toUtc();
    if (existing == null) {
      // First evaluation — schedule the next slot, don't fire retroactively.
      return CronEvaluation.idle(nextRunAt: _nextRunAt(trigger, now));
    }
    if (existing.isAfter(now)) {
      return CronEvaluation.idle(nextRunAt: existing);
    }
    // Due. If a whole slot elapsed since `existing` (the slot immediately after
    // it is ALSO already past), we're catching up after downtime rather than
    // firing on time. Under the skip policy, drop the missed run(s) and resume
    // at the next future slot; otherwise (catchUpLatestOnly) fire once.
    final slotAfterExisting = _nextRunAt(trigger, existing);
    final caughtUp =
        slotAfterExisting != null && !slotAfterExisting.isAfter(now);
    if (caughtUp && trigger.catchUpPolicy == CronCatchUpPolicy.skip) {
      return CronEvaluation.idle(nextRunAt: _nextRunAt(trigger, now));
    }
    return CronEvaluation(
      shouldFire: true,
      plannedAt: existing,
      nextRunAt: _nextRunAt(trigger, now),
    );
  }

  /// The next cron fire (UTC) strictly after [fromUtc], honouring the trigger's
  /// timezone, or `null` if the expression is unsatisfiable.
  DateTime? _nextRunAt(PipelineTrigger trigger, DateTime fromUtc) {
    final schedule = trigger.cronSchedule;
    if (schedule == null) {
      return null;
    }
    final tz = (trigger.timezone == null || trigger.timezone!.isEmpty)
        ? 'UTC'
        : trigger.timezone!;
    final localFrom = _toLocal(fromUtc, tz);
    final localNext = schedule.nextAfter(localFrom);
    if (localNext == null) {
      return null;
    }
    return _toUtc(localNext, tz).toUtc();
  }
}
