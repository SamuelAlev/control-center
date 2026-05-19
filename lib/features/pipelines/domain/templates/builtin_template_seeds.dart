import 'package:control_center/core/domain/events/pr_events.dart' show ExternalPrDetected, PrMerged;
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_trigger.dart';
import 'package:control_center/features/teams/domain/entities/team.dart' show Team;

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
  static const String promptAgent = 'pipeline.promptAgent';

  /// Posts the consolidated findings as a PR comment.
  static const String prReviewComment = 'prReview.comment';

  /// Posts a message to a messaging channel via MessagingPort.
  static const String messagingPostChannel = 'messaging.postChannel';

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

  /// Creates a ticket via the vendor-agnostic ticketing service (used by
  /// escalation flows).
  static const String createTicket = 'pipeline.createTicket';

  /// Map / fan-out: runs an agent task per item in a state collection.
  static const String forEach = 'flow.forEach';

  /// Runs another pipeline template as a nested sub-step.
  static const String callFlow = 'flow.callPipeline';

  /// Demo bodies used by the hello template.
  static const String helloGreet = 'hello.greet';
  /// The "Hello, world!" body key.
  static const String helloWorld = 'hello.world';

  /// Background code indexer (tree-sitter → code graph). Walks a repo, extracts
  /// symbols + edges, and ingests them. Triggered by `RepoAdded`.
  static const String indexCode = 'code.index';

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
  /// transcript segments, and rewrites the `transcript` state so the downstream
  /// summarize step sees per-speaker context. No-op (passes the transcript
  /// through unchanged) when no audio was retained or the models aren't
  /// installed. See `registerMeetingBodies`.
  static const String meetingDiarize = 'meeting.diarize';
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

/// The trigger rows seeded for each built-in template, keyed by templateId.
/// Templates absent from this map ship with no triggers.
Map<String, List<BuiltInTriggerSeed>> builtInTriggerSeeds() => {
      'pr_review': const [BuiltInTriggerSeed.manual()],
      'external_pr_welcome': const [
        BuiltInTriggerSeed.event('ExternalPrDetected'),
      ],
      'pr_merged_cleanup': const [
        BuiltInTriggerSeed.event(
          'PullRequestStatusChanged',
          match: {
            'status': ['merged', 'closed'],
          },
        ),
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
      'ci_autofix': const [BuiltInTriggerSeed.manual()],
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
      // Two triggers: the event fired when a recording stops (auto), and
      // manual — used by the detail screen's "Re-run summary" (e.g. after
      // editing your personal notes) and the pipelines run page.
      'meeting_summary': const [
        BuiltInTriggerSeed.event('MeetingRecordingStopped'),
        BuiltInTriggerSeed.manual(),
      ],
      'hello': const [BuiltInTriggerSeed.manual()],
    };

/// Built-in templates that ship manually runnable. Derived from
/// [builtInTriggerSeeds] so the run page and seeding stay in sync.
Set<String> get manualRunnableBuiltInTemplateIds => {
      for (final entry in builtInTriggerSeeds().entries)
        if (entry.value
            .any((t) => t.eventType == PipelineTrigger.manualEventType))
          entry.key,
    };

// Shared input field builders for the built-in manual-run pipelines. These are
// seed defaults (data layer, no BuildContext) so the English labels/help are
// hardcoded — same convention as the built-in agent/prompt copy in this file.

PipelineInput _repoFullNameInput() => PipelineInput(
      key: 'repoFullName',
      label: 'Repository',
      type: PipelineInputType.repo,
      required: true,
      helpText: 'Pick a repository in this workspace.',
    );

PipelineInput _prNumberInput() => PipelineInput(
      key: 'prNumber',
      label: 'PR number',
      type: PipelineInputType.number,
      required: true,
      placeholder: '123',
    );

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
    _prMergedCleanupSeed(workspaceId: workspaceId),
    _crossReviewSeed(workspaceId: workspaceId, agentIds: agentIds),
    _ticketToPrSeed(workspaceId: workspaceId, agentIds: agentIds),
    _prTriageSeed(workspaceId: workspaceId, agentIds: agentIds),
    _preMergeGateSeed(workspaceId: workspaceId, agentIds: agentIds),
    _releaseNotesSeed(workspaceId: workspaceId, agentIds: agentIds),
    _ciAutofixSeed(workspaceId: workspaceId, agentIds: agentIds),
    _depAuditSeed(workspaceId: workspaceId, agentIds: agentIds),
    _prDigestSeed(workspaceId: workspaceId, agentIds: agentIds),
    _indexCodeSeed(
      workspaceId: workspaceId,
      librarianAgentId: agentIds.librarian,
    ),
    _meetingSummarySeed(workspaceId: workspaceId, agentIds: agentIds),
    _helloSeed(workspaceId: workspaceId),
  ].map(_triggerFirst).toList();
}

/// Rewrites [def] so it begins with the mandatory [StepKind.trigger] entry
/// node. The seed's own entry work-node — the first non-terminal step authored
/// with no inbound edges — is rewired to fire from the trigger, and the trigger
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
      triggers: const [StepTrigger(sourceStepIds: [triggerId])],
      waitForStepIds: s.waitForStepIds,
      config: s.config,
      x: s.x,
      y: s.y,
    );
  });
  return def.copyWith(steps: List.unmodifiable([triggerNode, ...rewired]));
}

