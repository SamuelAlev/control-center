import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show
        GoalAlreadyActiveException,
        GoalNotActiveSegmentException,
        GoalRefusedException,
        ValidationException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/ports/worktree_fingerprint_port.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/peer_ask_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_checks_outcome.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_pipeline_link.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_progress_marks.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_infra/src/dispatch/goal_activity.dart';
import 'package:cc_infra/src/dispatch/goal_owed_work.dart';
import 'package:cc_infra/src/dispatch/goal_progress.dart';
import 'package:cc_infra/src/dispatch/goal_store.dart';
import 'package:cc_infra/src/dispatch/goal_supervisor.dart';
import 'package:cc_infra/src/dispatch/goal_verifier.dart';
import 'package:cc_infra/src/dispatch/ticket_settled_wakes.dart';
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
    'agent-3': _agentNamed('agent-3', 'Bo'),
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

/// The agent's active wake rules in the conversation (owed when one-off or
/// a watch).
class _Rules implements WakeRuleRepository {
  final rules = <WakeRule>[];

  @override
  Future<List<WakeRule>> listForConversation(
    String workspaceId,
    String conversationId, {
    Set<WakeRuleStatus>? statuses,
  }) async => [
    for (final r in rules)
      if (r.workspaceId == workspaceId && r.conversationId == conversationId) r,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The agent's pending asks from the conversation.
class _Asks implements PeerAskRepository {
  final asks = <PeerAsk>[];

  @override
  Future<List<PeerAsk>> listPending(
    String workspaceId, {
    String? askerAgentId,
    String? recipientAgentId,
    String? askerConversationId,
  }) async => [
    for (final a in asks)
      if (a.workspaceId == workspaceId &&
          a.askerAgentId == askerAgentId &&
          a.askerConversationId == askerConversationId)
        a,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

WakeRule _rule(String id, WakeTrigger trigger, DateTime at) => WakeRule(
  id: id,
  workspaceId: _ws,
  spaceId: _space,
  conversationId: _conv,
  agentId: _agent,
  trigger: trigger,
  note: 'check again',
  costCapMicros: 1000000,
  expiresAt: at.add(const Duration(days: 7)),
  origin: WakeRuleOrigin.agent,
  createdAt: at,
  updatedAt: at,
);

PeerAsk _ask(String id, DateTime at) => PeerAsk(
  id: id,
  workspaceId: _ws,
  askerAgentId: _agent,
  askerConversationId: _conv,
  askerSpaceId: _space,
  recipientAgentId: 'agent-2',
  questionHash: 'q-$id',
  createdAt: at,
  expiresAt: at.add(const Duration(days: 2)),
);

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
            checkStarts.add(agentId);
            checksRunning++;
            maxChecksRunning = checksRunning > maxChecksRunning
                ? checksRunning
                : maxChecksRunning;
            try {
              await (checkGates[agentId] ?? checkGate)?.future;
              return checkOutcome();
            } finally {
              checksRunning--;
            }
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
        rules: rules,
        asks: asks,
        openDelegations:
            (ws, {required conversationId, required agentId}) async =>
                delegations,
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
  final rules = _Rules();
  final asks = _Asks();
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
  List<String> delegations = const [];
  bool budgetBlocked = false;
  GoalStartRefs? startRefs;
  String? spaceChecker;
  int checkRuns = 0;
  int checksRunning = 0;
  int maxChecksRunning = 0;

  /// While set, every check run waits for it.
  Completer<void>? checkGate;

  /// Per agent, in place of [checkGate].
  final checkGates = <String, Completer<void>>{};

  /// The agents whose checks started, in order.
  final checkStarts = <String>[];

  /// A read-only run is refused the way a backend that cannot hold a run to
  /// reading refuses it (`AgentDispatchService`, before any run row).
  bool refuseReadOnly = false;
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
    if (refuseReadOnly && run.readOnly) {
      throw const ReadOnlyRunUnavailableException.backend();
    }
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

  /// The sweep, then the verifications it started off the sweep.
  Future<void> sweep() async {
    await supervisor.sweep();
    await supervisor.verificationsDone();
    await pump();
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
      endReason: reason,
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

const _bash = RunToolCall(
  name: 'bash',
  arguments: {'command': 'make test'},
  ok: true,
);
const _edit = RunToolCall(
  name: 'edit',
  arguments: {'path': 'a.dart'},
  ok: true,
);

GoalCheckResult _check(String run, {int? exit = 0, bool broken = false}) =>
    GoalCheckResult(
      run: run,
      where: GoalCheckLocation.worktree,
      exitCode: exit,
      outputTail: exit == 0 ? '' : 'FAILED: 1 test',
      broken: broken,
    );

void main() {
  late _World w;

  setUp(() async {
    w = _World();
    // The queue delivers nothing before it is started (after the boot
    // reaper, on the server).
    await w.queue.start();
  });
  tearDown(() => w.dispose());

  group('segments are wakes', () {
    test('the first segment is a goal wake delivered at once, quietly, '
        'capped and fresh when the goal is', () async {
      final goal = await w.start('ship the feature --fresh --budget 3');
      expect(w.dispatched, hasLength(1));
      final run = w.dispatched.single;
      expect(run.wakeContext.wakeReason, WakeReason.goalContinuation);
      expect(run.wakeContext.goalId, goal.id);
      expect(run.requestedByUserId, _person);
      expect(run.freshHistory, isTrue);
      expect(run.costCapMicros, 3000000);
      // The person's message and the "Started" line say it: no "Woke" row.
      expect(w.wokeRows, isEmpty);
      expect(w.said.single, startsWith('Started a durable /goal'));
      expect(goal.activeRunId, w.runIds.single);
      expect(goal.lastFingerprint, 'fp-0');
      expect(
        await w.supervisor.goalRunKindOf(workspaceId: _ws, runId: 'run-1'),
        GoalRunKind.segment,
      );
      // A run id is never answered for another workspace.
      expect(
        await w.supervisor.goalRunKindOf(workspaceId: 'ws-2', runId: 'run-1'),
        isNull,
      );
    });

    test('a segment is capped at 5 USD however large the budget', () async {
      await w.start('ship it --budget 50');
      expect(w.dispatched.single.costCapMicros, 5000000);
    });

    test('a second goal of the same agent is refused', () async {
      await w.start('one');
      expect(
        () => w.supervisor.startGoal(
          workspaceId: _ws,
          spaceId: _space,
          conversationId: _conv,
          agentId: _agent,
          userText: 'two',
          requestedByUserId: _person,
        ),
        throwsA(isA<GoalAlreadyActiveException>()),
      );
    });

    test('a refused body throws with its kind and says nothing itself: the '
        'command path posts the typed row', () async {
      for (final body in ['', '--budget 5', 'ship it --checker Nobody']) {
        await expectLater(
          w.supervisor.startGoal(
            workspaceId: _ws,
            spaceId: _space,
            conversationId: _conv,
            agentId: _agent,
            userText: body,
            requestedByUserId: _person,
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.code,
              'code',
              startsWith('goal_'),
            ),
          ),
        );
      }
      expect(w.said, isEmpty);
      expect(w.dispatched, isEmpty);
    });

    test('a pipeline step\'s goal is stored with its step, waits for a '
        'person on a question, and is refused beside another goal', () async {
      final link = GoalPipelineLink(pipelineRunId: 'prun-1', stepId: 'pursue');
      Future<AgentGoalRun> pursue() => w.supervisor.startPursuit(
        workspaceId: _ws,
        spaceId: _space,
        conversationId: _conv,
        agentId: _agent,
        objective: 'Ship the release notes',
        contract: null,
        costCapMicros: 2000000,
        maxRuns: 4,
        deadlineAt: null,
        requestedByUserId: null,
        pipeline: link,
      );
      final goal = await pursue();
      await w.pump();
      expect(goal.pipeline, link);
      expect(goal.userText, 'Ship the release notes');
      expect(goal.maxRuns, 4);
      expect(goal.requestedByUserId, isNull);
      expect(goal.unattended, GoalUnattendedPolicy.wait);
      expect(w.dispatched.single.wakeContext.goalId, goal.id);
      expect(w.dispatched.single.requestedByUserId, isNull);
      await expectLater(pursue(), throwsA(isA<GoalAlreadyActiveException>()));
    });
  });

  group('what happens when a segment ends', () {
    test('progress (the worktree changed) continues at once', () async {
      await w.start('ship it');
      w.fingerprints.value = 'fp-1';
      await w.settle('run-1');
      expect(w.goal.runCount, 1);
      expect(w.goal.lastFingerprint, 'fp-1');
      expect(w.goal.noProgressStreak, 0);
      await w.advance(WakeQueueService.quietWindow);
      expect(w.dispatched, hasLength(2));
      expect(w.goal.activeRunId, 'run-2');
      // Only the first segment is quiet: a later one leaves its "Woke" row.
      expect(w.wokeRows, hasLength(1));
    });

    test('three segments without progress pause the goal for a person, '
        'after 30 s and 60 s', () async {
      await w.start('ship it');
      await w.settle('run-1');
      expect(w.goal.noProgressStreak, 1);
      await w.advance(const Duration(seconds: 29));
      expect(w.dispatched, hasLength(1));
      await w.advance(const Duration(seconds: 2));
      expect(w.dispatched, hasLength(2));
      await w.settle('run-2');
      expect(w.goal.noProgressStreak, 2);
      await w.advance(const Duration(seconds: 59));
      expect(w.dispatched, hasLength(2));
      await w.advance(const Duration(seconds: 2));
      expect(w.dispatched, hasLength(3));
      await w.settle('run-3');
      expect(w.goal.status, AgentGoalStatus.paused);
      expect(w.goal.hold, GoalHold.needsReview);
      expect(w.goal.holdDetail, GoalHoldDetails.stalled);
      expect(w.settled.single.hold, GoalHold.needsReview);
      await w.advance(const Duration(minutes: 30));
      expect(w.dispatched, hasLength(3));
      expect(w.openGoalWakes(), isEmpty);
    });

    test('A2: the same calls twice are a strike; the same command after an '
        'edit is not', () async {
      await w.start('ship it');
      await w.settle('run-1', calls: const [_bash]);
      expect(w.goal.noProgressStreak, 0, reason: 'first time: new');
      await w.advance(WakeQueueService.quietWindow);
      await w.settle('run-2', calls: const [_bash]);
      expect(w.goal.noProgressStreak, 1, reason: 'same digest');
      await w.advance(const Duration(seconds: 31));
      await w.settle('run-3', calls: const [_edit, _bash]);
      expect(w.goal.noProgressStreak, 0);
      expect(w.goal.lastActivityDigest, activityDigest(const [_edit, _bash]));
    });

    test('A2: a segment that made no tool call is never progress, even with '
        'a changed worktree', () async {
      await w.start('ship it');
      w.fingerprints.value = 'fp-9';
      await w.settle('run-1', calls: const []);
      expect(w.goal.noProgressStreak, 1);
    });

    test('a failed tool call is not progress', () async {
      await w.start('ship it');
      await w.settle(
        'run-1',
        calls: const [
          RunToolCall(name: 'Edit', arguments: {'p': 1}, ok: false),
        ],
      );
      expect(w.goal.noProgressStreak, 1);
    });

    test('owed work: the goal waits, and the first wake that arrives is the '
        'next segment; the fallback is cancelled', () async {
      await w.start('ship it');
      w.delegations = const ['T-1'];
      await w.settle('run-1');
      expect(w.goal.hold, GoalHold.waiting);
      expect(w.goal.holdDetail, contains('1 open delegated ticket'));
      final fallback = w.openGoalWakes().single;
      expect(fallback.notBefore, w.now.add(GoalSupervisor.owedFallback));
      // A peer's reply arrives for the agent in the conversation.
      await w.queue.enqueueAndDeliver(
        Wake(
          id: 'reply-1',
          workspaceId: _ws,
          spaceId: _space,
          conversationId: _conv,
          agentId: _agent,
          reason: WakeReason.peerReply,
          payload: 'here is the answer',
          dedupKey: 'reply-1',
          notBefore: w.now,
          createdAt: w.now,
        ),
      );
      await w.pump();
      expect(w.dispatched, hasLength(2));
      expect(w.dispatched.last.wakeContext.wakeReason, WakeReason.peerReply);
      expect(w.dispatched.last.costCapMicros, 5000000);
      expect(w.goal.activeRunId, 'run-2');
      expect(w.goal.hold, isNull);
      expect(
        (await w.wakes.getById(_ws, fallback.id))!.state,
        WakeState.cancelled,
      );
    });

    test(
      'owed work: the fallback continues the goal after 20 minutes',
      () async {
        await w.start('ship it');
        w.delegations = const ['T-1'];
        await w.settle('run-1');
        await w.advance(const Duration(minutes: 19));
        expect(w.dispatched, hasLength(1));
        await w.advance(const Duration(minutes: 2));
        expect(w.dispatched, hasLength(2));
        expect(w.goal.hold, isNull);
        expect(w.goal.activeRunId, 'run-2');
      },
    );

    test('a segment that delegated waits, and the delegated ticket\'s '
        'completion wake is its next segment', () async {
      await w.start('ship it');
      w.delegations = const ['T-1'];
      await w.settle('run-1');
      expect(w.goal.hold, GoalHold.waiting);
      // The ticket it delegated from this conversation completed.
      await w.queue.enqueueAndDeliver(
        childCompletedWake(
          id: 'ticket-T-1-settled',
          workspaceId: _ws,
          spaceId: _space,
          conversationId: _conv,
          delegatorAgentId: _agent,
          workerAgentId: 'agent-2',
          workerName: 'Bo',
          status: 'completed',
          dedupKey: 'ticket:T-1:settled',
          now: w.now,
          payload: 'Done: three unused indexes.',
          ticketId: 'T-1',
        ),
      );
      await w.pump();
      expect(w.dispatched, hasLength(2));
      expect(
        w.dispatched.last.wakeContext.wakeReason,
        WakeReason.childCompleted,
      );
      expect(w.goal.activeRunId, 'run-2');
      expect(w.goal.hold, isNull);
    });

    test(
      'three errors in a row fail the goal, with the backoff between',
      () async {
        await w.start('ship it');
        await w.settle('run-1', reason: RunEndReason.error);
        expect(w.goal.consecutiveFailures, 1);
        await w.advance(const Duration(seconds: 29));
        expect(w.dispatched, hasLength(1));
        await w.advance(const Duration(seconds: 2));
        await w.settle('run-2', reason: RunEndReason.silence);
        expect(w.goal.consecutiveFailures, 2);
        await w.advance(const Duration(seconds: 61));
        await w.settle('run-3', reason: RunEndReason.error);
        expect(w.goal.status, AgentGoalStatus.failed);
        expect(w.settled.single.status, AgentGoalStatus.failed);
      },
    );

    test('a usage limit counts one failure today and no strike (the '
        'onLimitReached seam)', () async {
      await w.start('ship it');
      await w.settle('run-1', reason: RunEndReason.usageLimit);
      expect(w.goal.consecutiveFailures, 1);
      expect(w.goal.noProgressStreak, 0);
      expect(w.goal.status, AgentGoalStatus.active);
    });

    test('the server stopping is not a failure and starts nothing; the '
        'sweep at boot continues the goal', () async {
      await w.start('ship it');
      await w.settle('run-1', reason: RunEndReason.serverStopped);
      expect(w.goal.consecutiveFailures, 0);
      expect(w.goal.noProgressStreak, 0);
      expect(w.goal.status, AgentGoalStatus.active);
      expect(w.openGoalWakes(), isEmpty);
      await w.advance(const Duration(minutes: 1));
      expect(w.dispatched, hasLength(1));
      // Boot: `start()` sweeps once.
      await w.sweep();
      await w.advance(WakeQueueService.quietWindow);
      expect(w.dispatched, hasLength(2));
      expect(
        w.dispatched.last.wakeContext.wakeReason,
        WakeReason.goalContinuation,
      );
    });

    test('at boot the sweep continues a segment the reaper just ended for '
        'the server stop, before its settlement is handled', () async {
      await w.start('ship it');
      // The boot reaper's terminal write, with no settlement handled yet.
      w.runLogs.logs['run-1'] = w.runLogs.logs['run-1']!.copyWith(
        status: RunStatus.error,
        completedAt: w.now,
        endReason: RunEndReason.serverStopped,
      );
      await w.sweep();
      await w.advance(WakeQueueService.quietWindow);
      expect(w.dispatched, hasLength(2));
      expect(w.goal.consecutiveFailures, 0);
    });

    test('at boot a claim whose segment the server stopped is verified at '
        'once, before its settlement is handled', () async {
      await w.start('ship it --check "make test"');
      await w.claim();
      w.runLogs.logs['run-1'] = w.runLogs.logs['run-1']!.copyWith(
        status: RunStatus.error,
        completedAt: w.now,
        endReason: RunEndReason.serverStopped,
      );
      await w.sweep();
      expect(w.checkRuns, 1);
      // The settlement arriving afterwards starts nothing more.
      await w.settle('run-1', reason: RunEndReason.serverStopped);
      expect(w.checkRuns, 1);
    });

    for (final (label, block) in [
      ('a paused agent', 'agent_paused'),
      ('a budget block', 'budget_blocked'),
    ]) {
      test('a segment wake that expires waiting out $label stops the goal for '
          'a person, naming the kind', () async {
        await w.start('ship it');
        w.fingerprints.value = 'fp-1';
        await w.settle('run-1', calls: const [_bash]);
        expect(w.openGoalWakes(), hasLength(1));
        if (block == 'agent_paused') {
          w.agents.agents[_agent] = _agentNamed(
            _agent,
            'Ada',
            lifecycle: AgentLifecycleStatus.paused,
          );
        } else {
          w.budgetBlocked = true;
        }
        await w.advance(WakeQueueService.quietWindow);
        expect(w.dispatched, hasLength(1));
        expect(w.goal.status, AgentGoalStatus.active);
        await w.advance(const Duration(days: 7, minutes: 2));
        expect(w.dispatched, hasLength(1));
        expect(w.goal.status, AgentGoalStatus.paused);
        expect(w.goal.hold, GoalHold.needsReview);
        expect(w.goal.holdDetail, '${GoalHoldDetails.wakeSkipped}: $block');
        expect(w.openGoalWakes(), isEmpty);
        expect(w.settled.last.status, AgentGoalStatus.paused);
      });
    }

    test('a segment that settles before its dispatch returned is counted '
        'once, as its own segment', () async {
      w.beforeReturn = (runId) async {
        w.beforeReturn = null;
        await w.settle(runId, reason: RunEndReason.error);
      };
      await w.start('ship it');
      await w.pump();
      expect(w.dispatched, hasLength(1));
      expect(w.goal.runCount, 1);
      expect(w.goal.consecutiveFailures, 1);
      expect(w.goal.activeRunId, isNull);
      expect(w.openGoalWakes(), hasLength(1));
      expect(
        w.openGoalWakes().single.notBefore,
        w.now.add(const Duration(seconds: 30)),
      );
    });

    test('a person stopping the segment pauses the goal', () async {
      await w.start('ship it');
      await w.settle('run-1', reason: RunEndReason.stoppedByUser);
      expect(w.goal.status, AgentGoalStatus.paused);
      expect(w.goal.hold, GoalHold.byPerson);
      expect(w.openGoalWakes(), isEmpty);
      expect(w.settled, isEmpty);
    });

    test(
      'a paused goal still adds its live run\'s cost, and nothing more',
      () async {
        await w.start('ship it');
        await w.supervisor.pauseGoal(_ws, w.goal.id);
        await w.settle('run-1', cost: 777);
        expect(w.goal.status, AgentGoalStatus.paused);
        expect(w.goal.costMicros, 777);
        expect(w.goal.runCount, 1);
        await w.advance(const Duration(minutes: 30));
        expect(w.dispatched, hasLength(1));
      },
    );

    test('the event arrives twice, or after the goal was cancelled: counted '
        'once, nothing restarts', () async {
      await w.start('ship it');
      await w.supervisor.cancelGoal(_ws, w.goal.id);
      expect(w.goal.status, AgentGoalStatus.cancelled);
      expect(w.goal.activeRunId, 'run-1', reason: 'kept for its cost');
      await w.settle('run-1', cost: 500);
      await w.settle('run-1', cost: 500);
      expect(w.goal.costMicros, 500);
      expect(w.goal.activeRunId, isNull);
      await w.advance(const Duration(minutes: 30));
      expect(w.dispatched, hasLength(1));
    });

    test('the goal cap ends the goal with the agent\'s last message as its '
        'wrap-up', () async {
      await w.start('ship it --budget 1');
      await w.settle(
        'run-1',
        cost: 1000000,
        summary: 'Half done: the parser is in, the tests are not.',
      );
      expect(w.goal.status, AgentGoalStatus.budgetExhausted);
      expect(w.goal.summary, 'Half done: the parser is in, the tests are not.');
      expect(w.settled.single.status, AgentGoalStatus.budgetExhausted);
    });

    test('a segment at its own cap continues like a normal end', () async {
      await w.start('ship it');
      w.fingerprints.value = 'fp-1';
      await w.settle('run-1', reason: RunEndReason.budget);
      expect(w.goal.consecutiveFailures, 0);
      await w.advance(WakeQueueService.quietWindow);
      expect(w.dispatched, hasLength(2));
    });

    test(
      'waiting on a person holds the goal until the request settles',
      () async {
        await w.start('ship it');
        w.bus.publish(
          AgentAwaitingInput(
            workspaceId: _ws,
            waitId: 'wait-1',
            kind: AgentInputKind.question,
            summary: 'Which branch?',
            runId: 'run-1',
            occurredAt: w.now,
          ),
        );
        await w.pump();
        expect(w.goal.hold, GoalHold.person);
        w.bus.publish(
          AgentInputResolved(
            workspaceId: _ws,
            waitId: 'wait-1',
            occurredAt: w.now,
          ),
        );
        await w.pump();
        expect(w.goal.hold, isNull);
      },
    );
  });

  group('admission', () {
    Wake goalWake(String goalId, {String workspaceId = _ws}) => Wake(
      id: 'gw-$goalId-$workspaceId',
      workspaceId: workspaceId,
      spaceId: _space,
      conversationId: _conv,
      agentId: _agent,
      reason: WakeReason.goalContinuation,
      payload: '',
      detail: WakeDetail(goalId: goalId),
      dedupKey: 'k',
      notBefore: w.now,
      createdAt: w.now,
    );

    test('a closed or unknown goal\'s wake is skipped; one from another '
        'workspace too', () async {
      final goal = await w.start('ship it');
      expect(
        await w.supervisor.admit(goalWake('nope'), now: w.now),
        isA<WakeSkip>(),
      );
      expect(
        await w.supervisor.admit(
          goalWake(goal.id, workspaceId: 'ws-2'),
          now: w.now,
        ),
        isA<WakeSkip>(),
      );
      await w.supervisor.cancelGoal(_ws, goal.id);
      expect(
        await w.supervisor.admit(goalWake(goal.id), now: w.now),
        isA<WakeSkip>(),
      );
    });

    test('a live segment or a paused goal defers its wake', () async {
      final goal = await w.start('ship it');
      final live = await w.supervisor.admit(goalWake(goal.id), now: w.now);
      expect(live, isA<WakeDefer>());
      expect((live as WakeDefer).reason, WakeStateReasons.liveRunNoInput);
      await w.supervisor.pauseGoal(_ws, goal.id);
      final paused = await w.supervisor.admit(goalWake(goal.id), now: w.now);
      expect((paused as WakeDefer).reason, GoalWakeReasons.paused);
    });

    test('the budget wall at admission closes the goal', () async {
      await w.start('ship it --budget 1');
      await w.supervisor.pauseGoal(_ws, w.goal.id);
      await w.settle('run-1', cost: 999999);
      await w.supervisor.resumeGoal(_ws, w.goal.id);
      expect(w.goal.status, AgentGoalStatus.active);
      w.goals.goals[w.goal.id] = w.goal.copyWith(costMicros: 1000000);
      await w.advance(WakeQueueService.quietWindow);
      expect(w.goal.status, AgentGoalStatus.budgetExhausted);
      expect(w.dispatched, hasLength(1));
    });
  });

  group('complete_goal is a claim', () {
    const contracted =
        'ship it\n\n## Success criteria\n- the tests pass\n- no API removed';

    test('another agent, or a run that is not the active segment, is '
        'refused', () async {
      await w.start('ship it');
      expect(
        () => w.supervisor.claimCompletion(
          _ws,
          'agent-2',
          conversationId: _conv,
          callingRunId: 'run-1',
          summary: 'done',
          evidence: const [],
        ),
        throwsA(isA<GoalNotActiveSegmentException>()),
      );
      expect(
        () => w.supervisor.claimCompletion(
          _ws,
          _agent,
          conversationId: _conv,
          callingRunId: 'run-other',
          summary: 'done',
          evidence: const [],
        ),
        throwsA(isA<GoalNotActiveSegmentException>()),
      );
      expect(
        () => w.supervisor.claimCompletion(
          'ws-2',
          _agent,
          conversationId: _conv,
          callingRunId: 'run-1',
          summary: 'done',
          evidence: const [],
        ),
        throwsA(isA<GoalNotActiveSegmentException>()),
      );
    });

    test('evidence missing an item is refused, naming it', () async {
      await w.start(contracted);
      await expectLater(
        w.claim(
          evidence: [
            GoalClaimEvidence(criterion: '1', evidence: 'ran the tests'),
          ],
        ),
        throwsA(
          isA<GoalRefusedException>()
              .having((e) => e.code, 'kind', 'goal_evidence_incomplete')
              .having((e) => e.message, 'message', contains('no API removed')),
        ),
      );
      expect(w.goal.hold, isNull);
    });

    test('a covered claim is recorded (by number or text), the goal holds '
        'for verification, and a second claim is refused', () async {
      await w.start(contracted);
      final claimed = await w.claim(
        evidence: [
          GoalClaimEvidence(criterion: '1', evidence: 'exit 0'),
          GoalClaimEvidence(criterion: 'no  API removed', evidence: 'diff'),
        ],
      );
      expect(claimed.status, AgentGoalStatus.active);
      expect(claimed.hold, GoalHold.verifying);
      expect(claimed.verification!.round, 1);
      expect(claimed.verification!.claimEvidence.map((e) => e.criterion), [
        'the tests pass',
        'no API removed',
      ]);
      await expectLater(
        w.claim(
          evidence: [
            GoalClaimEvidence(criterion: '1', evidence: 'x'),
            GoalClaimEvidence(criterion: '2', evidence: 'y'),
          ],
        ),
        throwsA(
          isA<GoalRefusedException>().having(
            (e) => e.code,
            'kind',
            'goal_claim_pending',
          ),
        ),
      );
    });
  });

  group('verification', () {
    Future<void> claimAndEnd() async {
      await w.claim();
      await w.settle(w.goal.activeRunId!);
    }

    // A goal with no "Done means" items passes on one item on the objective.
    Map<String, dynamic> verdict(String outcome) => {
      'verdict': outcome,
      'items': outcome == 'pass'
          ? [
              {
                'criterion': 'the objective',
                'state': 'met',
                'evidence': 'read the files',
              },
            ]
          : const [],
      'concerns': outcome == 'fail' ? ['the parser is missing'] : const [],
    };

    test('checks pass, the review is a fresh, read-only, capped run of the '
        'checker, and its pass completes the goal with its cost', () async {
      w.spaceChecker = 'agent-2';
      await w.start('ship it --check "make test"');
      w.checkOutcome = () => GoalChecksOutcome(
        status: GoalChecksStatus.ran,
        results: [_check('make test')],
        fingerprint: 'fp-0',
      );
      await claimAndEnd();
      expect(w.checkRuns, 1);
      await w.advance(WakeQueueService.quietWindow);
      final review = w.dispatched.last;
      expect(review.agentId, 'agent-2');
      expect(review.wakeContext.wakeReason, WakeReason.goalReview);
      expect(review.readOnly, isTrue);
      expect(review.freshHistory, isTrue);
      expect(review.costCapMicros, 2000000);
      expect(review.expectedOutputSchema, isNotNull);
      final reviewRun = w.runIds.last;
      expect(
        await w.supervisor.goalRunKindOf(workspaceId: _ws, runId: reviewRun),
        GoalRunKind.review,
      );
      expect(
        await w.supervisor.goalRunKindOf(workspaceId: 'ws-2', runId: reviewRun),
        isNull,
      );
      expect(w.goal.verification!.reviewRunId, reviewRun);
      final spent = w.goal.costMicros;
      await w.settle(reviewRun, cost: 300, output: verdict('pass'));
      expect(w.goal.status, AgentGoalStatus.completed);
      expect(w.goal.costMicros, spent + 300);
      expect(w.goal.verification!.verdict!.verdict, GoalVerdictOutcome.pass);
      expect(w.settled.last.status, AgentGoalStatus.completed);
      expect(w.said.last, contains('verified by Rita'));
    });

    test('a server stop under a claiming segment starts no check and no wake; '
        'the sweep at boot verifies the claim once', () async {
      await w.start('ship it --check "make test"');
      await w.claim();
      await w.settle(w.goal.activeRunId!, reason: RunEndReason.serverStopped);
      expect(w.checkRuns, 0);
      expect(w.openGoalWakes(), isEmpty);
      expect(w.goal.hold, GoalHold.verifying);
      expect(w.goal.verification!.claimSummary, 'done');
      await w.advance(const Duration(minutes: 1));
      expect(w.checkRuns, 0);
      expect(w.dispatched, hasLength(1));
      await w.sweep();
      expect(w.checkRuns, 1);
      await w.sweep();
      expect(w.checkRuns, 1);
      await w.advance(WakeQueueService.quietWindow);
      expect(w.dispatched.last.wakeContext.wakeReason, WakeReason.goalReview);
    });

    test('a server stop under a review run starts no check and no wake; the '
        'sweep at boot asks for the review again, once, without rerunning '
        'the checks', () async {
      await w.start('ship it --check "make test"');
      await claimAndEnd();
      expect(w.checkRuns, 1);
      await w.advance(WakeQueueService.quietWindow);
      final reviewRun = w.runIds.last;
      final spent = w.goal.costMicros;
      await w.settle(reviewRun, cost: 50, reason: RunEndReason.serverStopped);
      expect(w.goal.costMicros, spent + 50);
      expect(w.goal.hold, GoalHold.verifying);
      expect(w.goal.verification!.reviewRunId, isNull);
      expect(w.openGoalWakes(), isEmpty);
      await w.advance(const Duration(minutes: 1));
      expect(w.checkRuns, 1);
      expect(w.runIds.last, reviewRun);
      await w.sweep();
      await w.sweep();
      expect(w.checkRuns, 1, reason: 'the checks already passed');
      expect(w.openGoalWakes(), hasLength(1));
      await w.advance(WakeQueueService.quietWindow);
      expect(w.runIds.last, isNot(reviewRun));
      // Not the reviewer's failure: it still has its one ask again.
      expect(w.goal.verification!.reviewAsks, 0);
      expect(w.dispatched.last.wakeContext.wakeReason, WakeReason.goalReview);
    });

    test('a failing review sends the worker a verification wake; the third '
        'failed round stops for a person with no fourth segment', () async {
      await w.start('ship it');
      for (var round = 1; round <= 3; round++) {
        await claimAndEnd();
        await w.advance(WakeQueueService.quietWindow);
        final reviewRun = w.runIds.last;
        expect(w.dispatched.last.wakeContext.wakeReason, WakeReason.goalReview);
        await w.settle(reviewRun, output: verdict('fail'));
        expect(w.goal.verificationRounds, round);
        if (round < 3) {
          await w.advance(WakeQueueService.quietWindow);
          final next = w.dispatched.last.wakeContext;
          expect(next.wakeReason, WakeReason.goalVerification);
          expect(next.wakes.single.detail.fields[WakeFields.round], round);
          expect(w.goal.hold, isNull);
        }
      }
      expect(w.goal.status, AgentGoalStatus.paused);
      expect(w.goal.hold, GoalHold.needsReview);
      expect(w.goal.holdDetail, GoalHoldDetails.verificationFailed);
      final count = w.dispatched.length;
      await w.advance(const Duration(hours: 1));
      expect(w.dispatched, hasLength(count));
      // Resuming a verification stop starts the rounds over.
      await w.supervisor.resumeGoal(_ws, w.goal.id);
      expect(w.goal.verificationRounds, 0);
      expect(w.goal.status, AgentGoalStatus.active);
    });

    test('a failing check with an unchanged workspace is not rerun, and the '
        'round counts', () async {
      await w.start('ship it --check "make test"');
      w.checkOutcome = () => GoalChecksOutcome(
        status: GoalChecksStatus.ran,
        results: [_check('make test', exit: 1)],
        fingerprint: 'fp-0',
      );
      await claimAndEnd();
      expect(w.checkRuns, 1);
      expect(w.goal.verificationRounds, 1);
      expect(w.goal.verification!.lastFailedFingerprint, 'fp-0');
      await w.advance(WakeQueueService.quietWindow);
      expect(
        w.dispatched.last.wakeContext.wakeReason,
        WakeReason.goalVerification,
      );
      // The worker changes nothing and claims again.
      await claimAndEnd();
      expect(w.checkRuns, 1, reason: 'not rerun');
      expect(w.goal.verificationRounds, 2);
      expect(w.goal.verification!.checks.single.skippedUnchanged, isTrue);
    });

    test('A1: a broken check stops for a person without counting a round; '
        'resuming verifies the same claim again', () async {
      await w.start('ship it --check "maek test"');
      w.checkOutcome = () => GoalChecksOutcome(
        status: GoalChecksStatus.ran,
        results: [_check('maek test', exit: 127, broken: true)],
        fingerprint: 'fp-0',
      );
      await claimAndEnd();
      expect(w.goal.status, AgentGoalStatus.paused);
      expect(w.goal.hold, GoalHold.needsReview);
      expect(w.goal.holdDetail, 'check_broken: maek test');
      expect(w.goal.verificationRounds, 0);
      expect(w.goal.verification!.claimSummary, 'done');
      expect(w.settled.single.summary, contains('could not run'));
      final count = w.dispatched.length;
      await w.advance(const Duration(minutes: 5));
      expect(w.dispatched, hasLength(count), reason: 'no worker segment');
      w.checkOutcome = () => GoalChecksOutcome(
        status: GoalChecksStatus.ran,
        results: [_check('make test')],
        fingerprint: 'fp-0',
      );
      await w.supervisor.resumeGoal(_ws, w.goal.id);
      await w.pump();
      expect(w.checkRuns, 2);
      await w.advance(WakeQueueService.quietWindow);
      expect(w.dispatched.last.wakeContext.wakeReason, WakeReason.goalReview);
    });

    test('no sandbox stops for a person', () async {
      await w.start('ship it --check "make test"');
      w.checkOutcome = () => GoalChecksOutcome(
        status: GoalChecksStatus.sandboxUnavailable,
        results: const [],
        fingerprint: null,
      );
      await claimAndEnd();
      expect(w.goal.hold, GoalHold.needsReview);
      expect(w.goal.holdDetail, GoalHoldDetails.sandboxUnavailable);
    });

    test(
      'cannot_verify, and a review run that fails, stop for a person',
      () async {
        await w.start('ship it');
        await claimAndEnd();
        await w.advance(WakeQueueService.quietWindow);
        // A failed review run is asked again once (finding 12)...
        final first = w.runIds.last;
        await w.settle(first, reason: RunEndReason.error);
        expect(w.goal.status, AgentGoalStatus.active);
        expect(w.goal.verification!.reviewAsks, 1);
        await w.advance(WakeQueueService.quietWindow);
        expect(w.runIds.last, isNot(first));
        expect(w.dispatched.last.wakeContext.wakeReason, WakeReason.goalReview);
        // ...and a second failure cannot verify.
        await w.settle(w.runIds.last, reason: RunEndReason.error);
        expect(w.goal.status, AgentGoalStatus.paused);
        expect(w.goal.holdDetail, GoalHoldDetails.cannotVerify);
        expect(
          w.goal.verification!.verdict!.verdict,
          GoalVerdictOutcome.cannotVerify,
        );
      },
    );

    test('approveCompletion closes a goal in review on the person\'s word; '
        'anything else is refused', () async {
      await w.start('ship it');
      await expectLater(
        w.supervisor.approveCompletion(_ws, w.goal.id, userId: _person),
        throwsA(
          isA<GoalRefusedException>().having(
            (e) => e.code,
            'kind',
            'goal_not_in_review',
          ),
        ),
      );
      await claimAndEnd();
      await w.advance(WakeQueueService.quietWindow);
      await w.settle(w.runIds.last, output: verdict('cannot_verify'));
      await expectLater(
        w.supervisor.approveCompletion('ws-2', w.goal.id, userId: _person),
        throwsA(isA<GoalRefusedException>()),
      );
      final closed = await w.supervisor.approveCompletion(
        _ws,
        w.goal.id,
        userId: _person,
      );
      expect(closed.status, AgentGoalStatus.completed);
      expect(closed.verification!.approvedByUserId, _person);
      await w.pump();
      expect(w.settled.last.status, AgentGoalStatus.completed);
    });
  });

  group('resume, cancel and the sweep', () {
    test(
      'a goal leaving active tells the steering side once (it holds the '
      "cards a review kept); a resume or a paused goal's cancel does not",
      () async {
        final left = <AgentGoalStatus>[];
        w.store.onLeftActive = (g) async => left.add(g.status);
        await w.start('ship it');
        await w.supervisor.pauseGoal(_ws, w.goal.id);
        expect(left, [AgentGoalStatus.paused]);
        await w.settle('run-1');
        await w.supervisor.resumeGoal(_ws, w.goal.id);
        expect(left, [AgentGoalStatus.paused]);
        await w.supervisor.cancelGoal(_ws, w.goal.id);
        expect(left, [AgentGoalStatus.paused, AgentGoalStatus.cancelled]);
        await w.supervisor.cancelGoal(_ws, w.goal.id);
        expect(left, hasLength(2));
      },
    );

    test("a removed person's goal pauses for a person at once, its live "
        "segment's server stop leaves it paused (not failed), and nothing "
        'starts again; a second removal changes nothing', () async {
      await w.start('ship it');
      expect(await w.supervisor.pauseForRemovedPerson(_ws, _person), 1);
      expect(w.goal.status, AgentGoalStatus.paused);
      expect(w.goal.hold, GoalHold.needsReview);
      expect(w.goal.holdDetail, 'wake_skipped: person_removed');

      await w.settle('run-1', reason: RunEndReason.serverStopped);
      await w.advance(WakeQueueService.quietWindow);

      expect(w.goal.status, AgentGoalStatus.paused);
      expect(w.goal.consecutiveFailures, 0);
      expect(w.goal.activeRunId, isNull);
      expect(w.dispatched, hasLength(1), reason: 'only the first segment');
      expect(await w.supervisor.pauseForRemovedPerson(_ws, _person), 0);
      expect(await w.supervisor.pauseForRemovedPerson(_ws, 'user-9'), 0);
    });

    test('two resumes start one segment', () async {
      await w.start('ship it');
      await w.supervisor.pauseGoal(_ws, w.goal.id);
      await w.settle('run-1');
      await Future.wait([
        w.supervisor.resumeGoal(_ws, w.goal.id),
        w.supervisor.resumeGoal(_ws, w.goal.id),
      ]);
      await w.advance(WakeQueueService.quietWindow);
      expect(w.dispatched, hasLength(2));
      expect(w.said.where((s) => s == 'Durable /goal resumed.'), hasLength(1));
    });

    test('resuming a stalled goal clears its strikes', () async {
      await w.start('ship it');
      w.goals.goals[w.goal.id] = w.goal.copyWith(noProgressStreak: 2);
      await w.settle('run-1');
      expect(w.goal.holdDetail, GoalHoldDetails.stalled);
      await w.supervisor.resumeGoal(_ws, w.goal.id);
      expect(w.goal.noProgressStreak, 0);
      expect(w.goal.hold, isNull);
    });

    test('the sweep gives an idle active goal its continuation, and leaves '
        'one with a queued wake alone', () async {
      await w.start('ship it');
      // The server went down with the segment: its row is ended, nothing
      // was heard.
      w.runLogs.logs['run-1'] = w.runLogs.logs['run-1']!.copyWith(
        status: RunStatus.error,
        completedAt: w.now,
      );
      w.now = w.now.add(const Duration(minutes: 2));
      await w.sweep();
      expect(w.goal.activeRunId, isNull);
      expect(w.goal.runCount, 1);
      expect(w.openGoalWakes(), hasLength(1));
      await w.sweep();
      expect(w.openGoalWakes(), hasLength(1));
      await w.advance(WakeQueueService.quietWindow);
      expect(w.dispatched, hasLength(2));
    });

    test(
      'a review wake skipped for lack of a sandbox stops for a person',
      () async {
        await w.start('ship it');
        await w.claim();
        await w.settle('run-1');
        final review = w.openGoalWakes().single;
        await w.verifier.onReviewWakeSettled(
          WakeSettlement(
            wake: review,
            state: WakeState.skipped,
            reason: WakeStateReasons.sandboxUnavailable,
          ),
        );
        expect(w.goal.holdDetail, GoalHoldDetails.sandboxUnavailable);
      },
    );

    test(
      'a segment wake the queue skipped stops the goal for a person',
      () async {
        await w.start('ship it');
        w.fingerprints.value = 'fp-1';
        await w.settle('run-1');
        final next = w.openGoalWakes().single;
        await w.supervisor.onWakeSettled(
          WakeSettlement(
            wake: next,
            state: WakeState.skipped,
            reason: WakeStateReasons.agentDeleted,
          ),
        );
        expect(w.goal.status, AgentGoalStatus.paused);
        expect(w.goal.holdDetail, 'wake_skipped: agent_deleted');
      },
    );

    test('a lost write re-reads: a pause that lands first stands', () async {
      await w.start('ship it');
      w.fingerprints.value = 'fp-1';
      final id = w.goal.id;
      w.goals.beforeNextReplace = () async {
        final g = w.goals.goals[id]!;
        w.goals.goals[id] = g.copyWith(
          status: AgentGoalStatus.paused,
          hold: GoalHold.byPerson,
        );
      };
      await w.settle('run-1');
      expect(w.goal.status, AgentGoalStatus.paused);
      expect(w.goal.hold, GoalHold.byPerson);
      await w.advance(const Duration(minutes: 5));
      expect(w.dispatched, hasLength(1));
    });
  });

  group('the second review', () {
    Future<void> claimAndEnd() async {
      await w.claim();
      await w.settle(w.goal.activeRunId!);
      await w.supervisor.verificationsDone();
      await w.pump();
    }

    Map<String, dynamic> verdict(String outcome) => {
      'verdict': outcome,
      'items': outcome == 'pass'
          ? [
              {
                'criterion': 'the objective',
                'state': 'met',
                'evidence': 'read the files',
              },
            ]
          : const [],
      'concerns': const [],
    };

    test('finding 1: paused during a review that then passes, the resume '
        'applies the verdict with no second pass', () async {
      await w.start('ship it');
      await claimAndEnd();
      await w.advance(WakeQueueService.quietWindow);
      expect(w.dispatched.last.wakeContext.wakeReason, WakeReason.goalReview);
      final review = w.runIds.last;
      await w.supervisor.pauseGoal(_ws, w.goal.id);
      expect(w.goal.holdDetail, GoalHoldDetails.claimPending);
      await w.settle(review, cost: 300, output: verdict('pass'));
      expect(w.goal.status, AgentGoalStatus.paused);
      expect(w.goal.verification!.verdict!.verdict, GoalVerdictOutcome.pass);
      final runs = w.dispatched.length;
      await w.supervisor.resumeGoal(_ws, w.goal.id);
      await w.supervisor.verificationsDone();
      await w.advance(WakeQueueService.quietWindow);
      expect(w.goal.status, AgentGoalStatus.completed);
      expect(w.dispatched, hasLength(runs));
    });

    test("finding 1: the server stopped between the review's end and its "
        'verdict, the boot sweep reads the verdict from the run log', () async {
      await w.start('ship it');
      await claimAndEnd();
      await w.advance(WakeQueueService.quietWindow);
      final review = w.runIds.last;
      // The terminal row was written; its settlement was never handled.
      w.runLogs.logs[review] = w.runLogs.logs[review]!.copyWith(
        status: RunStatus.completed,
        completedAt: w.now,
        endReason: RunEndReason.completed,
        outputJson: verdict('pass'),
      );
      await w.sweep();
      expect(
        w.goal.status,
        AgentGoalStatus.active,
        reason: 'within the grace, its settlement may still arrive',
      );
      w.now = w.now.add(GoalVerifier.settleGrace);
      await w.sweep();
      expect(w.goal.status, AgentGoalStatus.completed);
      expect(w.goal.verification!.verdict!.verdict, GoalVerdictOutcome.pass);
    });

    for (final (label, change) in [
      ('deleted', (_Agents a) => a.agents.remove('agent-2')),
      (
        'archived',
        (_Agents a) => a.agents['agent-2'] = _agentNamed(
          'agent-2',
          'Rita',
          lifecycle: AgentLifecycleStatus.archived,
        ),
      ),
    ]) {
      test('finding 4: a checker that is $label ends the verification at '
          'once for a person; no other reviewer is woken', () async {
        w.spaceChecker = 'agent-2';
        await w.start('ship it');
        change(w.agents);
        await claimAndEnd();
        expect(w.goal.status, AgentGoalStatus.paused);
        expect(w.goal.hold, GoalHold.needsReview);
        expect(w.goal.holdDetail, GoalHoldDetails.checkerUnavailable);
        expect(w.openGoalWakes(), isEmpty);
        await w.advance(const Duration(minutes: 5));
        expect(w.dispatched, hasLength(1));
        // Back: the resume verifies the same claim with that checker.
        w.agents.agents['agent-2'] = _agentNamed('agent-2', 'Rita');
        await w.supervisor.resumeGoal(_ws, w.goal.id);
        await w.supervisor.verificationsDone();
        await w.advance(WakeQueueService.quietWindow);
        expect(w.dispatched.last.agentId, 'agent-2');
        expect(w.dispatched.last.wakeContext.wakeReason, WakeReason.goalReview);
      });
    }

    test('findings 4 and 6: a review its backend cannot hold to reading is '
        'refused before a run exists and ends the verification for a '
        'person', () async {
      await w.start('ship it');
      w.refuseReadOnly = true;
      await claimAndEnd();
      await w.advance(WakeQueueService.quietWindow);
      expect(w.dispatched, hasLength(1));
      final review = w.wakes
          .all(_ws)
          .singleWhere((x) => x.reason == WakeReason.goalReview);
      expect(review.state, WakeState.skipped);
      expect(review.stateReason, WakeStateReasons.readOnlyUnavailable);
      expect(w.goal.status, AgentGoalStatus.paused);
      expect(w.goal.holdDetail, GoalHoldDetails.checkerUnavailable);
    });

    test('finding 12: a review at a usage limit waits for the reset, then '
        'the review is asked again', () async {
      await w.start('ship it');
      await claimAndEnd();
      await w.advance(WakeQueueService.quietWindow);
      final review = w.runIds.last;
      await w.settle(
        review,
        reason: RunEndReason.usageLimit,
        limitResetsAt: w.now.add(const Duration(hours: 1)),
      );
      expect(w.goal.status, AgentGoalStatus.active);
      expect(w.goal.hold, GoalHold.verifying);
      expect(w.goal.parkCount, 1);
      final park = w.openGoalWakes().single;
      expect(park.reason, WakeReason.limitReset);
      expect(park.detail.fields[WakeFields.review], isTrue);
      expect(park.dedupKey, LimitPark.dedupKey(review));
      await w.advance(const Duration(minutes: 30));
      expect(w.runIds.last, review);
      await w.advance(const Duration(minutes: 31));
      expect(w.runIds.last, isNot(review));
      expect(w.dispatched.last.readOnly, isTrue);
      await w.settle(w.runIds.last, output: verdict('pass'));
      expect(w.goal.status, AgentGoalStatus.completed);
    });

    test('finding 3: a held wake is not owed work, so the goal does not wait '
        'on what only a person releases', () async {
      await w.start('ship it');
      await w.queue.enqueue(
        Wake(
          id: 'peer-1',
          workspaceId: _ws,
          spaceId: _space,
          conversationId: _conv,
          agentId: _agent,
          reason: WakeReason.peerMessage,
          payload: 'later',
          dedupKey: 'peer-1',
          notBefore: w.now.add(const Duration(hours: 1)),
          createdAt: w.now,
        ),
      );
      await w.queue.hold(
        _ws,
        conversationId: _conv,
        agentId: _agent,
        reason: WakeStateReasons.stopped,
      );
      expect((await w.wakes.getById(_ws, 'peer-1'))!.state, WakeState.held);
      await w.settle('run-1');
      expect(w.goal.hold, isNull);
      expect(w.goal.noProgressStreak, 1);
    });

    test(
      'finding 5 (review 4a, 4): a long wait on one unchanged ask doubles '
      'the fallback and stops only after 24 hours, not after six waits',
      () async {
        await w.start('ship it');
        w.asks.asks.add(_ask('ask-1', w.now));
        final start = w.now;
        final fallbacks = <int>[];
        for (var i = 0; i < 20; i++) {
          await w.settle(w.runIds.last);
          if (w.goal.hold != GoalHold.waiting) {
            break;
          }
          final delay = w.openGoalWakes().single.notBefore.difference(w.now);
          fallbacks.add(delay.inMinutes);
          await w.advance(delay + const Duration(seconds: 1));
        }
        expect(fallbacks.take(6), [20, 40, 80, 160, 240, 240]);
        expect(fallbacks.length, greaterThan(GoalProgressMarks.maxFreshWaits));
        expect(w.goal.status, AgentGoalStatus.paused);
        expect(w.goal.hold, GoalHold.needsReview);
        expect(w.goal.holdDetail, GoalHoldDetails.stalledWaiting);
        expect(
          w.now.difference(start),
          greaterThanOrEqualTo(GoalProgressMarks.maxWait),
        );
        expect(
          w.said.last,
          contains(
            'over ${w.goal.progressMarks!.waits} '
            'segments without progress',
          ),
        );
        expect(w.settled.last.hold, GoalHold.needsReview);
        // A person's resume starts the stretch over.
        await w.supervisor.resumeGoal(_ws, w.goal.id);
        expect(w.goal.progressMarks!.waits, 0);
      },
    );

    for (final (label, setUpFresh) in <(String, void Function(_World, int))>[
      (
        'a new wake_me each segment',
        (w, i) => w.rules.rules
          ..clear()
          ..add(
            _rule(
              'once-$i',
              OnceAt(w.now.add(const Duration(minutes: 20))),
              w.now,
            ),
          ),
      ),
      (
        'a new watch each segment',
        (w, i) => w.rules.rules.add(
          _rule('watch-$i', OnEvent(WakeEventKind.prMerged), w.now),
        ),
      ),
      (
        'a new ask each segment',
        (w, i) => w.asks.asks
          ..clear()
          ..add(_ask('ask-$i', w.now)),
      ),
    ]) {
      test(
        'review 4a, finding 4: $label is waiting without progress; the '
        'fallback keeps doubling and the sixth such wait stops the goal',
        () async {
          await w.start('ship it');
          final start = w.now;
          final fallbacks = <int>[];
          for (var i = 0; i < 12; i++) {
            setUpFresh(w, i);
            await w.settle(w.runIds.last);
            if (w.goal.hold != GoalHold.waiting) {
              break;
            }
            final delay = w.openGoalWakes().single.notBefore.difference(w.now);
            fallbacks.add(delay.inMinutes);
            await w.advance(delay + const Duration(seconds: 1));
          }
          expect(fallbacks, [20, 40, 80, 160, 240]);
          expect(w.goal.status, AgentGoalStatus.paused);
          expect(w.goal.holdDetail, GoalHoldDetails.stalledWaiting);
          expect(w.goal.progressMarks!.waits, GoalProgressMarks.maxFreshWaits);
          expect(w.now.difference(start), lessThan(GoalProgressMarks.maxWait));
          expect(
            w.said.last,
            contains(
              'over ${GoalProgressMarks.maxFreshWaits} segments without '
              'progress, setting up new work to wait on in '
              '${GoalProgressMarks.maxFreshWaits} of them',
            ),
          );
        },
      );
    }

    test('review 4a, finding 4: five waits and then progress do not stop the '
        'goal; the progress starts the stretch over', () async {
      await w.start('ship it');
      for (var i = 0; i < 5; i++) {
        w.asks.asks
          ..clear()
          ..add(_ask('ask-$i', w.now));
        await w.settle(w.runIds.last);
        final delay = w.openGoalWakes().single.notBefore.difference(w.now);
        await w.advance(delay + const Duration(seconds: 1));
      }
      expect(w.goal.progressMarks!.waits, 5);
      w.asks.asks
        ..clear()
        ..add(_ask('ask-5', w.now));
      w.fingerprints.value = 'fp-1';
      await w.settle(w.runIds.last, calls: const [_edit]);
      expect(w.goal.status, AgentGoalStatus.active);
      expect(w.goal.hold, GoalHold.waiting);
      expect(w.goal.progressMarks!.waits, 0);
      expect(w.goal.progressMarks!.freshWaits, 0);
      final delay = w.openGoalWakes().single.notBefore.difference(w.now);
      expect(delay, GoalProgressMarks.firstFallback);
    });

    test('finding 5: a state the goal has had before is no progress, however '
        'it differs from the last segment', () async {
      await w.start('ship it');
      w.fingerprints.value = 'fp-1';
      await w.settle('run-1', calls: const [_edit]);
      expect(w.goal.noProgressStreak, 0);
      await w.advance(WakeQueueService.quietWindow);
      w.fingerprints.value = 'fp-0';
      await w.settle(w.runIds.last, calls: const [_bash]);
      expect(w.goal.noProgressStreak, 0, reason: 'a state not seen before');
      await w.advance(WakeQueueService.quietWindow);
      w.fingerprints.value = 'fp-1';
      await w.settle(w.runIds.last, calls: const [_edit]);
      expect(w.goal.noProgressStreak, 1, reason: "segment 1's state again");
      expect(w.goal.progressMarks!.marks, hasLength(3));
    });

    test("finding 5: a worktree another run changed is not this segment's "
        'progress when it changed nothing itself', () async {
      await w.start('ship it');
      w.fingerprints.value = 'fp-1';
      await w.settle(
        'run-1',
        calls: const [
          RunToolCall(name: 'read', arguments: {'path': 'a.dart'}, ok: true),
        ],
      );
      expect(w.goal.noProgressStreak, 1);
    });

    test('finding 7: a checkout that appears after the start gets its start '
        'from the first segment that sees it, and keeps it', () async {
      final a = 'a' * 40;
      final b = 'b' * 40;
      await w.start('ship it');
      expect(w.goal.startRefs, isNull);
      w.startRefs = GoalStartRefs({'app': a});
      w.fingerprints.value = 'fp-1';
      await w.settle('run-1');
      await w.advance(WakeQueueService.quietWindow);
      expect(w.goal.startRefs!.refs, {'app': a});
      w.startRefs = GoalStartRefs({'app': b});
      w.fingerprints.value = 'fp-2';
      await w.settle(w.runIds.last);
      await w.advance(WakeQueueService.quietWindow);
      expect(w.goal.startRefs!.refs, {'app': a});
    });

    test('finding 9: closing a goal whose segment ended unsettled counts that '
        'segment, once', () async {
      await w.start('ship it');
      w.runLogs.logs['run-1'] = w.runLogs.logs['run-1']!.copyWith(
        status: RunStatus.completed,
        completedAt: w.now,
        endReason: RunEndReason.completed,
        cost: const RunCost(costMicros: 700),
      );
      await w.supervisor.cancelGoal(_ws, w.goal.id);
      expect(w.goal.status, AgentGoalStatus.cancelled);
      expect(w.goal.costMicros, 700);
      expect(w.goal.runCount, 1);
      await w.settle('run-1', cost: 700);
      expect(w.goal.costMicros, 700);
      expect(w.goal.runCount, 1);
    });

    test("finding 4: the sweep never waits for a goal's checks, and at most "
        '${GoalVerifier.maxConcurrentChecks} check runs go at once', () async {
      final contract = GoalContract(checks: [GoalCheck(run: 'make test')]);
      for (final (id, agent) in [
        ('g-a', 'agent-1'),
        ('g-b', 'agent-2'),
        ('g-c', 'agent-3'),
      ]) {
        await w.goals.upsert(
          AgentGoalRun(
            id: id,
            workspaceId: _ws,
            spaceId: _space,
            conversationId: _conv,
            agentId: agent,
            userText: 'ship $id',
            costCapMicros: 50000000,
            requestedByUserId: _person,
            contract: contract,
            hold: GoalHold.verifying,
            verification: GoalVerification(
              round: 1,
              claimSummary: 'done',
              at: w.now,
            ),
            createdAt: w.now,
            updatedAt: w.now,
          ),
        );
      }
      w.checkGate = Completer<void>();
      await w.supervisor.sweep().timeout(const Duration(seconds: 5));
      await w.pump();
      expect(w.checkRuns, GoalVerifier.maxConcurrentChecks);
      w.checkGate!.complete();
      await w.supervisor.verificationsDone();
      await w.pump();
      expect(w.checkRuns, 3);
      expect(w.maxChecksRunning, GoalVerifier.maxConcurrentChecks);
    });
  });

  group('the third review', () {
    Map<String, dynamic> pass() => {
      'verdict': 'pass',
      'items': [
        {
          'criterion': 'the objective',
          'state': 'met',
          'evidence': 'read the files',
        },
      ],
      'concerns': const [],
    };

    test(
      'finding 13: the failure line names the count, not the class',
      () async {
        await w.start('ship it');
        await w.settle('run-1', reason: RunEndReason.error);
        expect(
          w.said.last,
          'Durable /goal: segment 1 ended in error (error); retrying in 30 s '
          '(failure 1 of ${GoalSupervisor.maxConsecutiveFailures}).',
        );
      },
    );

    test('finding 7: a review at the limit with no park left pauses for a '
        'person as limit_parks, never cannot_verify, and each Resume asks '
        'the review again', () async {
      await w.start('ship it');
      final started = w.goal;
      w.goals.goals[started.id] = started.copyWith(
        parkCount: LimitPark.maxGoalParks,
      );
      await w.claim();
      await w.settle(w.goal.activeRunId!);
      await w.supervisor.verificationsDone();
      for (var resumes = 0; resumes < 2; resumes++) {
        await w.advance(WakeQueueService.quietWindow);
        expect(
          w.dispatched.last.wakeContext.wakeReason,
          anyOf(WakeReason.goalReview, WakeReason.limitReset),
        );
        expect(w.dispatched.last.readOnly, isTrue);
        final review = w.runIds.last;
        w.goals.goals[w.goal.id] = w.goal.copyWith(
          parkCount: LimitPark.maxGoalParks,
        );
        await w.settle(
          review,
          reason: RunEndReason.usageLimit,
          limitResetsAt: w.now.add(const Duration(hours: 1)),
        );
        expect(w.goal.status, AgentGoalStatus.paused);
        expect(w.goal.hold, GoalHold.needsReview);
        expect(w.goal.holdDetail, LimitPark.goalHoldDetail);
        expect(w.goal.verification!.verdict, isNull);
        expect(w.said.last, contains('during the review of its claim'));
        final runs = w.dispatched.length;
        await w.supervisor.resumeGoal(_ws, w.goal.id);
        await w.supervisor.verificationsDone();
        expect(w.goal.parkCount, 0);
        expect(w.goal.hold, GoalHold.verifying);
        await w.advance(WakeQueueService.quietWindow);
        expect(w.dispatched, hasLength(runs + 1));
        expect(w.dispatched.last.wakeContext.wakeReason, WakeReason.goalReview);
        if (resumes == 1) {
          await w.settle(w.runIds.last, output: pass());
          expect(w.goal.status, AgentGoalStatus.completed);
        }
      }
    });

    test('finding 14: while another workspace waits, one workspace runs at '
        'most one check; waiting checks go round-robin by workspace', () async {
      final contract = GoalContract(checks: [GoalCheck(run: 'make test')]);
      AgentGoalRun verifying(String id, String ws, String agent) =>
          AgentGoalRun(
            id: id,
            workspaceId: ws,
            spaceId: _space,
            conversationId: _conv,
            agentId: agent,
            userText: 'ship $id',
            costCapMicros: 50000000,
            requestedByUserId: _person,
            contract: contract,
            hold: GoalHold.verifying,
            verification: GoalVerification(
              round: 1,
              claimSummary: 'done',
              at: w.now,
            ),
            createdAt: w.now,
            updatedAt: w.now,
          );
      for (final agent in ['a1', 'a2', 'a3', 'b1']) {
        w.checkGates[agent] = Completer<void>();
      }
      for (final (id, agent) in [('g-1', 'a1'), ('g-2', 'a2'), ('g-3', 'a3')]) {
        await w.goals.upsert(verifying(id, _ws, agent));
      }
      await w.supervisor.sweep();
      await w.pump();
      // Nobody else waits: workspace A takes both slots.
      expect(w.checkStarts, ['a1', 'a2']);
      await w.goals.upsert(verifying('g-b', 'ws-2', 'b1'));
      await w.supervisor.sweep();
      await w.pump();
      expect(w.checkStarts, ['a1', 'a2']);
      w.checkGates['a1']!.complete();
      await w.pump();
      // Workspace B's check, not A's third.
      expect(w.checkStarts, ['a1', 'a2', 'b1']);
      w.checkGates['a2']!.complete();
      await w.pump();
      expect(w.checkStarts, ['a1', 'a2', 'b1', 'a3']);
      w.checkGates['a3']!.complete();
      w.checkGates['b1']!.complete();
      await w.supervisor.verificationsDone();
    });
  });

  group('the fifth review', () {
    /// Ticket [ticket] completed and [left] stay open: its completion wake
    /// starts the next segment.
    Future<void> ticketDone(String ticket, List<String> left) async {
      w.delegations = left;
      await w.queue.enqueueAndDeliver(
        childCompletedWake(
          id: 'ticket-$ticket-settled',
          workspaceId: _ws,
          spaceId: _space,
          conversationId: _conv,
          delegatorAgentId: _agent,
          workerAgentId: 'agent-2',
          workerName: 'Bo',
          status: 'completed',
          dedupKey: 'ticket:$ticket:settled',
          now: w.now,
          payload: 'Done.',
          ticketId: ticket,
        ),
      );
      await w.pump();
    }

    for (final firstProgressed in [true, false]) {
      test('finding 3: seven tickets answered one by one never stop the goal '
          '(${firstProgressed ? 'with' : 'without'} progress in the first '
          'segment): a ticket finishing is not new work', () async {
        await w.start('ship it');
        final tickets = [for (var i = 1; i <= 7; i++) 'T-$i'];
        w.delegations = tickets;
        if (firstProgressed) {
          w.fingerprints.value = 'fp-1';
          await w.settle('run-1', calls: const [_edit]);
        } else {
          await w.settle('run-1');
        }
        expect(w.goal.hold, GoalHold.waiting);
        for (var done = 1; done < tickets.length; done++) {
          final run = w.runIds.length;
          await ticketDone(tickets[done - 1], tickets.sublist(done));
          expect(w.runIds, hasLength(run + 1), reason: 'segment ${done + 1}');
          // The segment reads the result and ends, no progress of its own.
          await w.settle(w.runIds.last);
          expect(w.goal.status, AgentGoalStatus.active);
          expect(w.goal.hold, GoalHold.waiting);
          expect(w.goal.holdDetail, contains('${7 - done} open delegated'));
        }
        final marks = w.goal.progressMarks!;
        expect(marks.waits, firstProgressed ? 6 : 7);
        expect(marks.freshWaits, firstProgressed ? 0 : 1);
        expect(marks.owed, ['ticket:T-7']);
      });
    }

    for (final firstProgressed in [true, false]) {
      test('finding 3: seven asks answered one by one never stop the goal '
          '(${firstProgressed ? 'with' : 'without'} progress in the first '
          'segment): an answer is not new work', () async {
        await w.start('ship it');
        w.asks.asks.addAll([
          for (var i = 1; i <= 7; i++) _ask('ask-$i', w.now),
        ]);
        if (firstProgressed) {
          w.fingerprints.value = 'fp-1';
          await w.settle('run-1', calls: const [_edit]);
        } else {
          await w.settle('run-1');
        }
        for (var answered = 1; answered < 7; answered++) {
          final ask = w.asks.asks.removeAt(0);
          await w.queue.enqueueAndDeliver(
            Wake(
              id: 'reply-${ask.id}',
              workspaceId: _ws,
              spaceId: _space,
              conversationId: _conv,
              agentId: _agent,
              reason: WakeReason.peerReply,
              payload: 'the answer',
              detail: WakeDetail(askId: ask.id, status: 'answered'),
              dedupKey: 'ask:${ask.id}:reply',
              notBefore: w.now,
              createdAt: w.now,
            ),
          );
          await w.pump();
          await w.settle(w.runIds.last);
          expect(w.goal.status, AgentGoalStatus.active);
          expect(w.goal.hold, GoalHold.waiting);
        }
        expect(w.goal.progressMarks!.freshWaits, firstProgressed ? 0 : 1);
        expect(w.goal.progressMarks!.owed, ['ask:ask-7']);
      });
    }

    test('finding 3: one ticket finishing and another delegated is one fresh '
        'wait; a ticket finishing after it is none', () async {
      await w.start('ship it');
      w.delegations = const ['T-1', 'T-2'];
      w.fingerprints.value = 'fp-1';
      await w.settle('run-1', calls: const [_edit]);
      expect(w.goal.progressMarks!.waits, 0);
      // T-1 finished; the segment delegates T-3 and ends.
      await ticketDone('T-1', const ['T-2', 'T-3']);
      await w.settle(w.runIds.last);
      expect(w.goal.progressMarks!.waits, 1);
      expect(w.goal.progressMarks!.freshWaits, 1);
      // T-2 finished; nothing new.
      await ticketDone('T-2', const ['T-3']);
      await w.settle(w.runIds.last);
      expect(w.goal.progressMarks!.waits, 2);
      expect(w.goal.progressMarks!.freshWaits, 1);
      // The fallback between answers adds a wait, never a fresh one.
      final delay = w.openGoalWakes().single.notBefore.difference(w.now);
      await w.advance(delay + const Duration(seconds: 1));
      await w.settle(w.runIds.last);
      expect(w.goal.progressMarks!.waits, 3);
      expect(w.goal.progressMarks!.freshWaits, 1);
    });

    test(
      'check: an approval of the segment, announced as the publisher sends '
      'it (run and conversation), holds the goal on the person without '
      'deferring or striking anything, and its end clears the hold',
      () async {
        await w.start('ship it');
        w.bus.publish(
          AgentAwaitingInput(
            workspaceId: _ws,
            waitId: 'approval-1',
            kind: AgentInputKind.approval,
            summary: 'Run make deploy',
            spaceId: _space,
            conversationId: _conv,
            agentId: _agent,
            agentName: 'Ada',
            runId: 'run-1',
            occurredAt: w.now,
          ),
        );
        await w.pump();
        expect(w.goal.status, AgentGoalStatus.active);
        expect(w.goal.activeRunId, 'run-1');
        expect(w.goal.hold, GoalHold.person);
        expect(
          w.goal.holdDetail,
          '${GoalSupervisor.inputHoldPrefix}approval-1',
        );
        // An hour of waiting: the sweep and the queue start nothing, the
        // live segment is neither struck nor failed.
        await w.advance(const Duration(hours: 1));
        await w.sweep();
        expect(w.runIds, ['run-1']);
        expect(w.goal.activeRunId, 'run-1');
        expect(w.goal.noProgressStreak, 0);
        expect(w.goal.consecutiveFailures, 0);
        expect(w.openGoalWakes(), isEmpty);
        w.bus.publish(
          AgentInputResolved(
            workspaceId: _ws,
            waitId: 'approval-1',
            occurredAt: w.now,
          ),
        );
        await w.pump();
        expect(w.goal.hold, isNull);
        // An approval of another run (not this segment) holds nothing.
        w.bus.publish(
          AgentAwaitingInput(
            workspaceId: _ws,
            waitId: 'approval-2',
            kind: AgentInputKind.approval,
            summary: 'Run make deploy',
            spaceId: _space,
            conversationId: _conv,
            agentId: _agent,
            agentName: 'Ada',
            runId: 'run-other',
            occurredAt: w.now,
          ),
        );
        await w.pump();
        expect(w.goal.hold, isNull);
      },
    );

    test('check: an approval answered at once leaves no hold: its end is '
        'handled after its start', () async {
      await w.start('ship it');
      w.bus
        ..publish(
          AgentAwaitingInput(
            workspaceId: _ws,
            waitId: 'approval-1',
            kind: AgentInputKind.approval,
            summary: 'Run make deploy',
            spaceId: _space,
            conversationId: _conv,
            agentId: _agent,
            agentName: 'Ada',
            runId: 'run-1',
            occurredAt: w.now,
          ),
        )
        ..publish(
          AgentInputResolved(
            workspaceId: _ws,
            waitId: 'approval-1',
            occurredAt: w.now,
          ),
        );
      await w.pump();
      expect(w.goal.hold, isNull);
    });

    test('check: a segment that ends while its approval is pending clears '
        'the hold; the late end of the approval changes nothing', () async {
      await w.start('ship it');
      w.bus.publish(
        AgentAwaitingInput(
          workspaceId: _ws,
          waitId: 'approval-1',
          kind: AgentInputKind.approval,
          summary: 'Run make deploy',
          spaceId: _space,
          conversationId: _conv,
          agentId: _agent,
          agentName: 'Ada',
          runId: 'run-1',
          occurredAt: w.now,
        ),
      );
      await w.pump();
      expect(w.goal.hold, GoalHold.person);
      w.delegations = const ['T-1'];
      await w.settle('run-1');
      expect(w.goal.hold, GoalHold.waiting);
      w.bus.publish(
        AgentInputResolved(
          workspaceId: _ws,
          waitId: 'approval-1',
          occurredAt: w.now,
        ),
      );
      await w.pump();
      expect(w.goal.hold, GoalHold.waiting);
    });
  });

  group('review 6a', () {
    AgentAwaitingInput approval(
      String waitId, {
      required String runId,
      String conversationId = _conv,
      String agentId = _agent,
    }) => AgentAwaitingInput(
      workspaceId: _ws,
      waitId: waitId,
      kind: AgentInputKind.approval,
      summary: 'Run make deploy',
      spaceId: _space,
      conversationId: conversationId,
      agentId: agentId,
      agentName: 'Ada',
      runId: runId,
      occurredAt: w.now,
    );

    AgentInputResolved resolved(String waitId) =>
        AgentInputResolved(workspaceId: _ws, waitId: waitId, occurredAt: w.now);

    /// Goal G of agent `a2` in `conv-2`, whose next segment's dispatch is
    /// parked (on credentials, the path lock) until [parked] completes.
    Future<Future<String?>> parkG(Completer<String?> parked) async {
      await w.goals.upsert(
        AgentGoalRun(
          id: 'goal-g',
          workspaceId: _ws,
          spaceId: _space,
          conversationId: 'conv-2',
          agentId: 'a2',
          userText: 'other work',
          costCapMicros: 50000000,
          requestedByUserId: _person,
          hold: GoalHold.waiting,
          createdAt: w.now,
          updatedAt: w.now,
        ),
      );
      final dispatch = w.supervisor.dispatchWakeRun(
        const WakeDispatchRequest(
          workspaceId: _ws,
          spaceId: _space,
          conversationId: 'conv-2',
          agentId: 'a2',
          wakeContext: WakeContext(
            wakeReason: WakeReason.peerReply,
            startedByRunId: null,
          ),
          requestedByUserId: null,
          mentionChain: [],
          inReplyToAgentId: null,
          costCapMicros: null,
          expectedOutputSchema: null,
          freshHistory: false,
          readOnly: false,
        ),
        (_) => parked.future,
      );
      await w.pump();
      return dispatch;
    }

    AgentGoalRun goalH() =>
        w.goals.goals.values.firstWhere((g) => g.agentId == _agent);

    test('finding 4: a wait that waits for a parked dispatch delays no other '
        "goal's hold or its clearing", () async {
      await w.start('ship it');
      final parked = Completer<String?>();
      final dispatch = await parkG(parked);
      // A run of G's agent in G's conversation that is not (yet) a segment:
      // its lookup waits for G's attach, rightly.
      w.bus.publish(
        approval(
          'other',
          runId: 'run-x',
          conversationId: 'conv-2',
          agentId: 'a2',
        ),
      );
      await w.pump();
      w.bus.publish(approval('approval-h', runId: 'run-1'));
      await w.pump();
      expect(goalH().hold, GoalHold.person);
      w.bus.publish(resolved('approval-h'));
      await w.pump();
      expect(goalH().hold, isNull);
      parked.complete(null);
      await dispatch;
    });

    test('finding 4: a segment that settles before its dispatch returned does '
        "not wait for another goal's parked dispatch", () async {
      final parked = Completer<String?>();
      final dispatch = await parkG(parked);
      w.beforeReturn = (runId) async {
        w.beforeReturn = null;
        await w.settle(runId, reason: RunEndReason.error);
      };
      await w.start('ship it');
      await w.pump();
      expect(goalH().runCount, 1);
      expect(goalH().consecutiveFailures, 1);
      parked.complete(null);
      await dispatch;
    });

    test('finding 5: with two approvals open, answering the first keeps the '
        'hold; answering the second clears it', () async {
      await w.start('ship it');
      w.bus
        ..publish(approval('approval-1', runId: 'run-1'))
        ..publish(approval('approval-2', runId: 'run-1'));
      await w.pump();
      expect(w.goal.hold, GoalHold.person);
      expect(w.goal.holdDetail, '${GoalSupervisor.inputHoldPrefix}approval-1');
      w.bus.publish(resolved('approval-1'));
      await w.pump();
      expect(w.goal.hold, GoalHold.person);
      expect(w.goal.holdDetail, '${GoalSupervisor.inputHoldPrefix}approval-2');
      w.bus.publish(resolved('approval-2'));
      await w.pump();
      expect(w.goal.hold, isNull);
    });

    test('finding 5: two approvals, each answered as soon as it is asked, '
        'leave no hold', () async {
      await w.start('ship it');
      w.bus
        ..publish(approval('approval-1', runId: 'run-1'))
        ..publish(approval('approval-2', runId: 'run-1'))
        ..publish(resolved('approval-2'))
        ..publish(resolved('approval-1'));
      await w.pump();
      expect(w.goal.hold, isNull);
    });
  });

  group('nothing is stuck: a person ends every paused hold', () {
    for (final (hold, detail, claim) in <(GoalHold, String?, bool)>[
      (GoalHold.byPerson, null, false),
      (GoalHold.byPerson, GoalHoldDetails.claimPending, true),
      (GoalHold.needsReview, GoalHoldDetails.stalled, false),
      (GoalHold.needsReview, GoalHoldDetails.stalledWaiting, false),
      (GoalHold.needsReview, LimitPark.goalHoldDetail, false),
      (GoalHold.needsReview, '${GoalHoldDetails.wakeSkipped}: x', false),
      (GoalHold.needsReview, GoalHoldDetails.verificationFailed, true),
      (GoalHold.needsReview, GoalHoldDetails.cannotVerify, true),
      (GoalHold.needsReview, GoalHoldDetails.sandboxUnavailable, true),
      (GoalHold.needsReview, GoalHoldDetails.checkerUnavailable, true),
      (GoalHold.needsReview, '${GoalHoldDetails.checkBroken}: x', true),
    ]) {
      test("paused, ${hold.wire}${detail == null ? '' : ' ($detail)'}: the "
          "requester's Resume starts a run", () async {
        await w.start('ship it');
        w.fingerprints.value = 'fp-1';
        await w.settle('run-1');
        await w.supervisor.pauseGoal(_ws, w.goal.id);
        final paused = w.goal;
        w.goals.goals[paused.id] = paused.copyWith(
          hold: hold,
          holdDetail: detail,
          removeHoldDetail: detail == null,
          verification: claim
              ? GoalVerification(round: 1, claimSummary: 'done', at: w.now)
              : null,
        );
        final runs = w.dispatched.length;
        await w.supervisor.resumeGoal(_ws, paused.id);
        await w.supervisor.verificationsDone();
        await w.advance(WakeQueueService.quietWindow);
        expect(w.goal.status, AgentGoalStatus.active);
        expect(w.dispatched, hasLength(runs + 1));
      });
    }
  });

  test('every segment end writes a transcript-independent record: the '
      'activity of a run is read once', () {
    final activity = RunToolActivity();
    activity.recordSegments(
      workspaceId: _ws,
      runId: 'r',
      segments: [
        ToolSegment(
          toolName: 'bash',
          toolCallId: 't1',
          inputs: const {'command': 'ls'},
          status: ToolSegmentStatus.ok,
          startedAt: DateTime.utc(2026),
        ),
      ],
    );
    expect(activity.take(workspaceId: 'ws-2', runId: 'r'), isNull);
    expect(activity.take(workspaceId: _ws, runId: 'r'), hasLength(1));
    expect(activity.take(workspaceId: _ws, runId: 'r'), isNull);
  });
}
