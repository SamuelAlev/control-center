import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/cc_domain.dart'
    show
        GoalAlreadyActiveException,
        GoalNotActiveSegmentException,
        GoalRefusedException,
        ValidationException;
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/ports/goal_supervision_port.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_block.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_budget_shares.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_checker_choice.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_command.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_pipeline_link.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_progress_marks.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_infra/src/dispatch/goal_claim.dart';
import 'package:cc_infra/src/dispatch/goal_owed_work.dart';
import 'package:cc_infra/src/dispatch/goal_progress.dart';
import 'package:cc_infra/src/dispatch/goal_store.dart';
import 'package:cc_infra/src/dispatch/goal_verifier.dart';
import 'package:cc_infra/src/dispatch/wake_dispatch.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

part 'goal_limit_park.dart';
part 'goal_segment_end.dart';
part 'goal_sweep.dart';

/// Whether an agent has a live top-level run in a conversation (the wake
/// queue's `hasLiveRun` port).
typedef GoalLiveRunCheck =
    Future<bool> Function(
      String workspaceId,
      String conversationId,
      String agentId,
    );

/// What a run is to the goals: one of a goal's segments, or the review of a
/// goal's completion claim.
enum GoalRunKind {
  /// A segment of a goal: a wake-started run of the goal's agent in the
  /// goal's conversation that the goal counts as its own.
  segment,

  /// The independent review of a goal's completion claim.
  review,
}

/// The guard's skip and deferral reasons (wake state reasons).
abstract final class GoalWakeReasons {
  /// The goal is gone or closed.
  static const String goalEnded = 'goal_ended';

  /// The goal is at its cost cap, run budget or deadline.
  static const String budgetExhausted = 'goal_budget_exhausted';

  /// A review wake whose goal no longer waits on that review.
  static const String reviewStale = 'goal_review_stale';

  /// The goal is paused.
  static const String paused = 'goal_paused';

  /// The goal holds for a person or a verification.
  static const String held = 'goal_held';

  /// A goal's wakes cancelled because a segment started.
  static const String segmentStarted = 'goal_segment_started';

  /// A goal's wakes cancelled because a person paused, cancelled or closed
  /// it.
  static const String stopped = 'goal_stopped';

  /// The guard's own skips: a settled handler ignores them.
  static const Set<String> ownSkips = {goalEnded, budgetExhausted, reviewStale};
}

/// Keeps a durable `/goal` alive as wake-driven segments (plan section 8).
///
/// - Every segment starts from one of the goal's wakes (`goalContinuation`,
///   `goalVerification` after a failed verification) or, while the goal
///   waits for something it is owed (`hold: waiting`), from the first wake of
///   its agent in its conversation. The supervisor never dispatches a run
///   itself: a delay is a wake's `notBefore` ([GoalStore.insertSegmentWake]).
/// - Admission ([admit], a [WakeAdmissionGuard]) skips a closed goal's wakes,
///   defers a paused or held goal's, never lets a goal's wake into a live
///   run's lane, and closes a goal at its budget wall.
/// - [dispatchWakeRun] wraps the queue's dispatch: it caps the segment, makes
///   it fresh when the goal is, and attaches the run as the goal's segment.
/// - Each segment's end is decided once, from [AgentRunSettled] (the table
///   "What happens when a segment ends"); progress is observed
///   ([GoalProgressObserver]), never reported; what the agent is owed is
///   read from rows ([GoalOwedWork]).
/// - `complete_goal` records a claim ([claimCompletion]); the segment's end
///   hands it to the [GoalVerifier].
/// - A sweep ([sweep], every [sweepInterval] and once at [start]) gives an
///   active goal that has nothing running, holding or queued its
///   continuation.
class GoalSupervisor implements GoalSupervisionPort, WakeAdmissionGuard {
  /// Creates the supervisor and subscribes it to [AgentRunSettled],
  /// [AgentAwaitingInput] and [AgentInputResolved] on [eventBus].
  GoalSupervisor({
    required this._store,
    required this._verifier,
    required this._progress,
    required GoalOwedWork owedWork,
    required this._agents,
    required this._runLogs,
    required this._todos,
    required this._hasLiveRun,
    required DomainEventBus? eventBus,
    this.sweepInterval = const Duration(minutes: 5),
  }) : _owed = owedWork {
    if (eventBus != null) {
      _subscriptions
        ..add(
          eventBus.on<AgentRunSettled>().listen(
            (event) => unawaited(_safely('run settled', _onRunSettled(event))),
          ),
        )
        ..add(
          eventBus.on<AgentAwaitingInput>().listen(
            (event) => _inOrder(
              event.workspaceId,
              event.waitId,
              'awaiting input',
              () => _onAwaitingInput(event),
            ),
          ),
        )
        ..add(
          eventBus.on<AgentInputResolved>().listen(
            (event) => _inOrder(
              event.workspaceId,
              event.waitId,
              'input resolved',
              () => _onInputResolved(event),
            ),
          ),
        );
    }
  }

  /// Hard cost cap for a whole goal, in micro-dollars (50 USD; priced models
  /// only). The `agent_goal_runs.cost_cap_micros` column default matches.
  static const int defaultCostCapMicros = 50000000;

  /// Consecutive failed segments after which the goal fails.
  static const int maxConsecutiveFailures = 3;

  /// Cap for the failure backoff.
  static const Duration maxBackoff = Duration(minutes: 15);

  /// How long a goal that waits for what it is owed waits at most before its
  /// fallback continuation.
  static const Duration owedFallback = Duration(minutes: 20);

  /// How long a goal wake is deferred while its goal is held or its agent
  /// busy.
  static const Duration heldDeferral = Duration(minutes: 5);

  /// The delays after the first and the second segment without progress.
  static const List<Duration> strikeDelays = [
    Duration(seconds: 30),
    Duration(seconds: 60),
  ];

