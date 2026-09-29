import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_server_core/src/demo/demo_world.dart';

/// Demo-only template id. Not a product built-in: the seeder upserts it after
/// the built-in prune, and [kDemoPipelineTemplateIds] keeps the prune from
/// deleting it on the next pass.
const String kDemoReleaseChecksTemplateId = 'release_checks';

/// Shell steps and a file gate, so a demo run has something other than agent
/// prompts to open: the script that ran, and the transcript it printed.
///
/// Fictional. Nothing here executes — pipeline execution is refused on the
/// demo host. The graph exists so the run page has nodes whose input and
/// output are worth reading.
PipelineDefinition demoReleaseChecksTemplate(String workspaceId) {
  const fetchId = 'fetch';
  const testsId = 'run_tests';
  const analyzeId = 'analyze';
  const gateId = 'budget_gate';
  const diffId = 'diff_budget';
  const noteId = 'note_missing';
  const terminalId = 'checks\$terminal';

  const fetchScript =
      'set -euo pipefail\n'
      'cd "{{repo_local_path}}"\n'
      'git fetch --quiet origin\n'
      'git switch --detach origin/main\n'
      'pwd';
  const testScript =
      'set -euo pipefail\n'
      'cd "{{repo_local_path}}"\n'
      'python -m pytest -q --tb=line';
  const analyzeScript =
      'set -euo pipefail\n'
      'cd "{{repo_local_path}}"\n'
      'python -m compileall -q .\n'
      'echo "compileall: ok"';
  const diffScript =
      'set -euo pipefail\n'
      'cd "{{repo_local_path}}"\n'
      'git diff origin/main -- evalkit/budget.py';
  const noteScript =
      'set -euo pipefail\n'
      'cd "{{repo_local_path}}"\n'
      'echo "evalkit/budget.py is not in this checkout"';

  return PipelineDefinition(
    templateId: kDemoReleaseChecksTemplateId,
    workspaceId: workspaceId,
    name: 'Release checks',
    description:
        'Agentless cut checks. Fetches the checkout, runs the suite and a '
        'compile in parallel, then branches on whether evalkit/budget.py is '
        'present.',
    inputs: [
      PipelineInput(
        key: 'repo_local_path',
        label: 'Checkout',
        required: true,
        placeholder: '/workspace/helix/evalkit',
        helpText: 'Working copy the shell steps cd into.',
      ),
    ],
    steps: [
      PipelineStepDefinition(
        id: 'trigger',
        kind: StepKind.trigger,
        bodyKey: BuiltInBodyKeys.trigger,
        config: const PipelineNodeConfig(label: 'Trigger'),
        x: 0,
        y: 120,
      ),
      PipelineStepDefinition(
        id: fetchId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.bashScript,
        triggers: const [
          StepTrigger(sourceStepIds: ['trigger']),
        ],
        config: const PipelineNodeConfig(
          label: 'Fetch suite',
          inputKeys: ['repo_local_path'],
          outputKey: 'repo_local_path',
          timeoutMs: 120000,
          script: fetchScript,
        ),
        x: 280,
        y: 120,
      ),
      PipelineStepDefinition(
        id: testsId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.bashScript,
        triggers: const [
          StepTrigger(sourceStepIds: [fetchId]),
        ],
        config: const PipelineNodeConfig(
          label: 'Run eval suite',
          inputKeys: ['repo_local_path'],
          outputKey: 'test_log',
          timeoutMs: 600000,
          script: testScript,
        ),
        x: 560,
        y: 0,
      ),
      PipelineStepDefinition(
        id: analyzeId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.bashScript,
        triggers: const [
          StepTrigger(sourceStepIds: [fetchId]),
        ],
        config: const PipelineNodeConfig(
          label: 'Compile checkout',
          inputKeys: ['repo_local_path'],
          outputKey: 'analyze_log',
          timeoutMs: 180000,
          script: analyzeScript,
        ),
        x: 560,
        y: 240,
      ),
      PipelineStepDefinition(
        id: gateId,
        kind: StepKind.router,
        bodyKey: BuiltInBodyKeys.condition,
        triggers: const [
          StepTrigger(sourceStepIds: [testsId]),
        ],
        config: const PipelineNodeConfig(
          label: 'Budget file present?',
          inputKeys: ['repo_local_path'],
          extras: {
            'predicate': {
              'type': 'fileExists',
              'paths': ['evalkit/budget.py'],
              'baseKey': 'repo_local_path',
            },
          },
        ),
        x: 840,
        y: 0,
      ),
      PipelineStepDefinition(
        id: diffId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.bashScript,
        triggers: const [
          StepTrigger(sourceStepIds: [gateId], routeKey: 'true'),
        ],
        config: const PipelineNodeConfig(
          label: 'Diff budget fixtures',
          inputKeys: ['repo_local_path'],
          outputKey: 'budget_diff',
          timeoutMs: 60000,
          script: diffScript,
        ),
        x: 1120,
        y: 0,
      ),
      PipelineStepDefinition(
        id: noteId,
        kind: StepKind.listen,
        bodyKey: BuiltInBodyKeys.bashScript,
        triggers: const [
          StepTrigger(sourceStepIds: [gateId], routeKey: 'false'),
        ],
        config: const PipelineNodeConfig(
          label: 'Note missing budget file',
          inputKeys: ['repo_local_path'],
          outputKey: 'missing_note',
          timeoutMs: 30000,
          script: noteScript,
        ),
        x: 1120,
        y: 160,
      ),
      PipelineStepDefinition(
        id: terminalId,
        kind: StepKind.terminal,
        bodyKey: '_terminal_checks',
        triggers: const [
          StepTrigger(sourceStepIds: [diffId, noteId, analyzeId]),
        ],
      ),
    ],
  );
}

