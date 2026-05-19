import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_infra/src/dispatch/goal_supervisor.dart';
import 'package:test/test.dart';

/// Minimal map-backed AgentGoalRunRepository honoring workspace scoping.
class _FakeGoalRepo implements AgentGoalRunRepository {
  final goals = <String, AgentGoalRun>{};

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
  Future<void> upsert(AgentGoalRun goal) async {
    goals[goal.id] = goal;
  }
}

/// Map-backed AgentRunLogRepository; only getById/upsert are exercised.
class _FakeRunLogRepo implements AgentRunLogRepository {

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
  final logs = <String, AgentRunLog>{};

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    final log = logs[id];
    return log != null && log.workspaceId == workspaceId ? log : null;
  }

  @override
  Future<void> upsert(AgentRunLog log) async {
    logs[log.id] = log;
  }

  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) =>
      const Stream.empty();

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => const [];

  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => const [];

  @override
  Stream<List<AgentRunLog>> watchAll() => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchRecent(int limit) => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchActiveBySpace(
    String workspaceId,
    String conversationId,
  ) => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchBySpace(
    String workspaceId,
    String conversationId,
  ) => const Stream.empty();

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async => null;
}

class _DispatchCall {
  _DispatchCall({
    required this.spaceId,
    required this.agentId,
    required this.prompt,
    required this.workspaceId,
    this.conversationId,
    this.requestedByUserId,
    this.costCapCents,
  });

  final String spaceId;
  final String agentId;
  final String prompt;
  final String workspaceId;
  final String? conversationId;
  final String? requestedByUserId;
  final int? costCapCents;
}

class _SystemMessage {
  _SystemMessage(
    this.workspaceId,
    this.spaceId,
    this.content,
    this.conversationId,
  );

  final String workspaceId;
  final String spaceId;
  final String content;
  final String? conversationId;
}

