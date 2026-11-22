import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show
        GoalNotActiveSegmentException,
        GoalRefusedException,
        ValidationException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart'
    show renderWakeItems;
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_budget_shares.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_command.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_arm_settings.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_goal_outcome.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/context.dart'
    show ToolCallForms, newWakeDataNonce, plainToolForm;
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/dispatch/goal_changes.dart';
import 'package:cc_infra/src/dispatch/goal_check_runner.dart';
import 'package:cc_infra/src/dispatch/goal_claim.dart';
import 'package:cc_infra/src/dispatch/goal_store.dart';
import 'package:cc_infra/src/dispatch/goal_supervisor.dart' show GoalSupervisor;
import 'package:cc_infra/src/dispatch/goal_turn_texts.dart';
import 'package:cc_infra/src/dispatch/goal_verifier.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/worktree_fingerprints.dart';
import 'package:cc_infra/src/evaluation/goal_verification_ports.dart';
import 'package:path/path.dart' as p;

/// What a goal attempt's review run came to.
class EvaluationGoalReview {
  /// Creates a review result.
  const EvaluationGoalReview({
    required this.completed,
    required this.output,
    required this.costMicros,
    this.error,
  });

  /// Whether the run ended normally.
  final bool completed;

  /// What the reviewer submitted with `submit_output`; null when nothing.
  final Map<String, dynamic>? output;

  /// What the review run cost (0 when unpriced; the attempt's cost says so).
  final int costMicros;

  /// Why the run failed, when it did.
  final String? error;
}

/// Runs a goal's review: a fresh, read-only run with [prompt] that answers
/// with `submit_output`, stopped once it has spent [capMicros].
typedef EvaluationGoalReviewer =
    Future<EvaluationGoalReview> Function({
      required String prompt,
      required int capMicros,
    });

/// One evaluation attempt's goal, verified by the product's own classes.
///
/// The attempt's task prompt is a goal body (`GoalCommand.parse`). The
/// session holds the goal in memory and runs it the way the product does on
/// the verification path: the first segment's wake and the goal block come
/// from the product's `GoalStore` and `GoalTurnTexts`; a claim is checked by
/// `checkGoalClaim` and recorded as the supervisor records it; under
/// [GoalVerificationMode.checksReview] the product's `GoalVerifier` runs the
/// contract's checks through `GoalCheckRunner` and asks for the review, whose
/// prompt `GoalTurnTexts` renders, and a failed round's segment wake carries
/// the product's failed-verification notice back to the agent. Under
/// [GoalVerificationMode.claimOnly] the claim is the completion.
///
/// What differs from a real goal: the supervisor is not run (no wakes are
/// queued or delivered, no strikes, parks or holds; a segment that ends
/// without a claim ends the attempt), the checks run in the task workspace
/// the way the evaluation's own `bash` runs ([evaluationCheckStarter])
/// rather than in a sandbox over a worktree, and the review runs on the same
/// backend with the evaluation's system prompt and read tools.
class EvaluationGoalSession {
  EvaluationGoalSession._({
    required this.mode,
    required this.hasRepl,
    required this._attemptId,
    required this._rows,
    required this._queue,
    required this._runs,
    required this._store,
    required this._verifier,
    required this._turnTexts,
    required this._reviewer,
    required this._now,
  });

  /// The workspace id every goal attempt runs under.
  static const String workspaceId = 'cc-eval';

  /// The space id every goal attempt runs under.
  static const String spaceId = 'cc-eval-space';

  /// The agent id every goal attempt runs as (the harness context's).
  static const String agentId = 'cc-eval';

  /// What `complete_goal` tells the model after a claim is recorded: the
  /// product's words (`goalClaimRecordedNext`, which lives with the MCP
  /// tool this package cannot import).
  static const String claimRecordedNext =
      'The server is now running the checks, then an independent reviewer '
      'inspects the result. You will be woken with the result; end your turn.';