/// Finished (and failed) pipeline runs for one demo workspace.
///
/// A failed run's failing step has to be a visible work node. The canvas and
/// the waterfall both drop [StepKind.terminal], so a failure recorded only on
/// that sentinel leaves every node green and the detail panel empty.
List<DemoPipelineRunFixture> demoPipelineRuns() {
  return [
    _prReview88(),
    _prReview380(),
    _ticketHx129Failed(),
    _ticketHx131(),
    _releaseChecksPassed(),
    _releaseChecksFailed(),
    _releaseChecksNoBudgetFile(),
  ];
}

/// One seeded run. [steps] are the rows the run page reads; terminal sentinels
/// are omitted because the run view never draws them.
class DemoPipelineRunFixture {
  /// Creates a seeded run.
  const DemoPipelineRunFixture({
    required this.runId,
    required this.templateId,
    required this.startedAgo,
    required this.status,
    required this.costCents,
    required this.tokens,
    required this.steps,
    this.error,
    this.triggerEventType,
    this.triggerPayload,
    this.state = const <String, dynamic>{},
  });

  /// Stable suffix. The seeder prefixes the workspace id — run ids are routed
  /// globally, and a bare id collides across the visitor pool.
  final String runId;

  /// Template this run is an instance of.
  final String templateId;

  /// How long before seed time the run started.
  final Duration startedAgo;

  /// Terminal status. Demo runs are history, not work the engine should resume.
  final PipelineRunStatus status;

  /// Run-level error, shown on the meta strip. Set on failures.
  final String? error;

  /// What started the run (`PullRequestPublished`, `manual`, …).
  final String? triggerEventType;

  /// Trigger payload. Also the bag step inputs quote.
  final Map<String, dynamic>? triggerPayload;

  /// Pipeline state after the run, so `{{placeholders}}` in node labels resolve.
  final Map<String, dynamic> state;

  /// Aggregated cost, in cents.
  final int costCents;

  /// Aggregated token count.
  final int tokens;

  /// Step rows, in no particular order.
  final List<DemoPipelineStepFixture> steps;
}

/// One seeded step row.
class DemoPipelineStepFixture {
  /// Creates a seeded step row.
  const DemoPipelineStepFixture({
    required this.stepId,
    required this.status,
    required this.startSec,
    this.durationSec = 0,
    this.input,
    this.output,
    this.error,
  });

  /// Step id on the template. Must be a node the canvas actually draws.
  final String stepId;

  /// Status the node and the waterfall paint.
  final PipelineStepStatus status;

  /// Seconds after the run start when this step began.
  final int startSec;

  /// Wall-clock seconds. Zero for a step that was skipped without running.
  final int durationSec;

  /// What the step was given. Bash rows include the rendered script.
  final Map<String, dynamic>? input;

  /// What the step produced. Bash rows include the interleaved transcript
  /// under `output`, which is the shape the shell body streams.
  final Map<String, dynamic>? output;

