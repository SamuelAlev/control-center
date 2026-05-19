import 'package:cc_domain/core/domain/events/pr_events.dart'
    show ExternalPrDetected;
import 'package:cc_domain/features/meetings/domain/services/meeting_outcome.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart'
    show kReviewLevelStateKey;
import 'package:cc_domain/features/teams/domain/entities/team.dart' show Team;

/// Body-key constants for built-in nodes.
class BuiltInBodyKeys {
  /// No-op body for the mandatory [StepKind.trigger] entry node. It does no
  /// work — it completes immediately so the engine fans out to the trigger's
  /// downstream listeners. What actually *starts* the run (manual / event /
  /// schedule) is tracked separately as `PipelineTrigger` rows.
  static const String trigger = 'pipeline.trigger';

  /// Generic agentless bash-script node. Substitutes `{{key}}` placeholders
  /// in `config.script`, runs the result with `bash -c`, captures stdout,
  /// and writes it to `outputKey`. Used by the seeded "Clone PR branch"
  /// step so we don't burn agent tokens on plain git operations.
  static const String bashScript = 'pipeline.bashScript';

  /// Generic prompt-and-dispatch node. Used by reviewers, consolidation,
  /// and any user-authored "custom" node.
  static const String promptAgent = 'conversation.promptAgent';

  /// Opens the ONE visible conversation a run's agent steps share, up front,
  /// and writes its id to [kPipelineSpaceStateKey]. Every agent-bearing
  /// built-in starts with it: without it each agent step minted its own HIDDEN
  /// room, so a fan-out cloned the same repo once per branch and none of the
  /// resulting conversations appeared in the sidebar. The node states its
  /// scope — exactly which repos the room checks out, exactly which agents it
  /// opens with. See `registerCreateSpaceBody`.
  static const String createSpace = 'messaging.createSpace';

  /// Posts the consolidated findings as a PR comment.
  static const String prReviewComment = 'prReview.comment';

  /// Deterministically finalizes the review: gathers every `review_node` in
  /// the review space, classifies peer consensus, computes the verdict and
  /// posts the `review_summary` the PR's review tab renders — moving the
  /// association to `awaiting_approval` so the human can publish.
  ///
  /// A STEP rather than an instruction in the consolidating agent's prompt:
  /// the verdict is what decides whether a change ships, and a prompt is a
  /// request, not a guarantee. Publishing to GitHub is deliberately NOT part
  /// of it — that stays the human's press. See `registerPrReviewBodies`.
  static const String prReviewFinalize = 'prReview.finalize';

  /// The named conversation the `pr_review` pipeline's consolidate step runs
  /// in — one stream beside each reviewer's, holding the walkthrough artifact
  /// and the finalizer's `review_summary`. Shared with `finalizeReviewFn`
  /// (cc_server_core), which resolves the stream by this title to post the
  /// summary where the report lives rather than minting a standing
  /// conversation the space would otherwise never have.
  static const String reviewConsolidateConversationTitle =
      'Consolidate findings';

  /// Posts a message to a messaging space via MessagingPort.
  static const String messagingPostSpace = 'messaging.postSpace';

  /// Conditional / switch routing node. Evaluates a comparison or a switch on
  /// a state key and returns a router key (`StepResult.route`). Edges out of
  /// the node carry a `routeKey` that must match.
  static const String condition = 'pipeline.condition';

  /// Dispatches a whole [Team] (all members in parallel, or via a leader)
  /// instead of a single agent, suspending until the members' tasks finish.
  static const String teamDispatch = 'team.dispatch';

  /// Human / agent approval gate. Suspends until an approver completes the
  /// approval task (via the `approve_step` / `reject_step` MCP tools).
  static const String humanGate = 'human.gate';

  /// Removes stale isolated worktrees. With a `ticket_id` or PR
  /// (`repo_full_name` + `pr_number`) in the trigger payload it tears down that
  /// unit; on a manual run or the scheduled sweep it reaps every orphaned
  /// worktree in the workspace. See `registerCleanupReposBody`.
  static const String cleanupRepos = 'repos.cleanup';

  /// Map / fan-out: runs an agent task per item in a state collection.
  static const String forEach = 'flow.forEach';

  /// Runs another pipeline template as a nested sub-step.
  static const String callFlow = 'flow.callPipeline';

  /// Background code indexer (tree-sitter → code graph). Walks a repo, extracts
  /// symbols + edges and ingests them. Triggered by `RepoAdded`.
  static const String indexCode = 'code.index';

  /// Skills antivirus analysis (PRD 23 §2/§6): re-scans installed skills'
  /// on-disk bytes and enforces quarantines. Triggered by `SkillUpdated`
  /// (gated writes + the skills dir watcher) and manually.
  static const String skillAnalysis = 'skills.analyze';

  /// Deterministic meeting-summary persist bodies. They read the agent step's
  /// structured `meetingOutcome` payload and write each part to its own table —
  /// so action items / decisions are reliable rows, never scraped from the notes
  /// markdown. See `registerMeetingBodies`.
  static const String meetingSaveNotes = 'meeting.saveNotes';

  /// Writes the meeting's action items from the agent's structured output.
  static const String meetingAddActionItems = 'meeting.addActionItems';

  /// Writes the meeting's decisions from the agent's structured output.
  static const String meetingAddDecisions = 'meeting.addDecisions';

  /// Offline speaker diarization. Reads the meeting's retained audio, clusters
  /// it into individual speakers (`Person 1`, `Person 2`, …), relabels the
  /// transcript segments and rewrites the `transcript` state so the downstream
  /// summarize step sees per-speaker context. Also emits the raw speaker spans
  /// (`diarizationSpans`) for the parallel [meetingUpdateTranscript] step.
  /// No-op (passes the transcript through unchanged) when no audio was retained
  /// or the models aren't installed. See `registerMeetingBodies`.
  static const String meetingDiarize = 'meeting.diarize';

  /// Cross-meeting speaker recognition: matches each diarized speaker's
  /// WeSpeaker embedding against the workspace's saved voice profiles and
  /// auto-applies a confidently-matched profile's name (a weaker match is left
  /// for the rename UI to suggest). Runs between [meetingDiarize] and the
  /// summarize fan-out so auto-applied names appear in the summary transcript.
  /// No-op when there are no profiles / no embeddings. See
  /// `registerMeetingBodies`.
  static const String meetingIdentifySpeakers = 'meeting.identifySpeakers';

  /// Re-separates the meeting's transcript from the diarization result, in
  /// PARALLEL with the summarize step: it applies the `Person N` labels and
  /// merges the choppy per-window fragments into coherent per-speaker turns,
  /// then persists the cleaned transcript. Reads `diarizationSpans` (produced by
  /// [meetingDiarize]); a no-op when diarization produced nothing. See
  /// `registerMeetingBodies`.
  static const String meetingUpdateTranscript = 'meeting.updateTranscript';

  /// Assembles the meeting's mixed playback track (`mixed.wav`) from the
  /// retained per-channel WAVs during processing, so audio playback is ready the
  /// moment the meeting opens instead of being mixed lazily on the UI thread.
  /// No-op when no audio was retained. See `registerMeetingBodies`.
  static const String meetingAssemblePlayback = 'meeting.assemblePlayback';

  /// Orchestration join: at the end of the work DAG, writes failure sentinels
  /// for any sub-ticket that produced no output and flips the orchestration to
  /// `synthesizing`. Keeps downstream `{{out_<key>}}` placeholders resolvable.
  static const String orchestrationMarkPhase = 'orchestration.markPhase';

  /// Orchestration deliverable persist: writes the synthesis output to the
  /// parent ticket, completes it, posts the deliverable and marks the
  /// orchestration `completed`.
  static const String orchestrationPersistDeliverable =
      'orchestration.persistDeliverable';

  /// Orchestration partial-approval gate (PRD 17 §4): completes immediately
  /// when the step's node key is in the orchestration's approved set, else
  /// suspends until a later approval resumes it. Exempt from the suspended
  /// liveness backstop — waiting days for an explicit approval is its job.
  static const String orchestrationAwaitApproval =
      'orchestration.awaitApproval';
}

/// Agent IDs the built-in `pr_review` template references. These are the
/// UUIDs of the workspace's seeded specialist agents (qa / architect /
/// engineer / librarian).
class BuiltInAgentIds {
  /// Creates a [BuiltInAgentIds].
  const BuiltInAgentIds({
    required this.qa,
    required this.architect,
    required this.engineer,
    required this.librarian,
    required this.ceo,
    String? coder,
  }) : coder = coder ?? engineer;

  /// QA reviewer agent id.
  final String qa;

  /// Architecture reviewer agent id.
  final String architect;

  /// Engineer agent id (used as the consolidator).
  final String engineer;

  /// Librarian agent id.
  final String librarian;

  /// CEO agent id (used as the consolidator).
  final String ceo;

  /// Coder agent id used by `ticket_to_pr` / `ci_autofix` to write code.
  /// Defaults to [engineer] when not separately seeded.
  final String coder;
}

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

  /// Scheduled (`every:<seconds>`) trigger. Defaults to disabled so it is
  /// opt-in (the user enables it from the trigger panel).
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

/// Identifiers of the `index_code` template, named once because three surfaces
/// outside the template itself address it: the repo index button starts it, the
/// progress reader looks for its `index` node's snapshot and the code-graph
/// watcher publishes its background reindexes as runs of it.
class IndexCodeTemplate {
  /// The template id (`pipeline_runs.template_id`).
  static const String id = 'index_code';

  /// The mandatory entry node every template gets from `_triggerFirst`.
  static const String triggerStepId = 'trigger';

  /// The node that runs the indexer.
  static const String indexStepId = 'index';

  /// `triggerEventType` of a run published by the code-graph watcher rather
  /// than started by the engine.
  ///
  /// Not a `DomainEvent` type name (the watcher is driven by filesystem events,
  /// which never reach the bus) — it is a marker and the startup reconciler
  /// keys off it to close out rows left behind by a crash instead of letting the
  /// engine try to resume work it never owned.
  static const String watchTriggerEventType = 'CodeGraphWatch';
}

/// Identifiers of the `skill_analysis` template (the skills antivirus as a
/// pipeline). Named once because three surfaces outside the template itself
/// address it: the seeder, the projection reporter and the boot reconciler.
class SkillAnalysisTemplate {
  /// The template id (`pipeline_runs.template_id`).
  static const String id = 'skill_analysis';

  /// The mandatory entry node every template gets from `_triggerFirst`.
  static const String triggerStepId = 'trigger';

  /// The node that runs the analysis body.
  static const String scanStepId = 'scan';

  /// `triggerEventType` markers for runs published by the projection reporter
  /// (the settings UI's synchronous scan ops) rather than started by the
  /// engine. Like [IndexCodeTemplate.watchTriggerEventType], these are
  /// markers, not `DomainEvent` type names — the boot reaper keys off them.
  static const String manualProjectionTriggerEventType = 'SkillAnalysisManual';
  static const String updateProjectionTriggerEventType = 'SkillAnalysisUpdate';
}

/// Every `triggerEventType` marker used by a PROJECTION reporter — a run row
/// that mirrors work owned outside `PipelineEngine` (the code-graph watcher,
/// the settings UI's synchronous skill scans).
///
/// The engine neither starts nor finishes these runs, so they must not
/// participate in a template's `maxParallelRuns` accounting: a slot one of them
/// held would never be released, and every later run of that template would
/// queue forever behind a row nothing will ever close. The projections' own
/// concurrency is their owner's business (the watcher has its own ceiling).
const Set<String> kProjectionTriggerEventTypes = {
  IndexCodeTemplate.watchTriggerEventType,
  SkillAnalysisTemplate.manualProjectionTriggerEventType,
  SkillAnalysisTemplate.updateProjectionTriggerEventType,
};

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