  /// Opens the goal of [taskPrompt] for attempt [attemptId], whose workspace
  /// [workspaceRoot] sits in a space's `repos/` directory. Throws
  /// [StateError] when the prompt is not a goal body or the workspace is not
  /// laid out as a space's checkout.
  static Future<EvaluationGoalSession> open({
    required String attemptId,
    required String taskPrompt,
    required String workspaceRoot,
    required GoalVerificationMode mode,
    required bool hasRepl,
    required EvaluationGoalReviewer reviewer,
    DateTime Function() now = DateTime.now,
  }) async {
    final reposDir = p.dirname(workspaceRoot);
    if (p.basename(reposDir) != 'repos') {
      throw StateError(
        'a goal attempt runs in a workspace laid out as a space checkout '
        '(<space>/repos/<checkout>); $workspaceRoot is not',
      );
    }
    final GoalCommand command;
    try {
      command = GoalCommand.parse(taskPrompt);
    } on Object catch (e) {
      throw StateError('the task prompt is not a goal body: $e');
    }
    final at = now();
    final agent = Agent(
      id: agentId,
      name: 'cc-eval',
      title: 'Evaluated agent',
      agentMdPath: '',
      workspaceId: workspaceId,
      skills: AgentSkills(const []),
      createdAt: at,
    );
    final conversations = EvaluationGoalConversations(
      Conversation(
        id: attemptId,
        workspaceId: workspaceId,
        spaceId: spaceId,
        title: 'Evaluation attempt $attemptId',
        createdAt: at,
        updatedAt: at,
      ),
    );
    final files = EvaluationSpaceFiles(p.dirname(reposDir));
    final rows = EvaluationGoalRows();
    final queue = EvaluationWakeCapture();
    final runs = EvaluationReviewRuns();
    final changes = GoalChanges(
      conversations: conversations,
      filesystem: files,
      todos: null,
    );
    var ids = 0;
    final store = GoalStore(
      goals: rows,
      wakes: EvaluationNoWakeRows(),
      wakeQueue: () => queue,
      say:
          ({
            required workspaceId,
            required spaceId,
            required content,
            conversationId,
          }) async {},
      eventBus: null,
      now: now,
      startRefs: changes.startRefs,
      newId: () => '$attemptId-${++ids}',
    );
    final fingerprints = WorktreeFingerprints(
      conversations: conversations,
      filesystem: files,
    );
    final checks = GoalCheckRunner(
      gate: const HostExecutionGate(posture: HostExecutionPosture.offByOwner),
      sandboxManager: null,
      filesystem: files,
      fingerprints: fingerprints,
      environments: null,
      start: evaluationCheckStarter(workspaceRoot),
    );
    final verifier = GoalVerifier(
      store: store,
      runChecks: checks.run,
      fingerprintOf: (goal) => fingerprints.fingerprint(
        workspaceId: goal.workspaceId,
        conversationId: goal.conversationId,
      ),
      spaceCheckerOf: (_, _) async => null,
      agents: EvaluationGoalAgents(agent),
      runLogs: runs,
    );
    final goal = AgentGoalRun(
      id: 'goal-$attemptId',
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: attemptId,
      agentId: agentId,
      userText: command.objective,
      costCapMicros:
          command.budgetMicros ?? GoalSupervisor.defaultCostCapMicros,
      maxRuns: command.maxRuns,
      contract: command.contract,
      fresh: command.fresh,
      createdAt: at,
      updatedAt: at,
    );
    await rows.upsert(
      goal.copyWith(startRefs: await changes.startRefs(workspaceId, attemptId)),
    );
    return EvaluationGoalSession._(
      mode: mode,
      hasRepl: hasRepl,
      attemptId: attemptId,
      rows: rows,
      queue: queue,
      runs: runs,
      store: store,
      verifier: verifier,
      turnTexts: GoalTurnTexts(goals: rows, changes: changes, now: now),
      reviewer: reviewer,
      now: now,
    );
  }

  /// What the claim is worth.
  final GoalVerificationMode mode;