  /// Failure reason. Required when [status] is [PipelineStepStatus.failed].
  final String? error;
}

DemoPipelineRunFixture _prReview88() {
  const payload = <String, dynamic>{
    'repo_full_name': 'helix/retriever',
    'pr_number': 88,
    'pr_title': 'Hybrid BM25 + embedding retrieval',
    'head_ref': 'priya/hybrid-retrieval',
    'review_level': 'balanced',
  };
  return DemoPipelineRunFixture(
    runId: 'demo-pipeline-run-2',
    templateId: 'pr_review',
    startedAgo: const Duration(hours: 26),
    status: PipelineRunStatus.completed,
    costCents: 9,
    tokens: 22100,
    triggerEventType: 'PullRequestPublished',
    triggerPayload: payload,
    state: payload,
    steps: [
      _trigger(payload),
      _space(
        stepId: 'setup',
        startSec: 1,
        durationSec: 9,
        outputKey: 'review_space_id',
        space: 'retriever-review',
        extra: {'pr_number': 88, 'repo_full_name': 'helix/retriever'},
      ),
      _review(
        stepId: 'engineer_review',
        startSec: 12,
        durationSec: 40,
        pr: '#88 — Hybrid BM25 + embedding retrieval',
        findings:
            'The fusion weights are hardcoded in retriever/hybrid.py. A '
            'zero-hit BM25 query still pays for the embedding call. Fine '
            'for the cut, worth a flag.',
      ),
      _review(
        stepId: 'qa_review',
        startSec: 12,
        durationSec: 33,
        pr: '#88 — Hybrid BM25 + embedding retrieval',
        findings:
            'The empty-index case is tested. The tie-break between equal '
            'BM25 scores is not, so two runs can order the same page '
            'differently.',
      ),
      _review(
        stepId: 'architect_review',
        startSec: 12,
        durationSec: 36,
        pr: '#88 — Hybrid BM25 + embedding retrieval',
        findings:
            'The embedding client is constructed inside the query path. '
            'Move it next to the other clients so a test can substitute it '
            'without patching the module.',
      ),
      _skippedLevel('security_review', startSec: 12),
      _skippedLevel('perf_review', startSec: 12),
      _review(
        stepId: 'consolidate',
        startSec: 54,
        durationSec: 22,
        pr: '#88',
        outputKey: 'consolidated_findings',
        findings:
            'PR #88 fuses BM25 with embeddings. No blocking findings. The '
            'fusion weights and the tie-break are the two nits.',
      ),
      const DemoPipelineStepFixture(
        stepId: 'finalize',
        status: PipelineStepStatus.completed,
        startSec: 78,
        durationSec: 5,
        input: {
          'bodyKey': BuiltInBodyKeys.prReviewFinalize,
          'inputs': {'pr_number': 88, 'review_level': 'balanced'},
        },
        output: {'review_verdict': 'approve', 'blocking': 0, 'nits': 2},
      ),
    ],
  );
}

DemoPipelineRunFixture _prReview380() {
  const payload = <String, dynamic>{
    'repo_full_name': kDemoRepoFullName,
    'pr_number': 380,
    'pr_title': 'Pin the eval budget window to a fake clock',
    'head_ref': 'maya/budget-clock',
    'review_level': 'light',
  };
  return DemoPipelineRunFixture(
    runId: 'demo-pipeline-run-3',
    templateId: 'pr_review',
    startedAgo: const Duration(days: 5),
    status: PipelineRunStatus.completed,
    costCents: 4,
    tokens: 8600,
    triggerEventType: 'PullRequestPublished',
    triggerPayload: payload,
    state: payload,
    steps: [
      _trigger(payload),
      _space(
        stepId: 'setup',
        startSec: 1,
        durationSec: 8,
        outputKey: 'review_space_id',
        space: 'eval-review',
        extra: {'pr_number': 380},
      ),
      _review(
        stepId: 'engineer_review',
        startSec: 10,
        durationSec: 28,
        pr: '#380 — Pin the eval budget window to a fake clock',
        findings:
            'The window test takes a clock instead of datetime.now(). The '
            'HX-131 midnight case is in the diff and fails without the '
            'injection. Looks right.',
      ),
      _skippedLevel('qa_review', startSec: 10, level: 'light'),
      _skippedLevel('architect_review', startSec: 10, level: 'light'),
      _skippedLevel('security_review', startSec: 10, level: 'light'),
      _skippedLevel('perf_review', startSec: 10, level: 'light'),
      _review(
        stepId: 'consolidate',
        startSec: 40,
        durationSec: 12,
        pr: '#380',
        outputKey: 'consolidated_findings',
        findings:
            'Light pass on #380. The clock is injected and the midnight '
            'case is covered. Nothing else ran at this level.',
      ),
      const DemoPipelineStepFixture(
        stepId: 'finalize',
        status: PipelineStepStatus.completed,
        startSec: 54,
        durationSec: 4,
        input: {
          'bodyKey': BuiltInBodyKeys.prReviewFinalize,
          'inputs': {'pr_number': 380, 'review_level': 'light'},
        },
        output: {'review_verdict': 'approve', 'blocking': 0, 'nits': 0},
      ),
    ],
  );
}

