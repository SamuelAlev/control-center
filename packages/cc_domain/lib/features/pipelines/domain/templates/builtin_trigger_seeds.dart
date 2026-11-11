import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';

/// A trigger row seeded for a built-in template — the declarative source of
/// truth for which `PipelineTrigger` rows ship with each built-in pipeline.
///
/// Reconciled into the `PipelineTriggers` table on seed/re-seed: a missing
/// (templateId, eventType) row is inserted with these defaults; an existing one
/// is left untouched so the user's enable/disable + filter choices survive.
class BuiltInTriggerSeed {
  /// Creates a [BuiltInTriggerSeed].
  const BuiltInTriggerSeed({
    required this.eventType,
    this.cronExpression,
    this.match = const {},
    this.enabled = true,
  });

  /// Manual trigger (run-by-hand from the run page).
  const BuiltInTriggerSeed.manual()
    : eventType = PipelineTrigger.manualEventType,
      cronExpression = null,
      match = const {},
      enabled = true;

  /// Event trigger with an optional payload [match] filter.
  const BuiltInTriggerSeed.event(
    this.eventType, {
    this.match = const {},
    this.enabled = true,
  }) : cronExpression = null;

  /// Scheduled cron or `every:<seconds>` trigger. Defaults to disabled unless
  /// the built-in requires an automatic sweep.
  const BuiltInTriggerSeed.schedule(this.cronExpression, {this.enabled = false})
    : eventType = PipelineTrigger.scheduleEventType,
      match = const {};

  /// Event type, `schedule`, or `manual`.
  final String eventType;

  /// Schedule expression for [PipelineTrigger.scheduleEventType] triggers.
  final String? cronExpression;

  /// Optional event-payload value filter (see [PipelineTrigger.match]).
  final Map<String, dynamic> match;

  /// Default enabled state when first seeded.
  final bool enabled;
}

/// The trigger rows seeded for each built-in template, keyed by templateId.
/// Templates absent from this map ship with no triggers.
Map<String, List<BuiltInTriggerSeed>> builtInTriggerSeeds() => {
  'pr_review': const [BuiltInTriggerSeed.manual()],
  'external_pr_welcome': const [BuiltInTriggerSeed.event('ExternalPrDetected')],
  // Removes stale isolated worktrees. Fires on PR merged/closed/approved
  // and ticket done/cancelled (cleaning up that unit), plus a manual run
  // and an opt-in weekly sweep that reaps any orphaned worktree the events
  // missed. 'approved' fires when the local user submits an approving
  // review — pruning the reviewer's "open in editor" worktree.
  'pr_merged_cleanup': const [
    BuiltInTriggerSeed.manual(),
    BuiltInTriggerSeed.event(
      'PullRequestStatusChanged',
      match: {
        'status': ['merged', 'closed', 'approved'],
      },
    ),
    BuiltInTriggerSeed.event('TicketCompleted'),
    BuiltInTriggerSeed.event('TicketCancelled'),
    // Deleting a conversation orphans its worktrees, its conversation
    // folder (per-agent overlays + token-bearing `.mcp.json`) and the
    // code-graph partitions hanging off them. `WorktreeGcListener` already
    // releases on this event; the pipeline is the durable, visible,
    // retryable path for the same work — and the one that still runs when
    // the listener's in-process handling was missed.
    BuiltInTriggerSeed.event('SpaceDeleted'),
    // ENABLED and daily rather than weekly — unlike the other scheduled
    // seeds this one is not a convenience, it is garbage collection. Left
    // opt-in and weekly, worktree rows accumulate (117 on a real host, most
    // from conversations deleted long ago) and each one costs a watcher, a
    // code-graph partition and a CoW copy on disk. Events cover the normal
    // path; this catches everything they missed while the server was down.
    BuiltInTriggerSeed.schedule('every:86400', enabled: true),
  ],
  // One workspace per run; old snapshots are pruned only after a fresh
  // snapshot succeeds. Cron runs every Sunday at 03:00 UTC.
  'workspace_backup': const [
    BuiltInTriggerSeed.schedule('0 3 * * 0', enabled: true),
  ],
  'cross_review': const [BuiltInTriggerSeed.manual()],
  'ticket_to_pr': const [
    BuiltInTriggerSeed.manual(),
    BuiltInTriggerSeed.event('TicketAssigned'),
  ],
  'pr_triage': const [BuiltInTriggerSeed.manual()],
  'pre_merge_gate': const [BuiltInTriggerSeed.manual()],
  'release_notes': const [
    BuiltInTriggerSeed.manual(),
    BuiltInTriggerSeed.event(
      'PullRequestStatusChanged',
      match: {
        'status': ['merged'],
      },
    ),
  ],
  // "manual or a cron": ship manual + a weekly schedule (opt-in).
  'dep_audit': const [
    BuiltInTriggerSeed.manual(),
    BuiltInTriggerSeed.schedule('every:604800'),
  ],
  'pr_digest': const [
    BuiltInTriggerSeed.manual(),
    BuiltInTriggerSeed.schedule('every:86400'),
  ],
  // Manual run from the pipeline page, or automatically when a repo is
  // added to the workspace.
  'index_code': const [
    BuiltInTriggerSeed.manual(),
    BuiltInTriggerSeed.event('RepoAdded'),
  ],
  // Skills antivirus (PRD 23 §2/§6): manual run, or automatically whenever a
  // skill is written through a gated path (marketplace install/update, editor
  // save) or observed changing on disk. Disabling the template (or just the
  // event trigger) silences the automatic runs — the antivirus gate itself is
  // unaffected.
  'skill_analysis': const [
    BuiltInTriggerSeed.manual(),
    BuiltInTriggerSeed.event('SkillUpdated'),
  ],
  // Two triggers: the event fired when a recording stops (auto) and
  // manual — used by the detail screen's "Re-run summary" (e.g. after
  // editing your personal notes) and the pipelines run page.
  'meeting_summary': const [
    BuiltInTriggerSeed.event('MeetingRecordingStopped'),
    BuiltInTriggerSeed.manual(),
  ],
};

/// Built-in templates that ship manually runnable. Derived from
/// [builtInTriggerSeeds] so the run page and seeding stay in sync.
Set<String> get manualRunnableBuiltInTemplateIds => {
  for (final entry in builtInTriggerSeeds().entries)
    if (entry.value.any((t) => t.eventType == PipelineTrigger.manualEventType))
      entry.key,
};
