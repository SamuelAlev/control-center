import 'package:cc_domain/features/code_graph/domain/ports/code_index_run_reporter.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
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
    IndexCodeTemplate.watchTriggerEventType => l10n.triggerEventCodeGraphWatch,
    'MessageReceived' => l10n.triggerEventMessageReceived,
    'TicketCompleted' => l10n.triggerEventTicketCompleted,
    'TicketFailed' => l10n.triggerEventTicketFailed,
    'TicketCancelled' => l10n.triggerEventTicketCancelled,
    'BudgetThresholdCrossed' => l10n.triggerEventBudgetCrossed,
    'TicketAssigned' => l10n.triggerEventTicketAssigned,
    _ => eventType,
  };
}

/// Display label for what started [run].
///
/// A null `triggerEventType` means a row written before triggers were recorded;
/// it reads as manual, which is what it was.
String runTriggerLabel(AppLocalizations l10n, PipelineRun run) {
  final eventType = run.triggerEventType;
  if (eventType == null) {
    return l10n.pipelineRunTriggerManual;
  }
  return triggerEventLabel(l10n, eventType);
}

/// Why [run] fired, drawn from its trigger payload — the part the label alone
/// cannot say.
///
/// Currently only the code-graph watcher records a cause; every other trigger
/// returns null and the caller falls back to the label. A run of background
/// index runs is otherwise a wall of identical rows: the label says "file
/// change" for all of them and only this says WHICH file.
String? runTriggerReason(AppLocalizations l10n, PipelineRun run) {
  final payload = run.triggerPayload;
  if (payload == null) {
    return null;
  }
  final kind = payload['cause'];
  if (kind == CodeIndexCauseKind.rescan.name) {
    return l10n.pipelineRunCauseRescan;
  }
  if (kind == CodeIndexCauseKind.initial.name) {
    return l10n.pipelineRunCauseInitial;
  }
  if (kind != CodeIndexCauseKind.changes.name) {
    return null;
  }
  final rawPaths = payload['changed_paths'];
  final named = rawPaths is List
      ? rawPaths.whereType<String>().toList()
      : const <String>[];
  final rawCount = payload['changed_count'];
  // The count is authoritative — the path list is capped, so trusting its
  // length would report "3 changed files" for a branch switch that touched
  // three thousand.
  final total = rawCount is int && rawCount > named.length
      ? rawCount
      : named.length;
  if (total == 0) {
    return null;
  }
  final summary = l10n.pipelineRunCauseChangedFiles(total);
  if (named.isEmpty) {
    return summary;
  }
  final omitted = total - named.length;
  final list = omitted > 0
      ? '${named.join(', ')} ${l10n.pipelineRunCauseMorePaths(omitted)}'
      : named.join(', ');
  return '$summary · $list';
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