/// The run the pipelines page opens when someone asks why a job failed.
///
/// `open_pr` is the bash step that pushes the branch. It is a real node.
/// Downstream `comment` is skipped. The parallel self-review still finished.
DemoPipelineRunFixture _ticketHx129Failed() {
  const ticket = 'HX-129';
  const path = '/workspace/helix/evalkit';
  const payload = <String, dynamic>{
    'repo_full_name': kDemoRepoFullName,
    'repo_local_path': path,
    'ticket_id': ticket,
    'ticket_title': 'Scheduled eval-score exports for research',
    'ticket_body':
        'Save a schedule against the week\'s eval runs and deliver it to '
        'research. A silent email failure needs a visible failure state.',
  };
  const pushError =
      'bash exited 1: gh: authentication required for helix/evalkit '
      '(no forge credential on this host)';
  return DemoPipelineRunFixture(
    runId: 'demo-pipeline-run-1',
    templateId: 'ticket_to_pr',
    startedAgo: const Duration(hours: 49),
    status: PipelineRunStatus.failed,
    error: pushError,
    costCents: 7,
    tokens: 16400,
    triggerEventType: 'TicketAssigned',
    triggerPayload: payload,
    state: {...payload, 'pipeline_space_id': 'implement-hx-129'},
    steps: [
      _trigger(payload),
      _space(
        stepId: 'space',
        startSec: 1,
        durationSec: 14,
        outputKey: 'pipeline_space_id',
        space: 'implement-hx-129',
        extra: {'ticket_id': ticket, 'repo_local_path': path},
      ),
      _bash(
        stepId: 'setup_branch',
        startSec: 16,
        durationSec: 8,
        script:
            'set -euo pipefail\n'
            'cd "$path"\n'
            'TICKET="$ticket"\n'
            'git fetch --quiet origin || true\n'
            'git switch -c "agent/\$TICKET" 2>/dev/null || '
            'git switch "agent/\$TICKET"\n'
            'echo "on \$(git rev-parse --abbrev-ref HEAD)"',
        inputs: {'repo_local_path': path, 'ticket_id': ticket},
        stdout: 'on agent/HX-129',
        stderr: "Switched to a new branch 'agent/HX-129'",
      ),
      _review(
        stepId: 'implement',
        startSec: 26,
        durationSec: 95,
        pr: 'HX-129',
        outputKey: 'implement_summary',
        findings:
            'Added evalkit/export.py: a weekly schedule, a delivery log, and '
            'a failed state when the handoff returns non-zero. Committed on '
            'agent/HX-129 as a1c4e90. Tests for the silent-failure path are '
            'in test_export.py.',
      ),
      _bash(
        stepId: 'open_pr',
        startSec: 122,
        durationSec: 4,
        outputKey: 'pr_number',
        script:
            'set -euo pipefail\n'
            'cd "$path"\n'
            'git push -u origin "agent/$ticket"\n'
            'gh pr create --draft --title "Scheduled eval-score exports" '
            '--head "agent/$ticket"',
        inputs: {
          'repo_local_path': path,
          'ticket_id': ticket,
          'ticket_title': 'Scheduled eval-score exports for research',
        },
        stdout: 'git push -u origin agent/HX-129',
        stderr:
            'gh: authentication required for helix/evalkit\n'
            'no forge credential on this host — the branch was left at '
            'agent/HX-129',
        exitCode: 1,
        error: pushError,
      ),
      _review(
        stepId: 'self_review',
        startSec: 122,
        durationSec: 40,
        pr: 'HX-129',
        outputKey: 'consolidated_findings',
        findings:
            'The delivery log records the non-zero handoff, which is what '
            'the ticket asked for. The schedule is stored next to the run '
            'group but never read back on the failure path — the failed '
            'state is visible, the retry is not.',
      ),
      _skippedBecause(
        'comment',
        startSec: 126,
        reason:
            'Skipped because Open draft PR failed: no forge credential, so '
            'there is no PR to comment on.',
      ),
    ],
  );
}