  /// Whether the worker's run has `repl` (picks the goal block's tool line).
  final bool hasRepl;

  /// How the worker's run calls each tool, for the wake frame.
  ToolCallForms forms = plainToolForm;

  final String _attemptId;
  final EvaluationGoalRows _rows;
  final EvaluationWakeCapture _queue;
  final EvaluationReviewRuns _runs;
  final GoalStore _store;
  final GoalVerifier _verifier;
  final GoalTurnTexts _turnTexts;
  final EvaluationGoalReviewer _reviewer;
  final DateTime Function() _now;

  int _segments = 0;
  int _claims = 0;
  int _reviews = 0;
  bool _accepted = false;
  GoalVerificationResult _result = GoalVerificationResult.notRun;
  String? _holdDetail;

  /// The goal as it stands.
  AgentGoalRun get goal => _rows.current;

  /// What the attempt's goal came to so far.
  EvaluationGoalOutcome get outcome => EvaluationGoalOutcome(
    claims: _claims,
    accepted: _accepted,
    verification: _result,
    rounds: goal.verificationRounds,
    segments: _segments,
    holdDetail: _holdDetail,
  );

  /// `complete_goal` for the worker's run.
  HarnessTool get completeGoalTool => EvaluationCompleteGoalTool(_claim);

  /// The first segment's message: the product's first-segment wake, framed,
  /// and the goal block.
  Future<String> firstSegment() async {
    final wake = await _store.insertSegmentWake(goal, quiet: true);
    if (wake == null || _queue.take()?.id != wake.id) {
      throw StateError('the goal store wrote no first segment wake');
    }
    return _segment(wake);
  }

  /// Ends the running segment, which spent [segmentMicros], and returns the
  /// next segment's message, or null when the attempt ends: no claim, a
  /// claim the arm accepts, or a verification that passed or stopped for a
  /// person.
  Future<String?> afterSegment({required int segmentMicros}) async {
    final ended = goal;
    await _rows.upsert(
      ended.copyWith(
        runCount: ended.runCount + 1,
        costMicros: ended.costMicros + segmentMicros,
        removeActiveRunId: true,
        updatedAt: _now(),
      ),
    );
    if (ended.hold != GoalHold.verifying) {
      return null;
    }
    if (mode == GoalVerificationMode.claimOnly) {
      _accepted = true;
      return null;
    }
    _result = GoalVerificationResult.stopped;
    await _verifier.start(goal);
    return _settle();
  }

  /// Follows the verifier: runs each review it asks for and returns the
  /// segment a failed round starts, or null once the goal completed or
  /// waits for a person.
  Future<String?> _settle() async {
    while (true) {
      final current = goal;
      if (current.status == AgentGoalStatus.completed) {
        _accepted = true;
        _result = GoalVerificationResult.passed;
        return null;
      }
      if (current.status == AgentGoalStatus.paused) {
        _holdDetail = current.holdDetail;
        _result = _resultOf(current.holdDetail);
        return null;
      }
      final wake = _queue.take();
      if (wake == null) {
        return null;
      }
      if (isGoalReviewWake(wake)) {
        await _review(current, wake);
        continue;
      }
      if (isGoalSegmentWake(wake)) {
        return _segment(wake);
      }
      throw StateError('the verifier wrote an unexpected ${wake.reason} wake');
    }
  }

  Future<String> _segment(Wake wake) async {
    _segments++;
    final current = goal;
    await _rows.upsert(
      current.copyWith(
        activeRunId: '$_attemptId/segment-$_segments',
        updatedAt: _now(),
      ),
    );
    final nonce = newWakeDataNonce();
    final text = await _turnTexts.forRun(
      workspaceId: workspaceId,
      agentId: agentId,
      conversationId: current.conversationId,
      wakeContext: WakeContext.fromWakes([wake], nonce: nonce),
      hasRepl: hasRepl,
    );
    if (text == null) {
      throw StateError('the product gave no goal text for segment $_segments');
    }
    final frame = renderWakeItems(
      [wake],
      nonce: nonce,
      forms: forms,
      replacements: text.wakeItems,
    );
    return '## ${PromptBuilder.wakeContextLabel}\n$frame\n\n${text.section}';
  }

