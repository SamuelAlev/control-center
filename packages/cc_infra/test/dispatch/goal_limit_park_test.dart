import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show GoalAlreadyActiveException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/ports/worktree_fingerprint_port.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_checks_outcome.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_infra/src/dispatch/goal_activity.dart';
import 'package:cc_infra/src/dispatch/goal_owed_work.dart';
import 'package:cc_infra/src/dispatch/goal_progress.dart';
import 'package:cc_infra/src/dispatch/goal_store.dart';
import 'package:cc_infra/src/dispatch/goal_supervisor.dart';
import 'package:cc_infra/src/dispatch/goal_verifier.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';
import 'package:test/test.dart';

import 'fake_wake_repository.dart';

const _ws = 'ws-1';
const _space = 'sp-1';
const _conv = 'conv-1';
const _agent = 'agent-1';
const _person = 'user-1';

/// Map-backed goal rows with the store's semantics: workspace-scoped reads,
/// a whole-row compare-and-set, one active goal per agent.
class _Goals implements AgentGoalRunRepository {
  final goals = <String, AgentGoalRun>{};

  /// Runs once, right before the next [replaceIf] compares: another writer
  /// landing between a read and its write.
  Future<void> Function()? beforeNextReplace;

  @override
  Future<AgentGoalRun?> getById(String workspaceId, String id) async {
    final goal = goals[id];
    return goal != null && goal.workspaceId == workspaceId ? goal : null;
  }

  @override
  Future<List<AgentGoalRun>> listByWorkspace(String workspaceId) async =>
      goals.values.where((g) => g.workspaceId == workspaceId).toList();

  @override
  Stream<List<AgentGoalRun>> watchByWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Future<List<AgentGoalRun>> listActive() async =>
      goals.values.where((g) => !g.status.isTerminal).toList();

  @override
  Future<AgentGoalRun?> getActiveForAgent(
    String workspaceId,
    String agentId,
  ) async => goals.values
      .where(
        (g) =>
            g.workspaceId == workspaceId &&
            g.agentId == agentId &&
            g.status == AgentGoalStatus.active,
      )
      .firstOrNull;

  @override
  Future<List<AgentGoalRun>> listHeld(
    String workspaceId, {
    GoalHold? hold,
  }) async => goals.values
      .where(
        (g) =>
            g.workspaceId == workspaceId &&
            !g.status.isTerminal &&
            g.hold != null &&
            (hold == null || g.hold == hold),
      )
      .toList();

  @override
  Future<AgentGoalRun?> getByActiveRunId(
    String workspaceId,
    String runId,
  ) async => goals.values
      .where((g) => g.workspaceId == workspaceId && g.activeRunId == runId)
      .firstOrNull;

  @override
  Future<List<AgentGoalRun>> listForPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => goals.values
      .where(
        (g) =>
            g.workspaceId == workspaceId &&
            g.pipeline?.pipelineRunId == pipelineRunId,
      )
      .toList();

  @override
  Future<void> upsert(AgentGoalRun goal) async {
    _refuseSecondActive(goal);
    goals[goal.id] = goal;
  }

  @override
  Future<bool> replaceIf(
    AgentGoalRun next, {
    required AgentGoalRun expected,
  }) async {
    if (next.id != expected.id || next.workspaceId != expected.workspaceId) {
      throw ArgumentError('not the same goal');
    }
    final race = beforeNextReplace;
    beforeNextReplace = null;
    await race?.call();
    final stored = goals[next.id];
    if (stored == null || stored != expected) {
      return false;
    }
    _refuseSecondActive(next);
    goals[next.id] = next;
    return true;
  }

  @override
  Future<bool> recordSegmentEnd(
    String workspaceId,
    String goalId, {
    required String runId,
    required int costMicros,
    required DateTime at,
  }) async {
    final stored = goals[goalId];
    if (stored == null ||
        stored.workspaceId != workspaceId ||
        stored.activeRunId != runId) {
      return false;
    }
    goals[goalId] = stored.copyWith(
      costMicros: stored.costMicros + costMicros,
      runCount: stored.runCount + 1,
      removeActiveRunId: true,
      updatedAt: at,
    );
    return true;
  }