  /// The prefix of the hold detail while a segment waits for a person's
  /// answer (`input:<waitId>`).
  static const String inputHoldPrefix = 'input:';

  /// The hold detail of a goal a person paused while its claim was being
  /// verified: resuming verifies the claim again.
  static const String claimPendingDetail = GoalHoldDetails.claimPending;

  /// How often [sweep] runs.
  final Duration sweepInterval;

  final GoalStore _store;
  final GoalVerifier _verifier;
  final GoalProgressObserver _progress;
  final GoalOwedWork _owed;
  final AgentRepository _agents;
  final AgentRunLogRepository _runLogs;
  final TodoRepository? _todos;
  final GoalLiveRunCheck _hasLiveRun;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// Each wait on a person's events in order, by workspace and wait id: a
  /// wait answered at once must not have its end handled before its start,
  /// which would leave a hold nothing clears. Other waits never wait for it.
  final Map<String, Future<void>> _waitChains = {};

  /// Each goal's hold writes for waits on people, one after the other, by
  /// workspace and goal id.
  final Map<String, Future<void>> _goalChains = {};

  /// The open waits on people of each segment run (`_runKey` → wait ids):
  /// the goal holds on the person while any is open.
  final Map<String, Set<String>> _runWaits = {};

  /// An open wait (`_runKey` of its wait id) → its segment's goal and run.
  final Map<String, ({String goalId, String runId})> _waitSegments = {};

  /// Waits whose end arrived before their start (the bus delivers each
  /// event type on its own lane), bounded: their start holds nothing.
  final LinkedHashSet<String> _endedFirst = LinkedHashSet();

  /// Told when a person paused, resumed, cancelled or closed a goal, so the
  /// server forgets its unanswered stretch (plan section 12). Set once.
  void Function(AgentGoalRun goal)? onPersonDecision;
  Timer? _sweepTimer;
  bool _sweeping = false;

  /// Segment run id → goal id, from the dispatch (bounded).
  final LinkedHashMap<String, String> _segments = LinkedHashMap();
  static const int _maxRemembered = 1024;

  /// Attaches in flight, with the conversation and agent of their segment:
  /// a settlement or a wait that finds no goal for its run waits for those
  /// of its own conversation and agent before looking again.
  final Map<
    Future<void>,
    ({String workspaceId, String conversationId, String agentId})
  >
  _attaching = {};

  /// Goals whose verification this supervisor is running now.
  final Set<String> _verifying = {};

  /// The verifications running now ([_verify]).
  final Set<Future<void>> _verifications = {};

  // ------------------------------------------------------------- lifecycle

  /// Starts the sweep: once now, then every [sweepInterval]. Call after the
  /// wake queue started (boot), so that a sweep's wakes are delivered.
  void start() {
    _sweepTimer?.cancel();
    _sweepTimer = Timer.periodic(
      sweepInterval,
      (_) => unawaited(_safely('sweep', sweep())),
    );
    unawaited(_safely('sweep', sweep()));
  }