// Shared input field builders for the built-in manual-run pipelines. These are
// seed defaults (data layer, no BuildContext) so the English labels/help are
// hardcoded — same convention as the built-in agent/prompt copy in this file.

PipelineInput _repoFullNameInput() => PipelineInput(
  key: 'repo_full_name',
  label: 'Repository',
  type: PipelineInputType.repo,
  required: true,
  helpText: 'Pick a repository in this workspace.',
);

PipelineInput _prNumberInput() => PipelineInput(
  key: 'pr_number',
  label: 'PR number',
  type: PipelineInputType.number,
  required: true,
  placeholder: '123',
);

/// The state key the [BuiltInBodyKeys.createSpace] node writes and every agent
/// step downstream names as its room.
///
/// Deliberately NOT `spaceId`: `pr_digest` takes an operator-chosen `spaceId`
/// as a manual-run input (the room the digest is posted to), and a run's own
/// working conversation is a different thing.
const String kPipelineSpaceStateKey = 'pipeline_space_id';

/// The state key the [BuiltInBodyKeys.createSpace] node writes when — and only
/// when — it was asked to open a conversation as well as a room
/// (`extras['createConversation']`).
///
/// A space and a conversation are two different things: the space owns the
/// checkout, the roster and the provisioning, and its conversations are flat
/// streams inside it. The node opens the room by default and leaves the streams
/// to the steps that actually write into them, so nothing is minted for a run
/// whose agents each open their own.
const String kPipelineConversationStateKey = 'pipeline_conversation_id';

/// The id of the space node every agent-bearing built-in opens with.
const String _spaceStepId = 'space';

/// The entry node that opens the run's ONE conversation — and, with it, the
/// checkout its steps work in.
///
/// It replaces the template's former entry step (which is rewired to fire from
/// it). [repoIds] is the exact checkout scope — `const []` means the room checks
/// out nothing, which is right for the steps that only reshape text (release
/// notes, a PR digest, a meeting summary) and used to drag every workspace repo
/// onto disk to do it. [agentIds] is the roster the room opens with: only the
/// agents that run on EVERY path, since a branch's agent joins when it is
/// actually dispatched.
///
/// [pr] resolves the pull request's own room instead of creating one, so the
/// worktree is a copy-on-write copy of the linked checkout fetched and checked
/// out at the PR head — the same room a human opening that PR gets.
///
/// [awaitReady] holds the step until that checkout exists and publishes its path
/// as `repoLocalPath`. Set it wherever a NON-agent step downstream addresses the
/// tree by path (a bash script, a `fileExists` router); an agent step needs no
/// wait, because dispatch already gates on the room being ready. This pairing —
/// CoW copy, scrub, fetch, switch — costs seconds and no network transfer,
/// where a clone re-downloads the full repository on every single run.
/// [after] names the steps the room waits on, for the one template whose room
/// is NOT the entry node (`index_code` opens it only once there is an indexed
/// graph to analyse). Left empty the node is the template's entry step, which
/// is what every other built-in wants.
///
/// [conversationTitle] opens the room's FIRST stream under that name, and
/// publishes its id as [kPipelineConversationStateKey]. Pass it when the
/// template has exactly one agent step, naming the same title that step uses:
/// the room is then born holding the stream its work lands in, so the standing
/// conversation every read path resolves IS that one. Left null the room opens
/// empty and each agent step opens its own — which is right for a fan-out, and
/// leaves a window in which anything that opens the room (the sidebar, the
/// step-detail panel) mints an untitled standing stream beside the named ones.
///
/// [spaceName] is what the ROOM is called, and it is deliberately separate from
/// [label], which names the NODE on the canvas. Left null the body falls back to
/// the label — which is how a room ended up called "Create space for X": a
/// perfectly good instruction to read on a canvas, and a title nobody would
/// choose for a conversation in the sidebar. Every node that actually creates a
/// room states it. A `pr: true` node deliberately does NOT: it resolves the pull
/// request's own room, which is already named by whoever opened it, so a name
/// here would be config that never renders.
PipelineStepDefinition _spaceStep({
  required String label,
  required List<String> agentIds,
  String? spaceName,
  List<String> repoIds = const [],
  String? mode,
  bool pr = false,
  bool awaitReady = false,
  String? conversationTitle,
  List<String> after = const [],
  double x = -240,
  double y = 0,
}) {
  return PipelineStepDefinition(
    id: _spaceStepId,
    kind: StepKind.listen,
    bodyKey: BuiltInBodyKeys.createSpace,
    triggers: after.isEmpty
        ? const []
        : [StepTrigger(sourceStepIds: List.unmodifiable(after))],
    config: PipelineNodeConfig(
      label: label,
      repoIds: repoIds,
      outputKey: kPipelineSpaceStateKey,
      extras: {
        // Deduped: `BuiltInAgentIds.coder` falls back to the engineer when no
        // dedicated coder is seeded, so a template naming both would otherwise
        // store the same id twice.
        'agentIds': agentIds.toSet().toList(),
        if (spaceName case final String name) 'spaceName': name,
        if (mode case final String value) 'mode': value,
        if (pr) 'pr': true,
        if (awaitReady) 'awaitReady': true,
        if (conversationTitle case final String title) ...{
          'createConversation': true,
          'conversationTitle': title,
        },
      },
    ),
    x: x,
    y: y,
  );
}

/// The `extras` an agent step carries to work in the run's shared room under
/// its own named stream, instead of minting a hidden conversation of its own.
///
/// A step that names the room must also name its stream: without a title it
/// writes into the space's standing conversation, and a fan-out of steps would
/// then interleave every agent's turn into one thread.
Map<String, dynamic> _inRunSpace(String conversationTitle) => {
  'spaceId': '{{$kPipelineSpaceStateKey}}',
  'conversationTitle': conversationTitle,
};

/// Rewires [step] to fire from the space node — used on each template's former
/// entry step, so the space (and its clone) is opened before anything else runs.
PipelineStepDefinition _afterSpace(PipelineStepDefinition step) {
  return PipelineStepDefinition(
    id: step.id,
    kind: step.kind,
    bodyKey: step.bodyKey,
    triggers: const [
      StepTrigger(sourceStepIds: [_spaceStepId]),
    ],
    waitForStepIds: step.waitForStepIds,
    config: step.config,
    x: step.x,
    y: step.y,
  );
}

