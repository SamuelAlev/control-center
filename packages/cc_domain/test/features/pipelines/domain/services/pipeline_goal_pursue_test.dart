import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/ports/goal_pursuit_port.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_budget_gate.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_validator.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/goal_pursue_config.dart';
import 'package:cc_domain/features/pipelines/domain/templates/goal_pursue_step.dart';
import 'package:test/test.dart';

class _Runs implements PipelineRunRepository {
  final Map<String, PipelineRun> runs = {};
  final Map<String, PipelineStepRun> steps = {};

  @override
  Future<PipelineRun?> getRun(String id) async => runs[id];

  @override
  Future<void> insertRun(PipelineRun run) async => runs[run.id] = run;

  @override
  Future<void> updateRun(PipelineRun run) async => runs[run.id] = run;

  @override
  Future<void> updateRunState(String runId, Map<String, dynamic> state) async {
    final run = runs[runId];
    if (run != null) {
      runs[runId] = run.copyWith(state: state);
    }
  }

  @override
  Future<void> incrementCost(String runId, int micros, int tokens) async {
    final run = runs[runId];
    if (run != null) {
      runs[runId] = run.copyWith(totalCostMicros: run.totalCostMicros + micros);
    }
  }

  @override
  Future<List<PipelineStepRun>> stepRunsForPipeline(String id) async =>
      steps.values.where((s) => s.pipelineRunId == id).toList();

  @override
  Future<void> insertStepRun(PipelineStepRun stepRun) async =>
      steps[stepRun.id] = stepRun;

  @override
  Future<PipelineStepRun?> getStepRunById(String ws, String id) async =>
      steps[id];

  @override
  Future<void> updateStepRun(
    String workspaceId,
    String stepRunId, {
    PipelineStepStatus? status,
    String? inputJson,
    String? outputJson,
    String? spaceId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {
    final c = steps[stepRunId];
    if (c == null) {
      return;
    }
    steps[stepRunId] = PipelineStepRun(
      id: c.id,
      pipelineRunId: c.pipelineRunId,
      stepId: c.stepId,
      status: status ?? c.status,
      inputJson: inputJson ?? c.inputJson,
      outputJson: outputJson ?? c.outputJson,
      spaceId: spaceId ?? c.spaceId,
      errorMessage: errorMessage ?? c.errorMessage,
      attemptCount: c.attemptCount,
      startedAt: c.startedAt,
      finishedAt: finishedAt ?? c.finishedAt,
    );
  }

  @override
  Future<void> restartStepRun(
    String workspaceId,
    String stepRunId, {
    required DateTime startedAt,
  }) async {
    final c = steps[stepRunId]!;
    steps[stepRunId] = PipelineStepRun(
      id: c.id,
      pipelineRunId: c.pipelineRunId,
      stepId: c.stepId,
      status: PipelineStepStatus.running,
      inputJson: c.inputJson,
      spaceId: c.spaceId,
      attemptCount: c.attemptCount,
      startedAt: startedAt,
    );
  }

  @override
  Future<List<PipelineRun>> nonTerminalRuns() async =>
      runs.values.where((r) => !r.isTerminal).toList();

  @override
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  }) async => null;

  @override
  Future<int> activeRunCountForTemplate({
    required String workspaceId,
    required String templateId,
  }) async => 0;