DemoPipelineRunFixture _ticketHx131() {
  const ticket = 'HX-131';
  const path = '/workspace/helix/evalkit';
  const payload = <String, dynamic>{
    'repo_full_name': kDemoRepoFullName,
    'repo_local_path': path,
    'ticket_id': ticket,
    'ticket_title': 'Budget window test is flaky across the UTC-day boundary',
  };
  return DemoPipelineRunFixture(
    runId: 'demo-pipeline-run-4',
    templateId: 'ticket_to_pr',
    startedAgo: const Duration(days: 6),
    status: PipelineRunStatus.completed,
    costCents: 11,
    tokens: 24800,
    triggerEventType: 'TicketAssigned',
    triggerPayload: payload,
    state: {
      ...payload,
      'pipeline_space_id': 'implement-hx-131',
      'pr_number': '380',
    },
    steps: [
      _trigger(payload),
      _space(
        stepId: 'space',
        startSec: 1,
        durationSec: 12,
        outputKey: 'pipeline_space_id',
        space: 'implement-hx-131',
        extra: {'ticket_id': ticket, 'repo_local_path': path},
      ),
      _bash(
        stepId: 'setup_branch',
        startSec: 14,
        durationSec: 6,
        script:
            'set -euo pipefail\n'
            'cd "$path"\n'
            'git switch -c "agent/$ticket" 2>/dev/null || '
            'git switch "agent/$ticket"\n'
            'echo "on agent/$ticket"',
        inputs: {'repo_local_path': path, 'ticket_id': ticket},
        stdout: 'on agent/HX-131',
        stderr: "Switched to a new branch 'agent/HX-131'",
      ),
      _review(
        stepId: 'implement',
        startSec: 22,
        durationSec: 80,
        pr: 'HX-131',
        outputKey: 'implement_summary',
        findings:
            'Injected a clock into the budget window. The midnight test '
            'pins 00:00:04 before the boundary and expects both records. '
            'Committed on agent/HX-131.',
      ),
      _bash(
        stepId: 'open_pr',
        startSec: 104,
        durationSec: 9,
        outputKey: 'pr_number',
        script:
            'set -euo pipefail\n'
            'cd "$path"\n'
            'git push -u origin "agent/$ticket"\n'
            'gh pr create --draft --title "Pin the eval budget window" '
            '--head "agent/$ticket"\n'
            'gh pr view "agent/$ticket" --json number --jq .number',
        inputs: {'repo_local_path': path, 'ticket_id': ticket},
        stdout: '380',
        stderr:
            "branch 'agent/HX-131' set up to track 'origin/agent/HX-131'.\n"
            'https://example.invalid/helix/evalkit/pull/380',
      ),
      _review(
        stepId: 'self_review',
        startSec: 104,
        durationSec: 28,
        pr: 'HX-131',
        outputKey: 'consolidated_findings',
        findings:
            'The test no longer calls datetime.now(). One nit: the clock '
            'default still falls back to the wall clock in production, '
            'which is what we want, and the test covers the override.',
      ),
      const DemoPipelineStepFixture(
        stepId: 'comment',
        status: PipelineStepStatus.completed,
        startSec: 136,
        durationSec: 4,
        input: {
          'bodyKey': BuiltInBodyKeys.prReviewComment,
          'inputs': {
            'pr_number': '380',
            'repo_full_name': kDemoRepoFullName,
            'consolidated_findings':
                'Clock is injected; midnight case is covered.',
          },
        },
        output: {
          'comment_url':
              'https://example.invalid/helix/evalkit/pull/380#issuecomment-1',
          'posted': true,
        },
      ),
    ],
  );
}