  void _refuseSecondActive(AgentGoalRun goal) {
    if (goal.status != AgentGoalStatus.active) {
      return;
    }
    if (goals.values.any(
      (g) =>
          g.id != goal.id &&
          g.workspaceId == goal.workspaceId &&
          g.agentId == goal.agentId &&
          g.status == AgentGoalStatus.active,
    )) {
      throw GoalAlreadyActiveException(
        workspaceId: goal.workspaceId,
        agentId: goal.agentId,
      );
    }
  }
}

class _RunLogs implements AgentRunLogRepository {
  final logs = <String, AgentRunLog>{};

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    final log = logs[id];
    return log != null && log.workspaceId == workspaceId ? log : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Agents implements AgentRepository {
  final agents = <String, Agent>{
    _agent: _agentNamed(_agent, 'Ada'),
    'agent-2': _agentNamed('agent-2', 'Rita'),
  };

  @override
  Future<Agent?> getById(String workspaceId, String id) async =>
      workspaceId == _ws ? agents[id] : null;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(workspaceId == _ws ? agents.values.toList() : const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Agent _agentNamed(
  String id,
  String name, {
  AgentLifecycleStatus lifecycle = AgentLifecycleStatus.active,
}) => Agent(
  id: id,
  name: name,
  title: 'Engineer',
  agentMdPath: '/tmp/$id.md',
  workspaceId: _ws,
  skills: AgentSkills(const []),
  createdAt: DateTime.utc(2026),
  lifecycleStatus: lifecycle,
);

class _Fingerprints implements WorktreeFingerprintPort {
  String? value = 'fp-0';

  @override
  Future<String?> fingerprint({
    required String workspaceId,
    required String conversationId,
  }) async => value;
}

class _NoTimer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}

/// The supervisor over a real wake queue (in-memory rows, manual clock).
class _World {
  _World() {
    bus = DomainEventBus();
    queue = WakeQueueService(
      wakes: wakes,
      runLedger: FakeWakeRunLedger(),
      eventBus: bus,
      clock: () => now,
      timerFactory: (_, _) => _NoTimer(),
      nonce: () => 'nonce1',
      ports: WakeQueuePorts(
        workspaceActive: (ws) async => ws == _ws,
        conversationSpace: (ws, conv) async =>
            ws == _ws && conv == _conv ? _space : null,
        agent: agents.getById,
        isMember: (ws, user) async => true,
        takenOver: (ws, space) async => false,
        budgetBlocked: (ws, agent) async => budgetBlocked,
        liveSessions: (_) => const [],
        hasLiveRun: (ws, conv, agentId) async => liveRun(agentId),
        dispatch: (run) => supervisor.dispatchWakeRun(run, _plain),
        postSystemRow:
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
              required String content,
              required Map<String, Object?> metadata,
            }) async => wokeRows.add(content),
      ),
    );
    store = GoalStore(
      goals: goals,
      wakes: wakes,
      wakeQueue: () => queue,
      say:
          ({
            required workspaceId,
            required spaceId,
            required content,
            conversationId,
          }) async => said.add(content),
      eventBus: bus,
      now: () => now,
      startRefs: (ws, conv) async => startRefs,
    );
    progress = GoalProgressObserver(
      fingerprints: fingerprints,
      todos: null,
      activity: activity,
      mcpClassesOf: (_) => null,
    );
    verifier = GoalVerifier(
      store: store,
      runChecks:
          ({
            required workspaceId,
            required spaceId,
            required conversationId,
            required agentId,
            required contract,
          }) async {
            checkRuns++;
            return checkOutcome();
          },
      fingerprintOf: progress.fingerprintOf,
      spaceCheckerOf: (ws, space) async => spaceChecker,
      agents: agents,
      runLogs: runLogs,
    );
    supervisor = GoalSupervisor(
      store: store,
      verifier: verifier,
      progress: progress,
      owedWork: GoalOwedWork(
        wakes: wakes,
        rules: null,
        asks: null,
        openDelegations:
            (ws, {required conversationId, required agentId}) async => [
              for (var i = 0; i < openDelegations; i++) 'ticket-$i',
            ],
      ),
      agents: agents,
      runLogs: runLogs,
      todos: null,
      hasLiveRun: (ws, conv, agentId) async => liveRun(agentId),
      eventBus: bus,
    );
    queue
      ..registerGuard(supervisor)
      ..registerSettledHandler(supervisor.onWakeSettled);
    bus.on<GoalSettled>().listen(settled.add);
  }