/// Seeds for the workspace identified by [workspaceId]. Returns one
/// [PipelineDefinition] per built-in template, each rewritten so it begins
/// with the mandatory [StepKind.trigger] entry node (see [_triggerFirst]).
List<PipelineDefinition> builtInTemplateSeeds({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  return [
    _prReviewSeed(workspaceId: workspaceId, agentIds: agentIds),
    _externalPrWelcomeSeed(workspaceId: workspaceId),
    _repoCleanupSeed(workspaceId: workspaceId),
    _crossReviewSeed(workspaceId: workspaceId, agentIds: agentIds),
    _ticketToPrSeed(workspaceId: workspaceId, agentIds: agentIds),
    _prTriageSeed(workspaceId: workspaceId, agentIds: agentIds),
    _preMergeGateSeed(workspaceId: workspaceId, agentIds: agentIds),
    _releaseNotesSeed(workspaceId: workspaceId, agentIds: agentIds),
    _depAuditSeed(workspaceId: workspaceId, agentIds: agentIds),
    _prDigestSeed(workspaceId: workspaceId, agentIds: agentIds),
    _indexCodeSeed(
      workspaceId: workspaceId,
      librarianAgentId: agentIds.librarian,
    ),
    _meetingSummarySeed(workspaceId: workspaceId, agentIds: agentIds),
  ].map(_triggerFirst).toList();
}

/// Rewrites [def] so it begins with the mandatory [StepKind.trigger] entry
/// node. The seed's own entry work-node — the first non-terminal step authored
/// with no inbound edges — is rewired to fire from the trigger and the trigger
/// node is prepended just to its left. What actually *starts* a run (manual /
/// event / schedule) is tracked separately as `PipelineTrigger` rows, seeded
/// alongside the template.
PipelineDefinition _triggerFirst(PipelineDefinition def) {
  const triggerId = 'trigger';
  final entry = def.steps.firstWhere(
    (s) => s.kind != StepKind.terminal && s.triggers.isEmpty,
  );
  final triggerNode = PipelineStepDefinition(
    id: triggerId,
    kind: StepKind.trigger,
    bodyKey: BuiltInBodyKeys.trigger,
    config: const PipelineNodeConfig(label: 'Trigger'),
    x: (entry.x ?? 0) - 220,
    y: entry.y ?? 0,
  );
  final rewired = def.steps.map((s) {
    if (s.id != entry.id) {
      return s;
    }
    return PipelineStepDefinition(
      id: s.id,
      kind: s.kind,
      bodyKey: s.bodyKey,
      triggers: const [
        StepTrigger(sourceStepIds: [triggerId]),
      ],
      waitForStepIds: s.waitForStepIds,
      config: s.config,
      x: s.x,
      y: s.y,
    );
  });
  return def.copyWith(steps: List.unmodifiable([triggerNode, ...rewired]));
}

/// Where a conversation's checkouts live, as told to an agent.
///
/// Every agent in a space runs from its own overlay directory, whose `repos`
/// symlink points at the space's shared worktrees — so this path is literally
/// true for every reviewer and needs no per-run substitution. A review space
/// holds exactly ONE repo (the one under review, at the PR head), so the
/// singular reads honestly.
const String _worktreeHint = 'repos/ under your working directory';

/// The half of a reviewer's brief that is the same for every specialism: how
/// to read the change, what to check before flagging, and how to FILE what it
/// finds.
///
/// Filing is the load-bearing part. A finding recorded with `add_review_node`
/// becomes a review node on the PR — which is what the review tab renders, what
/// the verdict is computed from, and what "publish to GitHub" turns into an
/// inline comment. A reviewer that only returns prose produces a pipeline run
/// that looks successful and a review surface that is empty, which is exactly
/// what the bulleted-list-only brief used to do.
const String _reviewerFilingBrief =
    '\n\nRead the change in the checked-out worktree with `read` / `bash` '
    '(`git diff`, `git show`).\n'
    'Before you flag anything:\n'
    '- use `code_impact` / `code_callers` to gauge a changed symbol\'s '
    'cross-file blast radius, so severity reflects reach rather than '
    'line count.\n'
    '- use `search_memory` (domain `review-suppressions`) to avoid '
    're-flagging a pattern the team has already dismissed.\n\n'
    'Record EVERY finding with `add_review_node`, always with `file_path` + '
    '`line_number` (that is what lets it post as an inline GitHub comment) and '
    'a `confidence` in `[0, 1]`.\n\n'
    'Classify each finding on three axes:\n'
    '- `category`: `security`, `stability`, `data_integrity`, `correctness`, '
    '`performance` or `maintainability` — what the finding is about.\n'
    '- `severity`: `critical` (failures, breaches, data loss), `major` '
    '(significant functional or performance impact), `minor` (should be fixed, '
    'not critical), `trivial` (polish) or `info` (context, no action). '
    'Severity sets the P0–P3 priority, so keep it honest: an inflated severity '
    'is what makes a review stop being read.\n'
    '- `effort`: `quick_win`, `moderate` or `heavy_lift` — roughly what acting '
    'on it costs. This is what lets a reader triage.\n\n'
    'Write the finding body in this shape, and KEEP IT SHORT:\n'
    '- FIRST LINE: a bold, imperative one-sentence title naming the fix — '
    '`**Await the future before closing the transaction.**`, not "There may be '
    'an issue with the transaction". End it with a period.\n'
    '- THEN TWO SENTENCES, around 45 words, in this exact shape: open with the '
    'CONDITION that triggers the defect ("When the provider returns a null '
    'expiry…", "If the list is empty…"), say what breaks and why, then name '
    'the fix — naming the actual symbol or API to change. That is the whole '
    'body. Three sentences is the ceiling, not the target.\n'
    '- A reviewer reads this in the margin of a diff, not as a report. If you '
    'cannot make the point in three sentences, you have either bundled two '
    'findings into one (file them separately) or you are explaining something '
    'the code already shows.\n'
    '- No headings, no bullet lists, no "why this matters" section. Prose.\n'
    '- Do not flag what the compiler, analyzer or linter already reports. A '
    'review that repeats `dart analyze` costs attention and buys nothing.\n'
    '- Do NOT paste evidence into the body: no shell transcripts, no `grep` '
    'output, no tables of inputs, no line-by-line derivations, no quoting the '
    'diff back. You may cite ONE adjacent call site that already does it '
    'correctly, as a bare `path:line` — that is the most persuasive evidence '
    'there is and it costs a clause. Everything else you found belongs in '
    '`fix_diff`, which is collapsed, or nowhere.\n'
    '- Write about the CODE, never about the review. No praise, no preamble, '
    'no restating the diff, no describing your own reasoning, scope, '
    'confidence or what you did and did not check. A reader wants the defect, '
    'not a note on how you arrived at it. One issue per finding.\n\n'
    'Fill `reasoning` BEFORE `content` on every call: what the code does, what '
    'you checked, why it is a defect. Nobody reads it — writing it is what '
    'makes the finding follow from the analysis instead of the other way '
    'round, and it is the only way to tell later whether a wrong finding came '
    'from wrong reasoning.\n\n'
    'Set `confidence` honestly. It is GATED: below the level\'s floor a '
    'finding is grouped away rather than shown, so inflating it buys nothing, '
    'and a careful score is what keeps the review worth reading. Critical and '
    'major findings are reported whatever their confidence.\n\n'
    'When the fix is small and you are certain, pass `fix_suggestion`: the '
    'exact replacement lines for the anchored range, no diff markers — it '
    'becomes a one-click committable suggestion, so it must be right in '
    'isolation and cover exactly the lines you anchored. '
    'When you can name the fix concretely but it is bigger than that, pass '
    '`fix_diff`: a minimal unified diff of just the changed lines. When the '
    'fix is mechanical, also pass '
    '`ai_prompt`: one paragraph instructing a coding agent to make it, naming '
    'the file and the line range. Omit both rather than guessing — a wrong '
    'patch costs more than no patch.\n\n'
    'Prefer no findings to weak findings. A finding you cannot anchor to a '
    'changed line, or that restates a linter, is noise.\n\n'
    'Then return a short bulleted summary of what you filed — the summary is '
    'for the human reading the run, the review nodes are the review.'
    '{{review_level_reporting_brief}}';

PipelineDefinition _prReviewSeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const setupId = 'setup';
  const qaId = 'qa_review';
  const archId = 'architect_review';
  const engId = 'engineer_review';
  const securityId = 'security_review';
  const perfId = 'perf_review';
  const consolidateId = 'consolidate';
  const finalizeId = 'finalize';

  // What a reviewer's output key holds when its level gate kept it from
  // running. The consolidation prompt interpolates every reviewer's key, and an
  // unresolved placeholder fails its step — so a gated-off reviewer has to
  // leave something behind, and it should read as an explicit absence rather
  // than an empty section the lead reviewer might narrate as "no issues".
  const notRunAtThisLevel = '(not run at this review level)';

  PipelineStepDefinition reviewer({
    required String stepId,
    required String agentId,
    required String label,
    required String prompt,
    required double x,
    required double y,
    List<Object?>? levels,
  }) {
    return PipelineStepDefinition(
      id: stepId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(sourceStepIds: [setupId]),
      ],
      config: PipelineNodeConfig(
        agentId: agentId,
        inputKeys: const [
          'review_space_id',
          'pr_title',
          'pr_body',
          'head_ref',
          'repo_full_name',
          'pr_number',
        ],
        // Every reviewer works in the PR's ONE space (ensured by [setupId]),
        // each in its own named stream. The space is linked to the pull
        // request, so its single checkout is the repo under review at the PR
        // head — which is why these nodes carry no `repoIds`: the repo scope is
        // the space's, not the step's, and a per-step room would clone the
        // whole workspace once per reviewer.
        extras: {
          'spaceId': '{{review_space_id}}',
          'conversationTitle': label,
          // Absent for reviewers that run at every level. A gate is declared
          // with `null` in its allow-list wherever the level may legitimately
          // be missing (runs started before levels existed, manual canvas
          // runs), which is what keeps those runs behaving as balanced.
          if (levels != null)
            'runWhen': {
              'key': kReviewLevelStateKey,
              'in': levels,
              'skippedOutput': notRunAtThisLevel,
            },
        },
        outputKey: '${stepId}_findings',
        label: label,
        prompt: prompt + _reviewerFilingBrief,
      ),
      x: x,
      y: y,
    );
  }

  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: setupId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.createSpace,
      config: const PipelineNodeConfig(
        label: 'Prepare review space',
        inputKeys: [
          'repo_full_name',
          'pr_number',
          'pr_external_id',
          'pr_title',
        ],
        outputKey: 'review_space_id',
        // `pr: true` resolves the pull request's OWN room — the same one the PR
        // page opens — so its single checkout is the repo under review at the
        // PR head. The node also normalizes the review level into run state,
        // which the reviewer gates and the finalizer both read.
        extras: {'pr': true},
      ),
      x: 0,
      y: 120,
    ),
    // The engineer reviewer is ungated: it is the one pass every level runs,
    // so a light review is still a review rather than an empty space.
    reviewer(
      stepId: engId,
      agentId: agentIds.engineer,
      label: 'Engineer review',
      prompt:
          'You are the engineer reviewer. PR #{{pr_number}} — {{pr_title}} is '
          'checked out at the PR head in `$_worktreeHint`.\n\n'
          'Focus on implementation details, correctness and obvious bugs.',
      x: 240,
      y: 120,
    ),
    reviewer(
      stepId: qaId,
      agentId: agentIds.qa,
      label: 'QA review',
      levels: const ['balanced', 'thorough', null],
      prompt:
          'You are a QA reviewer. PR #{{pr_number}} — {{pr_title}} is checked '
          'out at the PR head in `$_worktreeHint`.\n\n'
          'Focus on:\n'
          '- whether the change is covered by tests, missing edge-case '
          'tests and brittle assertions.\n'
          '- regression risk in adjacent code paths.',
      x: 240,
      y: 0,
    ),
    reviewer(
      stepId: archId,
      agentId: agentIds.architect,
      label: 'Architect review',
      levels: const ['balanced', 'thorough', null],
      prompt:
          'You are an architecture reviewer. PR #{{pr_number}} — {{pr_title}} '
          'is checked out at the PR head in `$_worktreeHint`.\n\n'
          'Focus on code quality, layering boundaries, dead/duplicated '
          'code and missed reuse opportunities. Call out anything that '
          'violates existing patterns in the repo.',
      x: 240,
      y: 240,
    ),
    // Specialists, thorough only. They share the architect/engineer agents
    // rather than introducing new seeded ones — the specialism is the brief,
    // and an agent per axis would be five more rows in every workspace for no
    // additional capability.
    reviewer(
      stepId: securityId,
      agentId: agentIds.architect,
      label: 'Security review',
      levels: const ['thorough'],
      prompt:
          'You are a security reviewer. PR #{{pr_number}} — {{pr_title}} is '
          'checked out at the PR head in `$_worktreeHint`.\n\n'
          'Focus on:\n'
          '- injection vectors (shell, SQL, path traversal)\n'
          '- credential exposure, hardcoded secrets and anything that widens '
          'what a token can reach\n'
          '- authorization gaps: an operation that takes an id without '
          'proving the caller owns it\n'
          '- dependency changes (pubspec.lock, Cargo.lock, package-lock.json)\n'
          '- input validation gaps on anything crossing a trust boundary.',
      x: 240,
      y: 360,
    ),
    reviewer(
      stepId: perfId,
      agentId: agentIds.engineer,
      label: 'Performance review',
      levels: const ['thorough'],
      prompt:
          'You are a performance reviewer. PR #{{pr_number}} — {{pr_title}} is '
          'checked out at the PR head in `$_worktreeHint`.\n\n'
          'Focus on:\n'
          '- work on a hot path that does not need to be there\n'
          '- synchronous or blocking I/O on a latency-sensitive path\n'
          '- N+1 queries and unbounded reads\n'
          '- allocations or rebuilds proportional to something that grows\n'
          '- missing caching where the same result is recomputed per call.\n\n'
          'Quantify when you can: "per row" and "once per request" are '
          'different findings, and the number is what makes the severity '
          'defensible.',
      x: 240,
      y: 480,
    ),
    PipelineStepDefinition(
      id: consolidateId,
      kind: StepKind.join,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(sourceStepIds: [qaId, archId, engId, securityId, perfId]),
      ],
      waitForStepIds: const [qaId, archId, engId, securityId, perfId],
      config: PipelineNodeConfig(
        agentId: agentIds.ceo,
        inputKeys: const [
          'qa_review_findings',
          'architect_review_findings',
          'engineer_review_findings',
          'security_review_findings',
          'perf_review_findings',
          'review_space_id',
          'pr_title',
          'pr_number',
        ],
        // Same room, same checkout — but its OWN named stream, beside one per
        // reviewer, not the space's standing conversation: a pipeline-made
        // space holds exactly the streams the pipeline opened (one per
        // reviewer + this one) and no "main" one. Two properties make that
        // safe:
        //
        //  - the review tab discovers the published walkthrough SPACE-WIDE
        //    (`workProduct.watchForSpace` with no conversation id scans every
        //    stream in the room), so the report is found wherever it lands;
        //  - `reuseExisting` keys the stream on its title, so a rerun
        //    continues the thread the last attempt wrote in.
        extras: const {
          'spaceId': '{{review_space_id}}',
          'conversationTitle':
              BuiltInBodyKeys.reviewConsolidateConversationTitle,
        },
        outputKey: 'consolidated_findings',
        label: 'Consolidate findings',
        prompt:
            'You are the lead reviewer. Write the walkthrough for PR '
            '#{{pr_number}} — {{pr_title}} from the specialist findings below.\n\n'
            '## QA\n{{qa_review_findings}}\n\n'
            '## Architecture\n{{architect_review_findings}}\n\n'
            '## Engineering\n{{engineer_review_findings}}\n\n'
            '## Security\n{{security_review_findings}}\n\n'
            '## Performance\n{{perf_review_findings}}\n\n'
            'A section reading "$notRunAtThisLevel" means that reviewer did '
            'not run at the level this review was requested at. Say nothing '
            'about it — it is not a finding, and it is not a clean bill of '
            'health for that area either.\n\n'
            'Write the walkthrough as prose a reviewer would actually read '
            'first:\n'
            '- A one-line headline: what this PR does, in plain language.\n'
            '- A short narrative per area of the change — what moved, and why '
            'it matters. Group by concern, not by file: twelve localization '
            'files that all gained the same key are ONE line, not twelve.\n'
            '- Cross-cutting risks worth flagging above the per-finding '
            'detail, if any.\n'
            '- When the change alters how components talk to each other '
            '(a new call path, an async flow, an event sequence), include ONE '
            '```mermaid `sequenceDiagram` showing it. Skip the diagram when '
            'the change is local — a diagram of a rename teaches nothing.\n\n'
            'Do NOT re-list the individual findings and do NOT restate their '
            'severities. Each one is already filed as a review node, and the '
            'verdict, the counts and the finding table are computed from those '
            '— a hand-written second copy is what drifts from the real one.\n\n'
            'Then PUBLISH the walkthrough as an artifact with '
            '`publish_artifact`, titled `Review: PR #{{pr_number}}`, '
            "`artifact_type` `report`. That artifact IS the review's output — "
            "it is what the pull request's review tab renders and what a human "
            'reads, so a report that only exists in your reply reaches '
            'nobody. Use markdown blocks for the prose and a code block for '
            'any snippet worth quoting.\n\n'
            'Finally, return the same walkthrough as GitHub-flavoured '
            'Markdown — it becomes the editorial note on the verdict.',
      ),
      x: 480,
      y: 120,
    ),
    // Deterministic close-out: the reviewers' `review_node` findings become a
    // verdict + `review_summary`, and the association moves to
    // `awaiting_approval`. This is what the PR's review tab reads, so without
    // it a finished run left the tab empty and the Publish button inert.
    //
    // NOTE: the former "Post PR comment" step is intentionally gone —
    // publishing to GitHub is user-gated through `publish_review_to_github`
    // (the "Publish to GitHub" button), so the pipeline must not post directly
    // or the review would double-publish.
    PipelineStepDefinition(
      id: finalizeId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.prReviewFinalize,
      triggers: const [
        StepTrigger(sourceStepIds: [consolidateId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Finalize review',
        inputKeys: ['review_space_id', 'consolidated_findings'],
        outputKey: 'review_verdict',
      ),
      x: 720,
      y: 120,
    ),
    PipelineStepDefinition(
      id: '$finalizeId\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_$finalizeId',
      triggers: const [
        StepTrigger(sourceStepIds: [finalizeId]),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'pr_review',
    workspaceId: workspaceId,
    name: 'PR review',
    description:
        "Opens the pull request's review space (its worktree checked out at "
        'the PR head), runs the reviewers the workspace review level calls for '
        '— each in its own stream in that space — and consolidates their '
        'findings into a walkthrough and a verdict.',
    isBuiltIn: true,
    inputs: [_repoFullNameInput(), _prNumberInput()],
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
// Tier 0 — External PR welcome bot
// ---------------------------------------------------------------------------

/// Triggered by [ExternalPrDetected]. Greets the external contributor with
/// a boilerplate welcome comment and a link to contributing docs.
PipelineDefinition _externalPrWelcomeSeed({required String workspaceId}) {
  const greetId = 'greet';
  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: greetId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: const PipelineNodeConfig(
        label: 'Post welcome comment',
        inputKeys: ['repo_owner', 'repo_name', 'pr_number', 'author'],
        outputKey: 'welcome_comment_url',
        script:
            'set -euo pipefail\n'
            'OWNER="{{repo_owner}}"\n'
            'REPO="{{repo_name}}"\n'
            'PR="{{pr_number}}"\n'
            'AUTHOR="{{author}}"\n'
            'MSG="👋 Thanks for the PR, @\$AUTHOR! A reviewer will take a '
            'look shortly. In the meantime, please check our [contributing '
            'guide](https://github.com/\$OWNER/\$REPO/blob/main/CONTRIBUTING.md)."'
            '\n'
            'gh pr comment "\$PR" --repo "\$OWNER/\$REPO" --body "\$MSG"\n'
            'echo "https://github.com/\$OWNER/\$REPO/pull/\$PR"',
      ),
      x: 0,
      y: 0,
    ),
    PipelineStepDefinition(
      id: '$greetId\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_$greetId',
      triggers: const [
        StepTrigger(sourceStepIds: [greetId]),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'external_pr_welcome',
    workspaceId: workspaceId,
    name: 'External PR welcome',
    description:
        'Greets external contributors with a welcome comment linking to '
        'contributing docs. Fires automatically on ExternalPrDetected.',
    isBuiltIn: true,
    isEnabled: false,
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
// Tier 0 / Tier 1 — Stale repository cleanup
// ---------------------------------------------------------------------------

/// Removes stale isolated worktrees via the deterministic `repos.cleanup`
/// body. The body picks its mode from the trigger payload: a `ticketId` (ticket
/// done/cancelled) or a PR (merged/closed) tears down that unit, while a manual
/// run or the weekly schedule sweeps the workspace.
///
/// The sweep reclaims three things, not just the first: worktrees whose
/// directory has vanished, worktrees whose SPACE no longer exists (deleting a
/// conversation fires `SpaceDeleted` → release, but an event missed while the
/// server was down leaves an intact worktree nothing would ever reclaim) and
/// orphan conversation FOLDERS — the per-agent overlays and their token-bearing
/// `.mcp.json` — left behind by a deleted space.
///
/// Keeps the `pr_merged_cleanup` templateId so existing workspaces' trigger
/// rows are preserved on re-seed; only the display name/behaviour broadened.
PipelineDefinition _repoCleanupSeed({required String workspaceId}) {
  const cleanupId = 'cleanup';
  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: cleanupId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.cleanupRepos,
      config: const PipelineNodeConfig(
        label: 'Remove stale repositories',
        outputKey: 'cleanup_result',
        // Destructive and non-reversible: never auto-re-run on crash resume.
        extras: {'idempotent': false},
      ),
      x: 0,
      y: 0,
    ),
    PipelineStepDefinition(
      id: '$cleanupId\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_$cleanupId',
      triggers: const [
        StepTrigger(sourceStepIds: [cleanupId]),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'pr_merged_cleanup',
    workspaceId: workspaceId,
    name: 'Stale repository cleanup',
    description:
        'Removes stale isolated worktrees. Fires on PR merged/closed and ticket done/cancelled (cleans '
        'up that unit), or on a manual run / weekly schedule — the sweep also '
        'reclaims worktrees and folders belonging to deleted conversations, '
        'including ones whose cleanup event was missed while the server was '
        'down.',
    isBuiltIn: true,
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
// Tier 0 — Cross-reviewer second opinion (manual run)
// ---------------------------------------------------------------------------

/// Manual-run pipeline. Same fan-out/join pattern as PR review but with
/// a different specialist mix: security, performance, accessibility.
/// Takes a PR number as state input. Reuses promptAgent for reviewers
/// and prReview.comment for the final post.
PipelineDefinition _crossReviewSeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const securityId = 'security_review';
  const perfId = 'perf_review';
  const a11yId = 'a11y_review';
  const consolidateId = 'consolidate';
  const commentId = 'comment';

  PipelineStepDefinition specialist({
    required String stepId,
    required String agentId,
    required String label,
    required String prompt,
    required double y,
  }) {
    return PipelineStepDefinition(
      id: stepId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(sourceStepIds: [_spaceStepId]),
      ],
      config: PipelineNodeConfig(
        agentId: agentId,
        inputKeys: const [
          'repo_local_path',
          'pr_title',
          'pr_body',
          'pr_number',
          'repo_full_name',
        ],
        // Every specialist works in the run's ONE room, each in its own named
        // stream: the PR checkout belongs to the space, so a three-way fan-out
        // materializes it once instead of three times.
        extras: _inRunSpace(label),
        outputKey: '${stepId}_findings',
        label: label,
        prompt: prompt,
      ),
      x: 240,
      y: y,
    );
  }

  final steps = <PipelineStepDefinition>[
    // The PR's room owns a copy-on-write copy of the linked checkout, scrubbed
    // and switched to the PR head. `awaitReady` publishes that worktree as
    // `repoLocalPath`, which is the key every prompt below reads.
    _spaceStep(
      label: 'Cross-review #{{pr_number}}',
      agentIds: [
        agentIds.architect,
        agentIds.engineer,
        agentIds.librarian,
        agentIds.ceo,
      ],
      pr: true,
      awaitReady: true,
      x: 0,
      y: 120,
    ),
    specialist(
      stepId: securityId,
      agentId: agentIds.architect,
      label: 'Security review',
      prompt:
          'You are a security reviewer. The PR branch is checked out at '
          '`{{repo_local_path}}`. PR #{{pr_number}} — {{pr_title}}.\n\n'
          'Focus on:\n'
          '- injection vectors (shell, SQL, path traversal)\n'
          '- credential exposure or hardcoded secrets\n'
          '- dependency changes (check pubspec.lock / Cargo.lock / '
          'package-lock.json)\n'
          '- input validation gaps\n\n'
          'Return findings as a bulleted list with `path:line` references.',
      y: 0,
    ),
    specialist(
      stepId: perfId,
      agentId: agentIds.engineer,
      label: 'Performance review',
      prompt:
          'You are a performance reviewer. The PR branch is checked out at '
          '`{{repo_local_path}}`. PR #{{pr_number}} — {{pr_title}}.\n\n'
          'Focus on:\n'
          '- unnecessary allocations in hot paths\n'
          '- synchronous I/O on the UI thread\n'
          '- missing caching or memoization opportunities\n'
          '- N+1 database queries\n'
          '- large widget rebuilds without const constructors\n\n'
          'Return findings as a bulleted list with `path:line` references.',
      y: 120,
    ),
    specialist(
      stepId: a11yId,
      agentId: agentIds.librarian,
      label: 'Accessibility review',
      prompt:
          'You are an accessibility reviewer. The PR branch is checked out '
          'at `{{repo_local_path}}`. PR #{{pr_number}} — {{pr_title}}.\n\n'
          'Focus on:\n'
          '- missing Semantics widgets\n'
          '- insufficient color contrast\n'
          '- touch target sizes under 48px\n'
          '- images without alt text or labels\n'
          '- keyboard navigation gaps\n\n'
          'Return findings as a bulleted list with `path:line` references.',
      y: 240,
    ),
    PipelineStepDefinition(
      id: consolidateId,
      kind: StepKind.join,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(sourceStepIds: [securityId, perfId, a11yId]),
      ],
      waitForStepIds: const [securityId, perfId, a11yId],
      config: PipelineNodeConfig(
        agentId: agentIds.ceo,
        inputKeys: const [
          'security_review_findings',
          'perf_review_findings',
          'a11y_review_findings',
          'pr_title',
          'pr_number',
        ],
        extras: _inRunSpace('Consolidate findings'),
        outputKey: 'consolidated_findings',
        label: 'Consolidate findings',
        prompt:
            'You are the lead reviewer. Consolidate the specialist findings '
            'into a single well-structured report for PR #{{pr_number}} — '
            '{{pr_title}}.\n\n'
            '## Security\n{{security_review_findings}}\n\n'
            '## Performance\n{{perf_review_findings}}\n\n'
            '## Accessibility\n{{a11y_review_findings}}\n\n'
            'De-duplicate, group by file, order by severity. Output a '
            'GitHub-flavoured Markdown comment body.',
      ),
      x: 480,
      y: 120,
    ),
    PipelineStepDefinition(
      id: commentId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.prReviewComment,
      triggers: const [
        StepTrigger(sourceStepIds: [consolidateId]),
      ],
      config: const PipelineNodeConfig(
        inputKeys: ['consolidated_findings', 'pr_number', 'repo_full_name'],
        label: 'Post PR comment',
      ),
      x: 720,
      y: 120,
    ),
    PipelineStepDefinition(
      id: '$commentId\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_$commentId',
      triggers: const [
        StepTrigger(sourceStepIds: [commentId]),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'cross_review',
    workspaceId: workspaceId,
    name: 'Cross-review (security / perf / a11y)',
    description:
        'Manual-run alternative to PR review with a security, performance, '
        'and accessibility focus. Takes repo_full_name + pr_number as input.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [_repoFullNameInput(), _prNumberInput()],
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
// Tier 1 — Ticket → draft PR (the core "turn a work item into code" flow)
// ---------------------------------------------------------------------------

/// Clones the repo on a fresh branch, has a coder agent implement the ticket,
/// opens a draft PR, runs a self-review in parallel and posts the review as a
/// PR comment. Trigger payload: repoFullName, ticketId, ticketTitle, ticketBody.
PipelineDefinition _ticketToPrSeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const setupId = 'setup_branch';
  const implementId = 'implement';
  const openPrId = 'open_pr';
  const reviewId = 'self_review';
  const commentId = 'comment';

  final steps = <PipelineStepDefinition>[
    // The coder's room owns a copy-on-write copy of the linked checkout, which
    // `awaitReady` publishes as `repoLocalPath` — no second full copy of the
    // repository downloaded per run beside the worktree the agent is already
    // going to work in.
    _spaceStep(
      label: 'Create space for ticket {{ticket_id}}',
      spaceName: 'Implement {{ticket_id}} · {{ticket_title}}',
      agentIds: [agentIds.coder, agentIds.engineer],
      repoIds: const ['{{repo_id}}'],
      awaitReady: true,
      y: 120,
    ),
    PipelineStepDefinition(
      id: setupId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      triggers: const [
        StepTrigger(sourceStepIds: [_spaceStepId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Fetch + switch branch',
        inputKeys: ['repo_local_path', 'ticket_id'],
        timeoutMs: 180000,
        // `git switch -c` fails if the branch already exists (a re-run, a
        // crash-resume), so fall back to switching onto it rather than failing
        // the step on work that is already done.
        script:
            'set -euo pipefail\n'
            'cd "{{repo_local_path}}"\n'
            'TICKET="{{ticket_id}}"\n'
            'git fetch --quiet origin || true\n'
            'git switch -c "agent/\$TICKET" 2>/dev/null '
            '|| git switch "agent/\$TICKET"\n'
            'echo "on \$(git rev-parse --abbrev-ref HEAD)"',
      ),
      x: 0,
      y: 120,
    ),
    PipelineStepDefinition(
      id: implementId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(sourceStepIds: [setupId]),
      ],
      config: PipelineNodeConfig(
        agentId: agentIds.coder,
        label: 'Implement ticket',
        inputKeys: const [
          'repo_local_path',
          'ticket_id',
          'ticket_title',
          'ticket_body',
        ],
        // The room the `space` step opened holds the ticket's repo and both
        // agents; this node only names its own stream inside it.
        extras: _inRunSpace('Implement ticket'),
        outputKey: 'implement_summary',
        timeoutMs: 1800000,
        prompt:
            'You are a senior engineer. A working clone of the repo is at '
            '`{{repo_local_path}}` on branch `agent/{{ticket_id}}`.\n\n'
            'Implement this ticket:\n'
            '# {{ticket_title}}\n{{ticket_body}}\n\n'
            'Make the change, follow the repo conventions, run any obvious '
            'checks, then `git add -A && git commit`. Reply with a short '
            'summary of what you changed.',
      ),
      x: 240,
      y: 120,
    ),
    PipelineStepDefinition(
      id: openPrId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      triggers: const [
        StepTrigger(sourceStepIds: [implementId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Open draft PR',
        inputKeys: ['repo_local_path', 'ticket_id', 'ticket_title'],
        outputKey: 'pr_number',
        timeoutMs: 120000,
        script:
            'set -euo pipefail\n'
            'cd "{{repo_local_path}}"\n'
            'TICKET="{{ticket_id}}"\n'
            'git push -u origin "agent/\$TICKET"\n'
            'gh pr create --draft --title "{{ticket_title}}" '
            '--body "Automated draft PR for ticket \$TICKET." '
            '--head "agent/\$TICKET" >/dev/null\n'
            "gh pr view \"agent/\$TICKET\" --json number --jq '.number'",
      ),
      x: 480,
      y: 0,
    ),
    PipelineStepDefinition(
      id: reviewId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(sourceStepIds: [implementId]),
      ],
      config: PipelineNodeConfig(
        agentId: agentIds.engineer,
        label: 'Self review',
        inputKeys: const ['repo_local_path', 'ticket_title'],
        extras: _inRunSpace('Self review'),
        outputKey: 'consolidated_findings',
        timeoutMs: 900000,
        prompt:
            'You are a reviewer. The change for "{{ticket_title}}" is '
            'committed in the clone at `{{repo_local_path}}` on branch '
            '`agent/...`. Review the diff (`git diff main...HEAD`).\n\n'
            'Return a concise GitHub-flavoured Markdown review: correctness, '
            'missing tests and risks, with `path:line` references.',
      ),
      x: 480,
      y: 240,
    ),
    PipelineStepDefinition(
      id: commentId,
      kind: StepKind.join,
      bodyKey: BuiltInBodyKeys.prReviewComment,
      triggers: const [
        StepTrigger(sourceStepIds: [openPrId, reviewId]),
      ],
      waitForStepIds: const [openPrId, reviewId],
      config: const PipelineNodeConfig(
        label: 'Post self-review',
        inputKeys: ['consolidated_findings', 'pr_number', 'repo_full_name'],
      ),
      x: 720,
      y: 120,
    ),
    PipelineStepDefinition(
      id: '$commentId\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_$commentId',
      triggers: const [
        StepTrigger(sourceStepIds: [commentId]),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'ticket_to_pr',
    workspaceId: workspaceId,
    name: 'Ticket → draft PR',
    description:
        'Clones a fresh branch, has a coder agent implement the ticket, opens '
        'a draft PR, self-reviews and posts the review. Provide repo_full_name, '
        'ticket_id, ticket_title, ticket_body.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [
      _repoFullNameInput(),
      PipelineInput(
        key: 'ticket_id',
        label: 'Ticket ID',
        required: true,
        placeholder: 'ENG-123',
        helpText: 'Used for the branch name (agent/<ticket_id>).',
      ),
      PipelineInput(key: 'ticket_title', label: 'Ticket title', required: true),
      PipelineInput(
        key: 'ticket_body',
        label: 'Ticket description',
        type: PipelineInputType.multiline,
        helpText: 'What the agent should implement.',
      ),
    ],
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
// Tier 1 — PR triage (router): classify, then route to a tailored reviewer
// ---------------------------------------------------------------------------

/// Classifies an incoming PR and routes to a tailored review depending on the
/// class, saving agent tokens on trivial PRs. Demonstrates the router.
PipelineDefinition _prTriageSeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const classifyId = 'classify';
  const switchId = 'route';

  PipelineStepDefinition branchReview({
    required String stepId,
    required String routeKey,
    required String agentId,
    required String label,
    required String prompt,
    required double y,
  }) {
    return PipelineStepDefinition(
      id: stepId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: [
        StepTrigger(sourceStepIds: const [switchId], routeKey: routeKey),
      ],
      config: PipelineNodeConfig(
        agentId: agentId,
        label: label,
        inputKeys: const ['repo_local_path', 'pr_title', 'pr_number'],
        // The chosen branch's reviewer joins the run's room when it is
        // dispatched — which is why the space node seeds only the classifier,
        // the one agent every path runs.
        extras: _inRunSpace(label),
        outputKey: 'consolidated_findings',
        timeoutMs: 900000,
        prompt: prompt,
      ),
      x: 720,
      y: y,
    );
  }

  PipelineStepDefinition branchComment({
    required String stepId,
    required String sourceId,
    required double y,
  }) {
    return PipelineStepDefinition(
      id: stepId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.prReviewComment,
      triggers: [
        StepTrigger(sourceStepIds: [sourceId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Post comment',
        inputKeys: ['consolidated_findings', 'pr_number', 'repo_full_name'],
      ),
      x: 960,
      y: y,
    );
  }

  final steps = <PipelineStepDefinition>[
    // The PR's room, checked out at the PR head as a copy-on-write copy of the
    // linked checkout. See `_spaceStep`.
    _spaceStep(
      label: 'PR triage #{{pr_number}}',
      agentIds: [agentIds.qa],
      pr: true,
      awaitReady: true,
      x: 0,
      y: 120,
    ),
    PipelineStepDefinition(
      id: classifyId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(sourceStepIds: [_spaceStepId]),
      ],
      config: PipelineNodeConfig(
        agentId: agentIds.qa,
        label: 'Classify PR',
        inputKeys: const ['repo_local_path', 'pr_title', 'pr_number'],
        extras: _inRunSpace('Classify PR'),
        outputKey: 'pr_class',
        timeoutMs: 300000,
        prompt:
            'The PR branch is checked out at `{{repo_local_path}}` '
            '(PR #{{pr_number}} — {{pr_title}}). Inspect the diff '
            '(`git diff main...HEAD --stat`).\n\n'
            'Classify the PR. Reply with EXACTLY ONE word:\n'
            '- `docs` if it only touches documentation / comments\n'
            '- `security` if it touches auth, crypto, dependencies, or '
            'network/credential handling\n'
            '- `standard` otherwise.',
      ),
      x: 240,
      y: 120,
    ),
    PipelineStepDefinition(
      id: switchId,
      kind: StepKind.router,
      bodyKey: BuiltInBodyKeys.condition,
      triggers: const [
        StepTrigger(sourceStepIds: [classifyId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Route by class',
        inputKeys: ['pr_class'],
        extras: {
          'switchKey': 'pr_class',
          'cases': ['docs', 'security', 'standard'],
          'default': 'standard',
        },
      ),
      x: 480,
      y: 120,
    ),
    branchReview(
      stepId: 'docs_review',
      routeKey: 'docs',
      agentId: agentIds.librarian,
      label: 'Docs check',
      prompt:
          'Docs-only PR at `{{repo_local_path}}` (#{{pr_number}} — '
          '{{pr_title}}). Quickly check clarity, broken links and accuracy. '
          'Return a short GitHub-flavoured Markdown comment.',
      y: 0,
    ),
    branchReview(
      stepId: 'security_review',
      routeKey: 'security',
      agentId: agentIds.architect,
      label: 'Security review',
      prompt:
          'Security-sensitive PR at `{{repo_local_path}}` (#{{pr_number}} — '
          '{{pr_title}}). Focus on injection, secrets, dependency changes and '
          'input validation. Return findings as Markdown with `path:line`.',
      y: 120,
    ),
    branchReview(
      stepId: 'standard_review',
      routeKey: 'standard',
      agentId: agentIds.engineer,
      label: 'Standard review',
      prompt:
          'PR at `{{repo_local_path}}` (#{{pr_number}} — {{pr_title}}). '
          'Review correctness, tests and code quality. Return findings as '
          'Markdown with `path:line`.',
      y: 240,
    ),
    branchComment(stepId: 'docs_comment', sourceId: 'docs_review', y: 0),
    branchComment(
      stepId: 'security_comment',
      sourceId: 'security_review',
      y: 120,
    ),
    branchComment(
      stepId: 'standard_comment',
      sourceId: 'standard_review',
      y: 240,
    ),
    PipelineStepDefinition(
      id: 'triage\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_triage',
      // ONE trigger listing every branch, not one trigger per branch: a
      // terminal is reached when its sources are all terminal (completed OR
      // skipped) and at least one genuinely completed, so the router's two
      // unchosen branches — which are skipped — still let the run finish.
      // This is also the only form persistence can represent (edges are
      // regrouped by target on load), so authoring it here keeps the seed
      // value-identical to the row a re-seed reads back.
      triggers: const [
        StepTrigger(
          sourceStepIds: [
            'docs_comment',
            'security_comment',
            'standard_comment',
          ],
        ),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'pr_triage',
    workspaceId: workspaceId,
    name: 'PR triage (router)',
    description:
        'Classifies a PR (docs / security / standard) and routes to a tailored '
        'review, saving tokens on trivial PRs. Provide repo_full_name + pr_number.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [_repoFullNameInput(), _prNumberInput()],
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
// Tier 1 — Pre-merge approval gate (human-in-the-loop + router)
// ---------------------------------------------------------------------------

/// Reviews a PR, then pauses for a lead/CEO approval before merging. Approve
/// via the `approve_step` MCP tool, reject via `reject_step`.
PipelineDefinition _preMergeGateSeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const reviewId = 'review';
  const gateId = 'gate';
  const routeId = 'route';
  const mergeId = 'merge';
  const rejectId = 'notify_changes';

  final steps = <PipelineStepDefinition>[
    // The PR's room, checked out at the PR head as a copy-on-write copy of the
    // linked checkout. See `_spaceStep`.
    _spaceStep(
      label: 'Pre-merge gate #{{pr_number}}',
      agentIds: [agentIds.engineer, agentIds.ceo],
      pr: true,
      awaitReady: true,
      x: 0,
      y: 60,
    ),
    PipelineStepDefinition(
      id: reviewId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(sourceStepIds: [_spaceStepId]),
      ],
      config: PipelineNodeConfig(
        agentId: agentIds.engineer,
        label: 'Review',
        inputKeys: const ['repo_local_path', 'pr_title', 'pr_number'],
        extras: _inRunSpace('Review'),
        outputKey: 'consolidated_findings',
        timeoutMs: 900000,
        prompt:
            'Review PR #{{pr_number}} — {{pr_title}} at `{{repo_local_path}}`. '
            'Summarize correctness and risk as Markdown.',
      ),
      x: 240,
      y: 60,
    ),
    PipelineStepDefinition(
      id: gateId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.humanGate,
      triggers: const [
        StepTrigger(sourceStepIds: [reviewId]),
      ],
      config: PipelineNodeConfig(
        agentId: agentIds.ceo,
        label: 'Approval gate',
        inputKeys: const ['consolidated_findings', 'pr_number'],
        extras: _inRunSpace('Approval gate'),
        outputKey: 'approval_decision',
        prompt:
            'Review findings for PR #{{pr_number}} before merge:\n\n'
            '{{consolidated_findings}}\n\n'
            'Approve to squash-merge, or reject to request changes.',
      ),
      x: 480,
      y: 60,
    ),
    PipelineStepDefinition(
      id: routeId,
      kind: StepKind.router,
      bodyKey: BuiltInBodyKeys.condition,
      triggers: const [
        StepTrigger(sourceStepIds: [gateId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Approved?',
        inputKeys: ['approval_decision'],
        extras: {
          'switchKey': 'approval_decision',
          'cases': ['approved', 'rejected'],
          'default': 'rejected',
        },
      ),
      x: 720,
      y: 60,
    ),
    PipelineStepDefinition(
      id: mergeId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      triggers: const [
        StepTrigger(sourceStepIds: [routeId], routeKey: 'approved'),
      ],
      config: const PipelineNodeConfig(
        label: 'Squash merge',
        inputKeys: ['repo_full_name', 'pr_number'],
        outputKey: 'merge_result',
        timeoutMs: 120000,
        // Merging is not idempotent — never auto-re-run it on crash-resume.
        extras: {'idempotent': false},
        script:
            'set -euo pipefail\n'
            'gh pr merge "{{pr_number}}" --repo "{{repo_full_name}}" --squash\n'
            'echo "merged"',
      ),
      x: 960,
      y: 0,
    ),
    PipelineStepDefinition(
      id: rejectId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      triggers: const [
        StepTrigger(sourceStepIds: [routeId], routeKey: 'rejected'),
      ],
      config: const PipelineNodeConfig(
        label: 'Request changes',
        inputKeys: ['repo_full_name', 'pr_number'],
        outputKey: 'notify_result',
        timeoutMs: 60000,
        script:
            'set -euo pipefail\n'
            'gh pr comment "{{pr_number}}" --repo "{{repo_full_name}}" '
            '--body "Changes requested by the pre-merge gate."\n'
            'echo "notified"',
      ),
      x: 960,
      y: 120,
    ),
    PipelineStepDefinition(
      id: 'gate\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_gate',
      // One trigger listing both branches — see `triage$terminal`.
      triggers: const [
        StepTrigger(sourceStepIds: [mergeId, rejectId]),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'pre_merge_gate',
    workspaceId: workspaceId,
    name: 'Pre-merge approval gate',
    description:
        'Reviews a PR then pauses for lead approval before squash-merging. '
        'Approve via approve_step, reject via reject_step. Provide '
        'repo_full_name + pr_number.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [_repoFullNameInput(), _prNumberInput()],
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
// Tier 2 — Release notes compiler (on PrMerged)
// ---------------------------------------------------------------------------

/// Collects the merged commit range and drafts a categorized changelog entry.
PipelineDefinition _releaseNotesSeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const collectId = 'collect';
  const draftId = 'draft';

  final steps = <PipelineStepDefinition>[
    // No repo: the drafter reshapes a commit log the `collect` step already
    // gathered. It used to mint a conversation that checked out every repo in
    // the workspace to write a changelog entry.
    _spaceStep(
      label: 'Create space for release notes #{{pr_number}}',
      spaceName: 'Release notes · PR #{{pr_number}}',
      agentIds: [agentIds.librarian],
    ),
    _afterSpace(
      PipelineStepDefinition(
        id: collectId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.bashScript,
        config: const PipelineNodeConfig(
          label: 'Collect commits',
          inputKeys: ['repo_full_name', 'pr_number'],
          outputKey: 'commit_log',
          timeoutMs: 120000,
          script:
              'set -euo pipefail\n'
              'REPO="{{repo_full_name}}"\n'
              'PR="{{pr_number}}"\n'
              'gh pr view "\$PR" --repo "\$REPO" '
              '--json title,commits '
              "--jq '.title, (.commits[].messageHeadline)' 2>/dev/null "
              '|| echo "(commit log unavailable)"',
        ),
        x: 0,
        y: 0,
      ),
    ),
    PipelineStepDefinition(
      id: draftId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(sourceStepIds: [collectId]),
      ],
      config: PipelineNodeConfig(
        agentId: agentIds.librarian,
        label: 'Draft release notes',
        inputKeys: const ['commit_log'],
        extras: _inRunSpace('Draft release notes'),
        outputKey: 'release_notes',
        timeoutMs: 300000,
        prompt:
            'Given these merged commits:\n\n{{commit_log}}\n\n'
            'Draft a changelog entry grouped into Features / Fixes / Chores '
            '(conventional-commit aware). Output GitHub-flavoured Markdown.',
      ),
      x: 240,
      y: 0,
    ),
    PipelineStepDefinition(
      id: '$draftId\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_$draftId',
      triggers: const [
        StepTrigger(sourceStepIds: [draftId]),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'release_notes',
    workspaceId: workspaceId,
    name: 'Release notes',
    description:
        'On a merged PR, collects the commit range and drafts a categorized '
        'changelog entry. Triggered on PrMerged. Provide repo_full_name + pr_number.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [_repoFullNameInput(), _prNumberInput()],
    steps: List.unmodifiable(steps),
  );
}

// Meeting summarization — augment-my-notes
// ---------------------------------------------------------------------------

/// Augments a meeting's live notes from its transcript, then persists the
/// result DETERMINISTICALLY: the agent step returns ONE structured payload
/// (`{summary, enhancedNotes, actionItems[], decisions[]}`) and three in-app
/// persist steps write each part to its own table. Nothing is scraped out of
/// the notes markdown, so the summary stays clean and action items / decisions
/// are reliable structured rows.
///
/// Started programmatically by the meeting recorder — once when a recording
/// stops (the `MeetingRecordingStopped` event trigger) and again from the
/// detail screen's "Re-run summary" (the manual trigger, e.g. after the user
/// edits their personal notes). The transcript + user notes are passed in the
/// run's trigger payload and interpolated into the prompt as `{{...}}`.
///
/// Flow: `summarize` (agent → `meetingOutcome`) fans out to THREE parallel
/// persist steps — `save_notes` (`meeting.saveNotes`), `add_action_items`
/// (`meeting.addActionItems`), `add_decisions` (`meeting.addDecisions`) — which
/// join at the terminal (its single trigger lists all three sources, so the run
/// completes only once all three finish). None of them flips the meeting to
/// `done`; the `MeetingSummaryReconciler` does that once the run terminates
/// (success OR failure), so a single persist failure can't strand a half-written
/// meeting that's already marked done. The agent calls NO meeting MCP tools —
/// it returns its structured result via the `submit_output` tool (there is no
/// ticket); the engine harvests it into `meetingOutcome`.
PipelineDefinition _meetingSummarySeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const diarizeId = 'diarize';
  const identifySpeakersId = 'identify_speakers';
  const updateTranscriptId = 'update_transcript';
  const assemblePlaybackId = 'assemble_playback';
  const summarizeId = 'summarize';
  const saveNotesId = 'save_notes';
  const actionItemsId = 'add_action_items';
  const decisionsId = 'add_decisions';
  final steps = <PipelineStepDefinition>[
    // No repo: summarizing a meeting reads a transcript and the user's notes,
    // nothing on disk. Its conversation used to be minted with no repo scope at
    // all, which meant checking out EVERY repo in the workspace to write notes.
    // `chat` mirrors the summarize step's own mode override — the room a step
    // runs in must not silently change the permissions it runs with.
    _spaceStep(
      label: 'Create space for {{title}} summary',
      // Placeholder LAST: a meeting with no title renders it empty, and
      // `renderStepLabel` drops a trailing separator but not a leading one — so
      // this degrades to "Meeting summary", never to "· meeting summary".
      spaceName: 'Meeting summary · {{title}}',
      agentIds: [agentIds.ceo],
      mode: 'chat',
      x: -760,
      y: 120,
    ),
    // Entry step: offline speaker diarization. Relabels the transcript's
    // "them" (or in-person mic) segments into individual speakers and rewrites
    // the `transcript` state the summarize step reads. No-op when no audio was
    // retained / the diarization models aren't installed — the original
    // transcript flows through unchanged.
    _afterSpace(
      PipelineStepDefinition(
        id: diarizeId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.meetingDiarize,
        config: const PipelineNodeConfig(
          label: 'Identify speakers',
          inputKeys: ['meeting_id', 'transcript'],
        ),
        x: -520,
        y: 120,
      ),
    ),
    // Cross-meeting recognition: matches each diarized speaker against the
    // workspace's saved voice profiles and auto-applies a confident match's
    // name. Sits between diarize and summarize so the recognized names flow into
    // the summary transcript. Best-effort — a no-op when there are no profiles.
    PipelineStepDefinition(
      id: identifySpeakersId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.meetingIdentifySpeakers,
      triggers: const [
        StepTrigger(sourceStepIds: [diarizeId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Match known speakers',
        inputKeys: ['meeting_id', 'transcript'],
      ),
      x: -260,
      y: 120,
    ),
    // Runs in PARALLEL with summarize (both fan out from diarize): re-separates
    // the transcript into clean per-speaker turns from the diarization spans and
    // persists it. Decoupled from summarize so the cleaned transcript lands as
    // soon as it's ready instead of waiting on the (slow) summarizer agent.
    PipelineStepDefinition(
      id: updateTranscriptId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.meetingUpdateTranscript,
      triggers: const [
        StepTrigger(sourceStepIds: [diarizeId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Update transcript',
        inputKeys: ['meeting_id', 'diarization_spans'],
      ),
      // Same column as its sibling fan-outs off diarize, stacked above them.
      x: -260,
      y: 0,
    ),
    // Folds the retained per-channel WAVs into mixed.wav for playback. Runs in
    // parallel with summarize (off the diarize fan-out); independent of the
    // agent, so playback is ready as soon as the recording is processed.
    PipelineStepDefinition(
      id: assemblePlaybackId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.meetingAssemblePlayback,
      triggers: const [
        StepTrigger(sourceStepIds: [diarizeId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Assemble playback audio',
        inputKeys: ['meeting_id'],
      ),
      x: -260,
      y: -120,
    ),
    PipelineStepDefinition(
      id: summarizeId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      // Fans out from identify_speakers (not diarize) so any voice-profile names
      // it auto-applied are already in the transcript this step summarizes.
      triggers: const [
        StepTrigger(sourceStepIds: [identifySpeakersId]),
      ],
      config: PipelineNodeConfig(
        agentId: agentIds.ceo,
        label: 'Summarize meeting',
        inputKeys: const [
          'meeting_id',
          'title',
          'user_notes',
          'transcript',
          'workspace_id',
        ],
        outputKey: 'meeting_outcome',
        outputSchema: MeetingOutcome.schema,
        timeoutMs: 1800000,
        // Run as a plain task agent (`chat`), not the promptAgent default of
        // `review`. Review/plan modes map to Claude's `--permission-mode plan`,
        // which is read-only — wrong for a content-generation step. The agent
        // returns its structured result via `submit_output`; there is no
        // ticket. NOTE: the resolver reads `extras['mode']` (see
        // `_resolveMode`), so the key MUST be `mode`, not
        // `conversationMode`, or the override is silently ignored.
        extras: {'mode': 'chat', ..._inRunSpace('Meeting summary')},
        prompt:
            'You are augmenting meeting notes for the meeting titled '
            '"{{title}}".\n\n'
            'Below is the speaker-tagged transcript and the user\'s own rough '
            'live notes. ME = the user running this app. The other participants '
            'appear either as THEM or, when speaker diarization has run, as '
            'distinct labels like "Person 1" / "Person 2" (or names the user '
            'assigned) — treat each distinct label as a different person. Read '
            'both, then produce a faithful, well-structured result. '
            'Expand the user\'s rough notes using the transcript, KEEP every '
            'point the user wrote (never drop their notes) and do NOT '
            'invent facts unsupported by the transcript or the notes.\n\n'
            'Return your result as the `output` argument to the '
            '`submit_output` tool — a single JSON object with these keys '
            '(do NOT wrap it in a "result" key and do NOT call any '
            'other tool):\n'
            '  - "title": a string — a concise 3-7 word title derived from the '
            'content (e.g. "Q3 roadmap planning"). Omit if the transcript is '
            'too thin to title confidently.\n'
            '  - "summary": a string — a 1-3 sentence executive summary. Keep '
            'it clean: do NOT list decisions or action items here.\n'
            '  - "enhancedNotes": a string of clean meeting notes in markdown, '
            'the narrative only — again, no decisions / action-items section.\n'
            '  - "actionItems": an array of objects, one per concrete follow-up '
            'task, each {"text": "<the action>", "owner": "<who owns it, or '
            'omit>"}. Use [] if there are none.\n'
            '  - "decisions": an array of strings, one per decision the group '
            'reached. Use [] if there are none.\n'
            '  - "speakerNames": an object mapping a speaker label that appears '
            'in the transcript (e.g. "Person 1") to that person\'s real name — '
            'but ONLY when the transcript explicitly reveals it (someone says '
            '"Hi, I\'m Dana", "this is Dana", or another speaker addresses them '
            'by name). Never guess from role or context. Omit any speaker whose '
            'name is not explicitly stated and use {} when none are. Do not map '
            '"ME" — that is the user.\n\n'
            'If template instructions are provided below, follow them for the '
            'structure, emphasis and tone of the notes:\n'
            r'<instructions>{{$trigger.summary_instructions}}</instructions>'
            '\n\n'
            '<user_notes>\n{{user_notes}}\n</user_notes>\n\n'
            '<transcript>\n{{transcript}}\n</transcript>',
      ),
      x: 0,
      y: 120,
    ),
    PipelineStepDefinition(
      id: saveNotesId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.meetingSaveNotes,
      triggers: const [
        StepTrigger(sourceStepIds: [summarizeId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Save notes',
        inputKeys: ['meeting_id', 'meeting_outcome'],
      ),
      x: 260,
      y: 0,
    ),
    PipelineStepDefinition(
      id: actionItemsId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.meetingAddActionItems,
      triggers: const [
        StepTrigger(sourceStepIds: [summarizeId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Add action items',
        inputKeys: ['meeting_id', 'meeting_outcome'],
      ),
      x: 260,
      y: 120,
    ),
    PipelineStepDefinition(
      id: decisionsId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.meetingAddDecisions,
      triggers: const [
        StepTrigger(sourceStepIds: [summarizeId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Add decisions',
        inputKeys: ['meeting_id', 'meeting_outcome'],
      ),
      x: 260,
      y: 240,
    ),
    // Joins the three parallel persist steps AND the parallel transcript-update
    // step: the run completes only once every source has finished (downstream
    // planner requires every sourceStepId to be terminal). The meeting is
    // finalized to `done` by MeetingSummaryReconciler.
    PipelineStepDefinition(
      id: 'meeting\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_meeting',
      triggers: const [
        StepTrigger(
          sourceStepIds: [
            saveNotesId,
            actionItemsId,
            decisionsId,
            updateTranscriptId,
            assemblePlaybackId,
          ],
        ),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'meeting_summary',
    workspaceId: workspaceId,
    name: 'Meeting summarization',
    description:
        'Augments your live meeting notes from the transcript and persists a '
        'clean summary, the enhanced notes and structured action items + '
        'decisions to their own records. Runs automatically when a recording '
        'stops, or on demand via "Re-run summary".',
    isBuiltIn: true,
    inputs: [
      PipelineInput(key: 'meeting_id', label: 'Meeting ID', required: true),
      PipelineInput(key: 'title', label: 'Meeting title'),
      PipelineInput(
        key: 'user_notes',
        label: 'Your notes',
        type: PipelineInputType.multiline,
      ),
      PipelineInput(
        key: 'transcript',
        label: 'Transcript',
        type: PipelineInputType.multiline,
      ),
    ],
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
// Tier 2 — Dependency / CVE audit (static fan-out)
// ---------------------------------------------------------------------------

/// Clones the repo, then — per ecosystem — checks whether its manifest exists
/// before dispatching an auditor agent. A `fileExists` router gates each
/// language so we never burn agent tokens auditing a manifest the repo doesn't
/// have. The surviving branches converge on a consolidation join; skipped
/// branches don't stall it.
PipelineDefinition _depAuditSeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const consolidateId = 'consolidate';

  // A `fileExists` router that routes "true" when any of [manifests] is present
  // in the room's checkout, gating the matching auditor.
  PipelineStepDefinition checkNode({
    required String id,
    required String label,
    required List<String> manifests,
    required double y,
  }) {
    return PipelineStepDefinition(
      id: id,
      kind: StepKind.router,
      bodyKey: BuiltInBodyKeys.condition,
      triggers: const [
        StepTrigger(sourceStepIds: [_spaceStepId]),
      ],
      config: PipelineNodeConfig(
        label: label,
        inputKeys: const ['repo_local_path'],
        extras: {
          'predicate': {
            'type': 'fileExists',
            'paths': manifests,
            'baseKey': 'repo_local_path',
          },
        },
      ),
      x: 260,
      y: y,
    );
  }

  // The auditor agent for an ecosystem — only reached on the router's "true"
  // edge, so its prompt no longer needs an "if absent, reply n/a" escape hatch.
  PipelineStepDefinition auditNode({
    required String id,
    required String checkId,
    required String label,
    required String manifest,
    required double y,
  }) {
    return PipelineStepDefinition(
      id: id,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: [
        StepTrigger(sourceStepIds: [checkId], routeKey: 'true'),
      ],
      config: PipelineNodeConfig(
        agentId: agentIds.architect,
        label: label,
        inputKeys: const ['repo_local_path'],
        // Up to five auditors run off the same clone. Each keeps its own
        // stream in the run's one room rather than minting a room — and a
        // checkout — of its own.
        extras: _inRunSpace(label),
        outputKey: '${id}_findings',
        timeoutMs: 900000,
        prompt:
            'The repo is cloned at `{{repo_local_path}}`. Audit the '
            '`$manifest` dependency manifest(s) for known-vulnerable or '
            'outdated dependencies. Return findings grouped by severity with '
            'package + version.',
      ),
      x: 520,
      y: y,
    );
  }

  final steps = <PipelineStepDefinition>[
    // The room's worktree is a copy-on-write copy of the linked checkout, and
    // `awaitReady` publishes its path as `repoLocalPath` — which is what the
    // manifest routers probe and the auditors read.
    _spaceStep(
      label: 'Create space for {{repo_name}} dependency audit',
      spaceName: 'Dependency audit · {{repo_name}}',
      agentIds: [agentIds.architect, agentIds.ceo],
      repoIds: const ['{{repo_id}}'],
      awaitReady: true,
      x: 0,
      y: 220,
    ),
    checkNode(
      id: 'check_dart',
      label: 'Dart manifest?',
      manifests: const ['pubspec.yaml', 'pubspec.lock'],
      y: 0,
    ),
    auditNode(
      id: 'audit_dart',
      checkId: 'check_dart',
      label: 'Dart deps',
      manifest: 'pubspec.lock',
      y: 0,
    ),
    checkNode(
      id: 'check_rust',
      label: 'Rust manifest?',
      manifests: const ['Cargo.toml', 'Cargo.lock'],
      y: 110,
    ),
    auditNode(
      id: 'audit_rust',
      checkId: 'check_rust',
      label: 'Rust deps',
      manifest: 'Cargo.lock',
      y: 110,
    ),
    checkNode(
      id: 'check_npm',
      label: 'npm manifest?',
      manifests: const ['package-lock.json'],
      y: 220,
    ),
    auditNode(
      id: 'audit_npm',
      checkId: 'check_npm',
      label: 'npm deps',
      manifest: 'package-lock.json',
      y: 220,
    ),
    checkNode(
      id: 'check_pnpm',
      label: 'pnpm manifest?',
      manifests: const ['pnpm-lock.yaml'],
      y: 330,
    ),
    auditNode(
      id: 'audit_pnpm',
      checkId: 'check_pnpm',
      label: 'pnpm deps',
      manifest: 'pnpm-lock.yaml',
      y: 330,
    ),
    checkNode(
      id: 'check_yarn',
      label: 'yarn manifest?',
      manifests: const ['yarn.lock'],
      y: 440,
    ),
    auditNode(
      id: 'audit_yarn',
      checkId: 'check_yarn',
      label: 'yarn deps',
      manifest: 'yarn.lock',
      y: 440,
    ),
    PipelineStepDefinition(
      id: consolidateId,
      kind: StepKind.join,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(
          sourceStepIds: [
            'audit_dart',
            'audit_rust',
            'audit_npm',
            'audit_pnpm',
            'audit_yarn',
          ],
        ),
      ],
      waitForStepIds: const [
        'audit_dart',
        'audit_rust',
        'audit_npm',
        'audit_pnpm',
        'audit_yarn',
      ],
      config: PipelineNodeConfig(
        agentId: agentIds.ceo,
        label: 'Consolidate audit',
        inputKeys: const [
          'audit_dart_findings',
          'audit_rust_findings',
          'audit_npm_findings',
          'audit_pnpm_findings',
          'audit_yarn_findings',
        ],
        extras: _inRunSpace('Consolidate audit'),
        outputKey: 'consolidated_findings',
        timeoutMs: 600000,
        prompt:
            'Consolidate the dependency-audit findings into one report, '
            'grouped by severity. Ecosystems whose manifest was absent were '
            'skipped and will be blank — omit them:\n\n'
            '## Dart\n{{audit_dart_findings}}\n\n'
            '## Rust\n{{audit_rust_findings}}\n\n'
            '## npm\n{{audit_npm_findings}}\n\n'
            '## pnpm\n{{audit_pnpm_findings}}\n\n'
            '## yarn\n{{audit_yarn_findings}}',
      ),
      x: 800,
      y: 220,
    ),
    PipelineStepDefinition(
      id: '$consolidateId\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_$consolidateId',
      triggers: const [
        StepTrigger(sourceStepIds: [consolidateId]),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'dep_audit',
    workspaceId: workspaceId,
    name: 'Dependency / CVE audit',
    description:
        'Clones the repo, then checks for each ecosystem\'s manifest before '
        'auditing it — Dart / Rust / npm / pnpm / yarn run only when present, '
        'then consolidate. Provide repo_full_name.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [_repoFullNameInput()],
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
// Tier 1 — PR digest to a messaging space (scheduled / on-merge)
// ---------------------------------------------------------------------------

/// Gathers open + recently-merged PRs and posts a stand-up digest to a space.
/// Provide repoFullName + spaceId (the latter via trigger payload / state).
PipelineDefinition _prDigestSeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const gatherId = 'gather';
  const summarizeId = 'summarize';
  const postId = 'post';

  final steps = <PipelineStepDefinition>[
    // No repo: the digest reshapes JSON `gh pr list` already returned. On the
    // scheduled trigger there is no `repoId` in the payload either, so the old
    // per-step room fell back to cloning the whole workspace — nightly.
    _spaceStep(
      label: 'Create space for {{repo_name}} PR digest',
      spaceName: 'PR digest · {{repo_name}}',
      agentIds: [agentIds.librarian],
    ),
    _afterSpace(
      PipelineStepDefinition(
        id: gatherId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.bashScript,
        config: const PipelineNodeConfig(
          label: 'Gather PRs',
          inputKeys: ['repo_full_name'],
          outputKey: 'pr_json',
          timeoutMs: 120000,
          script:
              'set -euo pipefail\n'
              'gh pr list --repo "{{repo_full_name}}" --state open '
              '--json number,title,author,updatedAt,isDraft '
              '--limit 50 2>/dev/null || echo "[]"',
        ),
        x: 0,
        y: 0,
      ),
    ),
    PipelineStepDefinition(
      id: summarizeId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(sourceStepIds: [gatherId]),
      ],
      config: PipelineNodeConfig(
        agentId: agentIds.librarian,
        label: 'Summarize digest',
        inputKeys: const ['pr_json'],
        extras: _inRunSpace('Summarize digest'),
        outputKey: 'content',
        timeoutMs: 300000,
        prompt:
            'Turn this open-PR JSON into a concise Markdown stand-up '
            'digest — group into "Awaiting review", "Drafts" and "Stale '
            '(>3 days)". Be brief.\n\n{{pr_json}}',
      ),
      x: 240,
      y: 0,
    ),
    PipelineStepDefinition(
      id: postId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.messagingPostSpace,
      triggers: const [
        StepTrigger(sourceStepIds: [summarizeId]),
      ],
      config: const PipelineNodeConfig(
        label: 'Post digest',
        inputKeys: ['space_id', 'content'],
        outputKey: 'posted_space_id',
      ),
      x: 480,
      y: 0,
    ),
    PipelineStepDefinition(
      id: 'digest\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_digest',
      triggers: const [
        StepTrigger(sourceStepIds: [postId]),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'pr_digest',
    workspaceId: workspaceId,
    name: 'PR digest',
    description:
        'Gathers open PRs and posts a stand-up digest to a space. Pair with a '
        'scheduled trigger. Provide repo_full_name + space_id.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [
      _repoFullNameInput(),
      PipelineInput(
        key: 'space_id',
        label: 'Space ID',
        required: true,
        helpText: 'Messaging space the digest is posted to.',
      ),
    ],
    steps: List.unmodifiable(steps),
  );
}

/// Background code indexing, triggered by `RepoAdded`. A single self-contained
/// step walks the repo, extracts symbols/edges with tree-sitter (in worker
/// isolates) and ingests them into the code graph. Enabled by default; the
/// step no-ops gracefully when the tree-sitter natives aren't installed.
/// The agentless built-in code-indexing template for [workspaceId]. Exposed so
/// it can be ensured independently of the agent-based templates (e.g. a startup
/// re-seed for workspaces created before the template existed).
PipelineDefinition indexCodeTemplate(String workspaceId) =>
    _triggerFirst(_indexCodeSeed(workspaceId: workspaceId));

/// The `skill_analysis` builtin (the skills antivirus as a pipeline): one
/// agentless scan step over the workspace's installed skills. Agentless, so
/// like `index_code` it is always ensured — even for workspaces whose
/// specialist agents aren't available.
PipelineDefinition skillAnalysisTemplate(String workspaceId) => _triggerFirst(
  PipelineDefinition(
    templateId: SkillAnalysisTemplate.id,
    workspaceId: workspaceId,
    name: 'Skill analysis',
    description:
        'Re-scans installed skills with the antivirus (static rules + '
        'capability manifest) and enforces quarantines. Runs when a skill is '
        'installed, updated, edited, or changed on disk — disable this '
        'template to stop the automatic runs.',
    isBuiltIn: true,
    inputs: [
      PipelineInput(
        key: 'skill_slug',
        label: 'Skill (optional)',
        helpText: 'Leave empty to scan every installed skill.',
      ),
    ],
    steps: List.unmodifiable([
      PipelineStepDefinition(
        id: SkillAnalysisTemplate.scanStepId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.skillAnalysis,
        config: const PipelineNodeConfig(
          label: 'Scan installed skills',
          inputKeys: ['workspace_id', 'skill_slug'],
          outputKey: 'skill_scan_summary',
          timeoutMs: 600000,
        ),
        x: 0,
        y: 0,
      ),
      // Without this sentinel `planDownstream` can never report
      // `terminalReached`, so the run sits at "Running" forever after its scan
      // step completes — and its dedup key then blocks every later run for the
      // same skill. Every seed needs one; `builtin_template_seeds_test.dart`
      // pins that.
      PipelineStepDefinition(
        id: '${SkillAnalysisTemplate.scanStepId}\$terminal',
        kind: StepKind.terminal,
        bodyKey: '_terminal_${SkillAnalysisTemplate.scanStepId}',
        triggers: const [
          StepTrigger(sourceStepIds: [SkillAnalysisTemplate.scanStepId]),
        ],
      ),
    ]),
  ),
);

/// The one stream `index_code` works in. Named once because the space node
/// opens it and the `analyze` step reuses it BY TITLE — two spellings would
/// leave the room holding two conversations.
const String _analysisConversationTitle = 'Architecture analysis';

PipelineDefinition _indexCodeSeed({
  required String workspaceId,
  String? librarianAgentId,
}) {
  final indexStep = PipelineStepDefinition(
    id: IndexCodeTemplate.indexStepId,
    kind: StepKind.listen,
    bodyKey: BuiltInBodyKeys.indexCode,
    config: const PipelineNodeConfig(
      label: 'Index repository code',
      inputKeys: ['workspace_id', 'repo_id', 'repo_local_path'],
      outputKey: 'index_summary',
      timeoutMs: 1800000,
    ),
    x: 0,
    y: 0,
  );

  final steps = <PipelineStepDefinition>[];

  // When a librarian agent is available, dispatch it to study the freshly
  // indexed code and record durable architecture/feature facts in memory.
  // (The indexing step itself writes no facts — only the code graph.)
  if (librarianAgentId != null) {
    steps.add(indexStep);
    // The room opens off the indexer, not before it: a run only earns a
    // conversation — and the copy-on-write checkout of the indexed repo that
    // comes with it — once there is a graph for the librarian to read.
    //
    // It opens holding the librarian's stream, under the same title the
    // `analyze` step names, which is what keeps the room at ONE conversation.
    // The analysis takes minutes; a room with no stream at all mints an
    // untitled standing one the moment anything reads it (the sidebar, the
    // step-detail panel), and the run then shows two conversations where the
    // work only ever happened in one.
    steps.add(
      _spaceStep(
        label: 'Create space for {{repo_name}} analyse',
        spaceName: 'Architecture analysis · {{repo_name}}',
        agentIds: [librarianAgentId],
        repoIds: const ['{{repo_id}}'],
        conversationTitle: _analysisConversationTitle,
        after: const [IndexCodeTemplate.indexStepId],
        x: 260,
      ),
    );
    steps.add(
      PipelineStepDefinition(
        id: 'analyze',
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.promptAgent,
        triggers: const [
          StepTrigger(sourceStepIds: [_spaceStepId]),
        ],
        config: PipelineNodeConfig(
          agentId: librarianAgentId,
          label: 'Analyze architecture',
          inputKeys: const [
            'workspace_id',
            'repo_id',
            'repo_local_path',
            'index_summary',
          ],
          // The room the `space` step opened owns the checkout — scoped to the
          // repo being indexed — so this node declares no `repoIds` of its own.
          extras: _inRunSpace(_analysisConversationTitle),
          outputKey: 'analysis',
          prompt:
              'The repository (id: {{repo_id}}) was just (re-)indexed into the '
              'code graph for workspace {{workspace_id}}. This pipeline runs on '
              'EVERY index, so your job is to RECONCILE existing workspace '
              'memory with the current state of the code — never to blindly '
              're-state what is already recorded (that accumulates '
              'near-duplicate facts).\n\n'
              '1. Review what is already known: call search_memory (and '
              'list_policies) for workspace {{workspace_id}} to load the '
              'existing architecture/feature facts and policies, with their '
              'ids.\n'
              '2. Study the current code with the code tools (search_code, '
              'code_symbol, code_callers, code_callees, code_impact) — always '
              'pass workspace_id: {{workspace_id}} and repo_id: {{repo_id}} so '
              'you query this workspace\'s graph.\n'
              '3. Reconcile:\n'
              '   • If an existing fact is now OUTDATED or contradicted, record '
              'the corrected fact with propose_fact, then call supersede_fact '
              '(fact_id: <old>, superseding_fact_id: <new>) so the stale one '
              'stops surfacing.\n'
              '   • If several existing facts are DUPLICATES of each other (the '
              'same knowledge worded differently — common after repeated '
              'indexing), keep the single clearest one and supersede the rest '
              'with supersede_fact, pointing each redundant fact at the '
              'keeper\'s id.\n'
              '   • If an existing policy no longer holds, call supersede_policy '
              '(policy_id: <old>); if a corrected rule still applies, '
              'propose_policy the new one.\n'
              '   • If an existing fact/policy is still accurate, LEAVE IT — do '
              'NOT re-propose it.\n'
              '   • Only propose genuinely NEW, durable, high-signal knowledge '
              'not already captured: overall architecture and layering, the '
              'main features and capabilities, key modules and their '
              'responsibilities, important entry points and notable '
              'conventions or patterns.\n\n'
              'Use appropriate domains (e.g. architecture, features) for '
              'workspace {{workspace_id}}. Focus on lasting, high-level '
              'understanding — not file-by-file detail.',
        ),
        x: 520,
        y: 0,
      ),
    );
    steps.add(
      PipelineStepDefinition(
        id: 'analyze\$terminal',
        kind: StepKind.terminal,
        bodyKey: '_terminal_analyze',
        triggers: const [
          StepTrigger(sourceStepIds: ['analyze']),
        ],
      ),
    );
  } else {
    // No agent, so no conversation: the agentless form indexes and stops.
    steps.add(indexStep);
    steps.add(
      PipelineStepDefinition(
        id: 'index\$terminal',
        kind: StepKind.terminal,
        bodyKey: '_terminal_index',
        triggers: const [
          StepTrigger(sourceStepIds: ['index']),
        ],
      ),
    );
  }

  return PipelineDefinition(
    templateId: IndexCodeTemplate.id,
    workspaceId: workspaceId,
    name: 'Index repository code',
    description: librarianAgentId != null
        ? "Parses a repository's source with tree-sitter into a code graph "
              '(symbols + edges) for code search, then dispatches the librarian '
              'to record architecture & feature facts. Triggered when a repo is '
              'added; safe to re-run (incremental).'
        : "Parses a repository's source with tree-sitter into a code graph "
              '(symbols + edges) for code search. Triggered when a repo is '
              'added; safe to re-run (incremental).',
    isBuiltIn: true,
    // Indexing is the one built-in that is CPU-bound end to end (walk + hash,
    // tree-sitter extraction, ONNX embedding, then a batched write against the
    // workspace's single DB connection). Adding a repo to a workspace that
    // already has several fires one run per repo, and running them at once
    // fights over the same cores and the same writer. Capped at one: the extra
    // runs queue and go through back to back, which finishes sooner than N
    // contending and leaves the machine usable meanwhile.
    maxParallelRuns: 1,
    inputs: [
      PipelineInput(
        key: 'repo_id',
        label: 'Repository',
        type: PipelineInputType.repo,
        required: true,
        helpText: 'Pick a repository in this workspace to index.',
      ),
    ],
    steps: List.unmodifiable(steps),
  );
}