  Future<void> _review(AgentGoalRun goal, Wake wake) async {
    _reviews++;
    final runId = '$_attemptId/review-$_reviews';
    await _verifier.reviewStarted(workspaceId, goal.id, runId, wakeId: wake.id);
    final nonce = newWakeDataNonce();
    final text = await _turnTexts.forRun(
      workspaceId: workspaceId,
      agentId: wake.agentId,
      conversationId: goal.conversationId,
      wakeContext: WakeContext.fromWakes([wake], nonce: nonce),
      hasRepl: false,
    );
    final startedAt = _now();
    final review = text == null
        ? const EvaluationGoalReview(
            completed: false,
            output: null,
            costMicros: 0,
            error: 'the product gave no review prompt',
          )
        : await _reviewer(
            prompt: text.section,
            capMicros:
                wake.runOptions?.costCapMicros ?? goalReviewCapMicros(goal),
          );
    final status = review.completed ? RunStatus.completed : RunStatus.error;
    final endReason = review.completed
        ? RunEndReason.completed
        : RunEndReason.error;
    await _runs.upsert(
      AgentRunLog(
        id: runId,
        agentId: wake.agentId,
        workspaceId: workspaceId,
        conversationId: goal.conversationId,
        spaceId: spaceId,
        startedAt: startedAt,
        completedAt: _now(),
        status: status,
        outputJson: review.output,
        endReason: endReason,
      ),
    );
    await _verifier.onRunSettled(
      AgentRunSettled(
        agentId: wake.agentId,
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: goal.conversationId,
        runId: runId,
        status: status,
        endReason: endReason,
        costMicros: review.costMicros,
        limitResetsAt: null,
        wakeIds: [wake.id],
        requestedByUserId: null,
        wakeReason: WakeReason.goalReview,
        occurredAt: _now(),
      ),
    );
  }

  static GoalVerificationResult _resultOf(String? detail) => switch (detail) {
    GoalHoldDetails.verificationFailed => GoalVerificationResult.failedRounds,
    GoalHoldDetails.cannotVerify => GoalVerificationResult.cannotVerify,
    GoalHoldDetails.sandboxUnavailable =>
      GoalVerificationResult.sandboxUnavailable,
    final d? when d.startsWith(GoalHoldDetails.checkBroken) =>
      GoalVerificationResult.checkBroken,
    _ => GoalVerificationResult.stopped,
  };

  /// Records the worker's claim as the supervisor does: checked by the
  /// product's claim rules, then held for verification (`hold: verifying`).
  Future<HarnessToolResult> _claim(Map<String, dynamic> args) async {
    final summary = args['summary'];
    if (summary is! String || summary.trim().isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: summary');
    }
    final evidence = _evidence(args['evidence']);
    if (evidence == null) {
      return HarnessToolResult.error(
        'Missing or invalid argument: evidence (a list of at most '
        '${EvaluationCompleteGoalTool.maxEvidence} {criterion, evidence} objects)',
      );
    }
    final current = goal;
    final List<GoalClaimEvidence> covered;
    try {
      covered = checkGoalClaim(
        current,
        conversationId: current.conversationId,
        callingRunId: current.activeRunId,
        summary: summary,
        evidence: evidence,
      );
    } on GoalNotActiveSegmentException catch (e) {
      return HarnessToolResult.error(e.message);
    } on GoalRefusedException catch (e) {
      return HarnessToolResult.error(e.message);
    } on ValidationException catch (e) {
      return HarnessToolResult.error(e.message);
    }
    final claimed = current.copyWith(
      hold: GoalHold.verifying,
      removeHoldDetail: true,
      removeHoldUntil: true,
      verification: GoalVerification(
        round: current.verificationRounds + 1,
        claimSummary: summary.trim(),
        claimEvidence: covered,
        lastFailedFingerprint: current.verification?.lastFailedFingerprint,
        at: _now(),
      ),
      updatedAt: _now(),
    );
    await _rows.upsert(claimed);
    _claims++;
    return HarnessToolResult.success(
      jsonEncode({
        'status': 'verifying',
        'goal_id': claimed.id,
        'round': claimed.verification!.round,
        'next': claimRecordedNext,
      }),
    );
  }

