/// A schedule's trigger in words, and a cron schedule's next fire times.
library;

import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_ui/cc_ui.dart' show CcStatusTone;
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// [rule]'s trigger read back from its `when` text, or null for one this
/// version cannot read (shown as the raw text).
WakeTrigger? ruleTrigger(WakeRuleView rule) {
  // A stored `at:` may be in the past; read it against an early clock so
  // the "must be ahead" check of a new rule does not reject it.
  final reading = parseWakeWhen(
    rule.trigger,
    now: DateTime.utc(2000),
    timeZone: rule.timeZone,
  );
  return switch (reading) {
    WakeWhenTrigger(:final trigger) => trigger,
    WakeWhenNext() => const SelfPaced(),
    _ => null,
  };
}

/// What fires [rule], in one sentence; null when its trigger is unreadable.
String? scheduleTriggerSentence(BuildContext context, WakeRuleView rule) {
  final l10n = AppLocalizations.of(context);
  return switch (ruleTrigger(rule)) {
    OnceAt(:final at) => l10n.scheduleTriggerOnce(workTimeLabel(context, at)),
    Every(:final interval) => l10n.scheduleTriggerEvery(
      workDurationLabel(interval),
    ),
    Cron(:final expression, :final timeZone) => l10n.scheduleTriggerCron(
      expression,
      timeZone,
    ),
    SelfPaced() => l10n.scheduleTriggerSelfPaced,
    OnEvent(:final eventKind, :final targetId) => switch (eventKind) {
      WakeEventKind.prChecks when targetId != null =>
        l10n.scheduleTriggerPrChecksOf(targetId),
      WakeEventKind.prChecks => l10n.scheduleTriggerPrChecks,
      WakeEventKind.prReview when targetId != null =>
        l10n.scheduleTriggerPrReviewOf(targetId),
      WakeEventKind.prReview => l10n.scheduleTriggerPrReview,
      WakeEventKind.prMerged when targetId != null =>
        l10n.scheduleTriggerPrMergedOf(targetId),
      WakeEventKind.prMerged => l10n.scheduleTriggerPrMerged,
      WakeEventKind.environment => l10n.scheduleTriggerEnvironment,
      WakeEventKind.ticket => l10n.scheduleTriggerTicket(targetId ?? ''),
      WakeEventKind.pipelineRun => l10n.scheduleTriggerPipelineRun(
        targetId ?? '',
      ),
    },
    null => null,
  };
}

/// Whether [rule] is a watch (fires on an event, not on a clock).
bool isWatchRule(WakeRuleView rule) => ruleTrigger(rule) is OnEvent;

/// The fire times the server sent for [rule] (`next_fires`: a cron rule's
/// next slots, computed with the server's zone rules) that are still ahead
/// of [nowUtc].
List<DateTime> upcomingFires(WakeRuleView rule, DateTime nowUtc) => [
  for (final f in rule.nextFires)
    if (f.isAfter(nowUtc)) f,
];

/// The longest a person may extend [rule] to, counted from its creation:
/// a person's rule lives up to a year, an agent's up to 30 days.
Duration ruleMaxLife(WakeRuleView rule) => rule.origin == WakeRuleOrigin.person
    ? WakeRuleBounds.personMaxExpiry
    : WakeRuleBounds.agentMaxExpiry;

/// A schedule's status, as a tag label.
String scheduleStatusLabel(AppLocalizations l10n, WakeRuleStatus status) =>
    switch (status) {
      WakeRuleStatus.active => l10n.scheduleStatusActive,
      WakeRuleStatus.paused => l10n.scheduleStatusPaused,
      WakeRuleStatus.ended => l10n.scheduleStatusEnded,
    };

/// A schedule's status, as a tag tone.
CcStatusTone scheduleStatusTone(WakeRuleStatus status) => switch (status) {
  WakeRuleStatus.active => CcStatusTone.positive,
  WakeRuleStatus.paused => CcStatusTone.caution,
  WakeRuleStatus.ended => CcStatusTone.neutral,
};

/// What a fire does while the agent is busy, in words.
String scheduleWhenBusyLabel(AppLocalizations l10n, WakeWhenBusy whenBusy) =>
    switch (whenBusy) {
      WakeWhenBusy.skip => l10n.scheduleWhenBusySkip,
      WakeWhenBusy.queue => l10n.scheduleWhenBusyQueue,
    };

/// What a fire delivers, in words.
String scheduleDeliverLabel(AppLocalizations l10n, WakeDeliver deliver) =>
    switch (deliver) {
      WakeDeliver.run => l10n.scheduleDeliverRun,
      WakeDeliver.notify => l10n.scheduleDeliverNotify,
    };

/// Whether [zone] has the shape of an IANA zone name (`UTC`,
/// `Europe/Berlin`, `America/Argentina/Salta`; empty means the workspace's
/// zone and is accepted). A shape check only: the client carries no zone
/// database, and whether the server knows the zone is its answer to
/// `wakeRules.previewCron` (`zoneKnown`, `cronPreviewProvider`).
bool looksLikeZoneName(String zone) {
  final z = zone.trim();
  return z.isEmpty || (z.length <= 64 && _zoneShape.hasMatch(z));
}

final _zoneShape = RegExp(r'^[A-Za-z][A-Za-z0-9_+\-]*(/[A-Za-z0-9_+\-]+)*$');

/// What a schedule's wake was for (`reason` from `wakeRules.listRuns`); an
/// unknown reason shows as itself.
String scheduleWakeReasonLabel(AppLocalizations l10n, String reason) =>
    switch (reason) {
      'schedule' => l10n.scheduleWakeReasonSchedule,
      'watch' => l10n.scheduleWakeReasonWatch,
      'limit_reset' => l10n.scheduleWakeReasonLimitReset,
      _ => reason,
    };

/// How a schedule's wake stands (`state` from `wakeRules.listRuns`), or null
/// for a state this version does not name.
String? scheduleWakeStateLabel(AppLocalizations l10n, String state) =>
    switch (state) {
      'pending' => l10n.scheduleWakeStatePending,
      'held' => l10n.scheduleWakeStateHeld,
      'claimed' => l10n.scheduleWakeStateClaimed,
      'delivered' => l10n.scheduleWakeStateDelivered,
      'skipped' => l10n.scheduleWakeStateSkipped,
      'expired' => l10n.scheduleWakeStateExpired,
      'cancelled' => l10n.scheduleWakeStateCancelled,
      _ => null,
    };

/// A wake's run status (`run.status`: `pending`, `running`, `completed`,
/// `error`); an unknown status shows as itself.
String scheduleRunStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'pending' => l10n.scheduleRunPending,
      'running' => l10n.scheduleRunRunning,
      'completed' => l10n.scheduleRunCompleted,
      'error' => l10n.scheduleRunFailed,
      _ => status,
    };