DemoPipelineRunFixture _releaseChecksPassed() {
  const path = '/workspace/helix/evalkit';
  const payload = <String, dynamic>{
    'repo_full_name': kDemoRepoFullName,
    'repo_local_path': path,
  };
  return DemoPipelineRunFixture(
    runId: 'demo-pipeline-run-5',
    templateId: kDemoReleaseChecksTemplateId,
    startedAgo: const Duration(hours: 3),
    status: PipelineRunStatus.completed,
    costCents: 0,
    tokens: 0,
    triggerEventType: 'manual',
    triggerPayload: payload,
    state: {...payload, 'test_log': '42 passed in 18.42s'},
    steps: [
      _trigger(payload),
      _bash(
        stepId: 'fetch',
        startSec: 1,
        durationSec: 7,
        outputKey: 'repo_local_path',
        script: _fetchScript(path),
        inputs: {'repo_local_path': path},
        stdout: path,
        stderr:
            'From https://example.invalid/helix/evalkit\n'
            ' * branch            main       -> FETCH_HEAD\n'
            'HEAD is now at 1a7de90c Pin grader clock',
      ),
      _bash(
        stepId: 'run_tests',
        startSec: 9,
        durationSec: 36,
        outputKey: 'test_log',
        script: _pytestScript(path),
        inputs: {'repo_local_path': path},
        stdout: _pytestPass,
      ),
      _bash(
        stepId: 'analyze',
        startSec: 9,
        durationSec: 11,
        outputKey: 'analyze_log',
        script: _compileScript(path),
        inputs: {'repo_local_path': path},
        stdout: 'compileall: ok\nListing evalkit ...\nListing evalkit/test ...',
      ),
      _gate(startSec: 46, exists: true, path: path),
      _bash(
        stepId: 'diff_budget',
        startSec: 48,
        durationSec: 3,
        outputKey: 'budget_diff',
        script:
            'set -euo pipefail\n'
            'cd "$path"\n'
            'git diff origin/main -- evalkit/budget.py',
        inputs: {'repo_local_path': path},
        stdout:
            'diff --git a/evalkit/budget.py b/evalkit/budget.py\n'
            '--- a/evalkit/budget.py\n'
            '+++ b/evalkit/budget.py\n'
            '@@ -40,6 +40,9 @@ def remaining(run_id):\n'
            '+def remaining_for_group(group_id):\n'
            '+    return _ledger.for_group(group_id)\n',
      ),
      _skippedBecause(
        'note_missing',
        startSec: 48,
        reason:
            'Router took the other branch: evalkit/budget.py is in the '
            'checkout.',
      ),
    ],
  );
}

DemoPipelineRunFixture _releaseChecksFailed() {
  const path = '/workspace/helix/evalkit';
  const payload = <String, dynamic>{
    'repo_full_name': kDemoRepoFullName,
    'repo_local_path': path,
  };
  const testError =
      'bash exited 1: FAILED evalkit/test_budget.py::'
      'test_window_across_utc_midnight';
  return DemoPipelineRunFixture(
    runId: 'demo-pipeline-run-6',
    templateId: kDemoReleaseChecksTemplateId,
    startedAgo: const Duration(hours: 18),
    status: PipelineRunStatus.failed,
    error: testError,
    costCents: 0,
    tokens: 0,
    triggerEventType: 'manual',
    triggerPayload: payload,
    state: payload,
    steps: [
      _trigger(payload),
      _bash(
        stepId: 'fetch',
        startSec: 1,
        durationSec: 6,
        outputKey: 'repo_local_path',
        script: _fetchScript(path),
        inputs: {'repo_local_path': path},
        stdout: path,
        stderr:
            'From https://example.invalid/helix/evalkit\n'
            ' * branch            main       -> FETCH_HEAD',
      ),
      _bash(
        stepId: 'run_tests',
        startSec: 8,
        durationSec: 22,
        outputKey: 'test_log',
        script: _pytestScript(path),
        inputs: {'repo_local_path': path},
        stdout: _pytestFail,
        stderr:
            'FAILED evalkit/test_budget.py::test_window_across_utc_midnight',
        exitCode: 1,
        error: testError,
      ),
      _bash(
        stepId: 'analyze',
        startSec: 8,
        durationSec: 9,
        outputKey: 'analyze_log',
        script: _compileScript(path),
        inputs: {'repo_local_path': path},
        stdout: 'compileall: ok',
      ),
      _skippedBecause(
        'budget_gate',
        startSec: 30,
        reason: 'Skipped because Run eval suite failed.',
      ),
      _skippedBecause(
        'diff_budget',
        startSec: 30,
        reason: 'Skipped because Run eval suite failed.',
      ),
      _skippedBecause(
        'note_missing',
        startSec: 30,
        reason: 'Skipped because Run eval suite failed.',
      ),
    ],
  );
}