  static List<GoalClaimEvidence>? _evidence(Object? raw) {
    if (raw is! List || raw.length > EvaluationCompleteGoalTool.maxEvidence) {
      return null;
    }
    final out = <GoalClaimEvidence>[];
    for (final entry in raw) {
      if (entry is! Map) {
        return null;
      }
      final criterion = entry['criterion'];
      final evidence = entry['evidence'];
      if (criterion is! String || evidence is! String) {
        return null;
      }
      try {
        out.add(GoalClaimEvidence(criterion: criterion, evidence: evidence));
      } on ArgumentError {
        return null;
      }
    }
    return out;
  }
}

/// `complete_goal` on the worker's surface: the product tool's name,
/// arguments and words (the MCP tool lives in a package this one cannot
/// import), with the claim handled by [EvaluationGoalSession].
class EvaluationCompleteGoalTool extends HarnessTool {
  /// Creates the tool over [_claim], which records or refuses one claim.
  EvaluationCompleteGoalTool(this._claim);

  final Future<HarnessToolResult> Function(Map<String, dynamic> args) _claim;

  /// The most evidence entries one claim may carry (the product's).
  static const int maxEvidence = 40;

  @override
  String get name => 'complete_goal';

  @override
  String get description =>
      'Claim that your active goal is fully achieved, with a summary and, '
      'for every "Done means" item, the evidence (the command you ran and '
      'its result, the file and line, the pull request), checked against '
      'the real state. The claim does not close the goal: the server runs '
      "the goal's checks and an independent reviewer inspects the result.";

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'summary': {
        'type': 'string',
        'description': 'What was achieved, at most 4,000 characters.',
      },
      'evidence': {
        'type': 'array',
        'description':
            'One entry per "Done means" item; criterion is the item\'s '
            'number (from 1) or its exact text.',
        'items': {
          'type': 'object',
          'properties': {
            'criterion': {'type': 'string'},
            'evidence': {'type': 'string'},
          },
          'required': ['criterion', 'evidence'],
        },
      },
    },
    'required': ['summary', 'evidence'],
  };

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.write;

  /// The claim changes the goal's state, never a file.
  @override
  Set<ActionClass> get actionClasses => const {};

  @override
  bool get parallelSafe => false;

  /// As the product's `complete_goal` (pinned callable).
  @override
  bool get scriptCallable => true;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) => _claim(args);
}

/// `submit_output` on a review run's surface: keeps the reviewer's answer
/// for the product's parser (`parseGoalReviewOutput`), which judges it.
class EvaluationSubmitOutputTool extends HarnessTool {
  /// The answer submitted last; null until one is.
  Map<String, dynamic>? output;

  @override
  String get name => 'submit_output';

  @override
  String get description =>
      'Submit the structured output payload for your current run. The '
      'payload must follow the answer shape your instructions give.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'output': {
        'type': 'object',
        'description': 'Output payload as a JSON object.',
      },
    },
    'required': ['output'],
  };

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  /// Not for scripts, as the product's `submit_output`: it ends the run's
  /// answer (the review run that offers it has no repl either).
  @override
  bool get scriptCallable => false;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final raw = args['output'];
    if (raw is! Map) {
      return HarnessToolResult.error(
        'Missing or invalid argument: output (a JSON object)',
      );
    }
    output = raw.cast<String, dynamic>();
    return HarnessToolResult.success(jsonEncode({'status': 'submitted'}));
  }
}
