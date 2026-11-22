import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show GoalAlreadyActiveException;
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/learning_events.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_pipeline_link.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/ports/goal_pursuit_port.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_budget_gate.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart'
    show kPipelineRequestedByKey;
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_domain/features/pipelines/domain/templates/goal_pursue_config.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart'
    show GoalSupervisor, kImprovementGoalField;

/// How long a pursued goal's wake waits before the cap is checked again.
const Duration kBudgetWakeDeferral = Duration(minutes: 5);

/// The goals pipelines pursue (`goal.pursue`), bound to the goal supervisor.
/// The link is the goal's row (`AgentGoalRun.pipeline`), read per call in the
/// goal's own workspace; nothing is kept in memory, so all of it holds from
/// the first moment after a restart:
///
/// - [GoalPursuitPort]: starts a step's goal with the link stored, or reads
///   it again for a re-fired step.
/// - On `GoalSettled` the linked step completes (completed) or fails
///   (failed, cancelled, budget exhausted) through
///   [PipelineEngine.settleSuspendedStep], while the step still waits on
///   that goal (a retried step waits on a newer one); a goal paused for a
///   person leaves it suspended.
/// - On `AgentRunSettled` a run that delivered a linked goal's wake (its
///   segments, its verifier's review, the improvement review of its
///   verified completion) is charged to the goal's pipeline run (the goal's
///   runs carry no pipeline run id, so the cost roll-up does not see them).
/// - When the pipeline run ends (cancelled, failed, completed) a linked goal
///   still going is cancelled: a goal never spends outside its pipeline's
///   cap. A run that ended or went away while the server was down is caught
///   at boot ([recover]) and at the goal's next wake.
/// - [WakeAdmissionGuard]: a linked goal's wake (the improvement review of
///   its completion too) waits while the orchestration that owns the run is
///   at its cap, and the run is held; otherwise its run spends at most the
///   lower of what is left of the goal and of the orchestration.
class PipelineGoalPursuits implements GoalPursuitPort, WakeAdmissionGuard {
  /// Creates the binding.
  PipelineGoalPursuits({
    required this._supervisor,
    required this._goals,
    required this._wakes,
    required this._eventBus,
  });

  final GoalSupervisor Function() _supervisor;
  final AgentGoalRunRepository _goals;
  final WakeRepository _wakes;
  final DomainEventBus _eventBus;

  PipelineEngine? _engine;
  PipelineRunRepository? _runs;
  OrchestrationBudgetGate? _gate;

  final List<StreamSubscription<Object?>> _subs = [];

  /// Binds the engine and its budget gate, once they are built, and starts
  /// listening.
  void bind({
    required PipelineEngine engine,
    required PipelineRunRepository runs,
    required OrchestrationBudgetGate gate,
  }) {
    _engine = engine;
    _runs = runs;
    _gate = gate;
    if (_subs.isNotEmpty) {
      return;
    }
    _subs
      ..add(_eventBus.on<GoalSettled>().listen((e) => _safely(onSettled(e))))
      ..add(_eventBus.on<AgentRunSettled>().listen((e) => _safely(onRun(e))))
      ..add(
        _eventBus.on<PipelineRunCancelled>().listen(
          (e) => _safely(onPipelineEnded(e.workspaceId, e.pipelineRunId)),
        ),
      )
      ..add(
        _eventBus.on<PipelineRunFailed>().listen(
          (e) => _safely(onPipelineEnded(e.workspaceId, e.pipelineRunId)),
        ),
      )
      ..add(
        _eventBus.on<PipelineRunCompleted>().listen(
          (e) => _safely(onPipelineEnded(e.workspaceId, e.pipelineRunId)),
        ),
      );
  }

  /// Boot recovery: held runs are watched for a raised cap again, and an
  /// active linked goal whose pipeline run ended or went away while the
  /// server was down is cancelled.
  Future<void> recover() async {
    await _gate?.rewatchHeld();
    // CROSS-WORKSPACE BY DESIGN: the boot sweep over every active goal, as
    // the goal reconciler does; each goal is then read and cancelled in its
    // own workspace.
    for (final goal in await _goals.listActive()) {
      final link = goal.pipeline;
      if (link != null &&
          !await _pipelineGoing(goal.workspaceId, link.pipelineRunId)) {
        await _supervisor().cancelGoal(goal.workspaceId, goal.id);
      }
    }
  }

  void _safely(Future<void> work) => unawaited(
    work.catchError((Object e, StackTrace st) {
      CcHostLog.warning('goal.pursue: $e\n$st');
    }),
  );