DemoPipelineRunFixture _releaseChecksNoBudgetFile() {
  const path = '/workspace/helix/finetune';
  const payload = <String, dynamic>{
    'repo_full_name': 'helix/finetune',
    'repo_local_path': path,
  };
  return DemoPipelineRunFixture(
    runId: 'demo-pipeline-run-7',
    templateId: kDemoReleaseChecksTemplateId,
    startedAgo: const Duration(days: 8),
    status: PipelineRunStatus.completed,
    costCents: 0,
    tokens: 0,
    triggerEventType: 'manual',
    triggerPayload: payload,
    state: payload,
    steps: [
      _trigger(payload),
      _bash(
        stepId: 'fetch',
        startSec: 1,
        durationSec: 5,
        outputKey: 'repo_local_path',
        script: _fetchScript(path),
        inputs: {'repo_local_path': path},
        stdout: path,
        stderr:
            'From https://example.invalid/helix/finetune\n'
            'HEAD is now at 9c21ab40 QLoRA sampler',
      ),
      _bash(
        stepId: 'run_tests',
        startSec: 7,
        durationSec: 18,
        outputKey: 'test_log',
        script: _pytestScript(path),
        inputs: {'repo_local_path': path},
        stdout:
            'train/test_sampler.py::test_peak_vram PASSED\n'
            '6 passed in 4.10s',
      ),
      _bash(
        stepId: 'analyze',
        startSec: 7,
        durationSec: 8,
        outputKey: 'analyze_log',
        script: _compileScript(path),
        inputs: {'repo_local_path': path},
        stdout: 'compileall: ok\nListing train ...',
      ),
      _gate(startSec: 26, exists: false, path: path),
      _skippedBecause(
        'diff_budget',
        startSec: 28,
        reason:
            'Router took the other branch: evalkit/budget.py is not in '
            'helix/finetune.',
      ),
      _bash(
        stepId: 'note_missing',
        startSec: 28,
        durationSec: 1,
        outputKey: 'missing_note',
        script:
            'set -euo pipefail\n'
            'cd "$path"\n'
            'echo "evalkit/budget.py is not in this checkout"',
        inputs: {'repo_local_path': path},
        stdout: 'evalkit/budget.py is not in this checkout',
      ),
    ],
  );
}

DemoPipelineStepFixture _trigger(Map<String, dynamic> payload) {
  return DemoPipelineStepFixture(
    stepId: 'trigger',
    status: PipelineStepStatus.completed,
    startSec: 0,
    durationSec: 1,
    input: {'bodyKey': BuiltInBodyKeys.trigger, 'triggerPayload': payload},
    output: {'accepted': true},
  );
}

DemoPipelineStepFixture _space({
  required String stepId,
  required int startSec,
  required int durationSec,
  required String outputKey,
  required String space,
  Map<String, dynamic> extra = const {},
}) {
  return DemoPipelineStepFixture(
    stepId: stepId,
    status: PipelineStepStatus.completed,
    startSec: startSec,
    durationSec: durationSec,
    input: {
      'bodyKey': BuiltInBodyKeys.createSpace,
      'outputKey': outputKey,
      'inputs': extra,
    },
    output: {outputKey: space, ...extra},
  );
}

DemoPipelineStepFixture _review({
  required String stepId,
  required int startSec,
  required int durationSec,
  required String pr,
  required String findings,
  String? outputKey,
}) {
  final key = outputKey ?? '${stepId}_findings';
  return DemoPipelineStepFixture(
    stepId: stepId,
    status: PipelineStepStatus.completed,
    startSec: startSec,
    durationSec: durationSec,
    input: {
      'bodyKey': BuiltInBodyKeys.promptAgent,
      'outputKey': key,
      'prompt': 'Review $pr. File findings with path:line references.',
      'inputs': {'pr': pr},
    },
    output: {key: findings},
  );
}

DemoPipelineStepFixture _skippedLevel(
  String stepId, {
  required int startSec,
  String level = 'balanced',
}) {
  final key = '${stepId}_findings';
  return DemoPipelineStepFixture(
    stepId: stepId,
    status: PipelineStepStatus.skipped,
    startSec: startSec,
    input: {
      'bodyKey': BuiltInBodyKeys.promptAgent,
      'outputKey': key,
      'inputs': {'review_level': level},
    },
    output: {
      'skipReason': 'Not run at review level $level.',
      key: '(not run at this review level)',
    },
  );
}