  DateTime now = DateTime.utc(2026, 11, 19, 12);
  final goals = _Goals();
  final wakes = FakeWakeRepository();
  final runLogs = _RunLogs();
  final agents = _Agents();
  final fingerprints = _Fingerprints();
  final activity = RunToolActivity();
  late final DomainEventBus bus;
  late final WakeQueueService queue;
  late final GoalStore store;
  late final GoalProgressObserver progress;
  late final GoalVerifier verifier;
  late final GoalSupervisor supervisor;

  final dispatched = <WakeDispatchRequest>[];
  final runIds = <String>[];
  final wokeRows = <String>[];
  final said = <String>[];
  final settled = <GoalSettled>[];
  int openDelegations = 0;
  bool budgetBlocked = false;
  GoalStartRefs? startRefs;
  String? spaceChecker;
  int checkRuns = 0;
  GoalChecksOutcome Function() checkOutcome = () => GoalChecksOutcome(
    status: GoalChecksStatus.ran,
    results: const [],
    fingerprint: null,
  );
  var _runSeq = 0;

  /// Live runs: their run log is active.
  bool liveRun(String agentId) =>
      runLogs.logs.values.any((l) => l.agentId == agentId && l.isActive);

  Future<String?> _plain(WakeDispatchRequest run) async {
    dispatched.add(run);
    final id = 'run-${++_runSeq}';
    runIds.add(id);
    runLogs.logs[id] = AgentRunLog(
      id: id,
      agentId: run.agentId,
      workspaceId: run.workspaceId,
      conversationId: run.conversationId,
      spaceId: run.spaceId,
      startedAt: now,
      status: RunStatus.running,
      adapter: 'claude-code',
    );
    await beforeReturn?.call(id);
    return id;
  }

  /// Runs after a run row exists and before the dispatch returns its id: a
  /// run that ends while its dispatch is still attaching.
  Future<void> Function(String runId)? beforeReturn;

  AgentGoalRun get goal => goals.goals.values.single;