  @override
  Future<PipelineRun?> nextQueuedRunForTemplate({
    required String workspaceId,
    required String templateId,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _Templates implements PipelineTemplateRepository {
  final Map<String, PipelineDefinition> byId = {};

  @override
  Future<PipelineDefinition?> getById(String ws, String id) async =>
      byId['$ws/$id'];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _RunLogs implements AgentRunLogRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _Agents implements AgentRepository {
  @override
  Future<Agent?> getById(String workspaceId, String id) async =>
      workspaceId == 'ws' && id == 'agent-1'
      ? Agent(
          id: 'agent-1',
          name: 'builder',
          title: 'Builder',
          agentMdPath: 'agents/builder.md',
          workspaceId: 'ws',
          skills: AgentSkills(const []),
          createdAt: DateTime.utc(2026),
        )
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _Messaging implements MessagingPort {
  final List<String> conversations = [];

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async =>
      spaceId == 'space-1';

  @override
  Future<void> addAgentToSpace(
    String workspaceId,
    String spaceId,
    String agentId, {
    bool renameForGroup = true,
  }) async {}

  @override
  Future<String?> createConversation({
    required String workspaceId,
    required String spaceId,
    required String title,
    String? createdByPrincipalId,
    bool reuseExisting = false,
  }) async {
    conversations.add(title);
    return 'conv-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

AgentGoalRun _goal(
  AgentGoalStatus status, {
  String? summary,
  String id = 'goal-1',
}) => AgentGoalRun(
  id: id,
  workspaceId: 'ws',
  spaceId: 'space-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  userText: 'Ship it',
  costCapMicros: 2000000,
  createdAt: DateTime.utc(2026, 11, 19),
  updatedAt: DateTime.utc(2026, 11, 19),
).copyWith(status: status, summary: summary);

class _Pursuits implements GoalPursuitPort {
  final List<Map<String, Object?>> started = [];
  final List<String> attached = [];
  AgentGoalRun? onAttach;

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
    started.add({
      'workspaceId': workspaceId,
      'spaceId': spaceId,
      'conversationId': conversationId,
      'objective': objective,
      'costCapMicros': costCapMicros,
      'maxRuns': maxRuns,
      'requestedByUserId': requestedByUserId,
      'stepId': stepId,
      'pipelineRunId': pipelineRunId,
    });
    return _goal(AgentGoalStatus.active, id: 'goal-${started.length}');
  }

  @override
  Future<AgentGoalRun?> attach({
    required String workspaceId,
    required String goalId,
    required String pipelineRunId,
    required String stepId,
  }) async {
    attached.add(goalId);
    return onAttach;
  }
}

class _Gate implements PipelineBudgetGate {
  bool atCap = false;
  final List<PipelineBudgetHold> told = [];

  @override
  Future<PipelineBudgetHold?> check(PipelineRun run) async => atCap
      ? PipelineBudgetHold(
          reason: kOrchestrationBudgetHoldReason,
          orchestrationId: 'orch-1',
          capMicros: 100,
          spentMicros: 120,
          heldAt: DateTime.utc(2026, 11, 19),
        )
      : null;

  @override
  Future<void> onHeld(PipelineRun run, PipelineBudgetHold hold) async =>
      told.add(hold);
}

PipelineNodeConfig _pursueConfig({Map<String, Object?>? extras}) =>
    PipelineNodeConfig(
      agentId: 'agent-1',
      prompt: 'Ship {{feature}}',
      outputKey: 'shipped',
      label: 'Ship',
      extras: extras ?? const {'spaceId': 'space-1', 'budgetMicros': 2000000},
    );

/// trigger → first → after → end, `first` being a `goal.pursue` step
/// unless [firstBody] names another body.
PipelineDefinition _definition({String firstBody = kGoalPursueBodyKey}) =>
    PipelineDefinition(
      templateId: 'tpl',
      workspaceId: 'ws',
      name: 'Pursue',
      steps: [
        PipelineStepDefinition(
          id: 'trigger',
          kind: StepKind.trigger,
          bodyKey: 'pipeline.trigger',
        ),
        PipelineStepDefinition(
          id: 'pursue',
          kind: StepKind.listen,
          bodyKey: firstBody,
          triggers: [
            const StepTrigger(sourceStepIds: ['trigger']),
          ],
          config: _pursueConfig(),
        ),
        PipelineStepDefinition(
          id: 'after',
          kind: StepKind.listen,
          bodyKey: 'after',
          triggers: [
            const StepTrigger(sourceStepIds: ['pursue']),
          ],
        ),
        PipelineStepDefinition(
          id: 'end',
          kind: StepKind.terminal,
          bodyKey: '_terminal',
          triggers: [
            const StepTrigger(sourceStepIds: ['after']),
          ],
        ),
      ],
    );

Future<void> _until(bool Function() condition, {String? reason}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(reason ?? 'condition not met');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late _Runs runs;
  late _Templates templates;
  late PipelineBodyRegistry bodies;
  late PipelineEngine engine;
  late _Pursuits pursuits;
  late _Gate gate;
  late int afterRuns;

  setUp(() {
    runs = _Runs();
    templates = _Templates();
    bodies = PipelineBodyRegistry();
    pursuits = _Pursuits();
    gate = _Gate();
    afterRuns = 0;
    bodies
      ..registerBody('pipeline.trigger', (_) async => StepResult.ok())
      ..registerBody('after', (_) async {
        afterRuns++;
        return StepResult.ok();
      })
      ..registerBody(
        'spend',
        (_) async => StepResult.ok(mutatedState: {'spent': true}),
      );
    registerGoalPursueBody(
      bodies,
      templateRepository: templates,
      agentRepository: _Agents(),
      messagingPort: _Messaging(),
      runRepository: runs,
      goals: pursuits,
    );
    engine = PipelineEngine(
      bodies: bodies,
      templates: templates,
      repository: runs,
      eventBus: DomainEventBus(),
      stepProcessRegistry: StepProcessRegistry(),
      agentRunLogRepository: _RunLogs(),
    )..registerBudgetGate(gate);
  });

  PipelineStepRun? row(String runId, String stepId) => runs.steps.values
      .where((s) => s.pipelineRunId == runId && s.stepId == stepId)
      .firstOrNull;

  Future<PipelineRun> startSuspended() async {
    templates.byId['ws/tpl'] = _definition();
    final run = (await engine.start(
      'tpl',
      workspaceId: 'ws',
      triggerPayload: const {'feature': 'search'},
      requestedByUserId: 'user-1',
    ))!;
    await _until(
      () => runs.runs[run.id]!.state.containsKey(goalPursueStateKey('pursue')),
      reason: 'the step records its goal',
    );
    return run;
  }

  group('goal.pursue', () {
    test('starts a goal with the step config and suspends', () async {
      final run = await startSuspended();
      final start = pursuits.started.single;
      expect(start['objective'], 'Ship search');
      expect(start['costCapMicros'], 2000000);
      expect(start['spaceId'], 'space-1');
      expect(start['conversationId'], 'conv-1');
      expect(start['requestedByUserId'], 'user-1');
      expect(runs.runs[run.id]!.state[goalPursueStateKey('pursue')], 'goal-1');
      expect(row(run.id, 'pursue')!.status, PipelineStepStatus.running);
      expect(row(run.id, 'after'), isNull);
    });

    test(
      'a completed goal completes the step with summary and verdict',
      () async {
        final run = await startSuspended();
        final settled = await engine.settleSuspendedStep(
          workspaceId: 'ws',
          pipelineRunId: run.id,
          stepId: 'pursue',
          result: (step) => goalPursueSettlement(
            _goal(AgentGoalStatus.completed, summary: 'shipped'),
            step,
          ),
        );
        expect(settled, isTrue);
        await _until(() => runs.runs[run.id]!.isTerminal);
        expect(runs.runs[run.id]!.status, PipelineRunStatus.completed);
        expect(runs.runs[run.id]!.state['shipped'], {
          'summary': 'shipped',
          'verdict': null,
        });
        expect(afterRuns, 1);
      },
    );

    for (final status in [
      AgentGoalStatus.failed,
      AgentGoalStatus.cancelled,
      AgentGoalStatus.budgetExhausted,
    ]) {
      test('a ${status.wire} goal fails the step', () async {
        final run = await startSuspended();
        await engine.settleSuspendedStep(
          workspaceId: 'ws',
          pipelineRunId: run.id,
          stepId: 'pursue',
          result: (_) => goalPursueOutcome(
            _goal(status, summary: 'gave up'),
            stepId: 'pursue',
            outputKey: 'shipped',
          ),
        );
        await _until(() => runs.runs[run.id]!.isTerminal);
        expect(runs.runs[run.id]!.status, PipelineRunStatus.failed);
        expect(row(run.id, 'pursue')!.status, PipelineStepStatus.failed);
        expect(
          row(run.id, 'pursue')!.errorMessage,
          contains('the goal ended ${status.wire}: gave up'),
        );
        expect(afterRuns, 0);
      });
    }

    test('a goal waiting on a person (needsReview) keeps it suspended', () {
      final outcome = goalPursueOutcome(
        _goal(AgentGoalStatus.paused),
        stepId: 'pursue',
        outputKey: 'shipped',
      );
      expect(outcome.isSuspended, isTrue);
      expect(outcome.mutatedState, {goalPursueStateKey('pursue'): 'goal-1'});
    });

    test('settling in another workspace changes nothing', () async {
      final run = await startSuspended();
      final settled = await engine.settleSuspendedStep(
        workspaceId: 'ws-other',
        pipelineRunId: run.id,
        stepId: 'pursue',
        result: (_) => StepResult.ok(),
      );
      expect(settled, isFalse);
      expect(row(run.id, 'pursue')!.status, PipelineStepStatus.running);
    });

    test(
      'after a restart, a goal that finished meanwhile completes the step',
      () async {
        final run = await startSuspended();
        pursuits.onAttach = _goal(AgentGoalStatus.completed, summary: 'done');
        await engine.resumeAll();
        await _until(() => runs.runs[run.id]!.isTerminal);
        expect(pursuits.attached, ['goal-1']);
        expect(pursuits.started, hasLength(1), reason: 'no second goal');
        expect(runs.runs[run.id]!.status, PipelineRunStatus.completed);
      },
    );

    test('after a restart, a goal still running keeps the step waiting, '
        'and its settlement completes it', () async {
      final run = await startSuspended();
      pursuits.onAttach = _goal(AgentGoalStatus.active);
      await engine.resumeAll();
      await _until(() => pursuits.attached.isNotEmpty);
      expect(pursuits.started, hasLength(1));
      expect(runs.runs[run.id]!.isTerminal, isFalse);
      await engine.settleSuspendedStep(
        workspaceId: 'ws',
        pipelineRunId: run.id,
        stepId: 'pursue',
        result: (_) => goalPursueOutcome(
          _goal(AgentGoalStatus.completed, summary: 'ok'),
          stepId: 'pursue',
          outputKey: 'shipped',
        ),
      );
      await _until(() => runs.runs[run.id]!.isTerminal);
      expect(runs.runs[run.id]!.status, PipelineRunStatus.completed);
    });

    for (final status in [
      AgentGoalStatus.failed,
      AgentGoalStatus.cancelled,
      AgentGoalStatus.budgetExhausted,
    ]) {
      test('a retry after the goal ended ${status.wire} starts a second goal '
          'on the same run and step', () async {
        final run = await startSuspended();
        // The run failed around its goal (a sibling failed, the run was
        // cancelled): the server cancelled the goal, and the step failed.
        await engine.settleSuspendedStep(
          workspaceId: 'ws',
          pipelineRunId: run.id,
          stepId: 'pursue',
          result: (_) => goalPursueOutcome(
            _goal(status),
            stepId: 'pursue',
            outputKey: 'shipped',
          ),
        );
        await _until(() => runs.runs[run.id]!.isTerminal);
        pursuits.onAttach = _goal(status);

        await engine.retry('ws', run.id);
        await _until(
          () => pursuits.started.length == 2,
          reason: 'the retry starts a new goal',
        );
        await _until(
          () =>
              runs.runs[run.id]!.state[goalPursueStateKey('pursue')] ==
              'goal-2',
          reason: "the new goal's id replaces the old one",
        );
        expect(pursuits.attached, ['goal-1']);
        final second = pursuits.started.last;
        expect(second['pipelineRunId'], run.id);
        expect(second['stepId'], 'pursue');
        expect(row(run.id, 'pursue')!.status, PipelineStepStatus.running);
        expect(runs.runs[run.id]!.isTerminal, isFalse);
      });
    }

    test('a goal that is gone on re-attach fails the step', () async {
      final run = await startSuspended();
      pursuits.onAttach = null;
      await engine.resumeAll();
      await _until(() => runs.runs[run.id]!.isTerminal);
      expect(
        row(run.id, 'pursue')!.errorMessage,
        contains('the goal this step started is gone'),
      );
    });
  });

  group('configuration', () {
    test('a valid config has no errors and parses', () {
      final config = _pursueConfig(
        extras: const {
          'budgetMicros': 5000000,
          'maxRuns': 10,
          'deadlineHours': 48,
          'contract': {
            'criteria': ['the tests pass'],
          },
        },
      );
      expect(GoalPursueConfig.errorsOf(config), isEmpty);
      final parsed = GoalPursueConfig.parse(config);
      expect(parsed.budgetMicros, 5000000);
      expect(parsed.maxRuns, 10);
      expect(parsed.deadlineHours, 48);
      expect(parsed.contract!.criteria, ['the tests pass']);
    });

    test('names every problem', () {
      final errors = GoalPursueConfig.errorsOf(
        const PipelineNodeConfig(
          extras: {'maxRuns': 0, 'deadlineHours': 'soon', 'contract': 7},
        ),
      );
      expect(errors, hasLength(7));
      expect(errors.join('\n'), contains('agentId'));
      expect(errors.join('\n'), contains('prompt'));
      expect(errors.join('\n'), contains('outputKey'));
      expect(errors.join('\n'), contains('extras.budgetMicros'));
      expect(errors.join('\n'), contains('extras.maxRuns'));
      expect(errors.join('\n'), contains('extras.deadlineHours'));
      expect(errors.join('\n'), contains('contract'));
      expect(
        () => GoalPursueConfig.parse(PipelineNodeConfig.empty),
        throwsFormatException,
      );
    });

    test('the validator refuses a bad goal.pursue step at save time', () {
      final def = _definition();
      final broken = PipelineDefinition(
        templateId: def.templateId,
        workspaceId: def.workspaceId,
        name: def.name,
        steps: [
          for (final s in def.steps)
            s.id == 'pursue'
                ? PipelineStepDefinition(
                    id: s.id,
                    kind: s.kind,
                    bodyKey: s.bodyKey,
                    triggers: s.triggers,
                    config: const PipelineNodeConfig(
                      agentId: 'agent-1',
                      prompt: 'Ship',
                      outputKey: 'shipped',
                      extras: {'spaceId': 'space-1'},
                    ),
                  )
                : s,
        ],
      );
      const validator = PipelineValidator();
      expect(
        validator
            .validate(def)
            .where(
              (i) =>
                  i.stepId == 'pursue' &&
                  i.severity == PipelineIssueSeverity.error,
            )
            .map((i) => i.message),
        isEmpty,
      );
      expect(
        validator
            .validate(broken)
            .map((i) => i.message)
            .where((m) => m.contains('budgetMicros')),
        isNotEmpty,
      );
    });
  });

  group('the orchestration cap', () {
    test(
      'holds the remaining steps, tells once, and resumes when raised',
      () async {
        templates.byId['ws/tpl'] = _definition(firstBody: 'spend');
        // A fresh run held from its first dispatch.
        gate.atCap = true;
        final held = (await engine.start('tpl', workspaceId: 'ws'))!;
        await _until(
          () => runs.runs[held.id]!.status == PipelineRunStatus.suspended,
          reason: 'the run is held',
        );
        expect(
          runs.runs[held.id]!.state[kBudgetHoldStateKey],
          containsPair('reason', kOrchestrationBudgetHoldReason),
        );
        expect(row(held.id, 'pursue'), isNull, reason: 'nothing dispatched');
        // Asked again (a pursued goal's next segment): still held, told once.
        expect(await engine.holdIfOverBudget('ws', held.id), isTrue);
        expect(gate.told, hasLength(1));
        // Still at the cap: no resume.
        expect(await engine.resumeHeld('ws', held.id), isFalse);
        // Another workspace cannot resume it.
        gate.atCap = false;
        expect(await engine.resumeHeld('ws-other', held.id), isFalse);

        expect(await engine.resumeHeld('ws', held.id), isTrue);
        await _until(() => runs.runs[held.id]!.isTerminal);
        expect(runs.runs[held.id]!.status, PipelineRunStatus.completed);
        expect(
          runs.runs[held.id]!.state.containsKey(kBudgetHoldStateKey),
          isFalse,
        );
        expect(gate.told, hasLength(1));
      },
    );

    test('a hold between steps stops the next one', () async {
      bodies.registerBody('spend-then-cap', (_) async {
        gate.atCap = true;
        return StepResult.ok();
      });
      templates.byId['ws/tpl'] = _definition(firstBody: 'spend-then-cap');
      final run = (await engine.start('tpl', workspaceId: 'ws'))!;
      await _until(
        () => runs.runs[run.id]!.status == PipelineRunStatus.suspended,
      );
      expect(row(run.id, 'pursue')!.status, PipelineStepStatus.completed);
      expect(row(run.id, 'after'), isNull);
      expect(afterRuns, 0);
      expect(gate.told, hasLength(1));
      gate.atCap = false;
      expect(await engine.resumeHeld('ws', run.id), isTrue);
      await _until(() => runs.runs[run.id]!.isTerminal);
      expect(afterRuns, 1);
    });
  });
}