void main() {
  const ws = 'ws-1';
  const spaceId = 'ch-1';
  const conversationId = 'conv-1';
  const agentId = 'agent-1';

  late _FakeGoalRepo goalRepo;
  late _FakeRunLogRepo runLogRepo;
  late DomainEventBus eventBus;
  late List<_DispatchCall> dispatches;
  late List<_SystemMessage> systemMessages;
  late DateTime current;
  late GoalSupervisor supervisor;
  var runSeq = 0;

  Future<String?> fakeDispatcher({
    required String spaceId,
    required String agentId,
    required String prompt,
    required String workspaceId,
    String? conversationId,
    String? requestedByUserId,
    int? costCapCents,
  }) async {
    dispatches.add(
      _DispatchCall(
        spaceId: spaceId,
        agentId: agentId,
        prompt: prompt,
        workspaceId: workspaceId,
        conversationId: conversationId,
        requestedByUserId: requestedByUserId,
        costCapCents: costCapCents,
      ),
    );
    return 'run-${++runSeq}';
  }

  Future<void> fakeSystemMessageSender({
    required String workspaceId,
    required String spaceId,
    required String content,
    String? conversationId,
  }) async {
    systemMessages.add(
      _SystemMessage(workspaceId, spaceId, content, conversationId),
    );
  }

  /// Pumps the event queue so the broadcast event-bus listener and any
  /// zero-delay backoff timers fully settle.
  Future<void> settle() async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  AgentRunLog runLog(String id, RunStatus status, {int costCents = 0}) =>
      AgentRunLog(
        id: id,
        agentId: agentId,
        workspaceId: ws,
        startedAt: current,
        status: status,
        cost: RunCost(estimatedCostCents: costCents),
      );

  void publishCompletion(String runId) {
    eventBus.publish(
      AgentRunCompleted(
        agentId: agentId,
        workspaceId: ws,
        conversationId: conversationId,
        occurredAt: current,
        runId: runId,
      ),
    );
  }

  AgentGoalRun seededGoal({
    String id = 'goal-seed',
    AgentGoalStatus status = AgentGoalStatus.active,
    AgentGoalKind kind = AgentGoalKind.goal,
    String userText = 'Seeded objective',
    int runCount = 0,
    int costCents = 0,
    int consecutiveFailures = 0,
    String? activeRunId,
    DateTime? deadlineAt,
    bool uncapped = false,
  }) {
    final goal = AgentGoalRun(
      id: id,
      workspaceId: ws,
      spaceId: spaceId,
      conversationId: conversationId,
      agentId: agentId,
      userText: userText,
      kind: kind,
      status: status,
      deadlineAt: uncapped
          ? null
          : (deadlineAt ?? current.add(const Duration(days: 5))),
      costCapCents: 5000,
      maxRuns: uncapped ? null : 100,
      runCount: runCount,
      costCents: costCents,
      consecutiveFailures: consecutiveFailures,
      activeRunId: activeRunId,
      createdAt: current,
      updatedAt: current,
    );
    goalRepo.goals[id] = goal;
    return goal;
  }

  Future<AgentGoalRun?> startGoal({
    String text = 'Ship the feature',
    AgentGoalKind kind = AgentGoalKind.goal,
  }) => supervisor.startGoal(
    workspaceId: ws,
    spaceId: spaceId,
    conversationId: conversationId,
    agentId: agentId,
    userText: text,
    kind: kind,
  );

  setUp(() {
    goalRepo = _FakeGoalRepo();
    runLogRepo = _FakeRunLogRepo();
    eventBus = DomainEventBus();
    dispatches = [];
    systemMessages = [];
    current = DateTime(2026, 7, 27, 12);
    runSeq = 0;
    supervisor = GoalSupervisor(
      goalRepository: goalRepo,
      runLogRepository: runLogRepo,
      dispatcher: fakeDispatcher,
      systemMessageSender: fakeSystemMessageSender,
      eventBus: eventBus,
      now: () => current,
      backoff: (_) => Duration.zero,
    );
  });

  tearDown(() {
    supervisor.dispose();
    eventBus.dispose();
  });

  test(
    'startGoal dispatches the verbatim slash command and narrates the start',
    () async {
      final goal = await startGoal();

      expect(goal, isNotNull);
      expect(dispatches, hasLength(1));
      expect(dispatches.single.prompt, '/goal Ship the feature');
      expect(dispatches.single.workspaceId, ws);
      expect(dispatches.single.conversationId, conversationId);
      expect(goal!.activeRunId, 'run-1');

      final persisted = await goalRepo.getActiveForAgent(ws, agentId);
      expect(persisted, goal);
      expect(persisted!.deadlineAt, isNull);
      expect(persisted.costCapCents, 5000);
      expect(persisted.maxRuns, isNull);
      expect(persisted.status, AgentGoalStatus.active);

      expect(
        systemMessages.any(
          (m) =>
              m.workspaceId == ws &&
              m.spaceId == spaceId &&
              m.content.startsWith('Started a durable /goal goal'),
        ),
        isTrue,
      );
    },
  );

  test(
    'run completion below budgets re-dispatches the continuation prompt',
    () async {
      final goal = (await startGoal())!;
      runLogRepo.logs['run-1'] = runLog(
        'run-1',
        RunStatus.completed,
        costCents: 120,
      );

      publishCompletion('run-1');
      await settle();

      expect(dispatches, hasLength(2));
      final continuation = dispatches[1].prompt;
      expect(
        continuation,
        'AUTOMATIC CONTINUATION of your durable /goal (run 2): '
        'Ship the feature\n\n'
        'Your previous segment ended; the conversation above + your notes hold '
        'the state. Continue without restarting. Declare the objective achieved '
        'with the complete_goal tool when done.',
      );

      final updated = await goalRepo.getById(ws, goal.id);
      expect(updated!.runCount, 1);
      expect(updated.costCents, 120);
      expect(updated.consecutiveFailures, 0);
      expect(updated.activeRunId, 'run-2');
      expect(updated.status, AgentGoalStatus.active);

      expect(
        systemMessages.any(
          (m) => m.content == 'Run 1 finished, continuing (run 2).',
        ),
        isTrue,
      );
    },
  );

  test('completeGoal marks completed and stops further dispatch', () async {
    final goal = (await startGoal())!;
    runLogRepo.logs['run-1'] = runLog('run-1', RunStatus.completed);

    await supervisor.completeGoal(ws, agentId, summary: 'All done.');

    final completed = await goalRepo.getById(ws, goal.id);
    expect(completed!.status, AgentGoalStatus.completed);
    expect(completed.summary, 'All done.');
    expect(completed.activeRunId, isNull);
    expect(
      systemMessages.any(
        (m) => m.content == 'Durable /goal goal completed: All done.',
      ),
      isTrue,
    );

    // The finishing run's completion event arrives after the declaration and
    // must not trigger another dispatch.
    publishCompletion('run-1');
    await settle();
    expect(dispatches, hasLength(1));
  });

  test(
    'completeGoal without an active goal throws an agent-readable error',
    () {
      expect(
        () => supervisor.completeGoal(ws, agentId, summary: 'n/a'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'You have no active goal in this workspace.',
          ),
        ),
      );
    },
  );

  test('deadline wall stops the goal as budgetExhausted', () async {
    final goal = (await startGoal(text: 'Ship it --days 5'))!;
    runLogRepo.logs['run-1'] = runLog('run-1', RunStatus.completed);
    current = current.add(const Duration(days: 6));

    publishCompletion('run-1');
    await settle();

    final updated = await goalRepo.getById(ws, goal.id);
    expect(updated!.status, AgentGoalStatus.budgetExhausted);
    expect(dispatches, hasLength(1));
    expect(
      systemMessages.any(
        (m) => m.content == 'Durable /goal goal stopped: the deadline passed.',
      ),
      isTrue,
    );
  });

  test('cost cap wall stops the goal as budgetExhausted', () async {
    final goal = (await startGoal())!;
    runLogRepo.logs['run-1'] = runLog(
      'run-1',
      RunStatus.completed,
      costCents: 5000,
    );

    publishCompletion('run-1');
    await settle();

    final updated = await goalRepo.getById(ws, goal.id);
    expect(updated!.status, AgentGoalStatus.budgetExhausted);
    expect(updated.costCents, 5000);
    expect(dispatches, hasLength(1));
    expect(
      systemMessages.any(
        (m) =>
            m.content ==
            'Durable /goal goal stopped: the cost cap of 5000 cents was '
                'reached.',
      ),
      isTrue,
    );
  });

  test('run budget wall stops the goal as budgetExhausted', () async {
    final goal = seededGoal(runCount: 99, activeRunId: 'run-x');
    runLogRepo.logs['run-x'] = runLog('run-x', RunStatus.completed);

    publishCompletion('run-x');
    await settle();

    final updated = await goalRepo.getById(ws, goal.id);
    expect(updated!.runCount, 100);
    expect(updated.status, AgentGoalStatus.budgetExhausted);
    expect(dispatches, isEmpty);
    expect(
      systemMessages.any(
        (m) =>
            m.content ==
            'Durable /goal goal stopped: the run budget of 100 runs was '
                'exhausted.',
      ),
      isTrue,
    );
  });

  test('three consecutive failed runs give up with status failed', () async {
    final goal = (await startGoal())!;
    expect(dispatches, hasLength(1));

    for (var failure = 1; failure <= 3; failure++) {
      final runId = 'run-$failure';
      runLogRepo.logs[runId] = runLog(runId, RunStatus.error);
      publishCompletion(runId);
      await settle();
      if (failure < 3) {
        // Backoff is zero in tests, so the retry has already been dispatched.
        expect(dispatches, hasLength(failure + 1));
        expect(
          dispatches.last.prompt,
          startsWith(
            'AUTOMATIC CONTINUATION of your durable /goal '
            '(run ${failure + 1}):',
          ),
        );
        final mid = await goalRepo.getById(ws, goal.id);
        expect(mid!.consecutiveFailures, failure);
      }
    }

    final updated = await goalRepo.getById(ws, goal.id);
    expect(updated!.status, AgentGoalStatus.failed);
    expect(updated.consecutiveFailures, 3);
    expect(dispatches, hasLength(3));
    expect(
      systemMessages.any(
        (m) =>
            m.content ==
            'Durable /goal goal failed: 3 consecutive runs ended in error. '
                'Giving up.',
      ),
      isTrue,
    );
  });

  test('a second startGoal for the same agent is refused', () async {
    final first = await startGoal(text: 'First objective');
    expect(first, isNotNull);

    final second = await startGoal(text: 'Second objective');
    expect(second, isNull);
    expect(dispatches, hasLength(1));
    expect(
      systemMessages.any(
        (m) =>
            m.content.contains('already has an active durable /goal goal') &&
            m.content.contains('complete_goal'),
      ),
      isTrue,
    );
  });

  test(
    'reconcileOnStartup re-dispatches active goals with terminal runs',
    () async {
      final dead = seededGoal(id: 'goal-dead', activeRunId: 'run-dead');
      runLogRepo.logs['run-dead'] = runLog('run-dead', RunStatus.completed);
      final orphaned = seededGoal(id: 'goal-orphan');
      final live = seededGoal(id: 'goal-live', activeRunId: 'run-live');
      runLogRepo.logs['run-live'] = runLog('run-live', RunStatus.running);
      seededGoal(id: 'goal-paused', status: AgentGoalStatus.paused);

      await supervisor.reconcileOnStartup();

      expect(dispatches, hasLength(2));
      final deadContinuation = dispatches
          .firstWhere((d) => d.prompt.contains('Seeded objective'))
          .prompt;
      expect(
        deadContinuation,
        startsWith(
          'AUTOMATIC CONTINUATION of your durable /goal (run 1 of 100):',
        ),
      );
      expect(
        await goalRepo.getById(ws, dead.id).then((g) => g!.activeRunId),
        isNotNull,
      );
      expect(
        await goalRepo.getById(ws, orphaned.id).then((g) => g!.activeRunId),
        isNotNull,
      );
      // Live runs and paused goals are left alone.
      expect(
        await goalRepo.getById(ws, live.id).then((g) => g!.activeRunId),
        'run-live',
      );
      expect(
        systemMessages.any(
          (m) => m.content.startsWith('Server restarted; continuing'),
        ),
        isTrue,
      );
    },
  );

  test(
    'reconcileOnStartup closes active goals already at a budget wall',
    () async {
      final goal = seededGoal(
        deadlineAt: current.subtract(const Duration(days: 1)),
      );

      await supervisor.reconcileOnStartup();

      expect(
        await goalRepo.getById(ws, goal.id).then((g) => g!.status),
        AgentGoalStatus.budgetExhausted,
      );
      expect(dispatches, isEmpty);
    },
  );

  test('an uncapped goal never hits a run-budget wall', () async {
    // maxRuns is null by default: a /goal keeps being re-dispatched no
    // matter how many runs it has burned through.
    final goal = seededGoal(
      runCount: 9999,
      activeRunId: 'run-x',
      uncapped: true,
    );
    runLogRepo.logs['run-x'] = runLog('run-x', RunStatus.completed);

    publishCompletion('run-x');
    await settle();

    final updated = await goalRepo.getById(ws, goal.id);
    expect(updated!.runCount, 10000);
    expect(updated.status, AgentGoalStatus.active);
    expect(dispatches, hasLength(1));
  });

  test('--max / --budget / --days flags opt back into the walls', () async {
    final goal = (await startGoal(
      text: 'Ship it --max 10 --budget 12.50 --days 3',
    ))!;

    final persisted = await goalRepo.getById(ws, goal.id);
    expect(persisted!.maxRuns, 10);
    expect(persisted.costCapCents, 1250);
    expect(persisted.deadlineAt, current.add(const Duration(days: 3)));
    // The flags are stripped from the objective; the dispatch prompt carries
    // the stripped objective too — the flags configure the walls, they must
    // not pollute the agent-facing directive.
    expect(persisted.userText, 'Ship it');
    expect(dispatches.single.prompt, '/goal Ship it');
  });

  test('a leading count becomes the run budget', () async {
    // `/loop 10 fix the tests` is what people type before they discover
    // `--max`; both must mean the same thing.
    final goal = (await startGoal(text: '10 fix the tests'))!;
    final persisted = await goalRepo.getById(ws, goal.id);
    expect(persisted!.maxRuns, 10);
    expect(persisted.userText, 'fix the tests');
    expect(dispatches.single.prompt, '/goal fix the tests');
  });

  test('a leading duration becomes the deadline', () async {
    final goal = (await startGoal(text: '30m refactor the router'))!;
    final persisted = await goalRepo.getById(ws, goal.id);
    expect(persisted!.deadlineAt, current.add(const Duration(minutes: 30)));
    expect(persisted.userText, 'refactor the router');
  });

  test('an explicit --max wins over a leading count', () async {
    final goal = (await startGoal(text: '10 ship it --max 3'))!;
    expect(
      (await goalRepo.getById(ws, goal.id))!.maxRuns,
      3,
      reason: 'the longer spelling is the more deliberate one',
    );
  });

  test('prose is an unbounded goal, not a parse error', () async {
    final goal = (await startGoal(text: 'keep going until CI is green'))!;
    final persisted = await goalRepo.getById(ws, goal.id);
    expect(persisted!.maxRuns, isNull);
    expect(persisted.userText, 'keep going until CI is green');
  });

  test('a malformed limit is refused instead of running unbounded', () async {
    // Starting an UNBOUNDED autonomous loop because "10x" did not parse is an
    // expensive, invisible failure.
    final goal = await startGoal(text: '10x the throughput');
    expect(goal, isNull);
    expect(dispatches, isEmpty);
    expect(systemMessages.last.content, contains('/loop'));
  });

  test(
    'resumeGoal refuses a budgetExhausted goal without a budget raise',
    () async {
      final goal = seededGoal(
        status: AgentGoalStatus.budgetExhausted,
        costCents: 5000,
      );

      await supervisor.resumeGoal(ws, goal.id);

      expect(
        await goalRepo.getById(ws, goal.id).then((g) => g!.status),
        AgentGoalStatus.budgetExhausted,
      );
      expect(dispatches, isEmpty);
      expect(
        systemMessages.any((m) => m.content.contains('Resume it with a raise')),
        isTrue,
      );
    },
  );

  test('a segment never gets a cap above the default 500', () async {
    await startGoal();

    expect(dispatches.single.costCapCents, 500);
  });

  test(
    'a nearly-exhausted goal threads its REMAINING budget as the run cap',
    () async {
      // $2.00 goal with $1.80 spent: the next segment may burn $0.20, not the
      // default $5.00 — an explicit `/goal --budget 2.00` must not be overshot
      // by a whole segment's worth of spend. First close the goal at the wall,
      // then observe the threaded cap on a continuing goal below it.
      final goal = AgentGoalRun(
        id: 'goal-tight',
        workspaceId: ws,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        userText: 'Tight budget',
        kind: AgentGoalKind.goal,
        status: AgentGoalStatus.active,
        deadlineAt: null,
        costCapCents: 200,
        maxRuns: null,
        runCount: 3,
        costCents: 180,
        consecutiveFailures: 0,
        activeRunId: 'run-tight',
        createdAt: current,
        updatedAt: current,
      );
      goalRepo.goals[goal.id] = goal;
      runLogRepo.logs['run-tight'] = runLog(
        'run-tight',
        RunStatus.completed,
        costCents: 60,
      );

      publishCompletion('run-tight');
      await settle();

      expect(
        await goalRepo.getById(ws, goal.id).then((g) => g!.status),
        AgentGoalStatus.budgetExhausted,
      );
      expect(dispatches, isEmpty);

      final continuing = goal.copyWith(
        costCents: 140,
        activeRunId: 'run-tight-2',
      );
      goalRepo.goals[goal.id] = continuing;
      runLogRepo.logs['run-tight-2'] = runLog(
        'run-tight-2',
        RunStatus.completed,
        costCents: 0,
      );

      publishCompletion('run-tight-2');
      await settle();

      expect(dispatches, hasLength(1));
      expect(dispatches.single.costCapCents, 60);
    },
  );

  test(
    'resumeGoal with a raise re-activates and re-dispatches immediately',
    () async {
      final goal = seededGoal(
        status: AgentGoalStatus.budgetExhausted,
        costCents: 5000,
      );

      await supervisor.resumeGoal(ws, goal.id, raiseCostCapCents: 10000);

      final updated = await goalRepo.getById(ws, goal.id);
      expect(updated!.status, AgentGoalStatus.active);
      expect(updated.costCapCents, 10000);
      expect(updated.activeRunId, isNotNull);
      expect(dispatches, hasLength(1));
      expect(
        dispatches.single.prompt,
        startsWith('AUTOMATIC CONTINUATION of your durable /goal'),
      );
    },
  );
}