  /// Whether [pipelineRunId] is a run of [workspaceId] that has not ended.
  Future<bool> _pipelineGoing(String workspaceId, String pipelineRunId) async {
    final run = await _runs?.getRun(pipelineRunId);
    return run != null && run.workspaceId == workspaceId && !run.isTerminal;
  }

  @override
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
    required String pipelineRunId,
    required String stepId,
  }) async {
    final link = GoalPipelineLink(pipelineRunId: pipelineRunId, stepId: stepId);
    try {
      return await _supervisor().startPursuit(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        objective: objective,
        contract: contract,
        costCapMicros: costCapMicros,
        maxRuns: maxRuns,
        deadlineAt: deadlineAt,
        requestedByUserId: requestedByUserId,
        pipeline: link,
      );
    } on GoalAlreadyActiveException {
      // A restart between the start and the step recording the goal's id:
      // the agent's active goal is this step's when its row says so. Any
      // other active goal of the agent refuses.
      final active = await _goals.getActiveForAgent(workspaceId, agentId);
      if (active == null ||
          active.workspaceId != workspaceId ||
          active.pipeline != link) {
        rethrow;
      }
      return active;
    }
  }

  @override
  Future<AgentGoalRun?> attach({
    required String workspaceId,
    required String goalId,
    required String pipelineRunId,
    required String stepId,
  }) async {
    final goal = await _goals.getById(workspaceId, goalId);
    if (goal == null ||
        goal.workspaceId != workspaceId ||
        goal.pipeline !=
            GoalPipelineLink(pipelineRunId: pipelineRunId, stepId: stepId)) {
      return null;
    }
    return goal;
  }

  /// Settles the linked step of [event]'s goal when the goal ended.
  Future<void> onSettled(GoalSettled event) async {
    final engine = _engine;
    final goal = await _goals.getById(event.workspaceId, event.goalId);
    final link = goal?.pipeline;
    if (engine == null || goal == null || link == null) {
      return;
    }
    if (!goal.status.isTerminal) {
      // Paused for a person: the step waits like a human gate.
      return;
    }
    // The step records the goal's id only after the start returns, so a
    // goal that ended at once (a person's cancel, a first wake skipped) may
    // settle before its id is there: then this waits for it. A retried step
    // that started a newer goal records that one, and this end is not the
    // step's.
    for (var attempt = 0; ; attempt++) {
      final run = await _runs?.getRun(link.pipelineRunId);
      if (run == null || run.workspaceId != goal.workspaceId) {
        return;
      }
      final recorded = run.state[goalPursueStateKey(link.stepId)];
      if (recorded == goal.id) {
        break;
      }
      if (run.isTerminal ||
          attempt >= kGoalRecordWaitAttempts ||
          !await _awaitsRecord(goal, recorded)) {
        return;
      }
      await Future<void>.delayed(kGoalRecordWaitStep);
    }
    await engine.settleSuspendedStep(
      workspaceId: goal.workspaceId,
      pipelineRunId: link.pipelineRunId,
      stepId: link.stepId,
      result: (step) => goalPursueSettlement(goal, step),
    );
  }

  /// Whether the step may still record [goal]: it recorded nothing yet, or
  /// a goal it started before [goal] (the retry's start has not returned).
  Future<bool> _awaitsRecord(AgentGoalRun goal, Object? recorded) async {
    if (recorded == null) {
      return true;
    }
    if (recorded is! String) {
      return false;
    }
    final earlier = await _goals.getById(goal.workspaceId, recorded);
    return earlier != null && earlier.createdAt.isBefore(goal.createdAt);
  }

  /// Charges a run that delivered a linked goal's wake to the goal's
  /// pipeline run, once.
  Future<void> onRun(AgentRunSettled event) async {
    final runs = _runs;
    if (runs == null || event.costMicros <= 0) {
      return;
    }
    final ws = event.workspaceId;
    for (final wakeId in event.wakeIds) {
      final wake = await _wakes.getById(ws, wakeId);
      final goalId = wake == null ? null : pursuedGoalIdOf(wake);
      final link = goalId == null
          ? null
          : (await _goals.getById(ws, goalId))?.pipeline;
      if (link == null) {
        continue;
      }
      final run = await runs.getRun(link.pipelineRunId);
      if (run != null && run.workspaceId == ws) {
        await runs.incrementCost(run.id, event.costMicros, 0);
      }
      return;
    }
  }

  /// Cancels the linked goals of [pipelineRunId] that are still going: the
  /// run ended, and its cap no longer stands over them.
  Future<void> onPipelineEnded(String workspaceId, String pipelineRunId) async {
    for (final goal in await _goals.listForPipelineRun(
      workspaceId,
      pipelineRunId,
    )) {
      if (!goal.status.isTerminal) {
        await _supervisor().cancelGoal(workspaceId, goal.id);
      }
    }
  }

  /// The goal [wake] spends for: its own goal, or the goal whose verified
  /// completion an improvement review looks at.
  static String? pursuedGoalIdOf(Wake wake) {
    final own = wake.detail.goalId;
    if (own != null) {
      return own;
    }
    final reviewed = wake.detail.fields[kImprovementGoalField];
    return reviewed is String && reviewed.isNotEmpty ? reviewed : null;
  }

  @override
  Future<WakeAdmission> admit(Wake wake, {required DateTime now}) async {
    final goalId = pursuedGoalIdOf(wake);
    final engine = _engine;
    final gate = _gate;
    if (goalId == null || engine == null || gate == null) {
      return const WakeAdmission.admit();
    }
    final ws = wake.workspaceId;
    final goal = await _goals.getById(ws, goalId);
    final link = goal?.pipeline;
    if (goal == null || link == null || goal.workspaceId != ws) {
      return const WakeAdmission.admit();
    }
    final review = wake.detail.goalId == null;
    if (!await _pipelineGoing(ws, link.pipelineRunId)) {
      if (!review) {
        await _supervisor().cancelGoal(ws, goal.id);
        return const WakeAdmission.skip(kPipelineRunEndedSkip);
      }
      // The review of a completion may outlive its run (the goal finished
      // the last step), but never the orchestration's cap.
      final left = await gate.remainder(ws, link.pipelineRunId);
      if (left != null && left <= 0) {
        return const WakeAdmission.skip(kOrchestrationBudgetHoldReason);
      }
      return _within(goal, left);
    }
    if (await engine.holdIfOverBudget(ws, link.pipelineRunId)) {
      return WakeAdmission.defer(
        reason: kOrchestrationBudgetHoldReason,
        until: now.add(kBudgetWakeDeferral),
      );
    }
    final left = await gate.remainder(ws, link.pipelineRunId);
    if (left != null && left <= 0) {
      // Spent past the cap since the check: held at the next one.
      return WakeAdmission.defer(
        reason: kOrchestrationBudgetHoldReason,
        until: now.add(kBudgetWakeDeferral),
      );
    }
    return _within(goal, left);
  }

  /// Admits within the lowest of what is left: of [goal] and of its
  /// orchestration ([orchestrationLeft], null when it has no cap). A goal
  /// with nothing left does not lift the orchestration's bound: its own
  /// segment is the goal's guard's to refuse, and a review of its completion
  /// runs within the orchestration's remainder. Nothing left of the
  /// orchestration skips the wake (`orchestration_budget`).
  static WakeAdmission _within(AgentGoalRun goal, int? orchestrationLeft) {
    if (orchestrationLeft != null && orchestrationLeft <= 0) {
      return const WakeAdmission.skip(kOrchestrationBudgetHoldReason);
    }
    final goalLeft = goal.costCapMicros - goal.costMicros;
    final bounds = [?orchestrationLeft, if (goalLeft > 0) goalLeft];
    if (bounds.isEmpty) {
      return const WakeAdmission.admit();
    }
    return WakeAdmission.admitWithin(
      bounds.reduce((a, b) => a < b ? a : b),
    );
  }
}

