import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show GoalAlreadyActiveException;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/learning_events.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_pipeline_link.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_run_options.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_budget_gate.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart'
    show kPipelineRequestedByKey;
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_domain/features/pipelines/domain/templates/goal_pursue_config.dart';
import 'package:cc_infra/cc_infra.dart'
    show GoalSupervisor, WakeQueueService, kImprovementGoalField;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/runtime/server_pipeline_goals.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

const _ws = 'ws-1';
const _other = 'ws-2';
final _t0 = DateTime.utc(2026, 11, 19, 14);
final _link = GoalPipelineLink(pipelineRunId: 'run-1', stepId: 'pursue');

/// The `goal.pursue` node of step `pursue`: its output lands under
/// `shipped`.
final _step = PipelineStepDefinition(
  id: 'pursue',
  kind: StepKind.listen,
  bodyKey: kGoalPursueBodyKey,
  config: const PipelineNodeConfig(
    agentId: 'agent-1',
    prompt: 'Ship it',
    outputKey: 'shipped',
    extras: {'spaceId': 'space-1', 'budgetMicros': 2000000},
  ),
);

AgentGoalRun _goal({
  String workspaceId = _ws,
  AgentGoalStatus status = AgentGoalStatus.active,
  GoalPipelineLink? pipeline,
  String? requestedBy = 'user-1',
}) => AgentGoalRun(
  id: 'goal-1',
  workspaceId: workspaceId,
  spaceId: 'space-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  userText: 'Ship it',
  costCapMicros: 2000000,
  requestedByUserId: requestedBy,
  pipeline: pipeline,
  createdAt: _t0,
  updatedAt: _t0,
).copyWith(status: status, summary: 'shipped');

