import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// Human-readable, localized display name for a trigger [eventType] (a domain
/// event type name, or the synthetic `manual` / `schedule` types). Falls back
/// to the raw type for events without a dedicated label.
String triggerEventLabel(AppLocalizations l10n, String eventType) {
  return switch (eventType) {
    PipelineTrigger.manualEventType => l10n.triggerEventManual,
    PipelineTrigger.scheduleEventType => l10n.triggerEventSchedule,
    'PullRequestStatusChanged' => l10n.triggerEventPrStatusChanged,
    'ExternalPrDetected' => l10n.triggerEventExternalPr,
    'PullRequestPublished' => l10n.triggerEventPrPublished,
    'PrMerged' => l10n.triggerEventPrMerged,
    'RepoAdded' => l10n.triggerEventRepoAdded,
    'MessageReceived' => l10n.triggerEventMessageReceived,
    'TicketCompleted' => l10n.triggerEventTicketCompleted,
    'TicketFailed' => l10n.triggerEventTicketFailed,
    'TicketCancelled' => l10n.triggerEventTicketCancelled,
    'BudgetThresholdCrossed' => l10n.triggerEventBudgetCrossed,
    'TicketAssigned' => l10n.triggerEventTicketAssigned,
    _ => eventType,
  };
}

/// A one-line description of a trigger, including its schedule interval or
/// payload match filter (e.g. "PR status changed · merged, closed").
String triggerDetailLabel(AppLocalizations l10n, PipelineTrigger trigger) {
  final base = triggerEventLabel(l10n, trigger.eventType);
  if (trigger.eventType == PipelineTrigger.scheduleEventType) {
    final secs = trigger.intervalSeconds;
    return secs == null ? base : '$base · ${l10n.triggerEverySeconds(secs)}';
  }
  if (trigger.match.isNotEmpty) {
    final parts = <String>[];
    trigger.match.forEach((key, value) {
      final values = value is List ? value.join(', ') : '$value';
      parts.add('$key: $values');
    });
    return '$base · ${parts.join('; ')}';
  }
  return base;
}