/// How long a settled goal waits for its step to record its id: the step
/// writes it right after the start returns, so this is a short window.
const int kGoalRecordWaitAttempts = 50;

/// The pause between two looks for a goal's recorded id.
const Duration kGoalRecordWaitStep = Duration(milliseconds: 100);

/// The skip reason of a linked goal's wake whose pipeline run ended.
const String kPipelineRunEndedSkip = 'pipeline_run_ended';

/// [PipelineBudgetGate] over the orchestration that owns a run: at or past
/// its `maxCostMicros` (a positive cap) the run is held. The first hold is
/// told once ([PipelineRunHeld] → a `review` notification, and a system row
/// in the orchestration's space); a raised cap resumes the run.
class OrchestrationBudgetGate implements PipelineBudgetGate {
  /// Creates the gate.
  OrchestrationBudgetGate({
    required this._orchestrations,
    required this._runs,
    required this._messages,
    required this._eventBus,
    required this._engine,
    required this._now,
  });

  final OrchestrationRepository _orchestrations;
  final PipelineRunRepository _runs;
  final MessagingRepository _messages;
  final DomainEventBus _eventBus;
  final PipelineEngine Function() _engine;
  final DateTime Function() _now;

  /// Held runs watched for a raised cap, by run id.
  final Map<String, StreamSubscription<Object?>> _watches = {};