  Future<void> pump() async {
    for (var i = 0; i < 200; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> advance(Duration by) async {
    now = now.add(by);
    await queue.tick();
    await pump();
  }

  Future<AgentGoalRun> start(String text) async {
    final goal = await supervisor.startGoal(
      workspaceId: _ws,
      spaceId: _space,
      conversationId: _conv,
      agentId: _agent,
      userText: text,
      requestedByUserId: _person,
    );
    await pump();
    return goal!;
  }

  /// Ends run [runId] the way the server does: the terminal row, then
  /// `AgentRunSettled`.
  Future<void> settle(
    String runId, {
    RunEndReason reason = RunEndReason.completed,
    int cost = 100000,
    String? summary,
    Map<String, dynamic>? output,
    List<RunToolCall>? calls,
    DateTime? limitResetsAt,
  }) async {
    final log = runLogs.logs[runId]!;
    final ok =
        reason == RunEndReason.completed || reason == RunEndReason.budget;
    runLogs.logs[runId] = log.copyWith(
      status: ok ? RunStatus.completed : RunStatus.error,
      completedAt: now,
      summary: summary,
      outputJson: output,
    );
    if (calls != null) {
      activity.record(workspaceId: _ws, runId: runId, calls: calls);
    }
    bus.publish(
      AgentRunSettled(
        agentId: log.agentId,
        workspaceId: _ws,
        spaceId: _space,
        conversationId: _conv,
        runId: runId,
        status: ok ? RunStatus.completed : RunStatus.error,
        endReason: reason,
        costMicros: cost,
        limitResetsAt: limitResetsAt,
        wakeIds: const [],
        requestedByUserId: _person,
        wakeReason: null,
        occurredAt: now,
      ),
    );
    await pump();
  }

  /// Claims completion from the goal's live segment.
  Future<AgentGoalRun> claim({List<GoalClaimEvidence> evidence = const []}) =>
      supervisor.claimCompletion(
        _ws,
        _agent,
        conversationId: _conv,
        callingRunId: goal.activeRunId,
        summary: 'done',
        evidence: evidence,
      );

  List<Wake> openGoalWakes() => [
    for (final w in wakes.all(_ws))
      if (w.detail.goalId != null &&
          (w.state == WakeState.pending || w.state == WakeState.held))
        w,
  ];

  void dispose() {
    supervisor.dispose();
    unawaited(queue.stop());
  }
}

/// The test file `goal_supervisor_test.dart` owns the world above; this file
/// copies it to test a goal's park at a provider's usage limit.
void main() {
  late _World w;

  setUp(() async {
    w = _World();
    await w.queue.start();
  });
  tearDown(() => w.dispose());

  Wake? limitWake() => w.wakes
      .all(_ws)
      .where((x) => x.reason == WakeReason.limitReset)
      .firstOrNull;

  test('a limit with a reset parks the goal with no strike and no failure, '
      'and resumes it at the reset plus 30 seconds', () async {
    await w.start('ship it');
    final reset = w.now.add(const Duration(hours: 2));
    await w.settle(
      'run-1',
      reason: RunEndReason.usageLimit,
      limitResetsAt: reset,
    );
    final parked = w.goal;
    expect(parked.status, AgentGoalStatus.active);
    expect(parked.hold, GoalHold.limit);
    expect(parked.holdUntil, reset);
    expect(parked.parkCount, 1);
    expect(parked.consecutiveFailures, 0);
    expect(parked.noProgressStreak, 0);
    final wake = limitWake()!;
    expect(wake.dedupKey, 'limit:run-1');
    expect(wake.state, WakeState.pending);
    expect(wake.notBefore, reset.add(const Duration(seconds: 30)));
    expect(wake.detail.goalId, parked.id);
    expect(wake.detail.sourceRunId, 'run-1');
    expect(wake.detail.fields[WakeFields.provider], 'anthropic');
    expect(wake.detail.fields[WakeFields.resetsAt], reset.toIso8601String());
    expect(wake.requestedByUserId, _person);
    expect(wake.runOptions?.costCapMicros, isNotNull);
    expect(w.said.last, contains('reached the anthropic usage limit'));
    expect(w.said.last, contains('park 1 of 8'));

    // Not before the reset plus 30 seconds.
    await w.advance(const Duration(hours: 2, seconds: 29));
    expect(w.dispatched, hasLength(1));
    await w.advance(const Duration(seconds: 1));
    await w.advance(WakeQueueService.quietWindow);
    expect(w.dispatched, hasLength(2));
    final resumed = w.dispatched.last;
    expect(resumed.wakeContext.wakeReason, WakeReason.limitReset);
    expect(resumed.wakeContext.goalId, parked.id);
    expect(resumed.costCapMicros, isNotNull);
    expect(w.goal.hold, isNull);
    expect(w.goal.holdUntil, isNull);
    expect(w.goal.activeRunId, 'run-2');
    expect(limitWake()!.state, WakeState.delivered);
  });

  test('the wake exists when the hold is written', () async {
    await w.start('ship it');
    Wake? atHold;
    w.goals.beforeNextReplace = () async => atHold = limitWake();
    await w.settle(
      'run-1',
      reason: RunEndReason.usageLimit,
      limitResetsAt: w.now.add(const Duration(minutes: 30)),
    );
    expect(atHold, isNotNull);
    expect(atHold!.dedupKey, 'limit:run-1');
    expect(w.goal.hold, GoalHold.limit);
  });

  test('a limit with no reset fails the segment as before', () async {
    await w.start('ship it');
    await w.settle('run-1', reason: RunEndReason.usageLimit);
    expect(w.goal.consecutiveFailures, 1);
    expect(w.goal.hold, isNull);
    expect(w.goal.parkCount, 0);
    expect(limitWake(), isNull);
  });

  test('a reset more than seven days away is treated as no reset', () async {
    await w.start('ship it');
    await w.settle(
      'run-1',
      reason: RunEndReason.usageLimit,
      limitResetsAt: w.now.add(const Duration(days: 7, minutes: 1)),
    );
    expect(w.goal.consecutiveFailures, 1);
    expect(w.goal.hold, isNull);
    expect(limitWake(), isNull);
  });

  test('a limit reported while the server stops is not a park', () async {
    await w.start('ship it');
    w.queue.beginStopping();
    await w.settle(
      'run-1',
      reason: RunEndReason.usageLimit,
      limitResetsAt: w.now.add(const Duration(hours: 1)),
    );
    expect(w.goal.hold, isNull);
    expect(w.goal.consecutiveFailures, 0);
    expect(w.goal.parkCount, 0);
    expect(limitWake(), isNull);
  });

  test('a goal parks eight times; the ninth pauses it for review, and a '
      'resume lets it park again', () async {
    await w.start('ship it');
    final id = w.goal.id;
    w.goals.goals[id] = w.goal.copyWith(parkCount: LimitPark.maxGoalParks);
    await w.settle(
      'run-1',
      reason: RunEndReason.usageLimit,
      limitResetsAt: w.now.add(const Duration(hours: 1)),
    );
    expect(w.goal.status, AgentGoalStatus.paused);
    expect(w.goal.hold, GoalHold.needsReview);
    expect(w.goal.holdDetail, 'limit_parks');
    expect(w.goal.consecutiveFailures, 0);
    expect(limitWake(), isNull);
    expect(w.settled.single.hold, GoalHold.needsReview);

    await w.supervisor.resumeGoal(_ws, id);
    await w.pump();
    expect(w.goal.status, AgentGoalStatus.active);
    expect(w.goal.parkCount, 0);
  });

  test('each park counts: the second limit is park 2', () async {
    await w.start('ship it');
    await w.settle(
      'run-1',
      reason: RunEndReason.usageLimit,
      limitResetsAt: w.now.add(const Duration(minutes: 10)),
    );
    await w.advance(const Duration(minutes: 10, seconds: 30));
    await w.advance(WakeQueueService.quietWindow);
    expect(w.goal.activeRunId, 'run-2');
    await w.settle(
      'run-2',
      reason: RunEndReason.usageLimit,
      limitResetsAt: w.now.add(const Duration(minutes: 10)),
    );
    expect(w.goal.parkCount, 2);
    expect(w.goal.hold, GoalHold.limit);
    expect(
      w.wakes.all(_ws).where((x) => x.reason == WakeReason.limitReset),
      hasLength(2),
    );
  });

  test('a person cancelling the resume pauses the goal', () async {
    await w.start('ship it');
    await w.settle(
      'run-1',
      reason: RunEndReason.usageLimit,
      limitResetsAt: w.now.add(const Duration(hours: 1)),
    );
    final wake = limitWake()!;
    expect(
      await w.queue.cancel(_ws, wake.id, reason: 'cancelled_by_person'),
      isTrue,
    );
    await w.pump();
    expect(w.goal.status, AgentGoalStatus.paused);
    expect(w.goal.hold, GoalHold.byPerson);
    await w.advance(const Duration(hours: 2));
    expect(w.dispatched, hasLength(1));
  });

  test('the sweep resumes a parked goal whose wake is gone once the reset '
      'passed, and not before', () async {
    await w.start('ship it');
    final reset = w.now.add(const Duration(hours: 1));
    await w.settle(
      'run-1',
      reason: RunEndReason.usageLimit,
      limitResetsAt: reset,
    );
    // The row lost behind the queue's back (no settled handler runs).
    await w.wakes.cancel(
      _ws,
      ids: [limitWake()!.id],
      reason: 'lost',
      now: w.now,
    );
    await w.supervisor.sweep();
    expect(w.goal.hold, GoalHold.limit);
    w.now = reset.add(const Duration(seconds: 31));
    await w.supervisor.sweep();
    await w.pump();
    expect(w.goal.hold, isNull);
    await w.advance(WakeQueueService.quietWindow);
    expect(w.dispatched, hasLength(2));
    expect(
      w.dispatched.last.wakeContext.wakeReason,
      WakeReason.goalContinuation,
    );
  });
}