DemoPipelineStepFixture _skippedBecause(
  String stepId, {
  required int startSec,
  required String reason,
}) {
  return DemoPipelineStepFixture(
    stepId: stepId,
    status: PipelineStepStatus.skipped,
    startSec: startSec,
    output: {'skipReason': reason},
  );
}

DemoPipelineStepFixture _gate({
  required int startSec,
  required bool exists,
  required String path,
}) {
  final route = exists ? 'true' : 'false';
  return DemoPipelineStepFixture(
    stepId: 'budget_gate',
    status: PipelineStepStatus.completed,
    startSec: startSec,
    durationSec: 1,
    input: {
      'bodyKey': BuiltInBodyKeys.condition,
      'inputs': {'repo_local_path': path},
      'predicate': {
        'type': 'fileExists',
        'paths': ['evalkit/budget.py'],
        'baseKey': 'repo_local_path',
      },
    },
    output: {
      'route': route,
      '__route__budget_gate': route,
      'detail': exists
          ? '$path/evalkit/budget.py exists'
          : '$path/evalkit/budget.py does not exist',
    },
  );
}

DemoPipelineStepFixture _bash({
  required String stepId,
  required int startSec,
  required int durationSec,
  required String script,
  required String stdout,
  String? outputKey,
  Map<String, dynamic> inputs = const {},
  String? stderr,
  int exitCode = 0,
  String? error,
}) {
  final failed = exitCode != 0;
  final transcript = StringBuffer(stdout.trimRight());
  if (stderr != null && stderr.trim().isNotEmpty) {
    for (final line in stderr.trimRight().split('\n')) {
      transcript.writeln();
      transcript.write('[stderr] $line');
    }
  }
  return DemoPipelineStepFixture(
    stepId: stepId,
    status: failed ? PipelineStepStatus.failed : PipelineStepStatus.completed,
    startSec: startSec,
    durationSec: durationSec,
    error: error,
    input: {
      'bodyKey': BuiltInBodyKeys.bashScript,
      'outputKey': ?outputKey,
      'script': script,
      if (inputs.isNotEmpty) 'inputs': inputs,
    },
    output: {
      'stepId': stepId,
      'runDir': '/tmp/cc-pipeline/demo/$stepId',
      'exitCode': exitCode,
      'output': transcript.toString(),
      if (!failed && outputKey != null) outputKey: stdout.trimRight(),
    },
  );
}

String _fetchScript(String path) =>
    'set -euo pipefail\n'
    'cd "$path"\n'
    'git fetch --quiet origin\n'
    'git switch --detach origin/main\n'
    'pwd';

String _pytestScript(String path) =>
    'set -euo pipefail\n'
    'cd "$path"\n'
    'python -m pytest -q --tb=line';

String _compileScript(String path) =>
    'set -euo pipefail\n'
    'cd "$path"\n'
    'python -m compileall -q .\n'
    'echo "compileall: ok"';

const String _pytestPass =
    'evalkit/test_budget.py::test_shared_run_group_ledger PASSED\n'
    'evalkit/test_budget.py::test_window_across_utc_midnight PASSED\n'
    'evalkit/test_export.py::test_schedule_persists PASSED\n'
    '42 passed in 18.42s';

const String _pytestFail =
    '============================= test session starts ==============================\n'
    'platform linux -- Python 3.12.4, pytest-8.3.2\n'
    'rootdir: /workspace/helix/evalkit\n'
    'collected 42 items\n'
    '\n'
    'evalkit/test_budget.py::test_shared_run_group_ledger PASSED\n'
    'evalkit/test_budget.py::test_window_across_utc_midnight FAILED\n'
    'evalkit/test_export.py::test_schedule_persists PASSED\n'
    '\n'
    '=================================== FAILURES ===================================\n'
    '____________________ test_window_across_utc_midnight _________________________\n'
    'E   AssertionError: expected 2 records in the window, got 1\n'
    'E   The first record landed 00:00:04 before the fake clock\'s UTC day.\n'
    '=========================== short test summary info ============================\n'
    'FAILED evalkit/test_budget.py::test_window_across_utc_midnight\n'
    '1 failed, 41 passed in 18.42s';