  /// Stops the sweep and the subscriptions.
  void dispose() {
    _sweepTimer?.cancel();
    _sweepTimer = null;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  // --------------------------------------------------------- person actions

  /// Starts a durable goal for [agentId] from a signed-in person's `/goal`
  /// body [userText] and delivers its first segment's wake at once (with no
  /// "Woke …" row: the person's message and the "Started" message say it).
  ///
  /// Throws [GoalAlreadyActiveException] (`goal_already_active`) when the
  /// agent already has an active goal, and a [ValidationException] with its
  /// kind when the body is refused: [GoalCommand.parse]'s refusals, a
  /// `--checker` that names no agent, several or the goal's own, or no
  /// objective (`goal_command_invalid`). Returns the goal as stored after
  /// the first wake's delivery (its `activeRunId` is the first segment when
  /// it started at once).
  Future<AgentGoalRun?> startGoal({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String agentId,
    required String userText,
    required String requestedByUserId,
  }) async {
    if (await _store.goals.getActiveForAgent(workspaceId, agentId) != null) {
      throw GoalAlreadyActiveException(
        workspaceId: workspaceId,
        agentId: agentId,
      );
    }
    final now = _store.now();
    // A refusal is thrown with its kind: the command path posts it as one
    // typed `command_refused` row (`startGoalFromMessage`).
    final command = GoalCommand.parse(userText);
    final checkerRef = command.checkerRef;
    final checkerAgentId = checkerRef == null
        ? null
        : chooseGoalChecker(
            checkerRef,
            agents: await _agents.watchByWorkspace(workspaceId).first,
            goalAgentId: agentId,
          ).id;
    if (command.objective.isEmpty) {
      throw const ValidationException(
        'A goal needs an objective, e.g. "/goal keep the changelog current".',
        code: goalCommandInvalidKind,
      );
    }
    final draft = AgentGoalRun(
      id: _store.newGoalId(),
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      agentId: agentId,
      userText: command.objective,
      deadlineAt: command.days == null
          ? null
          : now.add(Duration(days: command.days!)),
      costCapMicros: command.budgetMicros ?? defaultCostCapMicros,
      maxRuns: command.maxRuns,
      requestedByUserId: requestedByUserId,
      contract: command.contract,
      fresh: command.fresh,
      unattended: command.unattended ?? GoalUnattendedPolicy.wait,
      checkerAgentId: checkerAgentId,
      createdAt: now,
      updatedAt: now,
    );
    return _begin(draft);
  }

  /// Starts the goal a pipeline's `goal.pursue` step pursues: [startGoal]
  /// without slash parsing. The objective, contract and limits come from the
  /// step's checked configuration; [requestedByUserId] is the pipeline run's
  /// requester (null: nobody asked); [pipeline] is stored with the goal.
  /// Throws [GoalAlreadyActiveException] (the partial unique index's).
  Future<AgentGoalRun> startPursuit({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String agentId,
    required String objective,
    required GoalContract? contract,
    required int costCapMicros,
    required int? maxRuns,
    required DateTime? deadlineAt,
    required String? requestedByUserId,
    required GoalPipelineLink pipeline,
  }) async {
    final now = _store.now();
    return _begin(
      AgentGoalRun(
        id: _store.newGoalId(),
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        userText: objective,
        deadlineAt: deadlineAt,
        costCapMicros: costCapMicros,
        maxRuns: maxRuns,
        requestedByUserId: requestedByUserId,
        contract: contract,
        unattended: GoalUnattendedPolicy.wait,
        pipeline: pipeline,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<AgentGoalRun> _begin(AgentGoalRun draft) async {
    // The first segment is compared against the worktree as it was now,
    // and the review's "what changed" against each checkout's commit.
    final fingerprint = await _progress.fingerprintOf(draft);
    final goal = draft.copyWith(
      lastFingerprint: fingerprint,
      startRefs: await _store.startRefsOf(draft),
      // The state it starts from is a state it has had: coming back to it
      // is no progress.
      progressMarks: GoalProgressMarks.empty.remember(
        GoalProgressMarks.markOf(
          fingerprint: fingerprint,
          checklist: await _progress.checklistDigestOf(draft),
          activity: null,
        ),
      ),
    );
    // The partial unique index refuses a second active goal that raced past
    // the check above with the same [GoalAlreadyActiveException].
    await _store.goals.upsert(goal);
    try {
      await _todos?.setGoal(
        goal.workspaceId,
        goal.conversationId,
        goal.userText,
      );
    } on Object catch (e) {
      CcInfraLog.warning('goal ${goal.id}: checklist title not set: $e');
    }
    await _store.say(
      goal,
      'Started a durable /goal: ${goal.userText}\n\n'
      'It runs in segments until its completion claim passes the server\'s '
      'checks and an independent review, a person stops it, or the cost cap '
      '(${formatUsdMicros(goal.costCapMicros)}) is hit'
      '${goal.maxRuns == null ? '' : ', or the run budget of ${goal.maxRuns} runs is exhausted'}'
      '${goal.deadlineAt == null ? '' : ', or the deadline passes'}'
      '.',
    );
    await _store.insertSegmentWake(goal, deliver: true, quiet: true);
    return await _store.goals.getById(goal.workspaceId, goal.id) ?? goal;
  }

  /// Pauses [goalId] at a person's request (`hold: byPerson`) and cancels
  /// its pending wakes. A live segment runs to its end; its cost counts. A
  /// claim being verified is kept: resuming verifies it again.
  Future<void> pauseGoal(String workspaceId, String goalId) async {
    final goal = await _store.goals.getById(workspaceId, goalId);
    if (goal == null) {
      return;
    }
    final paused = await _store.transition(
      goal,
      (g) => g.status != AgentGoalStatus.active
          ? null
          : g.copyWith(
              status: AgentGoalStatus.paused,
              hold: GoalHold.byPerson,
              holdDetail: g.hold == GoalHold.verifying
                  ? claimPendingDetail
                  : null,
              removeHoldDetail: g.hold != GoalHold.verifying,
              removeHoldUntil: true,
              updatedAt: _store.now(),
            ),
    );
    if (paused == null) {
      return;
    }
    await _store.cancelWakes(paused, GoalWakeReasons.stopped);
    onPersonDecision?.call(paused);
    await _store.say(
      paused,
      'Durable /goal paused. Resume it to keep it running.',
    );
  }

  /// Resumes a paused [goalId], or a `budgetExhausted` one whose cap
  /// [raiseCostCapMicros] lifts above its spend.
  ///
  /// Resuming clears the hold and the strike and failure counts; a goal a
  /// verification stopped (`verification_failed`, `cannot_verify`) also
  /// starts its rounds over. A goal whose checks could not run (a broken
  /// check, no sandbox) or that was paused while its claim was being
  /// verified verifies that claim again; any other goal gets its next
  /// segment's wake now (unless its last segment still runs, whose end
  /// decides).
  ///
  /// Refused with [GoalAlreadyActiveException] (`goal_already_active`) while
  /// another goal of the same agent is active.
  Future<void> resumeGoal(
    String workspaceId,
    String goalId, {
    int? raiseCostCapMicros,
  }) async {
    final goal = await _store.goals.getById(workspaceId, goalId);
    final fromBudget = goal?.status == AgentGoalStatus.budgetExhausted;
    if (goal == null ||
        (goal.status != AgentGoalStatus.paused && !fromBudget)) {
      return;
    }
    final other = await _store.goals.getActiveForAgent(
      workspaceId,
      goal.agentId,
    );
    if (other != null && other.id != goal.id) {
      throw GoalAlreadyActiveException(
        workspaceId: workspaceId,
        agentId: goal.agentId,
      );
    }
    if (fromBudget &&
        (raiseCostCapMicros == null || raiseCostCapMicros <= goal.costMicros)) {
      await _store.say(
        goal,
        'Durable /goal is stopped at its cost cap '
        '(${formatUsdMicros(goal.costCapMicros)} spent: '
        '${formatUsdMicros(goal.costMicros)}). '
        'Resume it with a raised budget to continue.',
      );
      return;
    }
    var reverify = false;
    final resumed = await _store.transition(goal, (g) {
      if (g.status != goal.status) {
        return null;
      }
      final detail = g.holdDetail;
      final claim = g.verification;
      reverify =
          claim != null &&
          ((g.hold == GoalHold.needsReview &&
                  (GoalHoldDetails.restartsVerification(detail) ||
                      // Out of parks during the review: the claim was
                      // never judged.
                      (detail == LimitPark.goalHoldDetail &&
                          claim.verdict == null))) ||
              (g.hold == GoalHold.byPerson && detail == claimPendingDetail));
      final next = g.copyWith(
        status: AgentGoalStatus.active,
        costCapMicros: raiseCostCapMicros,
        removeHoldUntil: true,
        removeHoldDetail: true,
        noProgressStreak: 0,
        consecutiveFailures: 0,
        // A person's resume starts the waiting stretch over.
        progressMarks: g.progressMarks?.endWait(),
        // A person chose to continue: the parks start over.
        parkCount: 0,
        verificationRounds:
            g.hold == GoalHold.needsReview &&
                GoalHoldDetails.isVerificationStop(detail)
            ? 0
            : g.verificationRounds,
        updatedAt: _store.now(),
      );
      return reverify
          ? next.copyWith(hold: GoalHold.verifying)
          : next.copyWith(removeHold: true);
    });
    if (resumed == null) {
      return;
    }
    onPersonDecision?.call(resumed);
    final wall = budgetWall(resumed);
    if (wall != null) {
      await _terminate(
        resumed,
        AgentGoalStatus.budgetExhausted,
        'Durable /goal stopped: $wall.',
      );
      return;
    }
    await _store.say(resumed, 'Durable /goal resumed.');
    if (resumed.activeRunId != null && await _segmentLive(resumed)) {
      // Its end decides what comes next (a claim it holds included).
      return;
    }
    if (reverify) {
      // A person's resume never waits for the checks.
      _verifyLater(resumed);
      return;
    }
    await _store.insertSegmentWake(resumed);
  }

  /// Cancels [goalId] (terminal) and its pending wakes. A live segment runs
  /// to its end; its cost counts.
  Future<void> cancelGoal(String workspaceId, String goalId) async {
    final goal = await _store.goals.getById(workspaceId, goalId);
    if (goal == null || goal.status.isTerminal) {
      return;
    }
    onPersonDecision?.call(goal);
    await _terminate(
      goal,
      AgentGoalStatus.cancelled,
      'Durable /goal cancelled.',
    );
  }

  /// Closes [goalId], paused for a person's review (`hold: needsReview`), as
  /// done on [userId]'s word: `completed`, its `verification` marked
  /// approved by them. Returns the closed goal. Throws
  /// [GoalRefusedException] (`goal_not_in_review`) when the goal is not
  /// waiting for a review.
  Future<AgentGoalRun> approveCompletion(
    String workspaceId,
    String goalId, {
    required String userId,
  }) async {
    final goal = await _store.goals.getById(workspaceId, goalId);
    AgentGoalRun? approve(AgentGoalRun g) {
      if (g.status != AgentGoalStatus.paused ||
          g.hold != GoalHold.needsReview) {
        return null;
      }
      final now = _store.now();
      final v =
          g.verification ??
          GoalVerification(
            round: g.verificationRounds < 1 ? 1 : g.verificationRounds,
            claimSummary: '',
            at: now,
          );
      return g.copyWith(
        status: AgentGoalStatus.completed,
        summary: v.claimSummary.isEmpty ? null : v.claimSummary,
        removeSummary: v.claimSummary.isEmpty,
        verification: v.copyWith(approvedByUserId: userId, at: now),
        removeHold: true,
        removeHoldDetail: true,
        removeHoldUntil: true,
        updatedAt: now,
      );
    }

    final closed = goal == null ? null : await _store.transition(goal, approve);
    if (closed == null) {
      throw const GoalRefusedException(
        'Only a goal paused for a review can be closed as done.',
        kind: GoalRefusedException.notInReviewKind,
      );
    }
    await _store.cancelWakes(closed, GoalWakeReasons.stopped);
    onPersonDecision?.call(closed);
    const message = 'Durable /goal closed as done by a person.';
    await _store.say(closed, message);
    _store.publishSettled(closed, summary: closed.summary ?? message);
    return closed;
  }

  // ------------------------------------------------------------ agent side

  @override
  Future<AgentGoalRun?> activeGoalForAgent(
    String workspaceId,
    String agentId,
  ) => _store.goals.getActiveForAgent(workspaceId, agentId);

  /// [agentId]'s active goal (status `active`) when it runs in
  /// [conversationId]; null otherwise.
  Future<AgentGoalRun?> activeGoalInConversation(
    String workspaceId, {
    required String agentId,
    required String conversationId,
  }) async {
    final goal = await _store.goals.getActiveForAgent(workspaceId, agentId);
    return goal != null &&
            goal.status == AgentGoalStatus.active &&
            goal.conversationId == conversationId
        ? goal
        : null;
  }

  @override
  Future<AgentGoalRun> claimCompletion(
    String workspaceId,
    String agentId, {
    required String conversationId,
    required String? callingRunId,
    required String summary,
    required List<GoalClaimEvidence> evidence,
  }) async {
    final found = await _store.goals.getActiveForAgent(workspaceId, agentId);
    final covered = checkGoalClaim(
      found,
      conversationId: conversationId,
      callingRunId: callingRunId,
      summary: summary,
      evidence: evidence,
    );
    final goal = found!;
    final claimed = await _store.transition(goal, (g) {
      if (g.status != AgentGoalStatus.active ||
          g.activeRunId != callingRunId ||
          g.hold == GoalHold.verifying) {
        return null;
      }
      return g.copyWith(
        hold: GoalHold.verifying,
        removeHoldDetail: true,
        removeHoldUntil: true,
        verification: GoalVerification(
          round: g.verificationRounds + 1,
          claimSummary: summary.trim(),
          claimEvidence: covered,
          lastFailedFingerprint: g.verification?.lastFailedFingerprint,
          at: _store.now(),
        ),
        updatedAt: _store.now(),
      );
    });
    if (claimed != null) {
      return claimed;
    }
    final reread = await _store.goals.getById(workspaceId, goal.id);
    if (reread?.hold == GoalHold.verifying) {
      throw goalClaimPending;
    }
    throw const GoalNotActiveSegmentException(
      "This run is no longer your goal's active segment; only that segment "
      'can claim it.',
    );
  }

  // ------------------------------------------------------- run questions

  /// What [runId] of [workspaceId] is to the goals: a segment, a review,
  /// or null (neither).
  Future<GoalRunKind?> goalRunKindOf({
    required String workspaceId,
    required String runId,
  }) async {
    if (_segments.containsKey(_runKey(workspaceId, runId))) {
      return GoalRunKind.segment;
    }
    if (await _verifier.isReviewRun(workspaceId, runId)) {
      return GoalRunKind.review;
    }
    if (await _store.goals.getByActiveRunId(workspaceId, runId) != null) {
      return GoalRunKind.segment;
    }
    return null;
  }

  /// Whether [runId] is a goal segment or a goal review (the checker skips
  /// both).
  Future<bool> isGoalRun({
    required String workspaceId,
    required String runId,
  }) async =>
      await goalRunKindOf(workspaceId: workspaceId, runId: runId) != null;

  // ------------------------------------------------------------- admission

  @override
  Future<WakeAdmission> admit(Wake wake, {required DateTime now}) async {
    final goalId = wake.detail.goalId;
    if (goalId == null) {
      return const WakeAdmission.admit();
    }
    final goal = await _store.goals.getById(wake.workspaceId, goalId);
    if (goal == null ||
        goal.status.isTerminal ||
        goal.conversationId != wake.conversationId) {
      return const WakeAdmission.skip(GoalWakeReasons.goalEnded);
    }
    final busyUntil = now.add(heldDeferral);
    if (isGoalReviewWake(wake)) {
      // Only the wake this verification waits for starts its review.
      final v = goal.verification;
      if (goal.status != AgentGoalStatus.active ||
          goal.hold != GoalHold.verifying ||
          v == null ||
          v.verdict != null ||
          v.reviewWakeId != wake.id ||
          (v.reviewRunId != null && v.reviewRunId!.isNotEmpty) ||
          wake.detail.fields[WakeFields.round] != v.round) {
        return const WakeAdmission.skip(GoalWakeReasons.reviewStale);
      }
      // A review is a fresh, read-only run: never pushed into a live lane.
      if (await _hasLiveRun(
        wake.workspaceId,
        wake.conversationId,
        wake.agentId,
      )) {
        return WakeAdmission.defer(
          reason: WakeStateReasons.liveRunNoInput,
          until: busyUntil,
        );
      }
      return const WakeAdmission.admit();
    }
    if (wake.agentId != goal.agentId) {
      return const WakeAdmission.skip(GoalWakeReasons.goalEnded);
    }
    if (goal.status == AgentGoalStatus.paused) {
      return WakeAdmission.defer(
        reason: GoalWakeReasons.paused,
        until: busyUntil,
      );
    }
    if (_heldFor(goal, wake)) {
      return WakeAdmission.defer(
        reason: GoalWakeReasons.held,
        until: busyUntil,
      );
    }
    if (goal.activeRunId != null ||
        await _hasLiveRun(
          wake.workspaceId,
          wake.conversationId,
          wake.agentId,
        )) {
      return WakeAdmission.defer(
        reason: WakeStateReasons.liveRunNoInput,
        until: busyUntil,
      );
    }
    final wall = budgetWall(goal);
    if (wall != null) {
      await _terminate(
        goal,
        AgentGoalStatus.budgetExhausted,
        'Durable /goal stopped: $wall.',
        cancelWakes: false,
      );
      return const WakeAdmission.skip(GoalWakeReasons.budgetExhausted);
    }
    return const WakeAdmission.admit();
  }

  /// The wake queue's dispatch for [request], through [plain] (the plain
  /// agent dispatch). A review run is recorded as its goal's review. A run
  /// that is a goal's segment (the goal's own wake, or any wake of the goal's
  /// agent in its conversation while it waits) is capped at the segment's
  /// share of the goal's budget, made fresh when the goal is, and attached:
  /// the goal's `activeRunId`, its `waiting` hold cleared, its other pending
  /// wakes (a fallback continuation) cancelled.
  Future<String?> dispatchWakeRun(
    WakeDispatchRequest request,
    WakeRunDispatcher plain,
  ) async {
    final context = request.wakeContext;
    for (final wake in context.wakes) {
      final goalId = wake.detail.goalId;
      if (isGoalReviewWake(wake) && goalId != null) {
        final runId = await plain(request);
        if (runId != null) {
          await _verifier.reviewStarted(
            request.workspaceId,
            goalId,
            runId,
            wakeId: wake.id,
          );
        }
        return runId;
      }
    }
    final goal = await _segmentGoalFor(request);
    if (goal == null) {
      return plain(request);
    }
    final cap = goalSegmentCapMicros(goal);
    if (cap <= 0) {
      // At its budget wall: the guard closes it at its next wake.
      return plain(request);
    }
    final requested = request.costCapMicros;
    final segment = WakeDispatchRequest(
      workspaceId: request.workspaceId,
      spaceId: request.spaceId,
      conversationId: request.conversationId,
      agentId: request.agentId,
      wakeContext: context,
      requestedByUserId: request.requestedByUserId,
      mentionChain: request.mentionChain,
      inReplyToAgentId: request.inReplyToAgentId,
      costCapMicros: requested == null || requested > cap ? cap : requested,
      expectedOutputSchema: request.expectedOutputSchema,
      freshHistory: request.freshHistory || goal.fresh,
      readOnly: request.readOnly,
    );
    final attached = Completer<void>();
    _attaching[attached.future] = (
      workspaceId: request.workspaceId,
      conversationId: request.conversationId,
      agentId: request.agentId,
    );
    try {
      final runId = await plain(segment);
      if (runId != null) {
        _remember(goal.workspaceId, runId, goal.id);
        await _attach(goal, runId);
      }
      return runId;
    } finally {
      attached.complete();
      _attaching.remove(attached.future);
    }
  }

  Future<AgentGoalRun?> _segmentGoalFor(WakeDispatchRequest request) async {
    final ws = request.workspaceId;
    final goalId = request.wakeContext.goalId;
    if (goalId != null) {
      final own = request.wakeContext.wakes.any(
        (w) => w.detail.goalId == goalId && isGoalSegmentWake(w),
      );
      final goal = await _store.goals.getById(ws, goalId);
      if (own &&
          goal != null &&
          !goal.status.isTerminal &&
          goal.agentId == request.agentId &&
          goal.conversationId == request.conversationId) {
        return goal;
      }
    }
    final waiting = await _store.goals.getActiveForAgent(ws, request.agentId);
    if (waiting != null &&
        waiting.status == AgentGoalStatus.active &&
        waiting.hold == GoalHold.waiting &&
        waiting.conversationId == request.conversationId &&
        waiting.activeRunId == null) {
      return waiting;
    }
    return null;
  }

  Future<void> _attach(AgentGoalRun goal, String runId) async {
    // A checkout the goal has no start for (the first segment provisioned
    // the space's worktree, or another run added a repository) starts from
    // where it is as this segment starts.
    final now = await _store.startRefsOf(goal);
    final attached = await _store.transition(goal, (g) {
      if (g.activeRunId != null) {
        return null;
      }
      final refs = GoalStartRefs.merged(g.startRefs, now);
      final next = g.copyWith(
        activeRunId: runId,
        startRefs: refs,
        updatedAt: _store.now(),
      );
      return g.hold == GoalHold.waiting || g.hold == GoalHold.limit
          ? next.copyWith(
              removeHold: true,
              removeHoldDetail: true,
              removeHoldUntil: true,
            )
          : next;
    });
    if (attached == null) {
      CcInfraLog.warning(
        'goal ${goal.id}: run $runId started but the goal has a segment',
      );
      return;
    }
    await _store.cancelWakes(attached, GoalWakeReasons.segmentStarted);
    await _progress.segmentStarted(attached, runId);
  }

  /// The queue's settled-wake handler: a review wake that could not be
  /// delivered goes to the verifier; a segment wake the queue skipped for a
  /// reason of its own (the agent deleted, no budget, three refused
  /// dispatches) stops the goal for a person.
  Future<void> onWakeSettled(WakeSettlement settled) async {
    final wake = settled.wake;
    final goalId = wake.detail.goalId;
    if (goalId == null) {
      return;
    }
    if (isGoalReviewWake(wake)) {
      await _verifier.onReviewWakeSettled(settled);
      return;
    }
    if (await _limitWakeCancelled(settled)) {
      return;
    }
    if (!isGoalSegmentWake(wake) ||
        (settled.state != WakeState.skipped &&
            settled.state != WakeState.expired)) {
      return;
    }
    final kind = settled.reason ?? settled.state.name;
    if (GoalWakeReasons.ownSkips.contains(kind)) {
      return;
    }
    final goal = await _store.goals.getById(wake.workspaceId, goalId);
    if (goal == null) {
      return;
    }
    await _pauseForSkip(goal, kind, whateverRuns: false);
  }

  /// The person [userId] left [workspaceId]: each of their active goals is
  /// paused for a person exactly as its next segment's skip at admission
  /// would pause it (`needsReview`, `wake_skipped: person_removed`), at
  /// once and whatever runs: nothing of theirs may start again. The wakes
  /// are the caller's to cancel (`person_removed`); any member may cancel
  /// the goal. Returns how many goals were paused.
  Future<int> pauseForRemovedPerson(String workspaceId, String userId) async {
    var paused = 0;
    for (final goal in await _store.goals.listByWorkspace(workspaceId)) {
      if (goal.workspaceId == workspaceId &&
          goal.requestedByUserId == userId &&
          await _pauseForSkip(
                goal,
                WakeStateReasons.personRemoved,
                whateverRuns: true,
              ) !=
              null) {
        paused++;
      }
    }
    return paused;
  }

  /// Pauses the active [goal] for a person because its work cannot go on
  /// ([kind], said as `wake_skipped: <kind>`). Between segments only (and
  /// then its wakes are cancelled) unless [whateverRuns]. Returns the
  /// paused goal, or null when it was not active (or, between segments
  /// only, a segment or review runs).
  Future<AgentGoalRun?> _pauseForSkip(
    AgentGoalRun goal,
    String kind, {
    required bool whateverRuns,
  }) async {
    final detail = '${GoalHoldDetails.wakeSkipped}: $kind';
    final stopped = await _store.transition(
      goal,
      (g) =>
          g.status != AgentGoalStatus.active ||
              (!whateverRuns &&
                  (g.activeRunId != null || g.hold == GoalHold.verifying))
          ? null
          : g.copyWith(
              status: AgentGoalStatus.paused,
              hold: GoalHold.needsReview,
              holdDetail: detail.length > AgentGoalRun.maxHoldDetailLength
                  ? detail.substring(0, AgentGoalRun.maxHoldDetailLength)
                  : detail,
              removeHoldUntil: true,
              updatedAt: _store.now(),
            ),
    );
    if (stopped == null) {
      return null;
    }
    if (!whateverRuns) {
      await _store.cancelWakes(stopped, GoalWakeReasons.stopped);
    }
    // Nobody resumes a goal whose person left (`mayResumeGoal`): its row
    // must not send anyone looking for a Resume.
    final summary = kind == WakeStateReasons.personRemoved
        ? 'The person this goal acted for left the workspace. It cannot be '
              'resumed: stop it, or start a new goal.'
        : "The goal's next segment could not start ($kind). Resume the goal "
              'once that is fixed.';
    await _store.say(stopped, 'Durable /goal waits for a person: $summary');
    _store.publishSettled(stopped, summary: summary);
    return stopped;
  }

  // ------------------------------------------------------------ settlement

  /// A segment that ended at a provider's usage limit: the park until the
  /// reported reset (`goal_limit_park.dart`), or a failed segment without one.
  Future<void> onLimitReached(AgentGoalRun goal, AgentRunSettled event) =>
      _parkAtLimit(goal, event);

  /// The goal whose live segment is [runId]. One whose attach is still in
  /// flight is waited for when it is of [conversationId] and [agentId]
  /// (each only when known): a dispatch parked elsewhere (on credentials,
  /// the path lock) never delays this lookup.
  Future<AgentGoalRun?> _segmentGoalOf(
    String workspaceId,
    String runId, {
    required String? conversationId,
    required String? agentId,
  }) async {
    Future<AgentGoalRun?> find() async {
      final goalId = _segments[_runKey(workspaceId, runId)];
      if (goalId != null) {
        final goal = await _store.goals.getById(workspaceId, goalId);
        if (goal != null && goal.activeRunId == runId) {
          return goal;
        }
      }
      return _store.goals.getByActiveRunId(workspaceId, runId);
    }

    final found = await find();
    if (found != null || (conversationId == null && agentId == null)) {
      return found;
    }
    final relevant = [
      for (final MapEntry(key: attach, value: of) in _attaching.entries)
        if (of.workspaceId == workspaceId &&
            (conversationId == null || of.conversationId == conversationId) &&
            (agentId == null || of.agentId == agentId))
          attach,
    ];
    if (relevant.isEmpty) {
      return found;
    }
    // A segment that ended (or asked) before its attach landed.
    await Future.wait(relevant);
    return find();
  }

  /// Whether a segment's end may still be written: the goal is active, has
  /// no other segment, and nobody holds it for something else meanwhile.
  static bool _segmentEndApplies(AgentGoalRun g) =>
      g.status == AgentGoalStatus.active &&
      g.activeRunId == null &&
      (g.hold == null || g.hold == GoalHold.person);

  static AgentGoalRun _withoutPersonHold(AgentGoalRun g) =>
      g.hold == GoalHold.person
      ? g.copyWith(removeHold: true, removeHoldDetail: true)
      : g;

  /// Verifies [goal]'s claim ([GoalVerifier.start]), once at a time per
  /// goal.
  Future<void> _verify(AgentGoalRun goal) async {
    if (!_verifying.add(goal.id)) {
      return;
    }
    final work = _safely('verify ${goal.id}', _verifier.start(goal));
    _verifications.add(work);
    try {
      await work;
    } finally {
      _verifications.remove(work);
      _verifying.remove(goal.id);
    }
  }

  /// [_verify] without waiting for it: the sweep and a person's resume never
  /// wait for a goal's checks.
  void _verifyLater(AgentGoalRun goal) => unawaited(_verify(goal));

  /// Completes when the verifications running now have finished.
  Future<void> verificationsDone() => Future.wait(_verifications.toList());

  // ------------------------------------------------------- waiting on people

  void _inOrder(
    String workspaceId,
    String waitId,
    String what,
    Future<void> Function() work,
  ) =>
      unawaited(_serial(_waitChains, _runKey(workspaceId, waitId), what, work));

  /// Runs [work] after the earlier work of [key] in [chains]; never throws.
  static Future<void> _serial(
    Map<String, Future<void>> chains,
    String key,
    String what,
    Future<void> Function() work,
  ) {
    final next = (chains[key] ?? Future<void>.value()).then(
      (_) => _safely(what, work()),
    );
    chains[key] = next;
    return next.whenComplete(() {
      if (identical(chains[key], next)) {
        chains.remove(key);
      }
    });
  }

  /// A segment waits on a person: its goal holds on the person
  /// (`hold: person`, `input:<waitId>`) while any of the segment's waits is
  /// open.
  /// The only writer of that hold (an unattended approval included).
  Future<void> _onAwaitingInput(AgentAwaitingInput event) async {
    final runId = event.runId;
    if (runId == null) {
      return;
    }
    final ws = event.workspaceId;
    final waitKey = _runKey(ws, event.waitId);
    if (_endedFirst.remove(waitKey)) {
      return;
    }
    final goal = await _segmentGoalOf(
      ws,
      runId,
      conversationId: event.conversationId,
      agentId: event.agentId,
    );
    if (goal == null) {
      return;
    }
    final runKey = _runKey(ws, runId);
    _waitSegments[waitKey] = (goalId: goal.id, runId: runId);
    (_runWaits[runKey] ??= {}).add(event.waitId);
    await _serial(
      _goalChains,
      _runKey(ws, goal.id),
      'hold for a person',
      () async {
        final current = await _store.goals.getById(ws, goal.id);
        if (current == null ||
            !(_runWaits[runKey]?.contains(event.waitId) ?? false)) {
          return;
        }
        await _store.transition(
          current,
          (g) =>
              g.status != AgentGoalStatus.active ||
                  g.activeRunId != runId ||
                  g.hold != null
              ? null
              : g.copyWith(
                  hold: GoalHold.person,
                  holdDetail: '$inputHoldPrefix${event.waitId}',
                  updatedAt: _store.now(),
                ),
        );
      },
    );
  }

  /// A wait on a person ended: the hold that names it moves to another open
  /// wait of the same segment, or is cleared when none is left.
  Future<void> _onInputResolved(AgentInputResolved event) async {
    final ws = event.workspaceId;
    final waitKey = _runKey(ws, event.waitId);
    final segment = _waitSegments.remove(waitKey);
    if (segment == null) {
      // Not a segment's wait, or its start is not handled yet.
      _endedFirst.add(waitKey);
      if (_endedFirst.length > _maxRemembered) {
        _endedFirst.remove(_endedFirst.first);
      }
      return;
    }
    final runKey = _runKey(ws, segment.runId);
    final open = _runWaits[runKey]?..remove(event.waitId);
    if (open != null && open.isEmpty) {
      _runWaits.remove(runKey);
    }
    final detail = '$inputHoldPrefix${event.waitId}';
    await _serial(
      _goalChains,
      _runKey(ws, segment.goalId),
      'clear a hold for a person',
      () async {
        final goal = await _store.goals.getById(ws, segment.goalId);
        if (goal == null) {
          return;
        }
        await _store.transition(goal, (g) {
          if (g.hold != GoalHold.person || g.holdDetail != detail) {
            return null;
          }
          final rest = _runWaits[runKey];
          if (rest != null &&
              rest.isNotEmpty &&
              g.status == AgentGoalStatus.active &&
              g.activeRunId == segment.runId) {
            return g.copyWith(
              holdDetail: '$inputHoldPrefix${(rest.toList()..sort()).first}',
              updatedAt: _store.now(),
            );
          }
          return g.copyWith(
            removeHold: true,
            removeHoldDetail: true,
            updatedAt: _store.now(),
          );
        });
      },
    );
  }

  // ----------------------------------------------------------------- sweep

  /// Gives every active goal that has nothing running, holding or queued its
  /// next wake: a continuation now, a waiting goal's fallback, a claim whose
  /// verification nobody is running (the server restarted under it) its
  /// verification. A segment that ended while nothing listened is counted
  /// first. Closes a goal at its budget wall.
  ///
  /// CROSS-WORKSPACE BY DESIGN: reads every workspace's goals
  /// (`AgentGoalRunRepository.listActive`); each action is scoped to the
  /// goal's own workspace.
  Future<void> sweep() => _sweepAll();

  // ---------------------------------------------------------------- shared

  /// Names the budget wall [goal] sits at (its deadline, its cost cap, its
  /// run budget), or null within budget.
  String? budgetWall(AgentGoalRun goal) {
    if (goal.deadlinePassed(_store.now())) {
      return 'the deadline passed';
    }
    if (goal.costCapReached) {
      return 'the cost cap of ${formatUsdMicros(goal.costCapMicros)} was '
          'reached';
    }
    if (goal.runBudgetExhausted) {
      return 'the run budget of ${goal.maxRuns} runs was exhausted';
    }
    return null;
  }

  /// 30 s × 2^(n-1), capped at [maxBackoff].
  static Duration backoff(int consecutiveFailures) {
    final shift = consecutiveFailures <= 1 ? 0 : consecutiveFailures - 1;
    final delay = Duration(seconds: 30 << (shift > 10 ? 10 : shift));
    return delay > maxBackoff ? maxBackoff : delay;
  }

  /// Closes [goal] with [status] (unless it is closed already), cancels its
  /// wakes, says [message] and publishes [GoalSettled]. The goal keeps a
  /// live segment's `activeRunId`, so that segment's cost counts when it
  /// settles.
  Future<AgentGoalRun?> _terminate(
    AgentGoalRun goal,
    AgentGoalStatus status,
    String message, {
    String? summary,
    bool cancelWakes = true,
  }) async {
    final live = await _segmentLive(goal);
    final ended = goal.activeRunId;
    if (!live && ended != null) {
      // Its settlement may not have counted it yet: count it now, as the
      // sweep does. Whoever records it first is the only one to.
      final log = await _runLogs.getById(goal.workspaceId, ended);
      await _store.goals.recordSegmentEnd(
        goal.workspaceId,
        goal.id,
        runId: ended,
        costMicros: log?.totalCostMicrosWithChildren ?? 0,
        at: _store.now(),
      );
    }
    final closed = await _store.transition(
      goal,
      (g) => g.status.isTerminal
          ? null
          : g.copyWith(
              status: status,
              summary: summary,
              removeSummary: summary == null,
              removeActiveRunId: !live,
              removeHold: true,
              removeHoldUntil: true,
              removeHoldDetail: true,
              updatedAt: _store.now(),
            ),
    );
    if (closed == null) {
      return null;
    }
    if (cancelWakes) {
      await _store.cancelWakes(closed, GoalWakeReasons.stopped);
    }
    await _store.say(closed, message);
    _store.publishSettled(closed, summary: summary ?? message);
    return closed;
  }

  Future<bool> _segmentLive(AgentGoalRun goal) async {
    final runId = goal.activeRunId;
    if (runId == null) {
      return false;
    }
    final log = await _runLogs.getById(goal.workspaceId, runId);
    return log != null && log.isActive;
  }

  /// A run id is looked up only with its workspace.
  static String _runKey(String workspaceId, String runId) =>
      '$workspaceId\u0000$runId';

  void _remember(String workspaceId, String runId, String goalId) {
    _segments[_runKey(workspaceId, runId)] = goalId;
    while (_segments.length > _maxRemembered) {
      _segments.remove(_segments.keys.first);
    }
  }

  static String _seconds(Duration d) =>
      d.inMinutes >= 1 && d.inSeconds % 60 == 0
      ? '${d.inMinutes} min'
      : '${d.inSeconds} s';

  static Future<void> _safely(String what, Future<void> work) async {
    try {
      await work;
    } on Object catch (e, st) {
      // A supervisor hiccup must never take down the event bus; the next
      // settlement or the sweep drives the goal again.
      CcInfraLog.error('GoalSupervisor: $what failed', e, st);
    }
  }
}