/// The supervisor's start and cancel, writing the real goal rows.
class _Supervisor implements GoalSupervisor {
  _Supervisor(this.goals);
  final AgentGoalRunRepository goals;
  final List<String> cancelled = [];
  GoalPipelineLink? started;

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
    required GoalPipelineLink pipeline,
  }) async {
    started = pipeline;
    // The real start's new goal id meets the one-active-goal index.
    if (await goals.getActiveForAgent(workspaceId, agentId) != null) {
      throw GoalAlreadyActiveException(
        workspaceId: workspaceId,
        agentId: agentId,
      );
    }
    await goals.upsert(
      _goal(
        workspaceId: workspaceId,
        pipeline: pipeline,
        requestedBy: requestedByUserId,
      ),
    );
    return (await goals.getById(workspaceId, 'goal-1'))!;
  }

  @override
  Future<void> cancelGoal(String workspaceId, String goalId) async {
    final goal = await goals.getById(workspaceId, goalId);
    if (goal == null || goal.status.isTerminal) {
      return;
    }
    cancelled.add('$workspaceId/$goalId');
    await goals.upsert(goal.copyWith(status: AgentGoalStatus.cancelled));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Engine implements PipelineEngine {
  final List<({String ws, String run, String step, StepResult result})>
  settled = [];
  final List<String> resumed = [];
  bool overBudget = false;

  @override
  Future<bool> settleSuspendedStep({
    required String workspaceId,
    required String pipelineRunId,
    required String stepId,
    required StepResult Function(PipelineStepDefinition step) result,
  }) async {
    settled.add((
      ws: workspaceId,
      run: pipelineRunId,
      step: stepId,
      result: result(_step),
    ));
    return true;
  }

  @override
  Future<bool> holdIfOverBudget(String ws, String runId) async => overBudget;

  @override
  Future<bool> resumeHeld(String ws, String runId) async {
    resumed.add('$ws/$runId');
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Runs implements PipelineRunRepository {
  final Map<String, PipelineRun> byId = {};
  final List<(String, int)> charged = [];

  @override
  Future<PipelineRun?> getRun(String id) async => byId[id];

  @override
  Future<void> incrementCost(String runId, int micros, int tokens) async {
    charged.add((runId, micros));
    final run = byId[runId];
    if (run != null) {
      byId[runId] = run.copyWith(totalCostMicros: run.totalCostMicros + micros);
    }
  }

  @override
  Future<List<PipelineRun>> nonTerminalRuns() async =>
      byId.values.where((r) => !r.isTerminal).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Orchestrations implements OrchestrationRepository {
  Orchestration? current;
  // Closed with the test's isolate.
  // ignore: close_sinks
  final controller = StreamController<Orchestration?>.broadcast();

  @override
  Future<Orchestration?> forPipelineRun(String ws, String runId) async =>
      current?.workspaceId == ws && current?.pipelineRunId == runId
      ? current
      : null;

  @override
  Stream<Orchestration?> watchById(String ws, String id) => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

class _Messages implements MessagingRepository {
  final List<({String spaceId, String content, String type})> sent = [];

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String? conversationId,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
  }) async {
    sent.add((spaceId: spaceId, content: content, type: messageType));
    return 'm-${sent.length}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

Orchestration _orchestration({int? cap = 5000000}) => Orchestration(
  id: 'orch-1',
  workspaceId: _ws,
  proposal: const OrchestrationProposal(
    goal: 'Plan',
    roles: [],
    subTickets: [],
    synthesis: SynthesisSpec(roleKey: 'lead', prompt: 'Wrap', outputSchema: {}),
  ),
  createdAt: _t0,
  updatedAt: _t0,
  spaceId: 'space-1',
  pipelineRunId: 'run-1',
  maxCostMicros: cap,
);

PipelineRun _run({
  int spent = 0,
  PipelineRunStatus status = PipelineRunStatus.running,
}) => PipelineRun(
  id: 'run-1',
  templateId: 'tpl',
  workspaceId: _ws,
  status: status,
  triggerPayload: const {kPipelineRequestedByKey: 'user-1'},
  startedAt: _t0,
  totalCostMicros: spent,
  // The step waits on goal-1.
  state: {goalPursueStateKey('pursue'): 'goal-1'},
);

GoalSettled _settled(AgentGoalStatus status, {String ws = _ws}) => GoalSettled(
  goalId: 'goal-1',
  workspaceId: ws,
  spaceId: 'space-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  status: status,
  hold: null,
  summary: 'shipped',
  requestedByUserId: 'user-1',
  occurredAt: _t0,
);

AgentRunSettled _runSettled({
  String ws = _ws,
  List<String> wakeIds = const ['w-1'],
  RunEndReason end = RunEndReason.completed,
}) => AgentRunSettled(
  agentId: 'agent-1',
  workspaceId: ws,
  spaceId: 'space-1',
  conversationId: 'conv-1',
  runId: 'agent-run-1',
  status: end == RunEndReason.completed ? RunStatus.completed : RunStatus.error,
  endReason: end,
  costMicros: 700,
  limitResetsAt: null,
  wakeIds: wakeIds,
  requestedByUserId: 'user-1',
  wakeReason: WakeReason.goalContinuation,
  occurredAt: _t0,
);

Wake _wake({
  String ws = _ws,
  String? goalId = 'goal-1',
  String? reviewOf,
  int? cap,
}) => Wake(
  id: 'w-1',
  workspaceId: ws,
  spaceId: 'space-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  reason: reviewOf == null
      ? WakeReason.goalContinuation
      : WakeReason.improvementReview,
  payload: 'continue',
  detail: reviewOf == null
      ? WakeDetail(goalId: goalId)
      : WakeDetail(fields: {kImprovementGoalField: reviewOf}),
  runOptions: cap == null ? null : WakeRunOptions(costCapMicros: cap),
  dedupKey: 'k-1',
  notBefore: _t0,
  createdAt: _t0,
);

/// The workspaces' databases, shared by every [_Kit] built on them: a new
/// kit over the same databases is the server after a restart.
class _Store {
  _Store._(this.global, this.dbs);

  static Future<_Store> open() async {
    final global = createTestGlobalDatabase();
    final dbs = createTestWorkspaceDatabases(global: global);
    for (final ws in [_ws, _other]) {
      await seedTestWorkspace(global, dbs, ws);
      // The goal and wake rows reference agents, rooms and conversations
      // this test does not need.
      await dbs.of(ws).customStatement('PRAGMA foreign_keys = OFF');
    }
    return _Store._(global, dbs);
  }

  final GlobalDatabase global;
  final WorkspaceDatabaseManager dbs;
  late final goals = DaoAgentGoalRunRepository(dbs);
  late final wakes = DaoWakeRepository(dbs);

  Future<void> close() async {
    await dbs.closeAll();
    await global.close();
  }
}

class _Kit {
  _Kit(this.store) {
    supervisor = _Supervisor(store.goals);
    pursuits = PipelineGoalPursuits(
      supervisor: () => supervisor,
      goals: store.goals,
      wakes: store.wakes,
      eventBus: bus,
    );
    gate = OrchestrationBudgetGate(
      orchestrations: orchestrations,
      runs: runs,
      messages: messages,
      eventBus: bus,
      engine: () => engine,
      now: () => _t0,
    );
    pursuits.bind(engine: engine, runs: runs, gate: gate);
    bus.on<PipelineRunHeld>().listen(held.add);
    runs.byId['run-1'] = _run();
  }

  final _Store store;
  final bus = DomainEventBus();
  late final _Supervisor supervisor;
  final engine = _Engine();
  final runs = _Runs();
  final orchestrations = _Orchestrations();
  final messages = _Messages();
  final List<PipelineRunHeld> held = [];
  late final PipelineGoalPursuits pursuits;
  late final OrchestrationBudgetGate gate;

  Future<AgentGoalRun> start({String stepId = 'pursue'}) =>
      pursuits.startPursuit(
        workspaceId: _ws,
        spaceId: 'space-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        objective: 'Ship it',
        contract: null,
        costCapMicros: 2000000,
        maxRuns: null,
        deadlineAt: null,
        requestedByUserId: 'user-1',
        pipelineRunId: 'run-1',
        stepId: stepId,
      );

  Future<void> setGoal(AgentGoalRun goal) => store.goals.upsert(goal);
}

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late _Store store;

  setUp(() async => store = await _Store.open());
  tearDown(() async => store.close());

  group('the link is the goal row', () {
    test('the start stores the step with the goal', () async {
      final kit = _Kit(store);
      final goal = await kit.start();
      expect(goal.pipeline, _link);
      expect((await store.goals.getById(_ws, 'goal-1'))!.pipeline, _link);
      expect(
        (await store.goals.listForPipelineRun(_ws, 'run-1')).map((g) => g.id),
        ['goal-1'],
      );
      expect(await store.goals.listForPipelineRun(_other, 'run-1'), isEmpty);
    });

    test('a re-fired step finds its goal by the row, not by memory', () async {
      await _Kit(store).start();
      final restarted = _Kit(store);
      expect(
        await restarted.pursuits.attach(
          workspaceId: _ws,
          goalId: 'goal-1',
          pipelineRunId: 'run-1',
          stepId: 'pursue',
        ),
        isNotNull,
      );
      // Another step, another run or another workspace does not get it.
      for (final (ws, run, step) in [
        (_ws, 'run-1', 'other-step'),
        (_ws, 'run-9', 'pursue'),
        (_other, 'run-1', 'pursue'),
      ]) {
        expect(
          await restarted.pursuits.attach(
            workspaceId: ws,
            goalId: 'goal-1',
            pipelineRunId: run,
            stepId: step,
          ),
          isNull,
        );
      }
    });

    test('a start that already happened adopts only its own goal', () async {
      final kit = _Kit(store);
      await kit.start();
      // The step re-fired after a crash before it recorded the goal's id.
      expect((await _Kit(store).start()).id, 'goal-1');
      // Another step of the same agent is refused.
      await expectLater(
        _Kit(store).start(stepId: 'other-step'),
        throwsA(isA<GoalAlreadyActiveException>()),
      );
    });
  });

  group('after a restart, before anything re-fires', () {
    test("the goal's run is charged and its wake held at the cap", () async {
      await _Kit(store).start();
      await store.wakes.insertIfAbsent(_wake());

      final restarted = _Kit(store);
      restarted.bus.publish(_runSettled());
      await _flush();
      expect(restarted.runs.charged, [('run-1', 700)]);

      restarted.engine.overBudget = true;
      final admission = await restarted.pursuits.admit(_wake(), now: _t0);
      expect(admission, isA<WakeDefer>());
      expect((admission as WakeDefer).reason, kOrchestrationBudgetHoldReason);
      expect(admission.until, _t0.add(kBudgetWakeDeferral));
    });

    test('its settlement settles the step from the row', () async {
      await _Kit(store).start();
      final restarted = _Kit(store);
      await restarted.setGoal(
        _goal(status: AgentGoalStatus.completed, pipeline: _link),
      );
      restarted.bus.publish(_settled(AgentGoalStatus.completed));
      await _flush();
      final settled = restarted.engine.settled.single;
      expect((settled.ws, settled.run, settled.step), (_ws, 'run-1', 'pursue'));
      expect(settled.result.isFailed, isFalse);
      expect(settled.result.mutatedState!['shipped'], {
        'summary': 'shipped',
        'verdict': null,
      });
    });
  });

  group('a goal settles its step', () {
    test('failed, cancelled or out of budget: the step fails', () async {
      for (final status in [
        AgentGoalStatus.failed,
        AgentGoalStatus.cancelled,
        AgentGoalStatus.budgetExhausted,
      ]) {
        final kit = _Kit(store);
        await kit.setGoal(_goal(status: status, pipeline: _link));
        kit.bus.publish(_settled(status));
        await _flush();
        expect(kit.engine.settled.single.result.isFailed, isTrue);
        expect(
          kit.engine.settled.single.result.errorMessage,
          contains(status.wire),
        );
      }
    });

    test('paused for a person: the step keeps waiting', () async {
      final kit = _Kit(store);
      await kit.setGoal(_goal(status: AgentGoalStatus.paused, pipeline: _link));
      kit.bus.publish(_settled(AgentGoalStatus.paused));
      await _flush();
      expect(kit.engine.settled, isEmpty);
    });

    test('a retried step waits on a newer goal: the old one settles '
        'nothing', () async {
      final kit = _Kit(store);
      kit.runs.byId['run-1'] = _run().copyWith(
        state: {goalPursueStateKey('pursue'): 'goal-2'},
      );
      await kit.setGoal(
        _goal(status: AgentGoalStatus.cancelled, pipeline: _link),
      );
      kit.bus.publish(_settled(AgentGoalStatus.cancelled));
      await _flush();
      expect(kit.engine.settled, isEmpty);
    });

    test('a goal that ends before its step records it settles the step '
        'once the id is recorded', () async {
      final kit = _Kit(store);
      kit.runs.byId['run-1'] = _run().copyWith(state: const {});
      await kit.setGoal(
        _goal(status: AgentGoalStatus.cancelled, pipeline: _link),
      );
      kit.bus.publish(_settled(AgentGoalStatus.cancelled));
      await _flush();
      expect(kit.engine.settled, isEmpty, reason: 'not recorded yet');
      kit.runs.byId['run-1'] = _run();
      await Future<void>.delayed(kGoalRecordWaitStep * 3);
      expect(kit.engine.settled.single.result.isFailed, isTrue);
    });

    test('a goal no pipeline started settles nothing', () async {
      final kit = _Kit(store);
      await kit.setGoal(_goal(status: AgentGoalStatus.completed));
      kit.bus.publish(_settled(AgentGoalStatus.completed));
      await _flush();
      expect(kit.engine.settled, isEmpty);
    });

    test('a server stop settles nothing and cancels nothing', () async {
      final kit = _Kit(store);
      await kit.start();
      await store.wakes.insertIfAbsent(_wake());
      kit.bus.publish(_runSettled(end: RunEndReason.serverStopped));
      await _flush();
      expect(kit.engine.settled, isEmpty);
      expect(kit.supervisor.cancelled, isEmpty);
      expect(
        (await store.goals.getById(_ws, 'goal-1'))!.status,
        AgentGoalStatus.active,
      );
      // What the stopped run spent was spent for the pipeline.
      expect(kit.runs.charged, [('run-1', 700)]);
    });
  });

  group('isolation', () {
    test('the same ids in another workspace match nothing', () async {
      final kit = _Kit(store);
      await kit.start();
      // ws-2 has a goal and a wake with the same ids, its goal claiming
      // run-1 (a run of ws-1).
      await kit.setGoal(_goal(workspaceId: _other, pipeline: _link));
      await store.wakes.insertIfAbsent(_wake(ws: _other));
      kit.bus
        ..publish(_runSettled(ws: _other))
        ..publish(
          PipelineRunCancelled(
            workspaceId: _other,
            pipelineRunId: 'run-1',
            templateId: 'tpl',
            occurredAt: _t0,
          ),
        );
      await _flush();
      expect(kit.runs.charged, isEmpty);
      expect(kit.supervisor.cancelled, ['$_other/goal-1']);
      expect(
        (await store.goals.getById(_ws, 'goal-1'))!.status,
        AgentGoalStatus.active,
      );

      await kit.setGoal(
        _goal(
          workspaceId: _other,
          status: AgentGoalStatus.completed,
          pipeline: _link,
        ),
      );
      kit.bus.publish(_settled(AgentGoalStatus.completed, ws: _other));
      await _flush();
      // run-1 is not a run of the goal's workspace: nothing settles.
      expect(kit.engine.settled, isEmpty);
    });

    test("a run's wakes without a goal charge nothing", () async {
      final kit = _Kit(store);
      await kit.start();
      await store.wakes.insertIfAbsent(_wake(goalId: null));
      kit.bus.publish(_runSettled());
      await _flush();
      expect(kit.runs.charged, isEmpty);
    });
  });

  group('the pipeline run ends while its goal runs', () {
    test('cancelled or failed: the goal is cancelled', () async {
      for (final event in [
        PipelineRunCancelled(
          workspaceId: _ws,
          pipelineRunId: 'run-1',
          templateId: 'tpl',
          occurredAt: _t0,
        ),
        PipelineRunFailed(
          workspaceId: _ws,
          pipelineRunId: 'run-1',
          templateId: 'tpl',
          errorMessage: 'a step failed',
          occurredAt: _t0,
        ),
      ]) {
        final kit = _Kit(store);
        await kit.setGoal(_goal(pipeline: _link));
        kit.bus.publish(event);
        await _flush();
        expect(kit.supervisor.cancelled, ['$_ws/goal-1']);
        expect(
          (await store.goals.getById(_ws, 'goal-1'))!.status,
          AgentGoalStatus.cancelled,
        );
      }
    });

    test('a wake of a goal whose run ended is skipped', () async {
      final kit = _Kit(store);
      await kit.start();
      kit.runs.byId['run-1'] = _run(status: PipelineRunStatus.cancelled);
      final admission = await kit.pursuits.admit(_wake(), now: _t0);
      expect(admission, isA<WakeSkip>());
      expect((admission as WakeSkip).kind, kPipelineRunEndedSkip);
      expect(kit.supervisor.cancelled, ['$_ws/goal-1']);
    });

    test('a wake of a goal whose run is gone is skipped', () async {
      final kit = _Kit(store);
      await kit.start();
      kit.runs.byId.clear();
      expect(await kit.pursuits.admit(_wake(), now: _t0), isA<WakeSkip>());
    });

    test('at boot, a goal whose run ended while down is cancelled', () async {
      await _Kit(store).start();
      final restarted = _Kit(store);
      restarted.runs.byId['run-1'] = _run(status: PipelineRunStatus.failed);
      await restarted.pursuits.recover();
      expect(restarted.supervisor.cancelled, ['$_ws/goal-1']);
    });

    test('at boot, a goal whose run goes on is left alone', () async {
      await _Kit(store).start();
      final restarted = _Kit(store);
      await restarted.pursuits.recover();
      expect(restarted.supervisor.cancelled, isEmpty);
    });
  });

  group('the orchestration cap', () {
    test('holds at the cap, tells once, resumes when raised', () async {
      final kit = _Kit(store);
      expect(await kit.gate.check(kit.runs.byId['run-1']!), isNull);
      kit.orchestrations.current = _orchestration(cap: 1000);
      expect(await kit.gate.check(_run()), isNull, reason: 'under the cap');
      kit.runs.byId['run-1'] = _run(spent: 1200);
      final hold = await kit.gate.check(kit.runs.byId['run-1']!);
      expect(hold!.reason, kOrchestrationBudgetHoldReason);
      expect(hold.toJson(), {
        'reason': 'orchestration_budget',
        'orchestration_id': 'orch-1',
        'cap_micros': 1000,
        'spent_micros': 1200,
        'held_at': _t0.toIso8601String(),
      });

      await kit.gate.onHeld(kit.runs.byId['run-1']!, hold);
      await _flush();
      final event = kit.held.single;
      expect(event.pipelineRunId, 'run-1');
      expect(event.orchestrationId, 'orch-1');
      expect(event.spaceId, 'space-1');
      expect(event.requestedByUserId, 'user-1');
      final row = kit.messages.sent.single;
      expect(row.type, 'system');
      expect(row.content, OrchestrationBudgetGate.budgetHoldNotice(hold));

      kit.orchestrations.controller.add(_orchestration(cap: 5000));
      await _flush();
      expect(kit.engine.resumed, ['$_ws/run-1']);
    });

    test('an orchestration created without a cap (null or zero) never '
        'holds; a cap once set is never cleared (raiseCap refuses it and '
        'a whole-row update does not write it)', () async {
      final kit = _Kit(store);
      kit.runs.byId['run-1'] = _run(spent: 1 << 40);
      kit.orchestrations.current = _orchestration(cap: null);
      expect(await kit.gate.check(kit.runs.byId['run-1']!), isNull);
      kit.orchestrations.current = _orchestration(cap: 0);
      expect(await kit.gate.check(kit.runs.byId['run-1']!), isNull);
    });

    test('after a restart a held run whose cap was raised resumes', () async {
      final kit = _Kit(store);
      kit.orchestrations.current = _orchestration(cap: 1000);
      kit.runs.byId['run-1'] = _run(
        spent: 500,
        status: PipelineRunStatus.suspended,
      ).copyWith(state: {kBudgetHoldStateKey: <String, Object?>{}});
      await kit.pursuits.recover();
      expect(kit.engine.resumed, ['$_ws/run-1']);
    });
  });

  group('a pursued goal spends within its orchestration', () {
    test(
      'the improvement review of its completion is charged to the run',
      () async {
        final kit = _Kit(store);
        await kit.start();
        await store.wakes.insertIfAbsent(
          _wake(goalId: null, reviewOf: 'goal-1'),
        );
        kit.bus.publish(_runSettled());
        await _flush();
        expect(kit.runs.charged, [('run-1', 700)]);
      },
    );

    test('the review waits while the run is held at the cap', () async {
      final kit = _Kit(store);
      await kit.start();
      kit.engine.overBudget = true;
      final admission = await kit.pursuits.admit(
        _wake(goalId: null, reviewOf: 'goal-1'),
        now: _t0,
      );
      expect((admission as WakeDefer).reason, kOrchestrationBudgetHoldReason);
    });

    test('the review of a goal whose run finished runs within what is '
        'left, and not past the cap', () async {
      final kit = _Kit(store);
      await kit.start();
      kit.orchestrations.current = _orchestration(cap: 1000);
      kit.runs.byId['run-1'] = _run(
        spent: 400,
        status: PipelineRunStatus.completed,
      );
      final review = _wake(goalId: null, reviewOf: 'goal-1');
      final within = await kit.pursuits.admit(review, now: _t0);
      expect((within as WakeAdmit).capMicros, 600);
      expect(kit.supervisor.cancelled, isEmpty, reason: 'the goal finished');

      kit.runs.byId['run-1'] = _run(
        spent: 1000,
        status: PipelineRunStatus.completed,
      );
      final spent = await kit.pursuits.admit(review, now: _t0);
      expect((spent as WakeSkip).kind, kOrchestrationBudgetHoldReason);
    });

    test(
      'the review of a goal that spent its whole budget runs within the '
      "orchestration's remainder, and is skipped when that is spent",
      () async {
        final kit = _Kit(store);
        await kit.start();
        await kit.setGoal(
          _goal(
            status: AgentGoalStatus.completed,
            pipeline: _link,
          ).copyWith(costMicros: 2100000),
        );
        kit.orchestrations.current = _orchestration(cap: 1000);
        kit.runs.byId['run-1'] = _run(
          spent: 900,
          status: PipelineRunStatus.completed,
        );
        final review = _wake(goalId: null, reviewOf: 'goal-1');
        final within = await kit.pursuits.admit(review, now: _t0);
        expect((within as WakeAdmit).capMicros, 100);

        kit.runs.byId['run-1'] = _run(spent: 900);
        final running = await kit.pursuits.admit(review, now: _t0);
        expect((running as WakeAdmit).capMicros, 100);

        kit.orchestrations.current = _orchestration(cap: null);
        final uncapped = await kit.pursuits.admit(review, now: _t0);
        expect((uncapped as WakeAdmit).capMicros, isNull);
      },
    );

    test("a segment's cap is the lower of the goal's and the "
        "orchestration's remainder", () async {
      final kit = _Kit(store);
      await kit.start();
      // The goal has 2,000,000 left.
      kit.orchestrations.current = _orchestration(cap: 1500000);
      kit.runs.byId['run-1'] = _run(spent: 1000000);
      final orchestrationLower = await kit.pursuits.admit(_wake(), now: _t0);
      expect((orchestrationLower as WakeAdmit).capMicros, 500000);

      kit.orchestrations.current = _orchestration(cap: 50000000);
      final goalLower = await kit.pursuits.admit(_wake(), now: _t0);
      expect((goalLower as WakeAdmit).capMicros, 2000000);

      kit.orchestrations.current = _orchestration(cap: null);
      final uncapped = await kit.pursuits.admit(_wake(), now: _t0);
      expect((uncapped as WakeAdmit).capMicros, 2000000);
    });

    test('the queue runs the wake at the lower cap', () {
      final narrowed = WakeQueueService.narrowed(_wake(cap: 900000), 500000);
      expect(narrowed.runOptions!.costCapMicros, 500000);
      final kept = WakeQueueService.narrowed(_wake(cap: 300000), 500000);
      expect(kept.runOptions!.costCapMicros, 300000);
      final uncapped = WakeQueueService.narrowed(_wake(), 500000);
      expect(uncapped.runOptions!.costCapMicros, 500000);
      expect(WakeQueueService.narrowed(_wake(), null).runOptions, isNull);
    });
  });
}