PipelineDefinition _prReviewSeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const setupId = 'setup';
  const qaId = 'qa_review';
  const archId = 'architect_review';
  const engId = 'engineer_review';
  const consolidateId = 'consolidate';
  const commentId = 'comment';

  PipelineStepDefinition reviewer({
    required String stepId,
    required String agentId,
    required String label,
    required String prompt,
    required double x,
    required double y,
  }) {
    return PipelineStepDefinition(
      id: stepId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [StepTrigger(sourceStepIds: [setupId])],
      config: PipelineNodeConfig(
        agentId: agentId,
        inputKeys: const [
          'repoLocalPath',
          'prTitle',
          'prBody',
          'headRef',
          'repoFullName',
          'prNumber',
        ],
        outputKey: '${stepId}_findings',
        label: label,
        prompt: prompt,
      ),
      x: x,
      y: y,
    );
  }

  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: setupId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: const PipelineNodeConfig(
        label: 'Clone PR branch',
        inputKeys: ['repoFullName', 'prNumber'],
        outputKey: 'repoLocalPath',
        script:
            'set -euo pipefail\n'
            'REPO="{{repoFullName}}"\n'
            'PR_NUMBER="{{prNumber}}"\n'
            'TARGET="repo"\n'
            '\n'
            '# gh uses GITHUB_TOKEN when set, otherwise falls back to the '
            'local `gh auth` login.\n'
            'BRANCH=\$(gh pr view "\$PR_NUMBER" --repo "\$REPO" '
            "--json headRefName --jq '.headRefName')\n"
            'gh repo clone "\$REPO" "\$TARGET" -- --branch "\$BRANCH" '
            '--depth 50 --single-branch\n'
            'echo -n "\$(pwd)/\$TARGET"',
      ),
      x: 0,
      y: 120,
    ),
    reviewer(
      stepId: qaId,
      agentId: agentIds.qa,
      label: 'QA review',
      prompt:
          'You are a QA reviewer. The PR branch is checked out at '
          '`{{repoLocalPath}}`. PR #{{prNumber}} — {{prTitle}}.\n\n'
          'Focus on:\n'
          '- whether the change is covered by tests, missing edge-case '
          'tests, and brittle assertions.\n'
          '- regression risk in adjacent code paths.\n\n'
          'Return findings as a bulleted list. Use `path:line` references '
          'when possible.',
      x: 240,
      y: 0,
    ),
    reviewer(
      stepId: archId,
      agentId: agentIds.architect,
      label: 'Architect review',
      prompt:
          'You are an architecture reviewer. The PR branch is checked out '
          'at `{{repoLocalPath}}`. PR #{{prNumber}} — {{prTitle}}.\n\n'
          'Focus on code quality, layering boundaries, dead/duplicated '
          'code, and missed reuse opportunities. Call out anything that '
          'violates existing patterns in the repo. Return a bulleted list '
          'of findings with `path:line` references.',
      x: 240,
      y: 120,
    ),
    reviewer(
      stepId: engId,
      agentId: agentIds.engineer,
      label: 'Engineer review',
      prompt:
          'You are the engineer reviewer. The PR branch is checked out at '
          '`{{repoLocalPath}}`. PR #{{prNumber}} — {{prTitle}}.\n\n'
          'Focus on implementation details, correctness, and obvious bugs. '
          'Return a bulleted list of findings with `path:line` references.',
      x: 240,
      y: 240,
    ),
    PipelineStepDefinition(
      id: consolidateId,
      kind: StepKind.join,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [
        StepTrigger(sourceStepIds: [qaId, archId, engId]),
      ],
      waitForStepIds: const [qaId, archId, engId],
      config: PipelineNodeConfig(
        agentId: agentIds.ceo,
        inputKeys: const [
          'qa_review_findings',
          'architect_review_findings',
          'engineer_review_findings',
          'prTitle',
          'prNumber',
        ],
        outputKey: 'consolidatedFindings',
        label: 'Consolidate findings',
        prompt:
            'You are the lead reviewer. Consolidate the specialist findings '
            'into a single well-structured report for PR #{{prNumber}} — '
            '{{prTitle}}.\n\n'
            '## QA\n{{qa_review_findings}}\n\n'
            '## Architecture\n{{architect_review_findings}}\n\n'
            '## Engineering\n{{engineer_review_findings}}\n\n'
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
      triggers: const [StepTrigger(sourceStepIds: [consolidateId])],
      config: const PipelineNodeConfig(
        inputKeys: ['consolidatedFindings', 'prNumber', 'repoFullName'],
        label: 'Post PR comment',
      ),
      x: 720,
      y: 120,
    ),
    PipelineStepDefinition(
      id: '$commentId\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_$commentId',
      triggers: const [StepTrigger(sourceStepIds: [commentId])],
    ),
  ];

  return PipelineDefinition(
    templateId: 'pr_review',
    workspaceId: workspaceId,
    name: 'PR review',
    description:
        'Clones the PR branch, runs QA / architecture / engineer reviewers '
        'in parallel, consolidates their findings, and posts a GitHub '
        'comment.',
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
        inputKeys: ['repoOwner', 'repoName', 'prNumber', 'author'],
        outputKey: 'welcomeCommentUrl',
        script:
            'set -euo pipefail\n'
            'OWNER="{{repoOwner}}"\n'
            'REPO="{{repoName}}"\n'
            'PR="{{prNumber}}"\n'
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
      triggers: const [StepTrigger(sourceStepIds: [greetId])],
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
// Tier 0 / Tier 1 — PR merged cleanup
// ---------------------------------------------------------------------------

/// Triggered by [PrMerged]. Prunes the merged worktree and drafts a
/// release-note entry via a prompt agent.
PipelineDefinition _prMergedCleanupSeed({required String workspaceId}) {
  const pruneId = 'prune';
  const draftId = 'draft_notes';
  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: pruneId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: const PipelineNodeConfig(
        label: 'Prune merged worktree',
        inputKeys: ['prId'],
        outputKey: 'pruneResult',
        script:
            'set -euo pipefail\n'
            'PR_ID="{{prId}}"\n'
            '# Remove any worktree associated with this PR. Best-effort; '
            '# the worktree may already have been cleaned up.\n'
            'WORKTREE_DIR="\$HOME/.control-center/worktrees/pr-\$PR_ID"\n'
            'if [ -d "\$WORKTREE_DIR" ]; then\n'
            '  git -C "\$WORKTREE_DIR" worktree remove "\$WORKTREE_DIR" '
            '--force 2>/dev/null || rm -rf "\$WORKTREE_DIR"\n'
            '  echo "pruned \$WORKTREE_DIR"\n'
            'else\n'
            '  echo "no worktree to prune at \$WORKTREE_DIR"\n'
            'fi',
      ),
      x: 0,
      y: 0,
    ),
    PipelineStepDefinition(
      id: draftId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [StepTrigger(sourceStepIds: [pruneId])],
      config: const PipelineNodeConfig(
        label: 'Draft release notes',
        inputKeys: ['pruneResult', 'prId'],
        outputKey: 'releaseNotes',
        prompt:
            'A PR was just merged ({{prId}}). The worktree cleanup status: '
            '{{pruneResult}}.\n\n'
            'Draft a one-line release-note entry describing the change. '
            'Keep it concise — one sentence, imperative mood. Output just '
            'the note text.',
      ),
      x: 240,
      y: 0,
    ),
    PipelineStepDefinition(
      id: '$draftId\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_$draftId',
      triggers: const [StepTrigger(sourceStepIds: [draftId])],
    ),
  ];

  return PipelineDefinition(
    templateId: 'pr_merged_cleanup',
    workspaceId: workspaceId,
    name: 'PR merged cleanup',
    description:
        'Prunes the merged worktree and drafts a release-note entry. '
        'Triggered automatically on PrMerged.',
    isBuiltIn: true,
    isEnabled: false,
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
        StepTrigger(sourceStepIds: ['clone']),
      ],
      config: PipelineNodeConfig(
        agentId: agentId,
        inputKeys: const [
          'repoLocalPath',
          'prTitle',
          'prBody',
          'prNumber',
          'repoFullName',
        ],
        outputKey: '${stepId}_findings',
        label: label,
        prompt: prompt,
      ),
      x: 240,
      y: y,
    );
  }

  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: 'clone',
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: const PipelineNodeConfig(
        label: 'Clone PR branch',
        inputKeys: ['repoFullName', 'prNumber'],
        outputKey: 'repoLocalPath',
        script:
            'set -euo pipefail\n'
            'REPO="{{repoFullName}}"\n'
            'PR_NUMBER="{{prNumber}}"\n'
            'TARGET="repo"\n'
            '\n'
            'BRANCH=\$(gh pr view "\$PR_NUMBER" --repo "\$REPO" '
            "--json headRefName --jq '.headRefName')\n"
            'gh repo clone "\$REPO" "\$TARGET" -- --branch "\$BRANCH" '
            '--depth 50 --single-branch\n'
            'echo -n "\$(pwd)/\$TARGET"',
      ),
      x: 0,
      y: 120,
    ),
    specialist(
      stepId: securityId,
      agentId: agentIds.architect,
      label: 'Security review',
      prompt:
          'You are a security reviewer. The PR branch is checked out at '
          '`{{repoLocalPath}}`. PR #{{prNumber}} — {{prTitle}}.\n\n'
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
          '`{{repoLocalPath}}`. PR #{{prNumber}} — {{prTitle}}.\n\n'
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
          'at `{{repoLocalPath}}`. PR #{{prNumber}} — {{prTitle}}.\n\n'
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
        StepTrigger(
          sourceStepIds: [securityId, perfId, a11yId],
        ),
      ],
      waitForStepIds: const [securityId, perfId, a11yId],
      config: PipelineNodeConfig(
        agentId: agentIds.ceo,
        inputKeys: const [
          'security_review_findings',
          'perf_review_findings',
          'a11y_review_findings',
          'prTitle',
          'prNumber',
        ],
        outputKey: 'consolidatedFindings',
        label: 'Consolidate findings',
        prompt:
            'You are the lead reviewer. Consolidate the specialist findings '
            'into a single well-structured report for PR #{{prNumber}} — '
            '{{prTitle}}.\n\n'
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
      triggers: const [StepTrigger(sourceStepIds: [consolidateId])],
      config: const PipelineNodeConfig(
        inputKeys: ['consolidatedFindings', 'prNumber', 'repoFullName'],
        label: 'Post PR comment',
      ),
      x: 720,
      y: 120,
    ),
    PipelineStepDefinition(
      id: '$commentId\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_$commentId',
      triggers: const [StepTrigger(sourceStepIds: [commentId])],
    ),
  ];

  return PipelineDefinition(
    templateId: 'cross_review',
    workspaceId: workspaceId,
    name: 'Cross-review (security / perf / a11y)',
    description:
        'Manual-run alternative to PR review with a security, performance, '
        'and accessibility focus. Takes repoFullName + prNumber as input.',
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
/// opens a draft PR, runs a self-review in parallel, and posts the review as a
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
    PipelineStepDefinition(
      id: setupId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: const PipelineNodeConfig(
        label: 'Clone + branch',
        inputKeys: ['repoFullName', 'ticketId'],
        outputKey: 'repoLocalPath',
        timeoutMs: 180000,
        script: 'set -euo pipefail\n'
            'REPO="{{repoFullName}}"\n'
            'TICKET="{{ticketId}}"\n'
            'gh repo clone "\$REPO" repo -- --depth 1\n'
            'cd repo\n'
            'git checkout -b "agent/\$TICKET"\n'
            'echo -n "\$(pwd)"',
      ),
      x: 0,
      y: 120,
    ),
    PipelineStepDefinition(
      id: implementId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [StepTrigger(sourceStepIds: [setupId])],
      config: PipelineNodeConfig(
        agentId: agentIds.coder,
        label: 'Implement ticket',
        inputKeys: const [
          'repoLocalPath',
          'ticketId',
          'ticketTitle',
          'ticketBody',
        ],
        outputKey: 'implementSummary',
        timeoutMs: 1800000,
        prompt: 'You are a senior engineer. A working clone of the repo is at '
            '`{{repoLocalPath}}` on branch `agent/{{ticketId}}`.\n\n'
            'Implement this ticket:\n'
            '# {{ticketTitle}}\n{{ticketBody}}\n\n'
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
      triggers: const [StepTrigger(sourceStepIds: [implementId])],
      config: const PipelineNodeConfig(
        label: 'Open draft PR',
        inputKeys: ['repoLocalPath', 'ticketId', 'ticketTitle'],
        outputKey: 'prNumber',
        timeoutMs: 120000,
        script: 'set -euo pipefail\n'
            'cd "{{repoLocalPath}}"\n'
            'TICKET="{{ticketId}}"\n'
            'git push -u origin "agent/\$TICKET"\n'
            'gh pr create --draft --title "{{ticketTitle}}" '
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
      triggers: const [StepTrigger(sourceStepIds: [implementId])],
      config: PipelineNodeConfig(
        agentId: agentIds.engineer,
        label: 'Self review',
        inputKeys: const ['repoLocalPath', 'ticketTitle'],
        outputKey: 'consolidatedFindings',
        timeoutMs: 900000,
        prompt: 'You are a reviewer. The change for "{{ticketTitle}}" is '
            'committed in the clone at `{{repoLocalPath}}` on branch '
            '`agent/...`. Review the diff (`git diff main...HEAD`).\n\n'
            'Return a concise GitHub-flavoured Markdown review: correctness, '
            'missing tests, and risks, with `path:line` references.',
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
        inputKeys: ['consolidatedFindings', 'prNumber', 'repoFullName'],
      ),
      x: 720,
      y: 120,
    ),
    PipelineStepDefinition(
      id: '$commentId\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_$commentId',
      triggers: const [StepTrigger(sourceStepIds: [commentId])],
    ),
  ];

  return PipelineDefinition(
    templateId: 'ticket_to_pr',
    workspaceId: workspaceId,
    name: 'Ticket → draft PR',
    description:
        'Clones a fresh branch, has a coder agent implement the ticket, opens '
        'a draft PR, self-reviews, and posts the review. Provide repoFullName, '
        'ticketId, ticketTitle, ticketBody.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [
      _repoFullNameInput(),
      PipelineInput(
        key: 'ticketId',
        label: 'Ticket ID',
        required: true,
        placeholder: 'ENG-123',
        helpText: 'Used for the branch name (agent/<ticketId>).',
      ),
      PipelineInput(
        key: 'ticketTitle',
        label: 'Ticket title',
        required: true,
      ),
      PipelineInput(
        key: 'ticketBody',
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
  const cloneId = 'clone';
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
        inputKeys: const ['repoLocalPath', 'prTitle', 'prNumber'],
        outputKey: 'consolidatedFindings',
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
      triggers: [StepTrigger(sourceStepIds: [sourceId])],
      config: const PipelineNodeConfig(
        label: 'Post comment',
        inputKeys: ['consolidatedFindings', 'prNumber', 'repoFullName'],
      ),
      x: 960,
      y: y,
    );
  }

  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: cloneId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: const PipelineNodeConfig(
        label: 'Clone PR branch',
        inputKeys: ['repoFullName', 'prNumber'],
        outputKey: 'repoLocalPath',
        timeoutMs: 180000,
        script: 'set -euo pipefail\n'
            'REPO="{{repoFullName}}"\n'
            'PR_NUMBER="{{prNumber}}"\n'
            'BRANCH=\$(gh pr view "\$PR_NUMBER" --repo "\$REPO" '
            "--json headRefName --jq '.headRefName')\n"
            'gh repo clone "\$REPO" repo -- --branch "\$BRANCH" '
            '--depth 50 --single-branch\n'
            'echo -n "\$(pwd)/repo"',
      ),
      x: 0,
      y: 120,
    ),
    PipelineStepDefinition(
      id: classifyId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [StepTrigger(sourceStepIds: [cloneId])],
      config: PipelineNodeConfig(
        agentId: agentIds.qa,
        label: 'Classify PR',
        inputKeys: const ['repoLocalPath', 'prTitle', 'prNumber'],
        outputKey: 'prClass',
        timeoutMs: 300000,
        prompt: 'The PR branch is checked out at `{{repoLocalPath}}` '
            '(PR #{{prNumber}} — {{prTitle}}). Inspect the diff '
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
      triggers: const [StepTrigger(sourceStepIds: [classifyId])],
      config: const PipelineNodeConfig(
        label: 'Route by class',
        inputKeys: ['prClass'],
        extras: {
          'switchKey': 'prClass',
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
      prompt: 'Docs-only PR at `{{repoLocalPath}}` (#{{prNumber}} — '
          '{{prTitle}}). Quickly check clarity, broken links, and accuracy. '
          'Return a short GitHub-flavoured Markdown comment.',
      y: 0,
    ),
    branchReview(
      stepId: 'security_review',
      routeKey: 'security',
      agentId: agentIds.architect,
      label: 'Security review',
      prompt: 'Security-sensitive PR at `{{repoLocalPath}}` (#{{prNumber}} — '
          '{{prTitle}}). Focus on injection, secrets, dependency changes, and '
          'input validation. Return findings as Markdown with `path:line`.',
      y: 120,
    ),
    branchReview(
      stepId: 'standard_review',
      routeKey: 'standard',
      agentId: agentIds.engineer,
      label: 'Standard review',
      prompt: 'PR at `{{repoLocalPath}}` (#{{prNumber}} — {{prTitle}}). '
          'Review correctness, tests, and code quality. Return findings as '
          'Markdown with `path:line`.',
      y: 240,
    ),
    branchComment(stepId: 'docs_comment', sourceId: 'docs_review', y: 0),
    branchComment(
        stepId: 'security_comment', sourceId: 'security_review', y: 120),
    branchComment(
        stepId: 'standard_comment', sourceId: 'standard_review', y: 240),
    PipelineStepDefinition(
      id: 'triage\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_triage',
      triggers: const [
        StepTrigger(sourceStepIds: ['docs_comment']),
        StepTrigger(sourceStepIds: ['security_comment']),
        StepTrigger(sourceStepIds: ['standard_comment']),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'pr_triage',
    workspaceId: workspaceId,
    name: 'PR triage (router)',
    description:
        'Classifies a PR (docs / security / standard) and routes to a tailored '
        'review, saving tokens on trivial PRs. Provide repoFullName + prNumber.',
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
  const cloneId = 'clone';
  const reviewId = 'review';
  const gateId = 'gate';
  const routeId = 'route';
  const mergeId = 'merge';
  const rejectId = 'notify_changes';

  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: cloneId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: const PipelineNodeConfig(
        label: 'Clone PR branch',
        inputKeys: ['repoFullName', 'prNumber'],
        outputKey: 'repoLocalPath',
        timeoutMs: 180000,
        script: 'set -euo pipefail\n'
            'REPO="{{repoFullName}}"\n'
            'PR_NUMBER="{{prNumber}}"\n'
            'BRANCH=\$(gh pr view "\$PR_NUMBER" --repo "\$REPO" '
            "--json headRefName --jq '.headRefName')\n"
            'gh repo clone "\$REPO" repo -- --branch "\$BRANCH" '
            '--depth 50 --single-branch\n'
            'echo -n "\$(pwd)/repo"',
      ),
      x: 0,
      y: 60,
    ),
    PipelineStepDefinition(
      id: reviewId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [StepTrigger(sourceStepIds: [cloneId])],
      config: PipelineNodeConfig(
        agentId: agentIds.engineer,
        label: 'Review',
        inputKeys: const ['repoLocalPath', 'prTitle', 'prNumber'],
        outputKey: 'consolidatedFindings',
        timeoutMs: 900000,
        prompt: 'Review PR #{{prNumber}} — {{prTitle}} at `{{repoLocalPath}}`. '
            'Summarize correctness and risk as Markdown.',
      ),
      x: 240,
      y: 60,
    ),
    PipelineStepDefinition(
      id: gateId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.humanGate,
      triggers: const [StepTrigger(sourceStepIds: [reviewId])],
      config: PipelineNodeConfig(
        agentId: agentIds.ceo,
        label: 'Approval gate',
        inputKeys: const ['consolidatedFindings', 'prNumber'],
        outputKey: 'approvalDecision',
        prompt: 'Review findings for PR #{{prNumber}} before merge:\n\n'
            '{{consolidatedFindings}}\n\n'
            'Approve to squash-merge, or reject to request changes.',
      ),
      x: 480,
      y: 60,
    ),
    PipelineStepDefinition(
      id: routeId,
      kind: StepKind.router,
      bodyKey: BuiltInBodyKeys.condition,
      triggers: const [StepTrigger(sourceStepIds: [gateId])],
      config: const PipelineNodeConfig(
        label: 'Approved?',
        inputKeys: ['approvalDecision'],
        extras: {
          'switchKey': 'approvalDecision',
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
        inputKeys: ['repoFullName', 'prNumber'],
        outputKey: 'mergeResult',
        timeoutMs: 120000,
        // Merging is not idempotent — never auto-re-run it on crash-resume.
        extras: {'idempotent': false},
        script: 'set -euo pipefail\n'
            'gh pr merge "{{prNumber}}" --repo "{{repoFullName}}" --squash\n'
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
        inputKeys: ['repoFullName', 'prNumber'],
        outputKey: 'notifyResult',
        timeoutMs: 60000,
        script: 'set -euo pipefail\n'
            'gh pr comment "{{prNumber}}" --repo "{{repoFullName}}" '
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
      triggers: const [
        StepTrigger(sourceStepIds: [mergeId]),
        StepTrigger(sourceStepIds: [rejectId]),
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
        'repoFullName + prNumber.',
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
    PipelineStepDefinition(
      id: collectId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: const PipelineNodeConfig(
        label: 'Collect commits',
        inputKeys: ['repoFullName', 'prNumber'],
        outputKey: 'commitLog',
        timeoutMs: 120000,
        script: 'set -euo pipefail\n'
            'REPO="{{repoFullName}}"\n'
            'PR="{{prNumber}}"\n'
            'gh pr view "\$PR" --repo "\$REPO" '
            '--json title,commits '
            "--jq '.title, (.commits[].messageHeadline)' 2>/dev/null "
            '|| echo "(commit log unavailable)"',
      ),
      x: 0,
      y: 0,
    ),
    PipelineStepDefinition(
      id: draftId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [StepTrigger(sourceStepIds: [collectId])],
      config: PipelineNodeConfig(
        agentId: agentIds.librarian,
        label: 'Draft release notes',
        inputKeys: const ['commitLog'],
        outputKey: 'releaseNotes',
        timeoutMs: 300000,
        prompt: 'Given these merged commits:\n\n{{commitLog}}\n\n'
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
      triggers: const [StepTrigger(sourceStepIds: [draftId])],
    ),
  ];

  return PipelineDefinition(
    templateId: 'release_notes',
    workspaceId: workspaceId,
    name: 'Release notes',
    description:
        'On a merged PR, collects the commit range and drafts a categorized '
        'changelog entry. Triggered on PrMerged. Provide repoFullName + prNumber.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [_repoFullNameInput(), _prNumberInput()],
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
// Tier 2 — CI failure auto-fix (router + ticket escalation)
// ---------------------------------------------------------------------------

/// Fetches failing checks, has a coder agent attempt a fix, then either
/// comments that a fix was pushed or escalates by filing a ticket.
PipelineDefinition _ciAutofixSeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const fetchId = 'fetch_logs';
  const diagnoseId = 'diagnose';
  const routeId = 'route';
  const commentId = 'comment_fixed';
  const escalateId = 'escalate';

  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: fetchId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: const PipelineNodeConfig(
        label: 'Fetch failing checks',
        inputKeys: ['repoFullName', 'prNumber'],
        outputKey: 'failureLog',
        timeoutMs: 120000,
        script: 'set -euo pipefail\n'
            'gh pr checks "{{prNumber}}" --repo "{{repoFullName}}" '
            '2>/dev/null | grep -i fail || echo "(no failing checks found)"',
      ),
      x: 0,
      y: 60,
    ),
    PipelineStepDefinition(
      id: diagnoseId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [StepTrigger(sourceStepIds: [fetchId])],
      config: PipelineNodeConfig(
        agentId: agentIds.coder,
        label: 'Diagnose + fix',
        inputKeys: const ['repoFullName', 'prNumber', 'failureLog'],
        outputKey: 'fixOutcome',
        timeoutMs: 1800000,
        prompt: 'CI is failing on PR #{{prNumber}} of {{repoFullName}}:\n\n'
            '{{failureLog}}\n\n'
            'Clone the branch, determine whether this is a real failure or '
            'flaky. If you can fix it, commit and push the fix. End your reply '
            'with a line `OUTCOME: fixed` or `OUTCOME: unfixable`.',
      ),
      x: 240,
      y: 60,
    ),
    PipelineStepDefinition(
      id: routeId,
      kind: StepKind.router,
      bodyKey: BuiltInBodyKeys.condition,
      triggers: const [StepTrigger(sourceStepIds: [diagnoseId])],
      config: const PipelineNodeConfig(
        label: 'Fixed?',
        inputKeys: ['fixOutcome'],
        extras: {
          'switchKey': 'fixOutcome',
          'cases': ['fixed', 'unfixable'],
          'default': 'unfixable',
        },
      ),
      x: 480,
      y: 60,
    ),
    PipelineStepDefinition(
      id: commentId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      triggers: const [
        StepTrigger(sourceStepIds: [routeId], routeKey: 'fixed'),
      ],
      config: const PipelineNodeConfig(
        label: 'Comment: fixed',
        inputKeys: ['repoFullName', 'prNumber'],
        outputKey: 'commentResult',
        timeoutMs: 60000,
        script: 'set -euo pipefail\n'
            'gh pr comment "{{prNumber}}" --repo "{{repoFullName}}" '
            '--body "🤖 Pushed an automated fix for the failing checks."\n'
            'echo "commented"',
      ),
      x: 720,
      y: 0,
    ),
    PipelineStepDefinition(
      id: escalateId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.createTicket,
      triggers: const [
        StepTrigger(sourceStepIds: [routeId], routeKey: 'unfixable'),
      ],
      config: const PipelineNodeConfig(
        label: 'Escalate to ticket',
        inputKeys: ['repoFullName', 'prNumber', 'failureLog', 'fixOutcome'],
        outputKey: 'escalationTicket',
        // teamId is only needed by remote providers that require a team.
        extras: {
          'title': 'CI failing on {{repoFullName}}#{{prNumber}}',
        },
        prompt: 'Automated CI auto-fix could not resolve the failure on '
            '{{repoFullName}} PR #{{prNumber}}.\n\nLog:\n{{failureLog}}\n\n'
            'Diagnosis:\n{{fixOutcome}}',
      ),
      x: 720,
      y: 120,
    ),
    PipelineStepDefinition(
      id: 'ci\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_ci',
      triggers: const [
        StepTrigger(sourceStepIds: [commentId]),
        StepTrigger(sourceStepIds: [escalateId]),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'ci_autofix',
    workspaceId: workspaceId,
    name: 'CI failure auto-fix',
    description:
        'Fetches failing checks, has a coder agent attempt a fix, then comments '
        'or escalates by filing a ticket. Provide repoFullName + prNumber.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [_repoFullNameInput(), _prNumberInput()],
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
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
/// stops (the `MeetingRecordingStopped` event trigger), and again from the
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
/// it returns its result through the pipeline's `complete_ticket` channel.
PipelineDefinition _meetingSummarySeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const diarizeId = 'diarize';
  const summarizeId = 'summarize';
  const saveNotesId = 'save_notes';
  const actionItemsId = 'add_action_items';
  const decisionsId = 'add_decisions';
  final steps = <PipelineStepDefinition>[
    // Entry step: offline speaker diarization. Relabels the transcript's
    // "them" (or in-person mic) segments into individual speakers and rewrites
    // the `transcript` state the summarize step reads. No-op when no audio was
    // retained / the diarization models aren't installed — the original
    // transcript flows through unchanged.
    PipelineStepDefinition(
      id: diarizeId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.meetingDiarize,
      config: const PipelineNodeConfig(
        label: 'Identify speakers',
        inputKeys: ['meetingId', 'transcript'],
      ),
      x: -260,
      y: 120,
    ),
    PipelineStepDefinition(
      id: summarizeId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [StepTrigger(sourceStepIds: [diarizeId])],
      config: PipelineNodeConfig(
        agentId: agentIds.ceo,
        label: 'Summarize meeting',
        inputKeys: const [
          'meetingId',
          'title',
          'userNotes',
          'transcript',
          'workspaceId',
        ],
        outputKey: 'meetingOutcome',
        timeoutMs: 1800000,
        prompt: 'You are augmenting meeting notes for the meeting titled '
            '"{{title}}".\n\n'
            'Below is the speaker-tagged transcript and the user\'s own rough '
            'live notes. ME = the user running this app. The other participants '
            'appear either as THEM or, when speaker diarization has run, as '
            'distinct labels like "Person 1" / "Person 2" (or names the user '
            'assigned) — treat each distinct label as a different person. Read '
            'both, then produce a faithful, well-structured result. '
            'Expand the user\'s rough notes using the transcript, and do NOT '
            'invent facts unsupported by the transcript or the notes.\n\n'
            'Return your result as the `output` argument to the '
            '`complete_ticket` tool — a single JSON object with EXACTLY these '
            'four keys (do NOT wrap it in a "result" key, and do NOT call any '
            'other tool):\n'
            '  - "summary": a string — a 1-3 sentence executive summary. Keep '
            'it clean: do NOT list decisions or action items here.\n'
            '  - "enhancedNotes": a string of clean meeting notes in markdown, '
            'the narrative only — again, no decisions / action-items section.\n'
            '  - "actionItems": an array of objects, one per concrete follow-up '
            'task, each {"text": "<the action>", "owner": "<who owns it, or '
            'omit>"}. Use [] if there are none.\n'
            '  - "decisions": an array of strings, one per decision the group '
            'reached. Use [] if there are none.\n\n'
            '<user_notes>\n{{userNotes}}\n</user_notes>\n\n'
            '<transcript>\n{{transcript}}\n</transcript>',
      ),
      x: 0,
      y: 120,
    ),
    PipelineStepDefinition(
      id: saveNotesId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.meetingSaveNotes,
      triggers: const [StepTrigger(sourceStepIds: [summarizeId])],
      config: const PipelineNodeConfig(
        label: 'Save notes',
        inputKeys: ['meetingId', 'meetingOutcome'],
      ),
      x: 260,
      y: 0,
    ),
    PipelineStepDefinition(
      id: actionItemsId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.meetingAddActionItems,
      triggers: const [StepTrigger(sourceStepIds: [summarizeId])],
      config: const PipelineNodeConfig(
        label: 'Add action items',
        inputKeys: ['meetingId', 'meetingOutcome'],
      ),
      x: 260,
      y: 120,
    ),
    PipelineStepDefinition(
      id: decisionsId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.meetingAddDecisions,
      triggers: const [StepTrigger(sourceStepIds: [summarizeId])],
      config: const PipelineNodeConfig(
        label: 'Add decisions',
        inputKeys: ['meetingId', 'meetingOutcome'],
      ),
      x: 260,
      y: 240,
    ),
    // Joins all three parallel persist steps: the run completes only once every
    // source has finished (downstream planner requires every sourceStepId to be
    // terminal). The meeting is finalized to `done` by MeetingSummaryReconciler.
    PipelineStepDefinition(
      id: 'meeting\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_meeting',
      triggers: const [
        StepTrigger(sourceStepIds: [saveNotesId, actionItemsId, decisionsId]),
      ],
    ),
  ];

  return PipelineDefinition(
    templateId: 'meeting_summary',
    workspaceId: workspaceId,
    name: 'Meeting summarization',
    description:
        'Augments your live meeting notes from the transcript and persists a '
        'clean summary, the enhanced notes, and structured action items + '
        'decisions to their own records. Runs automatically when a recording '
        'stops, or on demand via "Re-run summary".',
    isBuiltIn: true,
    inputs: [
      PipelineInput(
        key: 'meetingId',
        label: 'Meeting ID',
        required: true,
      ),
      PipelineInput(key: 'title', label: 'Meeting title'),
      PipelineInput(
        key: 'userNotes',
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
  const cloneId = 'clone';
  const consolidateId = 'consolidate';

  // A `fileExists` router that routes "true" when any of [manifests] is present
  // under the clone, gating the matching auditor.
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
      triggers: const [StepTrigger(sourceStepIds: [cloneId])],
      config: PipelineNodeConfig(
        label: label,
        inputKeys: const ['repoLocalPath'],
        extras: {
          'predicate': {
            'type': 'fileExists',
            'paths': manifests,
            'baseKey': 'repoLocalPath',
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
        inputKeys: const ['repoLocalPath'],
        outputKey: '${id}_findings',
        timeoutMs: 900000,
        prompt: 'The repo is cloned at `{{repoLocalPath}}`. Audit the '
            '`$manifest` dependency manifest(s) for known-vulnerable or '
            'outdated dependencies. Return findings grouped by severity with '
            'package + version.',
      ),
      x: 520,
      y: y,
    );
  }

  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: cloneId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: const PipelineNodeConfig(
        label: 'Clone repo',
        inputKeys: ['repoFullName'],
        outputKey: 'repoLocalPath',
        timeoutMs: 180000,
        script: 'set -euo pipefail\n'
            'gh repo clone "{{repoFullName}}" repo -- --depth 1\n'
            'echo -n "\$(pwd)/repo"',
      ),
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
        StepTrigger(sourceStepIds: [
          'audit_dart',
          'audit_rust',
          'audit_npm',
          'audit_pnpm',
          'audit_yarn',
        ]),
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
        outputKey: 'consolidatedFindings',
        timeoutMs: 600000,
        prompt: 'Consolidate the dependency-audit findings into one report, '
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
      triggers: const [StepTrigger(sourceStepIds: [consolidateId])],
    ),
  ];

  return PipelineDefinition(
    templateId: 'dep_audit',
    workspaceId: workspaceId,
    name: 'Dependency / CVE audit',
    description:
        'Clones the repo, then checks for each ecosystem\'s manifest before '
        'auditing it — Dart / Rust / npm / pnpm / yarn run only when present, '
        'then consolidate. Provide repoFullName.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [_repoFullNameInput()],
    steps: List.unmodifiable(steps),
  );
}

// ---------------------------------------------------------------------------
// Tier 1 — PR digest to a messaging channel (scheduled / on-merge)
// ---------------------------------------------------------------------------

/// Gathers open + recently-merged PRs and posts a stand-up digest to a channel.
/// Provide repoFullName + channelId (the latter via trigger payload / state).
PipelineDefinition _prDigestSeed({
  required String workspaceId,
  required BuiltInAgentIds agentIds,
}) {
  const gatherId = 'gather';
  const summarizeId = 'summarize';
  const postId = 'post';

  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: gatherId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      config: const PipelineNodeConfig(
        label: 'Gather PRs',
        inputKeys: ['repoFullName'],
        outputKey: 'prJson',
        timeoutMs: 120000,
        script: 'set -euo pipefail\n'
            'gh pr list --repo "{{repoFullName}}" --state open '
            '--json number,title,author,updatedAt,isDraft '
            '--limit 50 2>/dev/null || echo "[]"',
      ),
      x: 0,
      y: 0,
    ),
    PipelineStepDefinition(
      id: summarizeId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      triggers: const [StepTrigger(sourceStepIds: [gatherId])],
      config: PipelineNodeConfig(
        agentId: agentIds.librarian,
        label: 'Summarize digest',
        inputKeys: const ['prJson'],
        outputKey: 'content',
        timeoutMs: 300000,
        prompt: 'Turn this open-PR JSON into a concise Markdown stand-up '
            'digest — group into "Awaiting review", "Drafts", and "Stale '
            '(>3 days)". Be brief.\n\n{{prJson}}',
      ),
      x: 240,
      y: 0,
    ),
    PipelineStepDefinition(
      id: postId,
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.messagingPostChannel,
      triggers: const [StepTrigger(sourceStepIds: [summarizeId])],
      config: const PipelineNodeConfig(
        label: 'Post digest',
        inputKeys: ['channelId', 'content'],
        outputKey: 'postedChannelId',
      ),
      x: 480,
      y: 0,
    ),
    PipelineStepDefinition(
      id: 'digest\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_digest',
      triggers: const [StepTrigger(sourceStepIds: [postId])],
    ),
  ];

  return PipelineDefinition(
    templateId: 'pr_digest',
    workspaceId: workspaceId,
    name: 'PR digest',
    description:
        'Gathers open PRs and posts a stand-up digest to a channel. Pair with a '
        'scheduled trigger. Provide repoFullName + channelId.',
    isBuiltIn: true,
    isEnabled: false,
    inputs: [
      _repoFullNameInput(),
      PipelineInput(
        key: 'channelId',
        label: 'Channel ID',
        required: true,
        helpText: 'Messaging channel the digest is posted to.',
      ),
    ],
    steps: List.unmodifiable(steps),
  );
}

PipelineDefinition _helloSeed({required String workspaceId}) {
  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: 'greet',
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.helloGreet,
      config: const PipelineNodeConfig(label: 'Greet'),
      x: 0,
      y: 0,
    ),
    PipelineStepDefinition(
      id: 'world',
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.helloWorld,
      triggers: const [StepTrigger(sourceStepIds: ['greet'])],
      config: const PipelineNodeConfig(label: 'World'),
      x: 240,
      y: 0,
    ),
    PipelineStepDefinition(
      id: 'world\$terminal',
      kind: StepKind.terminal,
      bodyKey: '_terminal_world',
      triggers: const [StepTrigger(sourceStepIds: ['world'])],
    ),
  ];

  return PipelineDefinition(
    templateId: 'hello',
    workspaceId: workspaceId,
    name: 'Hello pipeline',
    description: 'Minimal demo pipeline: greet → world → terminal.',
    isBuiltIn: true,
    steps: List.unmodifiable(steps),
  );
}

/// Background code indexing, triggered by `RepoAdded`. A single self-contained
/// step walks the repo, extracts symbols/edges with tree-sitter (in worker
/// isolates), and ingests them into the code graph. Enabled by default; the
/// step no-ops gracefully when the tree-sitter natives aren't installed.
/// The agentless built-in code-indexing template for [workspaceId]. Exposed so
/// it can be ensured independently of the agent-based templates (e.g. a startup
/// re-seed for workspaces created before the template existed).
PipelineDefinition indexCodeTemplate(String workspaceId) =>
    _triggerFirst(_indexCodeSeed(workspaceId: workspaceId));

PipelineDefinition _indexCodeSeed({
  required String workspaceId,
  String? librarianAgentId,
}) {
  final steps = <PipelineStepDefinition>[
    PipelineStepDefinition(
      id: 'index',
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.indexCode,
      config: const PipelineNodeConfig(
        label: 'Index repository code',
        inputKeys: ['workspaceId', 'repoId', 'repoLocalPath'],
        outputKey: 'indexSummary',
        timeoutMs: 1800000,
      ),
      x: 0,
      y: 0,
    ),
  ];

  // When a librarian agent is available, dispatch it to study the freshly
  // indexed code and record durable architecture/feature facts in memory.
  // (The indexing step itself writes no facts — only the code graph.)
  if (librarianAgentId != null) {
    steps.add(
      PipelineStepDefinition(
        id: 'analyze',
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.promptAgent,
        triggers: const [
          StepTrigger(sourceStepIds: ['index']),
        ],
        config: PipelineNodeConfig(
          agentId: librarianAgentId,
          label: 'Analyze architecture',
          inputKeys: const [
            'workspaceId',
            'repoId',
            'repoLocalPath',
            'indexSummary',
          ],
          outputKey: 'analysis',
          prompt:
              'The repository (id: {{repoId}}) was just indexed into the code '
              'graph for workspace {{workspaceId}}. Study it with the code '
              'tools (search_code, code_symbol, code_callers, code_callees, '
              'code_impact) — always pass workspace_id: {{workspaceId}} and '
              'repo_id: {{repoId}} so you query this workspace\'s graph — then '
              'record durable, high-signal knowledge as memory facts: the '
              'overall architecture and layering, the main features and '
              'capabilities, key modules and their responsibilities, important '
              'entry points, and notable conventions or patterns. Propose facts '
              'via the memory tools under appropriate domains (e.g. '
              'architecture, features) for workspace {{workspaceId}}. Focus on '
              'lasting, high-level understanding — not file-by-file detail.',
        ),
        x: 260,
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
    templateId: 'index_code',
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
    inputs: [
      PipelineInput(
        key: 'repoId',
        label: 'Repository',
        type: PipelineInputType.repo,
        required: true,
        helpText: 'Pick a repository in this workspace to index.',
      ),
    ],
    steps: List.unmodifiable(steps),
  );
}