  /// What the orchestration that owns run [runId] has left to spend, or
  /// null when it has no cap (or no orchestration owns the run).
  Future<int?> remainder(String workspaceId, String runId) async {
    final orchestration = await _orchestrations.forPipelineRun(
      workspaceId,
      runId,
    );
    final cap = orchestration?.maxCostMicros;
    if (cap == null || cap <= 0) {
      return null;
    }
    final run = await _runs.getRun(runId);
    return cap -
        (run != null && run.workspaceId == workspaceId
            ? run.totalCostMicros
            : 0);
  }

  @override
  Future<PipelineBudgetHold?> check(PipelineRun run) async {
    final orchestration = await _orchestrations.forPipelineRun(
      run.workspaceId,
      run.id,
    );
    final cap = orchestration?.maxCostMicros;
    if (orchestration == null || cap == null || cap <= 0) {
      return null;
    }
    final spent = (await _runs.getRun(run.id))?.totalCostMicros ?? 0;
    if (spent < cap) {
      return null;
    }
    _watch(run.workspaceId, run.id, orchestration.id);
    return PipelineBudgetHold(
      reason: kOrchestrationBudgetHoldReason,
      orchestrationId: orchestration.id,
      capMicros: cap,
      spentMicros: spent,
      heldAt: _now(),
    );
  }

  @override
  Future<void> onHeld(PipelineRun run, PipelineBudgetHold hold) async {
    final orchestration = await _orchestrations.forPipelineRun(
      run.workspaceId,
      run.id,
    );
    final requester = run.triggerPayload?[kPipelineRequestedByKey];
    _eventBus.publish(
      PipelineRunHeld(
        workspaceId: run.workspaceId,
        pipelineRunId: run.id,
        orchestrationId: hold.orchestrationId,
        spaceId: orchestration?.spaceId,
        reason: hold.reason,
        capMicros: hold.capMicros,
        spentMicros: hold.spentMicros,
        requestedByUserId: requester is String && requester.isNotEmpty
            ? requester
            : null,
        occurredAt: _now(),
      ),
    );
    final spaceId = orchestration?.spaceId;
    if (spaceId != null && spaceId.isNotEmpty) {
      await _messages.sendMessage(
        workspaceId: run.workspaceId,
        spaceId: spaceId,
        content: budgetHoldNotice(hold),
        senderId: 'system',
        senderType: 'system',
        messageType: 'system',
      );
    }
  }

  /// The system row a hold posts.
  static String budgetHoldNotice(PipelineBudgetHold hold) =>
      'This orchestration reached its cost cap '
      '(${formatUsdMicros(hold.spentMicros)} spent of '
      '${formatUsdMicros(hold.capMicros)}). Its remaining steps are held; '
      'raise the cap to resume.';

  void _watch(String workspaceId, String runId, String orchestrationId) {
    if (_watches.containsKey(runId)) {
      return;
    }
    _watches[runId] = _orchestrations
        .watchById(workspaceId, orchestrationId)
        .listen((orchestration) {
          if (orchestration == null) {
            return;
          }
          unawaited(
            _engine()
                .resumeHeld(workspaceId, runId)
                .then((resumed) async {
                  final run = await _runs.getRun(runId);
                  if (resumed || run == null || run.isTerminal) {
                    await _watches.remove(runId)?.cancel();
                  }
                })
                .catchError((Object e) {
                  CcHostLog.warning('budget hold $runId: resume failed: $e');
                }),
          );
        });
  }

  /// After a restart: watches every held run again, and resumes the ones
  /// whose cap was raised while the server was down.
  Future<void> rewatchHeld() async {
    for (final run in await _runs.nonTerminalRuns()) {
      if (!run.state.containsKey(kBudgetHoldStateKey)) {
        continue;
      }
      if (await check(run) == null) {
        await _engine().resumeHeld(run.workspaceId, run.id);
      }
    }
  }

  /// Stops watching.
  Future<void> dispose() async {
    for (final sub in _watches.values) {
      await sub.cancel();
    }
    _watches.clear();
  }
}
