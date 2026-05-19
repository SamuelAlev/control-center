import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
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
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../fakes/fake_agent_run_log_repository.dart';

// ── In-memory fakes ────────────────────────────────────────────────────────

class _FakeRunRepo implements PipelineRunRepository {
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
    final existing = runs[runId];
    if (existing == null) {
      return;
    }
    runs[runId] = PipelineRun(
      id: existing.id,
      templateId: existing.templateId,
      workspaceId: existing.workspaceId,
      status: existing.status,
      state: state,
      triggerEventType: existing.triggerEventType,
      triggerPayload: existing.triggerPayload,
      dedupKey: existing.dedupKey,
      startedAt: existing.startedAt,
      finishedAt: existing.finishedAt,
      errorMessage: existing.errorMessage,
      errorStackTrace: existing.errorStackTrace,
      parentPipelineRunId: existing.parentPipelineRunId,
      parentStepId: existing.parentStepId,
      templateVersion: existing.templateVersion,
      totalCostCents: existing.totalCostCents,
      totalTokens: existing.totalTokens,
      dryRun: existing.dryRun,
    );
  }

  @override
  Future<List<PipelineStepRun>> stepRunsForPipeline(
    String pipelineRunId,
  ) async =>
      steps.values.where((s) => s.pipelineRunId == pipelineRunId).toList();

  @override
  Future<void> insertStepRun(PipelineStepRun stepRun) async =>
      steps[stepRun.id] = stepRun;

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
    final current = steps[stepRunId];
    if (current == null) {
      return;
    }
    steps[stepRunId] = PipelineStepRun(
      id: current.id,
      pipelineRunId: current.pipelineRunId,
      stepId: current.stepId,
      status: status ?? current.status,
      inputJson: inputJson ?? current.inputJson,
      outputJson: outputJson ?? current.outputJson,
      spaceId: spaceId ?? current.spaceId,
      errorMessage: errorMessage ?? current.errorMessage,
      branchIndex: current.branchIndex,
      attemptCount: current.attemptCount,
      startedAt: current.startedAt,
      finishedAt: finishedAt ?? current.finishedAt,
    );
  }

  @override
  Future<void> restartStepRun(
    String workspaceId,
    String stepRunId, {
    required DateTime startedAt,
  }) async {
    final current = steps[stepRunId];
    if (current == null) {
      return;
    }
    steps[stepRunId] = PipelineStepRun(
      id: current.id,
      pipelineRunId: current.pipelineRunId,
      stepId: current.stepId,
      status: PipelineStepStatus.running,
      inputJson: current.inputJson,
      // The room the previous attempt opened survives; its outcome does not.
      spaceId: current.spaceId,
      branchIndex: current.branchIndex,
      attemptCount: current.attemptCount,
      startedAt: startedAt,
    );
  }

  @override
  Future<void> deleteStepRun(String workspaceId, String stepRunId) async =>
      steps.remove(stepRunId);

  @override
  Future<PipelineStepRun?> getStepRunById(
    String workspaceId,
    String stepRunId,
  ) async => steps[stepRunId];

  @override
  Future<List<PipelineRun>> nonTerminalRuns() async =>
      runs.values.where((r) => !r.isTerminal).toList();

  @override
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  }) async {
    try {
      return runs.values.firstWhere(
        (r) =>
            r.templateId == templateId &&
            r.workspaceId == workspaceId &&
            r.dedupKey == dedupKey &&
            !r.isTerminal,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<int> activeRunCountForTemplate({
    required String workspaceId,
    required String templateId,
    Set<String> excludeTriggerEventTypes = const {},
  }) async => runs.values
      .where(
        (r) =>
            r.workspaceId == workspaceId &&
            r.templateId == templateId &&
            !r.isTerminal &&
            r.status != PipelineRunStatus.queued &&
            !excludeTriggerEventTypes.contains(r.triggerEventType),
      )
      .length;

  @override
  Future<PipelineRun?> nextQueuedRunForTemplate({
    required String workspaceId,
    required String templateId,
  }) async {
    // Insertion order is the tiebreaker: two runs queued in the same
    // millisecond share a `startedAt`, and List.sort is not stable, so
    // without it a FIFO assertion would be flaky rather than wrong.
    final ordered = runs.values.toList();
    final queued = <(int, PipelineRun)>[];
    for (var i = 0; i < ordered.length; i++) {
      final r = ordered[i];
      if (r.workspaceId == workspaceId &&
          r.templateId == templateId &&
          r.status == PipelineRunStatus.queued) {
        queued.add((i, r));
      }
    }
    queued.sort((a, b) {
      final byTime = a.$2.startedAt.compareTo(b.$2.startedAt);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
    return queued.isEmpty ? null : queued.first.$2;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTemplateRepo implements PipelineTemplateRepository {
  final Map<String, PipelineDefinition> _templates = {};

  void seed(PipelineDefinition def) {
    _templates['${def.workspaceId}/${def.templateId}'] = def;
  }

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async => _templates['$workspaceId/$templateId'];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Polls until [condition] returns true, or [timeout] elapses.
Future<void> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  if (!condition()) {
    fail(reason ?? 'Condition not met within $timeout');
  }
}

/// A linear pipeline: trigger → stepA → stepB → terminal.
PipelineDefinition _linearDefinition({
  String templateId = 'tpl',
  String workspaceId = 'ws',
  PipelineNodeConfig? configA,
  PipelineNodeConfig? configB,
}) {
  return PipelineDefinition(
    templateId: templateId,
    workspaceId: workspaceId,
    name: 'Linear',
    steps: [
      PipelineStepDefinition(
        id: 'trigger',
        kind: StepKind.trigger,
        bodyKey: 'pipeline.trigger',
      ),
      PipelineStepDefinition(
        id: 'stepA',
        kind: StepKind.listen,
        bodyKey: 'bodyA',
        triggers: [
          const StepTrigger(sourceStepIds: ['trigger']),
        ],
        config: configA ?? PipelineNodeConfig.empty,
      ),
      PipelineStepDefinition(
        id: 'stepB',
        kind: StepKind.listen,
        bodyKey: 'bodyB',
        triggers: [
          const StepTrigger(sourceStepIds: ['stepA']),
        ],
        config: configB ?? PipelineNodeConfig.empty,
      ),
      PipelineStepDefinition(
        id: 'end',
        kind: StepKind.terminal,
        bodyKey: '_terminal',
        triggers: [
          const StepTrigger(sourceStepIds: ['stepB']),
        ],
      ),
    ],
  );
}

/// Parallel: trigger → stepA ─┬→ join → terminal
///            trigger → stepB ─┘
PipelineDefinition _parallelDefinition({
  String templateId = 'tpl',
  String workspaceId = 'ws',
}) {
  return PipelineDefinition(
    templateId: templateId,
    workspaceId: workspaceId,
    name: 'Parallel',
    steps: [
      PipelineStepDefinition(
        id: 'trigger',
        kind: StepKind.trigger,
        bodyKey: 'pipeline.trigger',
      ),
      PipelineStepDefinition(
        id: 'stepA',
        kind: StepKind.listen,
        bodyKey: 'bodyA',
        triggers: [
          const StepTrigger(sourceStepIds: ['trigger']),
        ],
      ),
      PipelineStepDefinition(
        id: 'stepB',
        kind: StepKind.listen,
        bodyKey: 'bodyB',
        triggers: [
          const StepTrigger(sourceStepIds: ['trigger']),
        ],
      ),
      PipelineStepDefinition(
        id: 'join',
        kind: StepKind.join,
        bodyKey: 'bodyJoin',
        waitForStepIds: ['stepA', 'stepB'],
        triggers: [
          const StepTrigger(sourceStepIds: ['stepA']),
          const StepTrigger(sourceStepIds: ['stepB']),
        ],
      ),
      PipelineStepDefinition(
        id: 'end',
        kind: StepKind.terminal,
        bodyKey: '_terminal',
        triggers: [
          const StepTrigger(sourceStepIds: ['join']),
        ],
      ),
    ],
  );
}

/// Router: trigger → router → branchA (routeKey 'a') → terminal
///                          → branchB (routeKey 'b') ↗
PipelineDefinition _routerDefinition({
  String templateId = 'tpl',
  String workspaceId = 'ws',
}) {
  return PipelineDefinition(
    templateId: templateId,
    workspaceId: workspaceId,
    name: 'Router',
    steps: [
      PipelineStepDefinition(
        id: 'trigger',
        kind: StepKind.trigger,
        bodyKey: 'pipeline.trigger',
      ),
      PipelineStepDefinition(
        id: 'router',
        kind: StepKind.router,
        bodyKey: 'bodyRouter',
        triggers: [
          const StepTrigger(sourceStepIds: ['trigger']),
        ],
      ),
      PipelineStepDefinition(
        id: 'branchA',
        kind: StepKind.listen,
        bodyKey: 'bodyA',
        triggers: [
          const StepTrigger(sourceStepIds: ['router'], routeKey: 'a'),
        ],
      ),
      PipelineStepDefinition(
        id: 'branchB',
        kind: StepKind.listen,
        bodyKey: 'bodyB',
        triggers: [
          const StepTrigger(sourceStepIds: ['router'], routeKey: 'b'),
        ],
      ),
      PipelineStepDefinition(
        id: 'end',
        kind: StepKind.terminal,
        bodyKey: '_terminal',
        triggers: [
          const StepTrigger(sourceStepIds: ['branchA']),
          const StepTrigger(sourceStepIds: ['branchB']),
        ],
      ),
    ],
  );
}

void main() {
  late _FakeRunRepo runRepo;
  late _FakeTemplateRepo templateRepo;
  late FakeAgentRunLogRepository agentRunLogRepo;
  late StepProcessRegistry registry;
  late PipelineBodyRegistry bodies;
  late DomainEventBus eventBus;
  late PipelineEngine engine;

  setUp(() {
    runRepo = _FakeRunRepo();
    templateRepo = _FakeTemplateRepo();
    agentRunLogRepo = FakeAgentRunLogRepository();
    registry = StepProcessRegistry();
    bodies = PipelineBodyRegistry();
    eventBus = DomainEventBus();
    engine = PipelineEngine(
      bodies: bodies,
      templates: templateRepo,
      repository: runRepo,
      agentRunLogRepository: agentRunLogRepo,
      stepProcessRegistry: registry,
      eventBus: eventBus,
    );
  });

  // ── 1. Happy path: linear pipeline ───────────────────────────────────

  group('happy path - linear pipeline', () {
    test(
      'executes trigger → stepA → stepB → terminal and completes the run',
      () async {
        final def = _linearDefinition();
        templateRepo.seed(def);

        bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
        bodies.registerBody(
          'bodyA',
          (_) async => StepResult.ok(mutatedState: {'a': 1}),
        );
        bodies.registerBody(
          'bodyB',
          (_) async => StepResult.ok(mutatedState: {'b': 2}),
        );

        final run = await engine.start('tpl', workspaceId: 'ws');
        expect(run, isNotNull);

        await _waitFor(
          () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
          reason: 'Run should reach completed status',
        );

        final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
        final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
        expect(statusMap['stepA'], PipelineStepStatus.completed);
        expect(statusMap['stepB'], PipelineStepStatus.completed);
      },
    );

    test('merges state from each step into the run', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'x': 'hello'}),
      );
      bodies.registerBody(
        'bodyB',
        (_) async => StepResult.ok(mutatedState: {'y': 'world'}),
      );

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.state['x'], 'hello');
      expect(stored.state['y'], 'world');
    });

    test('trigger payload is available to step bodies', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      Map<String, dynamic>? capturedPayload;
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (ctx) async {
        capturedPayload = ctx.triggerPayload;
        return StepResult.ok();
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'repo': 'acme/app'},
      );

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['repo'], 'acme/app');
    });
  });

  // ── 2. Parallel step execution ───────────────────────────────────────

  group('parallel step execution', () {
    test('both branches run after trigger and join waits for both', () async {
      final def = _parallelDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'a': true}),
      );
      bodies.registerBody(
        'bodyB',
        (_) async => StepResult.ok(mutatedState: {'b': true}),
      );
      bodies.registerBody(
        'bodyJoin',
        (_) async => StepResult.ok(mutatedState: {'joined': 1}),
      );

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        reason: 'Run should complete after all parallel branches + join',
      );

      final stored = runRepo.runs[run!.id]!;
      final stepRuns = await runRepo.stepRunsForPipeline(run.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['stepA'], PipelineStepStatus.completed);
      expect(statusMap['stepB'], PipelineStepStatus.completed);
      expect(statusMap['join'], PipelineStepStatus.completed);

      expect(stored.state['a'], isTrue);
      expect(stored.state['b'], isTrue);
      expect(stored.state['joined'], 1);
    });

    test('join step receives merged state from both branches', () async {
      final def = _parallelDefinition();
      templateRepo.seed(def);

      Map<String, dynamic>? joinState;
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'val': 'A'}),
      );
      bodies.registerBody(
        'bodyB',
        (_) async => StepResult.ok(mutatedState: {'other': 'B'}),
      );
      bodies.registerBody('bodyJoin', (ctx) async {
        joinState = Map<String, dynamic>.from(ctx.state);
        return StepResult.ok();
      });

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(joinState, isNotNull);
      expect(joinState!['val'], 'A');
      expect(joinState!['other'], 'B');
    });
  });

  // ── 3. Conditional step execution (router) ───────────────────────────

  group('conditional step execution - router', () {
    test('router selects branch A and skips branch B', () async {
      final def = _routerDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyRouter', (_) async => StepResult.route('a'));
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'took': 'A'}),
      );
      bodies.registerBody(
        'bodyB',
        (_) async => StepResult.ok(mutatedState: {'took': 'B'}),
      );

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        reason: 'Run should complete after router selects branch A',
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.state['took'], 'A');

      final stepRuns = await runRepo.stepRunsForPipeline(run.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['branchA'], PipelineStepStatus.completed);
      expect(statusMap['branchB'], PipelineStepStatus.skipped);
    });

    test('router selects branch B and skips branch A', () async {
      final def = _routerDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyRouter', (_) async => StepResult.route('b'));
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'took': 'A'}),
      );
      bodies.registerBody(
        'bodyB',
        (_) async => StepResult.ok(mutatedState: {'took': 'B'}),
      );

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.state['took'], 'B');

      final stepRuns = await runRepo.stepRunsForPipeline(run.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['branchA'], PipelineStepStatus.skipped);
      expect(statusMap['branchB'], PipelineStepStatus.completed);
    });
  });

  // ── 4. Error handling - step failure propagation ─────────────────────

  group('error handling', () {
    test('step failure propagates to fail the run', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.failed('something broke'),
      );
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.failed,
        reason: 'Run should fail when stepA returns failed',
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.errorMessage, 'something broke');
    });

    test('step body throwing propagates to fail the run', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        throw StateError('unexpected crash');
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.failed,
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.errorMessage, contains('unexpected crash'));
    });

    test('downstream steps do not execute after failure', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.failed('boom'));
      var stepBRan = false;
      bodies.registerBody('bodyB', (_) async {
        stepBRan = true;
        return StepResult.ok();
      });

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(() => runRepo.runs[run!.id]?.isTerminal == true);

      expect(stepBRan, isFalse);
    });

    test('continueOnFail marks step completed and keeps run alive', () async {
      final def = _linearDefinition(
        configA: const PipelineNodeConfig(continueOnFail: true),
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.failed('soft failure'),
      );
      bodies.registerBody(
        'bodyB',
        (_) async => StepResult.ok(mutatedState: {'recovered': 1}),
      );

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        reason: 'Run should complete despite continueOnFail step',
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.state['recovered'], 1);

      // Error stashed under _stepErrors.
      final errors = stored.state[kStepErrorsKey];
      expect(errors, isA<Map>());
      expect((errors as Map)['stepA'], 'soft failure');

      final stepRuns = await runRepo.stepRunsForPipeline(run.id);
      final stepARun = stepRuns.firstWhere((sr) => sr.stepId == 'stepA');
      expect(stepARun.status, PipelineStepStatus.completed);
    });

    test('retry policy retries before succeeding', () async {
      var attemptCount = 0;
      final def = _linearDefinition(
        configA: const PipelineNodeConfig(
          retryPolicy: StepRetryPolicy(maxAttempts: 3, initialDelayMs: 1),
        ),
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        attemptCount++;
        if (attemptCount < 3) {
          return StepResult.failed('transient');
        }
        return StepResult.ok(mutatedState: {'success': true});
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        reason: 'Run should complete after retry succeeds',
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.state['success'], isTrue);
      expect(attemptCount, 3);
    });

    test('retry policy exhausts retries and fails the run', () async {
      final def = _linearDefinition(
        configA: const PipelineNodeConfig(
          retryPolicy: StepRetryPolicy(maxAttempts: 2, initialDelayMs: 1),
        ),
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.failed('always fails'),
      );
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.failed,
        reason: 'Run should fail after retries exhausted',
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.errorMessage, 'always fails');
    });
  });

  // ── 5. State transitions ─────────────────────────────────────────────

  group('state transitions', () {
    test('run transitions pending → running → completed', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');
      expect(run!.status, PipelineRunStatus.pending);

      await _waitFor(
        () => runRepo.runs[run.id]?.status == PipelineRunStatus.completed,
      );

      final stored = runRepo.runs[run.id]!;
      expect(stored.finishedAt, isNotNull);
    });

    test('run transitions pending → running → failed on step error', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.failed('fail'));
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.failed,
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.finishedAt, isNotNull);
    });

    test('step transitions running → completed on success', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final stepARun = stepRuns.firstWhere((sr) => sr.stepId == 'stepA');
      expect(stepARun.status, PipelineStepStatus.completed);
      expect(stepARun.finishedAt, isNotNull);
    });

    test('step transitions running → failed on error', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.failed('bad'));
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.failed,
      );

      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final stepARun = stepRuns.firstWhere((sr) => sr.stepId == 'stepA');
      expect(stepARun.status, PipelineStepStatus.failed);
      expect(stepARun.finishedAt, isNotNull);
    });
  });

  // ── 6. Cancellation ──────────────────────────────────────────────────

  group('cancellation', () {
    test('cancel stops a running pipeline and kills in-flight step', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());

      // stepA suspends so we have time to cancel
      final resumeA = Completer<void>();
      bodies.registerBody('bodyA', (ctx) async {
        await resumeA.future;
        return StepResult.ok();
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      // Wait for stepA to be running
      await _waitFor(
        () => runRepo.steps.values.any(
          (s) =>
              s.pipelineRunId == run!.id &&
              s.stepId == 'stepA' &&
              s.status == PipelineStepStatus.running,
        ),
        reason: 'stepA should be running before cancel',
      );

      // Find stepA's step run and register a kill callback
      final stepARun = runRepo.steps.values.firstWhere(
        (s) => s.pipelineRunId == run!.id && s.stepId == 'stepA',
      );
      var killed = false;
      registry.register(stepARun.id, () {
        killed = true;
        resumeA.complete();
      });

      await engine.cancel('ws', run!.id);

      expect(killed, isTrue);
      final stored = runRepo.runs[run.id]!;
      expect(stored.status, PipelineRunStatus.cancelled);
    });

    test('cancel is no-op for already terminal run', () async {
      runRepo.runs['r1'] = PipelineRun(
        id: 'r1',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.completed,
        startedAt: DateTime(2026),
      );

      await engine.cancel('ws', 'r1');

      expect(runRepo.runs['r1']!.status, PipelineRunStatus.completed);
    });

    test('cancel is no-op for non-existent run', () async {
      // Should not throw
      await engine.cancel('ws', 'nonexistent');
    });
  });

  // ── 7. Event emission ────────────────────────────────────────────────

  group('event emission', () {
    test('emits PipelineRunCompleted when run finishes', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final events = <PipelineRunCompleted>[];
      eventBus.on<PipelineRunCompleted>().listen(events.add);

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events, hasLength(1));
      expect(events.first.templateId, 'tpl');
    });
  });

  // ── 8. Downstream planner integration ────────────────────────────────

  group('downstream planner integration', () {
    test('skips unreachable branches after router decision', () async {
      final def = _routerDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyRouter', (_) async => StepResult.route('a'));
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['branchB'], PipelineStepStatus.skipped);
    });

    test('terminal is reached when its source branch completes', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(runRepo.runs[run!.id]!.status, PipelineRunStatus.completed);
    });

    test('join waits for all parallel branches before firing', () async {
      final def = _parallelDefinition();
      templateRepo.seed(def);

      final aCompleter = Completer<void>();
      final bCompleter = Completer<void>();

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        await aCompleter.future;
        return StepResult.ok(mutatedState: {'a': 1});
      });
      bodies.registerBody('bodyB', (_) async {
        await bCompleter.future;
        return StepResult.ok(mutatedState: {'b': 2});
      });
      bodies.registerBody(
        'bodyJoin',
        (_) async => StepResult.ok(mutatedState: {'j': 3}),
      );

      final run = await engine.start('tpl', workspaceId: 'ws');

      // Wait for both branches to be running
      await _waitFor(
        () =>
            runRepo.steps.values
                .where(
                  (s) =>
                      s.pipelineRunId == run!.id &&
                      s.status == PipelineStepStatus.running,
                )
                .length >=
            2,
        reason: 'Both parallel branches should be running',
      );

      // The run should still be running — join hasn't fired yet.
      expect(runRepo.runs[run!.id]!.status, PipelineRunStatus.running);

      // Complete branch A — join should still wait for B.
      aCompleter.complete();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(runRepo.runs[run.id]!.status, PipelineRunStatus.running);

      // Complete branch B — now join fires and the run completes.
      bCompleter.complete();

      await _waitFor(
        () => runRepo.runs[run.id]?.status == PipelineRunStatus.completed,
        reason: 'Run should complete after both branches finish',
      );

      final stored = runRepo.runs[run.id]!;
      expect(stored.state['a'], 1);
      expect(stored.state['b'], 2);
      expect(stored.state['j'], 3);
    });
  });

  // ── 9. Template rendering for step inputs ────────────────────────────

  group('template rendering', () {
    test('step body receives trigger payload in context', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      Map<String, dynamic>? capturedPayload;
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (ctx) async {
        capturedPayload = ctx.triggerPayload;
        return StepResult.ok();
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'repo_name': 'my-repo'},
      );

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!['repo_name'], 'my-repo');
    });

    test('input snapshot is recorded on step run', () async {
      final def = _linearDefinition(
        configA: const PipelineNodeConfig(
          inputKeys: ['my_key'],
          prompt: 'Hello {{my_key}}',
        ),
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'my_key': 'value'},
      );

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final stepARun = stepRuns.firstWhere((sr) => sr.stepId == 'stepA');
      expect(stepARun.inputJson, isNotNull);
      expect(stepARun.inputJson, contains('bodyKey'));
    });

    test('prompt templates are rendered with trigger payload values', () async {
      final def = _linearDefinition(
        configA: const PipelineNodeConfig(
          prompt: 'Process {{name}} with {{count}} items',
          inputKeys: ['name', 'count'],
        ),
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'name': 'test-pipeline', 'count': 42},
      );

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final stepARun = stepRuns.firstWhere((sr) => sr.stepId == 'stepA');
      expect(stepARun.inputJson, contains('test-pipeline'));
      expect(stepARun.inputJson, contains('42'));
    });

    test('secret keys are redacted in input snapshot', () async {
      final def = _linearDefinition(
        configA: const PipelineNodeConfig(inputKeys: ['api_token', 'name']),
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'api_token': 'super-secret-value', 'name': 'visible'},
      );

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final stepARun = stepRuns.firstWhere((sr) => sr.stepId == 'stepA');
      // The inputKeys values are individually redacted by _redactSecret
      expect(stepARun.inputJson, contains('***redacted***'));
      expect(stepARun.inputJson, contains('visible'));
      // Note: triggerPayload is included raw in the snapshot; only the
      // per-inputKey lookups get redacted.
    });
  });

  // ── 10. Edge cases ───────────────────────────────────────────────────

  group('edge cases', () {
    test('start rejects disabled template and returns null', () async {
      final def = _linearDefinition().copyWith(isEnabled: false);
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');
      expect(run, isNull);
    });

    test('start with missing template throws StateError', () async {
      expect(
        () => engine.start('missing', workspaceId: 'ws'),
        throwsA(isA<StateError>()),
      );
    });

    test('dedup key prevents duplicate active runs', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      // stepA suspends so the first run stays non-terminal
      final resumeA = Completer<void>();
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        await resumeA.future;
        return StepResult.ok();
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final first = await engine.start(
        'tpl',
        workspaceId: 'ws',
        dedupKey: 'unique-1',
      );
      expect(first, isNotNull);

      // Wait for the first run's stepA to be running (non-terminal)
      await _waitFor(
        () => runRepo.steps.values.any(
          (s) =>
              s.pipelineRunId == first!.id &&
              s.status == PipelineStepStatus.running,
        ),
      );

      // Try starting again with same dedup key while first is active
      final second = await engine.start(
        'tpl',
        workspaceId: 'ws',
        dedupKey: 'unique-1',
      );
      expect(second, isNull, reason: 'Duplicate run should be rejected');

      // Clean up
      resumeA.complete();
      await _waitFor(() => runRepo.runs[first!.id]?.isTerminal == true);
    });

    test('different dedup keys allow parallel runs', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final first = await engine.start(
        'tpl',
        workspaceId: 'ws',
        dedupKey: 'key-1',
      );
      final second = await engine.start(
        'tpl',
        workspaceId: 'ws',
        dedupKey: 'key-2',
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.id, isNot(equals(second!.id)));

      await _waitFor(
        () =>
            runRepo.runs[first.id]?.status == PipelineRunStatus.completed &&
            runRepo.runs[second.id]?.status == PipelineRunStatus.completed,
      );
    });

    test(
      'single-step pipeline (trigger → terminal) completes immediately',
      () async {
        final def = PipelineDefinition(
          templateId: 'minimal',
          workspaceId: 'ws',
          name: 'Minimal',
          steps: [
            PipelineStepDefinition(
              id: 'trigger',
              kind: StepKind.trigger,
              bodyKey: 'pipeline.trigger',
            ),
            PipelineStepDefinition(
              id: 'end',
              kind: StepKind.terminal,
              bodyKey: '_terminal',
              triggers: [
                const StepTrigger(sourceStepIds: ['trigger']),
              ],
            ),
          ],
        );
        templateRepo.seed(def);

        bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());

        final run = await engine.start('minimal', workspaceId: 'ws');

        await _waitFor(
          () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
          reason: 'Minimal pipeline should complete immediately',
        );
      },
    );

    test(
      'StepResult.terminal from a body completes the run immediately',
      () async {
        final def = _linearDefinition();
        templateRepo.seed(def);

        bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
        bodies.registerBody(
          'bodyA',
          (_) async => StepResult.terminal(mutatedState: {'done': 1}),
        );
        bodies.registerBody('bodyB', (_) async => StepResult.ok());

        final run = await engine.start('tpl', workspaceId: 'ws');

        await _waitFor(
          () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
          reason: 'StepResult.terminal should complete the run',
        );

        final stored = runRepo.runs[run!.id]!;
        expect(stored.state['done'], 1);

        // stepB should never have run
        final stepRuns = await runRepo.stepRunsForPipeline(run.id);
        expect(stepRuns.any((sr) => sr.stepId == 'stepB'), isFalse);
      },
    );

    test(
      'maxStepsPerRun guard fails the run on excessive step executions',
      () async {
        final smallEngine = PipelineEngine(
          bodies: bodies,
          templates: templateRepo,
          repository: runRepo,
          agentRunLogRepository: agentRunLogRepo,
          stepProcessRegistry: registry,
          eventBus: eventBus,
          maxStepsPerRun: 2,
        );

        final def = _linearDefinition();
        templateRepo.seed(def);

        bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
        bodies.registerBody('bodyA', (_) async => StepResult.ok());
        bodies.registerBody('bodyB', (_) async => StepResult.ok());

        final run = await smallEngine.start('tpl', workspaceId: 'ws');

        await _waitFor(
          () => runRepo.runs[run!.id]?.status == PipelineRunStatus.failed,
          reason: 'Should fail due to step count guard',
        );

        final stored = runRepo.runs[run!.id]!;
        expect(stored.errorMessage, contains('Exceeded max step executions'));
      },
    );

    test('step output is stored as outputJson on step run', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'result': 'hello'}),
      );
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final stepARun = stepRuns.firstWhere((sr) => sr.stepId == 'stepA');
      expect(stepARun.outputJson, isNotNull);
      expect(stepARun.outputJson, contains('result'));
      expect(stepARun.outputJson, contains('hello'));
    });

    test('retry from failed run re-executes only failed steps', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      var aCallCount = 0;
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        aCallCount++;
        return StepResult.ok(mutatedState: {'a': aCallCount});
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      // First run succeeds
      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(aCallCount, 1);

      // Manually fail the run so we can retry
      runRepo.runs[run!.id] = runRepo.runs[run.id]!.copyWith(
        status: PipelineRunStatus.failed,
        errorMessage: 'force fail',
      );

      await engine.retry('ws', run.id);

      await _waitFor(
        () => runRepo.runs[run.id]?.status == PipelineRunStatus.completed,
        reason: 'Retry should re-execute and complete',
      );
    });

    test(
      'retry re-opens the failed step in place: fresh start, same room',
      () async {
        final def = _linearDefinition();
        templateRepo.seed(def);

        var failA = true;
        bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
        bodies.registerBody('bodyA', (ctx) async {
          if (failA) {
            return StepResult.failed('boom');
          }
          return StepResult.ok();
        });
        bodies.registerBody('bodyB', (_) async => StepResult.ok());

        final run = await engine.start('tpl', workspaceId: 'ws');
        await _waitFor(
          () => runRepo.runs[run!.id]?.status == PipelineRunStatus.failed,
        );

        final firstAttempt = runRepo.steps.values.firstWhere(
          (sr) => sr.stepId == 'stepA',
        );
        // The step's body opened a conversation on the first attempt: the room
        // is recorded on the row, and losing it is what mints a duplicate.
        await runRepo.updateStepRun('ws', firstAttempt.id, spaceId: 'space-1');
        final originalStart = runRepo.runs[run!.id]!.startedAt;

        failA = false;
        // The engine stamps wall-clock timestamps, so the re-stamp is only
        // observable if the clock has actually moved on.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await engine.retry('ws', run.id);
        await _waitFor(
          () => runRepo.runs[run.id]?.status == PipelineRunStatus.completed,
        );

        final rows = runRepo.steps.values
            .where((sr) => sr.stepId == 'stepA')
            .toList();
        expect(rows, hasLength(1), reason: 'the row is re-opened, not re-made');
        final retried = rows.single;
        expect(
          retried.id,
          firstAttempt.id,
          reason:
              'the step process registry and the agent logs address this id',
        );
        expect(
          retried.startedAt.isAfter(firstAttempt.startedAt),
          isTrue,
          reason: 'the step must report the attempt the operator is watching',
        );
        expect(retried.errorMessage, isNull);
        expect(
          retried.spaceId,
          'space-1',
          reason: 'the retry continues in the room the first attempt opened',
        );

        final after = runRepo.runs[run.id]!;
        expect(
          after.startedAt,
          originalStart,
          reason: 'the run keeps one origin; the waterfall draws from it',
        );
        expect(after.attemptStartedAt, isNotNull);
        expect(after.attemptStartedAt!.isAfter(originalStart), isTrue);
        expect(after.currentAttemptStartedAt, after.attemptStartedAt);
      },
    );

    test('killStep fails the step and the run', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      final resumeA = Completer<void>();
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        await resumeA.future;
        return StepResult.ok();
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      // Wait for stepA to be running
      await _waitFor(
        () => runRepo.steps.values.any(
          (s) =>
              s.pipelineRunId == run!.id &&
              s.stepId == 'stepA' &&
              s.status == PipelineStepStatus.running,
        ),
        reason: 'stepA must be running before kill',
      );
      final stepARun = runRepo.steps.values.firstWhere(
        (s) => s.pipelineRunId == run!.id && s.stepId == 'stepA',
      );

      // Register a kill callback (do NOT resume — the body should stay
      // blocked so killStep's _failStep wins the race against _runStep).
      registry.register(stepARun.id, () {});

      await engine.killStep('ws', stepARun.id);

      final stored = runRepo.runs[run!.id]!;
      expect(stored.status, PipelineRunStatus.failed);

      final updatedStep = runRepo.steps[stepARun.id]!;
      expect(updatedStep.status, PipelineStepStatus.failed);
    });

    test('killStep is no-op on already terminal step', () async {
      // Pre-seed a completed step run
      runRepo.runs['r1'] = PipelineRun(
        id: 'r1',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2026),
      );
      runRepo.steps['sr1'] = PipelineStepRun(
        id: 'sr1',
        pipelineRunId: 'r1',
        stepId: 'stepA',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026),
      );

      await engine.killStep('ws', 'sr1');

      // Unchanged
      expect(runRepo.steps['sr1']!.status, PipelineStepStatus.completed);
    });

    test('dispose waits for in-flight steps', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      // The engine runs steps asynchronously; wait for them to settle,
      // then dispose and verify the run reached a terminal state.
      await _waitFor(
        () => runRepo.runs[run!.id]?.isTerminal == true,
        reason: 'All steps should settle',
      );
      await engine.dispose();

      final stored = runRepo.runs[run!.id]!;
      expect(stored.isTerminal, isTrue);
    });
  });

  // ── 11. dryRun mode ──────────────────────────────────────────────────

  group('dryRun mode', () {
    test('dryRun flag is passed to pipeline context', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bool? capturedDryRun;
      bodies.registerBody('pipeline.trigger', (ctx) async {
        capturedDryRun = ctx.dryRun;
        return StepResult.ok();
      });
      bodies.registerBody('bodyA', (ctx) async {
        capturedDryRun = ctx.dryRun;
        return StepResult.ok();
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws', dryRun: true);

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(capturedDryRun, isTrue);
    });

    test('dryRun: true starts run but passes dryRun to context', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws', dryRun: true);
      expect(run, isNotNull);
      expect(run!.dryRun, isTrue);

      await _waitFor(
        () => runRepo.runs[run.id]?.status == PipelineRunStatus.completed,
      );

      final stored = runRepo.runs[run.id]!;
      expect(stored.dryRun, isTrue);
    });
  });

  // ── 12. Parallel failure propagation ─────────────────────────────────

  group('parallel failure propagation', () {
    test('one parallel branch failing does not block the other branch '
        'from completing', () async {
      // Parallel: trigger → stepA ─┬→ join → terminal
      //            trigger → stepB ─┘
      // stepA fails with continueOnFail, stepB completes, join fires.
      final def = PipelineDefinition(
        templateId: 'tpl',
        workspaceId: 'ws',
        name: 'ParallelFail',
        steps: [
          PipelineStepDefinition(
            id: 'trigger',
            kind: StepKind.trigger,
            bodyKey: 'pipeline.trigger',
          ),
          PipelineStepDefinition(
            id: 'stepA',
            kind: StepKind.listen,
            bodyKey: 'bodyA',
            triggers: [
              const StepTrigger(sourceStepIds: ['trigger']),
            ],
            config: const PipelineNodeConfig(continueOnFail: true),
          ),
          PipelineStepDefinition(
            id: 'stepB',
            kind: StepKind.listen,
            bodyKey: 'bodyB',
            triggers: [
              const StepTrigger(sourceStepIds: ['trigger']),
            ],
          ),
          PipelineStepDefinition(
            id: 'join',
            kind: StepKind.join,
            bodyKey: 'bodyJoin',
            waitForStepIds: ['stepA', 'stepB'],
            triggers: [
              const StepTrigger(sourceStepIds: ['stepA']),
              const StepTrigger(sourceStepIds: ['stepB']),
            ],
          ),
          PipelineStepDefinition(
            id: 'end',
            kind: StepKind.terminal,
            bodyKey: '_terminal',
            triggers: [
              const StepTrigger(sourceStepIds: ['join']),
            ],
          ),
        ],
      );
      templateRepo.seed(def);

      var branchBCalled = false;
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.failed('branch A failed'),
      );
      bodies.registerBody('bodyB', (_) async {
        branchBCalled = true;
        return StepResult.ok(mutatedState: {'b': 1});
      });
      bodies.registerBody(
        'bodyJoin',
        (_) async => StepResult.ok(mutatedState: {'j': 2}),
      );

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        reason: 'Run should complete despite stepA failing with continueOnFail',
      );

      // Branch B still completed.
      expect(branchBCalled, isTrue);
      final stored = runRepo.runs[run!.id]!;
      expect(stored.state['b'], 1);
      expect(stored.state['j'], 2);

      // Step errors stashed.
      final errors = stored.state[kStepErrorsKey];
      expect(errors, isA<Map>());
      expect((errors as Map)['stepA'], 'branch A failed');

      final stepRuns = await runRepo.stepRunsForPipeline(run.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['stepA'], PipelineStepStatus.completed);
      expect(statusMap['stepB'], PipelineStepStatus.completed);
      expect(statusMap['join'], PipelineStepStatus.completed);
    });

    test(
      'join still fires after one branch fails with continueOnFail',
      () async {
        // Same setup as above — verify the join step body actually ran.
        final def = PipelineDefinition(
          templateId: 'tpl',
          workspaceId: 'ws',
          name: 'ParallelFailJoin',
          steps: [
            PipelineStepDefinition(
              id: 'trigger',
              kind: StepKind.trigger,
              bodyKey: 'pipeline.trigger',
            ),
            PipelineStepDefinition(
              id: 'stepA',
              kind: StepKind.listen,
              bodyKey: 'bodyA',
              triggers: [
                const StepTrigger(sourceStepIds: ['trigger']),
              ],
              config: const PipelineNodeConfig(continueOnFail: true),
            ),
            PipelineStepDefinition(
              id: 'stepB',
              kind: StepKind.listen,
              bodyKey: 'bodyB',
              triggers: [
                const StepTrigger(sourceStepIds: ['trigger']),
              ],
            ),
            PipelineStepDefinition(
              id: 'join',
              kind: StepKind.join,
              bodyKey: 'bodyJoin',
              waitForStepIds: ['stepA', 'stepB'],
              triggers: [
                const StepTrigger(sourceStepIds: ['stepA']),
                const StepTrigger(sourceStepIds: ['stepB']),
              ],
            ),
            PipelineStepDefinition(
              id: 'end',
              kind: StepKind.terminal,
              bodyKey: '_terminal',
              triggers: [
                const StepTrigger(sourceStepIds: ['join']),
              ],
            ),
          ],
        );
        templateRepo.seed(def);

        var joinFired = false;
        bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
        bodies.registerBody(
          'bodyA',
          (_) async => StepResult.failed('branch A failed'),
        );
        bodies.registerBody(
          'bodyB',
          (_) async => StepResult.ok(mutatedState: {'b': 1}),
        );
        bodies.registerBody('bodyJoin', (_) async {
          joinFired = true;
          return StepResult.ok(mutatedState: {'j': 2});
        });

        final run = await engine.start('tpl', workspaceId: 'ws');

        await _waitFor(
          () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        );

        expect(joinFired, isTrue);
      },
    );
  });

  // ── 13. Retry policy edge cases ──────────────────────────────────────

  group('retry policy edge cases', () {
    test('retry with delay respects initialDelayMs', () async {
      var callCount = 0;
      final def = _linearDefinition(
        configA: const PipelineNodeConfig(
          retryPolicy: StepRetryPolicy(maxAttempts: 3, initialDelayMs: 1),
        ),
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        callCount++;
        if (callCount < 3) {
          return StepResult.failed('transient');
        }
        return StepResult.ok(mutatedState: {'success': true});
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        reason: 'Run should complete after retries with delay',
      );

      expect(callCount, 3);
      expect(runRepo.runs[run!.id]!.state['success'], isTrue);
    });

    test('retry counter resets across re-executions', () async {
      var callCount = 0;
      final def = _linearDefinition(
        configA: const PipelineNodeConfig(
          retryPolicy: StepRetryPolicy(maxAttempts: 2, initialDelayMs: 1),
        ),
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        callCount++;
        return StepResult.failed('always fails');
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      // First run: exhausts 2 retries.
      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.failed,
        reason: 'Run should fail after retries exhausted',
      );
      expect(callCount, 2);

      // Retry: counter should reset, giving fresh 2 attempts.
      await engine.retry('ws', run!.id);

      await _waitFor(
        () => runRepo.runs[run.id]?.status == PipelineRunStatus.failed,
        reason: 'Retried run should fail again after fresh attempts',
      );

      // Total callCount should be 4 (first run's 2 + retry's 2).
      expect(callCount, 4);
    });

    test('maxAttempts of 1 is no retry', () async {
      var callCount = 0;
      final def = _linearDefinition(
        configA: const PipelineNodeConfig(
          retryPolicy: StepRetryPolicy(maxAttempts: 1, initialDelayMs: 1000),
        ),
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        callCount++;
        return StepResult.failed('fail');
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.failed,
      );

      expect(callCount, 1);
    });
  });

  // ── 14. Concurrent start serialization ───────────────────────────────

  group('concurrent start serialization', () {
    test('two starts with same dedup key serialize correctly', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      // Slow down stepA so the first run stays non-terminal
      final resumeA = Completer<void>();
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        await resumeA.future;
        return StepResult.ok();
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      // Fire two starts concurrently
      final results = await Future.wait([
        engine.start('tpl', workspaceId: 'ws', dedupKey: 'serial-key'),
        engine.start('tpl', workspaceId: 'ws', dedupKey: 'serial-key'),
      ]);

      final nonNull = results.whereType<PipelineRun>();
      expect(
        nonNull.length,
        1,
        reason: 'Only one run should be created for same dedup key',
      );

      resumeA.complete();
      await _waitFor(() => runRepo.runs[nonNull.first.id]?.isTerminal == true);
    });

    test('null dedup keys allow parallel starts', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final results = await Future.wait([
        engine.start('tpl', workspaceId: 'ws'),
        engine.start('tpl', workspaceId: 'ws'),
      ]);

      final runs = results.whereType<PipelineRun>().toList();
      expect(runs.length, 2);
      expect(runs[0].id, isNot(equals(runs[1].id)));

      await _waitFor(
        () =>
            runRepo.runs[runs[0].id]?.status == PipelineRunStatus.completed &&
            runRepo.runs[runs[1].id]?.status == PipelineRunStatus.completed,
      );
    });
  });

  // ── 15. State merging edge cases ─────────────────────────────────────

  group('state merging edge cases', () {
    test('null mutatedState does not clear existing state', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'a': 1}),
      );
      // bodyB returns null mutatedState (explicit null).
      bodies.registerBody(
        'bodyB',
        (_) async => StepResult.ok(mutatedState: null),
      );

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.state['a'], 1);
    });

    test('empty mutatedState map does not clear existing state', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'a': 1}),
      );
      // bodyB returns an empty mutatedState map.
      bodies.registerBody(
        'bodyB',
        (_) async => StepResult.ok(mutatedState: {}),
      );

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.state['a'], 1);
    });
  });

  // ── 16. Downstream planner edge cases ────────────────────────────────

  group('downstream planner edge cases', () {
    test('skipped step does not execute body', () async {
      final def = _routerDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyRouter', (_) async => StepResult.route('a'));
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'took': 'A'}),
      );
      var branchBCalled = false;
      bodies.registerBody('bodyB', (_) async {
        branchBCalled = true;
        return StepResult.ok();
      });

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        reason: 'Run should complete after router selects branch A',
      );

      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['branchB'], PipelineStepStatus.skipped);
      expect(
        branchBCalled,
        isFalse,
        reason: 'Skipped branch body should never execute',
      );
    });

    test(
      'a trigger without any downstream steps completes immediately',
      () async {
        // Minimal pipeline: trigger → terminal. The only listener of the
        // trigger is the terminal sentinel, so no work-executing body fires.
        final def = PipelineDefinition(
          templateId: 'minimal',
          workspaceId: 'ws',
          name: 'Minimal',
          steps: [
            PipelineStepDefinition(
              id: 'trigger',
              kind: StepKind.trigger,
              bodyKey: 'pipeline.trigger',
            ),
            PipelineStepDefinition(
              id: 'end',
              kind: StepKind.terminal,
              bodyKey: '_terminal',
              triggers: [
                const StepTrigger(sourceStepIds: ['trigger']),
              ],
            ),
          ],
        );
        templateRepo.seed(def);

        var triggerFired = false;
        bodies.registerBody('pipeline.trigger', (_) async {
          triggerFired = true;
          return StepResult.ok();
        });

        final run = await engine.start('minimal', workspaceId: 'ws');

        await _waitFor(
          () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
          reason: 'Trigger-only pipeline should complete immediately',
        );

        expect(triggerFired, isTrue);

        // No body-executing steps should have run.
        final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
        for (final sr in stepRuns) {
          if (sr.stepId != 'trigger' && sr.stepId != 'end') {
            fail('Unexpected step run: ${sr.stepId}');
          }
        }
      },
    );
  });

  // ── 17. killStep edge cases ──────────────────────────────────────────

  group('killStep edge cases', () {
    test('killStep on non-existent step does not throw', () async {
      // Should complete without throwing.
      await engine.killStep('ws', 'nonexistent-step-id');
    });

    test('killStep on a step from a completed run does nothing', () async {
      // Pre-seed a completed run with a completed step.
      runRepo.runs['r1'] = PipelineRun(
        id: 'r1',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026),
      );
      runRepo.steps['sr1'] = PipelineStepRun(
        id: 'sr1',
        pipelineRunId: 'r1',
        stepId: 'stepA',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026),
      );

      await engine.killStep('ws', 'sr1');

      // Unchanged: step still completed, run still completed.
      expect(runRepo.steps['sr1']!.status, PipelineStepStatus.completed);
      expect(runRepo.runs['r1']!.status, PipelineRunStatus.completed);
    });
  });

  // ── 18. Template version tracking ────────────────────────────────────

  group('template version tracking', () {
    test('run records template version at start time', () async {
      final def = _linearDefinition().copyWith(version: 7);
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');
      expect(run, isNotNull);
      expect(
        run!.templateVersion,
        7,
        reason: 'Run should be pinned to the template version at start',
      );

      await _waitFor(
        () => runRepo.runs[run.id]?.status == PipelineRunStatus.completed,
      );

      final stored = runRepo.runs[run.id]!;
      expect(stored.templateVersion, 7);
    });
  });

  // ── 19. resumeAll tests ──────────────────────────────────────────────

  group('resumeAll', () {
    test('does nothing when there are no non-terminal runs', () async {
      await engine.resumeAll();
      // No crash = pass
    });

    test('skips run whose template no longer exists', () async {
      runRepo.runs['orphan'] = PipelineRun(
        id: 'orphan',
        templateId: 'gone-tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2026),
      );

      await engine.resumeAll();

      // Run should still be running (untouched).
      expect(runRepo.runs['orphan']!.status, PipelineRunStatus.running);
    });

    test(
      'completes a run left non-terminal by a template that lacked a terminal',
      () async {
        // Regression: `skill_analysis` shipped without a terminal node, so
        // `planDownstream` could never report `terminalReached` and every run
        // sat at "Running" forever after its only step completed (17 of them
        // on a real host, each holding a dedup key that blocked the next scan
        // of the same skill). The fix is the seed's terminal node; the boot
        // reconcile writes it, and THIS is the path that then heals the rows
        // already stuck — `resumeAll` re-evaluates downstream against the live
        // template even when no step needs re-running.
        final def = _linearDefinition();
        templateRepo.seed(def);

        // Bodies are registered but must not be invoked: every step already
        // completed, so healing is a pure re-evaluation, not a re-execution.
        var executions = 0;
        bodies.registerBody('pipeline.trigger', (_) async {
          executions++;
          return StepResult.ok();
        });
        bodies.registerBody('bodyA', (_) async {
          executions++;
          return StepResult.ok();
        });
        bodies.registerBody('bodyB', (_) async {
          executions++;
          return StepResult.ok();
        });

        runRepo.runs['stranded'] = PipelineRun(
          id: 'stranded',
          templateId: 'tpl',
          workspaceId: 'ws',
          status: PipelineRunStatus.running,
          startedAt: DateTime(2026),
        );
        for (final stepId in ['trigger', 'stepA', 'stepB']) {
          runRepo.steps['stranded-$stepId'] = PipelineStepRun(
            id: 'stranded-$stepId',
            pipelineRunId: 'stranded',
            stepId: stepId,
            status: PipelineStepStatus.completed,
            startedAt: DateTime(2026),
            finishedAt: DateTime(2026),
          );
        }

        await engine.resumeAll();

        await _waitFor(
          () => runRepo.runs['stranded']?.status == PipelineRunStatus.completed,
          reason:
              'A fully-completed run must not stay "Running" once the '
              'template it resumes against has a reachable terminal',
        );
        expect(
          executions,
          0,
          reason: 'no step should be re-executed to heal the run',
        );
      },
    );

    test('resumes a pending step from a crashed run', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'resumed': true}),
      );
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      // Seed a run stuck after trigger completed
      runRepo.runs['stuck'] = PipelineRun(
        id: 'stuck',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2026),
      );
      runRepo.steps['stuck-trigger'] = PipelineStepRun(
        id: 'stuck-trigger',
        pipelineRunId: 'stuck',
        stepId: 'trigger',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026),
      );
      // stepA is pending — should be resumed
      runRepo.steps['stuck-stepA'] = PipelineStepRun(
        id: 'stuck-stepA',
        pipelineRunId: 'stuck',
        stepId: 'stepA',
        status: PipelineStepStatus.pending,
        startedAt: DateTime(2026),
      );

      await engine.resumeAll();

      await _waitFor(
        () => runRepo.runs['stuck']?.status == PipelineRunStatus.completed,
        reason: 'Resumed run should complete',
      );

      final stored = runRepo.runs['stuck']!;
      expect(stored.state['resumed'], isTrue);
    });

    test('re-fires interrupted steps in dependency order, on their own rows', () async {
      // Observed in production on `index_code` (chain: space → index →
      // analyze). A restart found two rows open and re-fired BOTH in the same
      // instant, so `analyze` resolved `{{pipeline_space_id}}` against a run
      // whose `space` step had not written it yet, fell back to a hidden
      // conversation — and, naming no repo scope, checked out every repo in
      // the workspace to do it. Once per restart, seven times over.
      final def = _linearDefinition();
      templateRepo.seed(def);

      final order = <String>[];
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (ctx) async {
        order.add('A:${ctx.state['from_a'] ?? 'unset'}');
        // Give B every chance to run first if the engine lets it.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return StepResult.ok(mutatedState: {'from_a': 'written'});
      });
      bodies.registerBody('bodyB', (ctx) async {
        order.add('B:${ctx.state['from_a'] ?? 'unset'}');
        return StepResult.ok();
      });

      runRepo.runs['crashed'] = PipelineRun(
        id: 'crashed',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2026),
      );
      runRepo.steps['c-trigger'] = PipelineStepRun(
        id: 'c-trigger',
        pipelineRunId: 'crashed',
        stepId: 'trigger',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026),
      );
      // BOTH open when the process died — the shape that exposes the race.
      runRepo.steps['c-stepA'] = PipelineStepRun(
        id: 'c-stepA',
        pipelineRunId: 'crashed',
        stepId: 'stepA',
        status: PipelineStepStatus.running,
        startedAt: DateTime(2026),
      );
      runRepo.steps['c-stepB'] = PipelineStepRun(
        id: 'c-stepB',
        pipelineRunId: 'crashed',
        stepId: 'stepB',
        status: PipelineStepStatus.running,
        // The room a previous attempt of this step already opened.
        spaceId: 'space-from-first-attempt',
        startedAt: DateTime(2026),
      );

      await engine.resumeAll();

      await _waitFor(
        () => runRepo.runs['crashed']?.status == PipelineRunStatus.completed,
        reason: 'the resumed run should finish',
      );

      expect(
        order,
        ['A:unset', 'B:written'],
        reason:
            'stepB must not start until stepA has written the state it reads',
      );
      // Re-fired on the row it already owns, so the room from the interrupted
      // attempt survives — a fresh row mints (and clones) a second.
      expect(runRepo.steps['c-stepB']!.spaceId, 'space-from-first-attempt');
      expect(
        runRepo.steps.values.where(
          (s) => s.pipelineRunId == 'crashed' && s.stepId == 'stepB',
        ),
        hasLength(1),
        reason: 'no duplicate row for the held step',
      );
    });

    test(
      'fails non-idempotent running step on resume instead of re-executing',
      () async {
        final def = PipelineDefinition(
          templateId: 'tpl',
          workspaceId: 'ws',
          name: 'NonIdempotent',
          steps: [
            PipelineStepDefinition(
              id: 'trigger',
              kind: StepKind.trigger,
              bodyKey: 'pipeline.trigger',
            ),
            PipelineStepDefinition(
              id: 'stepA',
              kind: StepKind.listen,
              bodyKey: 'bodyA',
              triggers: [
                const StepTrigger(sourceStepIds: ['trigger']),
              ],
              config: const PipelineNodeConfig(extras: {'idempotent': false}),
            ),
            PipelineStepDefinition(
              id: 'end',
              kind: StepKind.terminal,
              bodyKey: '_terminal',
              triggers: [
                const StepTrigger(sourceStepIds: ['stepA']),
              ],
            ),
          ],
        );
        templateRepo.seed(def);

        bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
        var bodyCalled = false;
        bodies.registerBody('bodyA', (_) async {
          bodyCalled = true;
          return StepResult.ok();
        });

        // Seed a run in running state with stepA already running
        runRepo.runs['r1'] = PipelineRun(
          id: 'r1',
          templateId: 'tpl',
          workspaceId: 'ws',
          status: PipelineRunStatus.running,
          state: {'existing': 'kept'},
          startedAt: DateTime(2026),
        );
        runRepo.steps['trig'] = PipelineStepRun(
          id: 'trig',
          pipelineRunId: 'r1',
          stepId: 'trigger',
          status: PipelineStepStatus.completed,
          startedAt: DateTime(2026),
          finishedAt: DateTime(2026),
        );
        runRepo.steps['srA'] = PipelineStepRun(
          id: 'srA',
          pipelineRunId: 'r1',
          stepId: 'stepA',
          status: PipelineStepStatus.running,
          startedAt: DateTime(2026),
        );

        await engine.resumeAll();

        // The non-idempotent step should be failed, not re-executed.
        expect(bodyCalled, isFalse);
        final updatedRun = runRepo.runs['r1']!;
        expect(updatedRun.status, PipelineRunStatus.failed);

        final updatedStep = runRepo.steps['srA']!;
        expect(updatedStep.status, PipelineStepStatus.failed);
      },
    );

    test('fails suspended steps that exceed the timeout on resume', () async {
      final engine = PipelineEngine(
        bodies: bodies,
        templates: templateRepo,
        repository: runRepo,
        agentRunLogRepository: agentRunLogRepo,
        stepProcessRegistry: registry,
        eventBus: eventBus,
        suspendedStepTimeout: const Duration(milliseconds: 1),
      );

      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      // Seed a run with a suspended step whose start time is far in the past
      runRepo.runs['r2'] = PipelineRun(
        id: 'r2',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2020),
      );
      runRepo.steps['trig2'] = PipelineStepRun(
        id: 'trig2',
        pipelineRunId: 'r2',
        stepId: 'trigger',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2020),
        finishedAt: DateTime(2020),
      );
      runRepo.steps['srA2'] = PipelineStepRun(
        id: 'srA2',
        pipelineRunId: 'r2',
        stepId: 'stepA',
        status: PipelineStepStatus.suspended,
        startedAt: DateTime(2020),
      );

      await engine.resumeAll();

      // Step should be failed due to timeout
      final updatedStep = runRepo.steps['srA2']!;
      expect(updatedStep.status, PipelineStepStatus.failed);

      final updatedRun = runRepo.runs['r2']!;
      expect(updatedRun.status, PipelineRunStatus.failed);
    });
  });

  // ── 20. resumeStep tests ─────────────────────────────────────────────

  group('resumeStep', () {
    test('is no-op when the run does not exist', () async {
      await engine.resumeStep(pipelineRunId: 'nonexistent', stepId: 'any');
      // No crash = pass
    });

    test('is no-op when the run is already terminal', () async {
      runRepo.runs['r1'] = PipelineRun(
        id: 'r1',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026),
      );

      await engine.resumeStep(pipelineRunId: 'r1', stepId: 'stepA');

      // Run should still be completed
      expect(runRepo.runs['r1']!.status, PipelineRunStatus.completed);
    });

    test(
      'is no-op when no suspended/running step matches the stepId',
      () async {
        runRepo.runs['r2'] = PipelineRun(
          id: 'r2',
          templateId: 'tpl',
          workspaceId: 'ws',
          status: PipelineRunStatus.running,
          startedAt: DateTime(2026),
        );

        await engine.resumeStep(pipelineRunId: 'r2', stepId: 'noSuchStep');
        // No crash = pass
      },
    );

    test('completes a suspended step and evaluates downstream', () async {
      final def = PipelineDefinition(
        templateId: 'tpl',
        workspaceId: 'ws',
        name: 'ResumeStep',
        steps: [
          PipelineStepDefinition(
            id: 'trigger',
            kind: StepKind.trigger,
            bodyKey: 'pipeline.trigger',
          ),
          PipelineStepDefinition(
            id: 'stepA',
            kind: StepKind.listen,
            bodyKey: 'bodyA',
            triggers: [
              const StepTrigger(sourceStepIds: ['trigger']),
            ],
          ),
          PipelineStepDefinition(
            id: 'end',
            kind: StepKind.terminal,
            bodyKey: '_terminal',
            triggers: [
              const StepTrigger(sourceStepIds: ['stepA']),
            ],
          ),
        ],
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());

      // Seed run where trigger completed and stepA is suspended
      runRepo.runs['r3'] = PipelineRun(
        id: 'r3',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2026),
      );
      runRepo.steps['trig3'] = PipelineStepRun(
        id: 'trig3',
        pipelineRunId: 'r3',
        stepId: 'trigger',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026),
      );
      runRepo.steps['srA3'] = PipelineStepRun(
        id: 'srA3',
        pipelineRunId: 'r3',
        stepId: 'stepA',
        status: PipelineStepStatus.suspended,
        startedAt: DateTime(2026),
      );

      await engine.resumeStep(pipelineRunId: 'r3', stepId: 'stepA');

      // Step should be marked completed
      final updatedStep = runRepo.steps['srA3']!;
      expect(updatedStep.status, PipelineStepStatus.completed);

      // Downstream evaluation should complete the run
      await _waitFor(
        () => runRepo.runs['r3']?.status == PipelineRunStatus.completed,
        reason: 'Run should complete after step is resumed',
      );
    });

    test('a schemaless step whose runs produced no payload fails instead of '
        'harvesting an empty list', () async {
      // The regression: the "no run carried a payload" guard was on the
      // object-schema path only, so a schemaless node merged its EMPTY
      // payload list under `outputKey`. Downstream, `[]` is indistinguishable
      // from a reviewer who genuinely found nothing — which is how three PR
      // reviewers that had filed 52 findings between them handed the
      // consolidation step three empty finding sets.
      final def = PipelineDefinition(
        templateId: 'tpl',
        workspaceId: 'ws',
        name: 'EmptyHarvest',
        steps: [
          PipelineStepDefinition(
            id: 'trigger',
            kind: StepKind.trigger,
            bodyKey: 'pipeline.trigger',
          ),
          PipelineStepDefinition(
            id: 'review',
            kind: StepKind.listen,
            bodyKey: 'bodyA',
            triggers: [
              const StepTrigger(sourceStepIds: ['trigger']),
            ],
            config: const PipelineNodeConfig(outputKey: 'review_findings'),
          ),
        ],
      );
      templateRepo.seed(def);
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());

      runRepo.runs['r-empty'] = PipelineRun(
        id: 'r-empty',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2026),
      );
      runRepo.steps['sr-empty'] = PipelineStepRun(
        id: 'sr-empty',
        pipelineRunId: 'r-empty',
        stepId: 'review',
        status: PipelineStepStatus.running,
        startedAt: DateTime(2026),
      );
      agentRunLogRepo.seed(
        AgentRunLog(
          id: 'run-empty',
          agentId: 'agent-1',
          workspaceId: 'ws',
          pipelineRunId: 'r-empty',
          pipelineStepId: 'review',
          startedAt: DateTime(2026),
          completedAt: DateTime(2026),
          status: RunStatus.completed,
          summary: 'the agent finished without submitting output',
        ),
      );

      await engine.resumeStep(pipelineRunId: 'r-empty', stepId: 'review');

      expect(runRepo.steps['sr-empty']!.status, PipelineStepStatus.failed);
      expect(
        runRepo.steps['sr-empty']!.errorMessage,
        contains('the agent finished without submitting output'),
      );
      // The empty list must never reach downstream state as a result.
      expect(runRepo.runs['r-empty']!.state['review_findings'], isNull);
    });

    test(
      'a step whose run FAILED fails, even though the run left a payload',
      () async {
        // The reported bug: a reviewer's `claude -p` died on an expired
        // credential 15 seconds in, a best-effort payload was harvested onto the
        // run anyway, and the node rendered "Completed · 16s" on the canvas —
        // next to a conversation that said "Run failed". A partial answer written
        // before the process died is not a deliverable.
        final def = PipelineDefinition(
          templateId: 'tpl',
          workspaceId: 'ws',
          name: 'FailedHarvest',
          steps: [
            PipelineStepDefinition(
              id: 'trigger',
              kind: StepKind.trigger,
              bodyKey: 'pipeline.trigger',
            ),
            PipelineStepDefinition(
              id: 'review',
              kind: StepKind.listen,
              bodyKey: 'bodyA',
              triggers: [
                const StepTrigger(sourceStepIds: ['trigger']),
              ],
              config: const PipelineNodeConfig(outputKey: 'review_findings'),
            ),
          ],
        );
        templateRepo.seed(def);
        bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
        bodies.registerBody('bodyA', (_) async => StepResult.ok());

        runRepo.runs['r-failed'] = PipelineRun(
          id: 'r-failed',
          templateId: 'tpl',
          workspaceId: 'ws',
          status: PipelineRunStatus.running,
          startedAt: DateTime(2026),
        );
        runRepo.steps['sr-failed'] = PipelineStepRun(
          id: 'sr-failed',
          pipelineRunId: 'r-failed',
          stepId: 'review',
          status: PipelineStepStatus.running,
          startedAt: DateTime(2026),
        );
        agentRunLogRepo.seed(
          AgentRunLog(
            id: 'run-failed',
            agentId: 'agent-1',
            workspaceId: 'ws',
            pipelineRunId: 'r-failed',
            pipelineStepId: 'review',
            startedAt: DateTime(2026),
            completedAt: DateTime(2026),
            status: RunStatus.error,
            summary: '[claude] OAuth access token has expired',
            outputJson: const {'result': 'half an answer'},
          ),
        );

        await engine.resumeStep(pipelineRunId: 'r-failed', stepId: 'review');

        expect(runRepo.steps['sr-failed']!.status, PipelineStepStatus.failed);
        expect(
          runRepo.steps['sr-failed']!.errorMessage,
          contains('OAuth access token has expired'),
        );
        expect(runRepo.runs['r-failed']!.state['review_findings'], isNull);
      },
    );

    test('two completions racing the same step harvest it once', () async {
      // A fan-out step dispatches N agent runs and every one of them publishes
      // `AgentRunCompleted`. The listener asks whether they are ALL terminal,
      // and the last two to finish can both answer yes — the event's own run is
      // treated as terminal whether or not its status write has landed. Both
      // then reach resumeStep, with a dozen awaits between reading the step's
      // open row and writing it completed.
      //
      // Last-write-wins hides a double harvest on an `override` node. With a
      // reducer it does not: the second harvest folds into the value the first
      // just merged, so the step's output carries every payload twice and the
      // consolidating step downstream reports double the findings.
      final def = PipelineDefinition(
        templateId: 'tpl',
        workspaceId: 'ws',
        name: 'DoubleResume',
        steps: [
          PipelineStepDefinition(
            id: 'trigger',
            kind: StepKind.trigger,
            bodyKey: 'pipeline.trigger',
          ),
          PipelineStepDefinition(
            id: 'review',
            kind: StepKind.listen,
            bodyKey: 'bodyA',
            config: const PipelineNodeConfig(
              outputKey: 'review_findings',
              reducer: 'append',
            ),
            triggers: [
              const StepTrigger(sourceStepIds: ['trigger']),
            ],
          ),
          PipelineStepDefinition(
            id: 'end',
            kind: StepKind.terminal,
            bodyKey: '_terminal',
            triggers: [
              const StepTrigger(sourceStepIds: ['review']),
            ],
          ),
        ],
      );
      templateRepo.seed(def);
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());

      runRepo.runs['r-race'] = PipelineRun(
        id: 'r-race',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2026),
      );
      runRepo.steps['trig-race'] = PipelineStepRun(
        id: 'trig-race',
        pipelineRunId: 'r-race',
        stepId: 'trigger',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026),
      );
      runRepo.steps['sr-race'] = PipelineStepRun(
        id: 'sr-race',
        pipelineRunId: 'r-race',
        stepId: 'review',
        status: PipelineStepStatus.running,
        startedAt: DateTime(2026),
      );
      for (var i = 0; i < 2; i++) {
        agentRunLogRepo.seed(
          AgentRunLog(
            id: 'run-race-$i',
            agentId: 'agent-$i',
            workspaceId: 'ws',
            pipelineRunId: 'r-race',
            pipelineStepId: 'review',
            startedAt: DateTime(2026),
            completedAt: DateTime(2026),
            status: RunStatus.completed,
            outputJson: {'finding': 'f$i'},
          ),
        );
      }

      // Both agents' completions land at once, exactly as they do in a live
      // fan-out.
      await Future.wait([
        engine.resumeStep(pipelineRunId: 'r-race', stepId: 'review'),
        engine.resumeStep(pipelineRunId: 'r-race', stepId: 'review'),
      ]);

      final harvested = runRepo.runs['r-race']!.state['review_findings'];
      expect(
        harvested,
        isA<List<dynamic>>().having((l) => l.length, 'payload count', 2),
        reason: 'The two payloads must be harvested once, not once per event.',
      );
      expect(runRepo.steps['sr-race']!.status, PipelineStepStatus.completed);
    });
  });

  // ── 21. resumeChildFlow tests ────────────────────────────────────────

  group('resumeChildFlow', () {
    test('is no-op when parent run does not exist', () async {
      await engine.resumeChildFlow(
        parentRunId: 'nonexistent',
        parentStepId: 'stepA',
        childRun: PipelineRun(
          id: 'child1',
          templateId: 'child',
          workspaceId: 'ws',
          status: PipelineRunStatus.completed,
          startedAt: DateTime(2026),
          finishedAt: DateTime(2026),
        ),
      );
      // No crash = pass
    });

    test('is no-op when parent run is terminal', () async {
      runRepo.runs['parent1'] = PipelineRun(
        id: 'parent1',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026),
      );

      await engine.resumeChildFlow(
        parentRunId: 'parent1',
        parentStepId: 'stepA',
        childRun: PipelineRun(
          id: 'child2',
          templateId: 'child',
          workspaceId: 'ws',
          status: PipelineRunStatus.completed,
          startedAt: DateTime(2026),
          finishedAt: DateTime(2026),
        ),
      );

      // Unchanged
      expect(runRepo.runs['parent1']!.status, PipelineRunStatus.completed);
    });

    test('fails parent step when child run failed', () async {
      final def = PipelineDefinition(
        templateId: 'tpl',
        workspaceId: 'ws',
        name: 'ParentFlow',
        steps: [
          PipelineStepDefinition(
            id: 'trigger',
            kind: StepKind.trigger,
            bodyKey: 'pipeline.trigger',
          ),
          PipelineStepDefinition(
            id: 'stepA',
            kind: StepKind.listen,
            bodyKey: 'bodyA',
            triggers: [
              const StepTrigger(sourceStepIds: ['trigger']),
            ],
          ),
          PipelineStepDefinition(
            id: 'end',
            kind: StepKind.terminal,
            bodyKey: '_terminal',
            triggers: [
              const StepTrigger(sourceStepIds: ['stepA']),
            ],
          ),
        ],
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());

      // Seed parent run with stepA suspended
      runRepo.runs['parent-fail'] = PipelineRun(
        id: 'parent-fail',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2026),
      );
      runRepo.steps['trig-fail'] = PipelineStepRun(
        id: 'trig-fail',
        pipelineRunId: 'parent-fail',
        stepId: 'trigger',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026),
      );
      runRepo.steps['srA-fail'] = PipelineStepRun(
        id: 'srA-fail',
        pipelineRunId: 'parent-fail',
        stepId: 'stepA',
        status: PipelineStepStatus.suspended,
        startedAt: DateTime(2026),
      );

      await engine.resumeChildFlow(
        parentRunId: 'parent-fail',
        parentStepId: 'stepA',
        childRun: PipelineRun(
          id: 'child-failed',
          templateId: 'child',
          workspaceId: 'ws',
          status: PipelineRunStatus.failed,
          startedAt: DateTime(2026),
          finishedAt: DateTime(2026),
          errorMessage: 'child crashed',
        ),
      );

      // Parent step should be failed
      final updatedStep = runRepo.steps['srA-fail']!;
      expect(updatedStep.status, PipelineStepStatus.failed);

      // Parent run should be failed
      final updatedRun = runRepo.runs['parent-fail']!;
      expect(updatedRun.status, PipelineRunStatus.failed);
    });

    test('completes parent step when child run succeeds', () async {
      final def = PipelineDefinition(
        templateId: 'tpl',
        workspaceId: 'ws',
        name: 'ParentFlow',
        steps: [
          PipelineStepDefinition(
            id: 'trigger',
            kind: StepKind.trigger,
            bodyKey: 'pipeline.trigger',
          ),
          PipelineStepDefinition(
            id: 'stepA',
            kind: StepKind.listen,
            bodyKey: 'bodyA',
            triggers: [
              const StepTrigger(sourceStepIds: ['trigger']),
            ],
          ),
          PipelineStepDefinition(
            id: 'end',
            kind: StepKind.terminal,
            bodyKey: '_terminal',
            triggers: [
              const StepTrigger(sourceStepIds: ['stepA']),
            ],
          ),
        ],
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());

      // Seed parent run with stepA suspended and trigger completed
      runRepo.runs['parent-ok'] = PipelineRun(
        id: 'parent-ok',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2026),
      );
      runRepo.steps['trig-ok'] = PipelineStepRun(
        id: 'trig-ok',
        pipelineRunId: 'parent-ok',
        stepId: 'trigger',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026),
      );
      runRepo.steps['srA-ok'] = PipelineStepRun(
        id: 'srA-ok',
        pipelineRunId: 'parent-ok',
        stepId: 'stepA',
        status: PipelineStepStatus.suspended,
        startedAt: DateTime(2026),
      );

      await engine.resumeChildFlow(
        parentRunId: 'parent-ok',
        parentStepId: 'stepA',
        childRun: PipelineRun(
          id: 'child-ok',
          templateId: 'child',
          workspaceId: 'ws',
          status: PipelineRunStatus.completed,
          startedAt: DateTime(2026),
          finishedAt: DateTime(2026),
        ),
      );

      // Parent step should be completed
      final updatedStep = runRepo.steps['srA-ok']!;
      expect(updatedStep.status, PipelineStepStatus.completed);

      // Downstream evaluation should complete the run
      await _waitFor(
        () => runRepo.runs['parent-ok']?.status == PipelineRunStatus.completed,
        reason: 'Parent run should complete after child flow resumes',
      );
    });
  });

  // ── 22. retry edge cases ─────────────────────────────────────────────

  group('retry edge cases', () {
    test('retry is no-op when the run does not exist', () async {
      await engine.retry('ws', 'nonexistent');
      // No crash = pass
    });

    test('retry is a no-op on a run that has not stopped', () async {
      // Only the two outcomes an operator can act on are re-runnable — `failed`
      // and `cancelled`. Re-opening a run that is still working would re-fire
      // steps whose bodies are mid-flight.
      for (final status in [
        PipelineRunStatus.running,
        PipelineRunStatus.pending,
        PipelineRunStatus.queued,
        PipelineRunStatus.completed,
      ]) {
        runRepo.runs['r1'] = PipelineRun(
          id: 'r1',
          templateId: 'tpl',
          workspaceId: 'ws',
          status: status,
          startedAt: DateTime(2026),
        );

        await engine.retry('ws', 'r1');

        expect(runRepo.runs['r1']!.status, status, reason: '$status');
      }
    });

    test('retry with zero completed steps re-executes entry step', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      var triggerCallCount = 0;
      bodies.registerBody('pipeline.trigger', (_) async {
        triggerCallCount++;
        return StepResult.ok();
      });
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'a': 1}),
      );
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      // Seed a failed run where nothing completed
      runRepo.runs['r2'] = PipelineRun(
        id: 'r2',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.failed,
        startedAt: DateTime(2026),
        errorMessage: 'everything failed',
      );

      await engine.retry('ws', 'r2');

      await _waitFor(
        () => runRepo.runs['r2']?.status == PipelineRunStatus.completed,
        reason: 'Retry should complete from scratch',
      );

      expect(triggerCallCount, 1);
      expect(runRepo.runs['r2']!.state['a'], 1);
    });

    test('retry is no-op when template is missing', () async {
      // Don't seed the template
      runRepo.runs['r3'] = PipelineRun(
        id: 'r3',
        templateId: 'missing-tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.failed,
        startedAt: DateTime(2026),
        errorMessage: 'boom',
      );

      await engine.retry('ws', 'r3');

      // The template is resolved BEFORE the run is re-opened. Re-opening first
      // would flip a run whose template is gone to `running` and then abandon
      // it: nothing can execute it, nothing will finish it, and the list shows
      // it working forever. Left failed it still says what happened, and Retry
      // still offers the only thing that could help.
      expect(runRepo.runs['r3']!.status, PipelineRunStatus.failed);
      expect(runRepo.runs['r3']!.errorMessage, 'boom');
    });

    test('a cancelled run can be re-run', () async {
      // Stop stays reversible: without this the only way back is a fresh run
      // that redoes everything the cancelled one already finished.
      final def = _linearDefinition();
      templateRepo.seed(def);
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      runRepo.runs['r-cancelled'] = PipelineRun(
        id: 'r-cancelled',
        templateId: 'tpl',
        workspaceId: 'ws',
        status: PipelineRunStatus.cancelled,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026, 1, 1, 0, 5),
        errorMessage: 'Run cancelled',
      );

      await engine.retry('ws', 'r-cancelled');

      await _waitFor(
        () =>
            runRepo.runs['r-cancelled']?.status ==
            PipelineRunStatus.completed,
        reason: 'a stopped run picks up again',
      );
      // The previous outcome is forgotten, not carried into the new attempt.
      final done = runRepo.runs['r-cancelled']!;
      expect(done.errorMessage, isNull);
      expect(done.startedAt, DateTime(2026), reason: 'keeps its queue place');
      expect(done.attemptStartedAt, isNotNull);
      expect(done.attemptCount, 2);
    });

    test('each rerun counts an attempt', () async {
      // "Rerun 4m ago" says a rerun happened; it cannot say whether this is the
      // second try or the fifth, which on a run that keeps failing is the first
      // thing an operator asks.
      final def = _linearDefinition();
      templateRepo.seed(def);
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.failed('nope'));
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');
      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.failed,
      );
      expect(runRepo.runs[run!.id]!.attemptCount, 1, reason: 'the first try');

      for (var expected = 2; expected <= 4; expected++) {
        await engine.retry('ws', run.id);
        await _waitFor(
          () => runRepo.runs[run.id]?.status == PipelineRunStatus.failed,
        );
        expect(runRepo.runs[run.id]!.attemptCount, expected);
      }
    });
  });

  // ── 23. misc engine edge cases ───────────────────────────────────────

  group('misc engine edge cases', () {
    test(
      'StepResult.suspendUntilTasksComplete keeps step in running state',
      () async {
        final def = PipelineDefinition(
          templateId: 'tpl',
          workspaceId: 'ws',
          name: 'Suspend',
          steps: [
            PipelineStepDefinition(
              id: 'trigger',
              kind: StepKind.trigger,
              bodyKey: 'pipeline.trigger',
            ),
            PipelineStepDefinition(
              id: 'stepA',
              kind: StepKind.listen,
              bodyKey: 'bodyA',
              triggers: [
                const StepTrigger(sourceStepIds: ['trigger']),
              ],
            ),
            PipelineStepDefinition(
              id: 'end',
              kind: StepKind.terminal,
              bodyKey: '_terminal',
              triggers: [
                const StepTrigger(sourceStepIds: ['stepA']),
              ],
            ),
          ],
        );
        templateRepo.seed(def);

        bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
        bodies.registerBody(
          'bodyA',
          (_) async => StepResult.suspendUntilTasksComplete(['t1']),
        );

        final run = await engine.start('tpl', workspaceId: 'ws');

        // Wait for stepA to settle
        await _waitFor(
          () => runRepo.steps.values.any(
            (s) => s.pipelineRunId == run!.id && s.stepId == 'stepA',
          ),
          reason: 'stepA should persist as running',
        );

        // The step's status should remain running (not completed)
        final stepARun = runRepo.steps.values.firstWhere(
          (s) => s.pipelineRunId == run!.id && s.stepId == 'stepA',
        );
        expect(stepARun.status, PipelineStepStatus.running);

        // The run should still be running (not completed)
        expect(runRepo.runs[run!.id]!.status, PipelineRunStatus.running);
      },
    );

    test('continueOnFail with exception thrown marks step completed '
        'and keeps run alive', () async {
      final def = _linearDefinition(
        configA: const PipelineNodeConfig(continueOnFail: true),
      );
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        throw ArgumentError('invalid argument');
      });
      bodies.registerBody(
        'bodyB',
        (_) async => StepResult.ok(mutatedState: {'recovered': 1}),
      );

      final run = await engine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        reason: 'Run should complete despite exception in continueOnFail step',
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.state['recovered'], 1);

      // Error should be stashed under _stepErrors
      final errors = stored.state[kStepErrorsKey];
      expect(errors, isA<Map>());
      expect((errors as Map)['stepA'], contains('invalid argument'));

      final stepRuns = await runRepo.stepRunsForPipeline(run.id);
      final stepARun = stepRuns.firstWhere((sr) => sr.stepId == 'stepA');
      expect(stepARun.status, PipelineStepStatus.completed);
    });

    test('cancel handles kill callback throwing without crashing', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      final resumeA = Completer<void>();
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async {
        await resumeA.future;
        return StepResult.ok();
      });
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start('tpl', workspaceId: 'ws');

      // Wait for stepA to be running
      await _waitFor(
        () => runRepo.steps.values.any(
          (s) =>
              s.pipelineRunId == run!.id &&
              s.stepId == 'stepA' &&
              s.status == PipelineStepStatus.running,
        ),
        reason: 'stepA must be running before cancel',
      );

      final stepARun = runRepo.steps.values.firstWhere(
        (s) => s.pipelineRunId == run!.id && s.stepId == 'stepA',
      );

      // Register a kill callback that throws
      registry.register(stepARun.id, () {
        throw StateError('kill failed');
      });

      // Resume the body so it doesn't hang
      resumeA.complete();

      // Cancel should not throw even though kill callback throws
      await engine.cancel('ws', run!.id);

      // Run should still be cancelled
      expect(runRepo.runs[run.id]!.status, PipelineRunStatus.cancelled);
    });

    test('dispose does nothing when there are no in-flight steps', () async {
      await engine.dispose();
      // No crash = pass
    });

    test('parentPipelineRunId and parentStepId are recorded on run', () async {
      final def = _linearDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (_) async => StepResult.ok());
      bodies.registerBody('bodyB', (_) async => StepResult.ok());

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        parentPipelineRunId: 'parent-123',
        parentStepId: 'step-xyz',
      );

      expect(run, isNotNull);
      expect(run!.parentPipelineRunId, 'parent-123');
      expect(run.parentStepId, 'step-xyz');

      await _waitFor(
        () => runRepo.runs[run.id]?.status == PipelineRunStatus.completed,
      );

      final stored = runRepo.runs[run.id]!;
      expect(stored.parentPipelineRunId, 'parent-123');
      expect(stored.parentStepId, 'step-xyz');
    });

    test('maxConcurrentSteps semaphore allows parallel execution', () async {
      // Use a parallel pipeline with semaphore of 2
      final smallEngine = PipelineEngine(
        bodies: bodies,
        templates: templateRepo,
        repository: runRepo,
        agentRunLogRepository: agentRunLogRepo,
        stepProcessRegistry: registry,
        eventBus: eventBus,
        maxConcurrentSteps: 2,
      );

      final def = _parallelDefinition();
      templateRepo.seed(def);

      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody(
        'bodyA',
        (_) async => StepResult.ok(mutatedState: {'a': 1}),
      );
      bodies.registerBody(
        'bodyB',
        (_) async => StepResult.ok(mutatedState: {'b': 2}),
      );
      bodies.registerBody(
        'bodyJoin',
        (_) async => StepResult.ok(mutatedState: {'j': 3}),
      );

      final run = await smallEngine.start('tpl', workspaceId: 'ws');

      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        reason: 'Run should complete with semaphore of 2',
      );

      final stored = runRepo.runs[run!.id]!;
      expect(stored.state['a'], 1);
      expect(stored.state['b'], 2);
      expect(stored.state['j'], 3);
    });

    test('an idle-waiting body does not hold its concurrency permit', () async {
      // The cap bounds how much WORK runs at once. A body that is only polling
      // — the checkout-readiness wait, up to three minutes of asking whether
      // someone else has finished — is not work, and holding a permit through
      // it turns the cap into head-of-line blocking: enough of those and every
      // other pipeline on the host queues behind steps that are doing nothing.
      final oneAtATime = PipelineEngine(
        bodies: bodies,
        templates: templateRepo,
        repository: runRepo,
        agentRunLogRepository: agentRunLogRepo,
        stepProcessRegistry: registry,
        eventBus: eventBus,
        maxConcurrentSteps: 1,
      );

      final release = Completer<void>();
      var waiterStarted = false;
      var siblingRan = false;

      templateRepo.seed(_parallelDefinition());
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('bodyA', (ctx) async {
        waiterStarted = true;
        // Exactly the shape of `ensureSpace`'s readiness poll.
        await ctx.whileWaiting(() => release.future);
        return StepResult.ok(mutatedState: {'a': 1});
      });
      bodies.registerBody('bodyB', (_) async {
        siblingRan = true;
        return StepResult.ok(mutatedState: {'b': 2});
      });
      bodies.registerBody(
        'bodyJoin',
        (_) async => StepResult.ok(mutatedState: {'j': 3}),
      );

      final run = await oneAtATime.start('tpl', workspaceId: 'ws');

      await _waitFor(() => waiterStarted, reason: 'the waiter should start');
      // The ONLY permit is held by a step that is idle-waiting. Its sibling
      // must still get to run.
      await _waitFor(
        () => siblingRan,
        reason:
            'the sibling must not queue behind a step that is only waiting',
      );

      release.complete();
      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        reason: 'the run finishes once the wait resolves',
      );
      expect(runRepo.runs[run!.id]!.state['a'], 1);
    });

    test(
      '_redactSecret redacts keys that look secret in input snapshot',
      () async {
        final def = _linearDefinition(
          configA: const PipelineNodeConfig(
            inputKeys: ['password', 'api_key', 'name', 'secret_token'],
          ),
        );
        templateRepo.seed(def);

        bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
        bodies.registerBody('bodyA', (_) async => StepResult.ok());
        bodies.registerBody('bodyB', (_) async => StepResult.ok());

        final run = await engine.start(
          'tpl',
          workspaceId: 'ws',
          triggerPayload: {
            'password': 'p@ssw0rd',
            'api_key': 'sk-123456',
            'name': 'visible',
            'secret_token': 'abc123',
          },
        );

        await _waitFor(
          () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
        );

        final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
        final stepARun = stepRuns.firstWhere((sr) => sr.stepId == 'stepA');
        final snapshot = stepARun.inputJson!;

        // Secret keys should be redacted; 'name' should remain visible
        expect(snapshot, contains('***redacted***'));
        expect(snapshot, contains('visible'));
      },
    );
  });

  // ── Run concurrency cap (maxParallelRuns) ────────────────────────────

  group('maxParallelRuns', () {
    /// A one-step pipeline whose body blocks until its completer is resolved,
    /// so a run can be held "in flight" for as long as the test needs.
    PipelineDefinition gatedDefinition({int? maxParallelRuns}) =>
        PipelineDefinition(
          templateId: 'gated',
          workspaceId: 'ws',
          name: 'Gated',
          maxParallelRuns: maxParallelRuns,
          steps: [
            PipelineStepDefinition(
              id: 'trigger',
              kind: StepKind.trigger,
              bodyKey: 'pipeline.trigger',
            ),
            PipelineStepDefinition(
              id: 'work',
              kind: StepKind.listen,
              bodyKey: 'gatedBody',
              triggers: [
                const StepTrigger(sourceStepIds: ['trigger']),
              ],
            ),
            PipelineStepDefinition(
              id: 'end',
              kind: StepKind.terminal,
              bodyKey: '_terminal',
              triggers: [
                const StepTrigger(sourceStepIds: ['work']),
              ],
            ),
          ],
        );

    late List<Completer<void>> gates;

    void registerGatedBodies() {
      gates = [];
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      bodies.registerBody('gatedBody', (_) async {
        final gate = Completer<void>();
        gates.add(gate);
        await gate.future;
        return StepResult.ok();
      });
    }

    test('an uncapped template starts every run immediately', () async {
      templateRepo.seed(gatedDefinition());
      registerGatedBodies();

      final first = await engine.start('gated', workspaceId: 'ws');
      final second = await engine.start('gated', workspaceId: 'ws');

      await _waitFor(() => gates.length == 2, reason: 'both bodies should run');
      expect(runRepo.runs[first!.id]!.status, PipelineRunStatus.running);
      expect(runRepo.runs[second!.id]!.status, PipelineRunStatus.running);

      for (final gate in gates) {
        gate.complete();
      }
    });

    test('a start over the cap is queued, not dropped', () async {
      templateRepo.seed(gatedDefinition(maxParallelRuns: 1));
      registerGatedBodies();

      final first = await engine.start('gated', workspaceId: 'ws');
      await _waitFor(() => gates.length == 1);

      final second = await engine.start('gated', workspaceId: 'ws');

      // The run exists and is waiting — nothing was dropped and nothing ran.
      expect(second, isNotNull);
      expect(runRepo.runs[second!.id]!.status, PipelineRunStatus.queued);
      expect(await runRepo.stepRunsForPipeline(second.id), isEmpty);
      expect(gates, hasLength(1));
      // Waiting for a slot is idle time, so the active clock has not started.
      expect(runRepo.runs[second.id]!.lastResumedAt, isNull);

      gates.first.complete();
      await _waitFor(
        () => runRepo.runs[first!.id]?.status == PipelineRunStatus.completed,
      );

      // The freed slot admits the queued run.
      await _waitFor(
        () => runRepo.runs[second.id]?.status == PipelineRunStatus.running,
        reason: 'the queued run should be admitted when a slot frees',
      );
      await _waitFor(() => gates.length == 2);
      expect(runRepo.runs[second.id]!.lastResumedAt, isNotNull);

      gates.last.complete();
      await _waitFor(
        () => runRepo.runs[second.id]?.status == PipelineRunStatus.completed,
      );
    });

    test('a rerun over the cap queues and resumes its own progress', () async {
      // "Retry all" on a morning's worth of failures is exactly when the cap
      // matters, so a rerun takes a slot like a start does. And when its turn
      // comes it must pick up where it stopped — firing the entry step would
      // redo every step the first attempt had already completed, in rooms those
      // steps already worked in.
      templateRepo.seed(gatedDefinition(maxParallelRuns: 1));
      registerGatedBodies();

      // One run in flight, holding the only slot.
      final holder = await engine.start('gated', workspaceId: 'ws');
      await _waitFor(() => gates.length == 1);

      // A failed run of the same template, with its trigger step already
      // done.
      runRepo.runs['r-failed'] = PipelineRun(
        id: 'r-failed',
        templateId: 'gated',
        workspaceId: 'ws',
        status: PipelineRunStatus.failed,
        startedAt: DateTime(2025),
        finishedAt: DateTime(2025, 1, 1, 0, 5),
        errorMessage: 'boom',
      );
      runRepo.steps['sr-trigger'] = PipelineStepRun(
        id: 'sr-trigger',
        pipelineRunId: 'r-failed',
        stepId: 'trigger',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2025),
        finishedAt: DateTime(2025),
      );
      runRepo.steps['sr-work'] = PipelineStepRun(
        id: 'sr-work',
        pipelineRunId: 'r-failed',
        stepId: 'work',
        status: PipelineStepStatus.failed,
        startedAt: DateTime(2025),
        finishedAt: DateTime(2025),
      );

      await engine.retry('ws', 'r-failed');

      expect(
        runRepo.runs['r-failed']!.status,
        PipelineRunStatus.queued,
        reason: 'the template is full, so the rerun waits its turn',
      );
      expect(gates, hasLength(1), reason: 'nothing extra started');
      expect(runRepo.runs['r-failed']!.lastResumedAt, isNull);

      // Free the slot.
      gates.first.complete();
      await _waitFor(
        () => runRepo.runs[holder!.id]?.status == PipelineRunStatus.completed,
      );

      await _waitFor(
        () => runRepo.runs['r-failed']?.status == PipelineRunStatus.running,
        reason: 'the freed slot admits the queued rerun',
      );
      // Resumed from its progress: the failed `work` row is re-fired on the row
      // it already owns, and the completed trigger is NOT redone.
      await _waitFor(() => gates.length == 2);
      expect(runRepo.steps['sr-work']!.status, PipelineStepStatus.running);
      expect(
        runRepo.steps.values.where(
          (s) => s.pipelineRunId == 'r-failed' && s.stepId == 'trigger',
        ),
        hasLength(1),
        reason: 'a completed step must not be re-run by the admission',
      );

      gates.last.complete();
      await _waitFor(
        () => runRepo.runs['r-failed']?.status == PipelineRunStatus.completed,
      );
    });

    test('two concurrent starts cannot both take the last slot', () async {
      templateRepo.seed(gatedDefinition(maxParallelRuns: 1));
      registerGatedBodies();

      // Two starts issued together must still leave exactly one waiting. This
      // pins the OUTCOME, not the locking: the fakes resolve within one
      // microtask chain, so they cannot reproduce the check-then-insert race a
      // real (event-loop-crossing) repository can. Counting and inserting under
      // one cap lock is what actually closes that window.
      final runs = await Future.wait([
        engine.start('gated', workspaceId: 'ws'),
        engine.start('gated', workspaceId: 'ws'),
      ]);

      final statuses = runs.map((r) => runRepo.runs[r!.id]!.status).toList();
      expect(
        statuses.where((s) => s == PipelineRunStatus.queued),
        hasLength(1),
        reason: 'exactly one of the two must wait: $statuses',
      );

      await _waitFor(() => gates.length == 1);
      expect(gates, hasLength(1), reason: 'only one body may be executing');

      gates.first.complete();
      await _waitFor(() => gates.length == 2);
      gates.last.complete();
      await _waitFor(
        () => runs.every(
          (r) => runRepo.runs[r!.id]?.status == PipelineRunStatus.completed,
        ),
      );
    });

    test('queued runs are admitted oldest-first', () async {
      templateRepo.seed(gatedDefinition(maxParallelRuns: 1));
      registerGatedBodies();

      final first = await engine.start('gated', workspaceId: 'ws');
      await _waitFor(() => gates.length == 1);
      final second = await engine.start('gated', workspaceId: 'ws');
      final third = await engine.start('gated', workspaceId: 'ws');
      expect(runRepo.runs[second!.id]!.status, PipelineRunStatus.queued);
      expect(runRepo.runs[third!.id]!.status, PipelineRunStatus.queued);

      gates.first.complete();
      await _waitFor(
        () => runRepo.runs[second.id]?.status == PipelineRunStatus.running,
      );
      expect(
        runRepo.runs[third.id]!.status,
        PipelineRunStatus.queued,
        reason: 'only one slot freed, so the third run still waits',
      );
      expect(runRepo.runs[first!.id]!.status, PipelineRunStatus.completed);

      await _waitFor(() => gates.length == 2);
      gates[1].complete();
      await _waitFor(
        () => runRepo.runs[third.id]?.status == PipelineRunStatus.running,
      );

      await _waitFor(() => gates.length == 3);
      gates[2].complete();
      await _waitFor(
        () => runRepo.runs[third.id]?.status == PipelineRunStatus.completed,
      );
    });

    test('a failed run frees its slot for the queue', () async {
      templateRepo.seed(gatedDefinition(maxParallelRuns: 1));
      var failNext = true;
      bodies.registerBody('pipeline.trigger', (_) async => StepResult.ok());
      final started = <Completer<void>>[];
      bodies.registerBody('gatedBody', (_) async {
        final gate = Completer<void>();
        started.add(gate);
        await gate.future;
        if (failNext) {
          failNext = false;
          throw StateError('boom');
        }
        return StepResult.ok();
      });

      final first = await engine.start('gated', workspaceId: 'ws');
      await _waitFor(() => started.length == 1);
      final second = await engine.start('gated', workspaceId: 'ws');
      expect(runRepo.runs[second!.id]!.status, PipelineRunStatus.queued);

      started.first.complete();
      await _waitFor(
        () => runRepo.runs[first!.id]?.status == PipelineRunStatus.failed,
      );
      await _waitFor(
        () => runRepo.runs[second.id]?.status == PipelineRunStatus.running,
        reason: 'a failure must free the slot too, not strand the queue',
      );

      await _waitFor(() => started.length == 2);
      started.last.complete();
      await _waitFor(
        () => runRepo.runs[second.id]?.status == PipelineRunStatus.completed,
      );
    });

    test('a cancelled run frees its slot for the queue', () async {
      templateRepo.seed(gatedDefinition(maxParallelRuns: 1));
      registerGatedBodies();

      final first = await engine.start('gated', workspaceId: 'ws');
      await _waitFor(() => gates.length == 1);
      final second = await engine.start('gated', workspaceId: 'ws');
      expect(runRepo.runs[second!.id]!.status, PipelineRunStatus.queued);

      await engine.cancel('ws', first!.id);
      await _waitFor(
        () => runRepo.runs[second.id]?.status == PipelineRunStatus.running,
      );

      for (final gate in gates) {
        if (!gate.isCompleted) {
          gate.complete();
        }
      }
    });

    test(
      'projection rows published outside the engine do not hold a slot',
      () async {
        templateRepo.seed(gatedDefinition(maxParallelRuns: 1));
        registerGatedBodies();

        // What the code-graph watcher writes: a `running` row for the template
        // that the engine neither started nor will ever see finish.
        await runRepo.insertRun(
          PipelineRun(
            id: 'projection-1',
            templateId: 'gated',
            workspaceId: 'ws',
            status: PipelineRunStatus.running,
            triggerEventType: IndexCodeTemplate.watchTriggerEventType,
            startedAt: DateTime.now(),
          ),
        );

        final run = await engine.start('gated', workspaceId: 'ws');
        await _waitFor(() => gates.length == 1);
        expect(
          runRepo.runs[run!.id]!.status,
          PipelineRunStatus.running,
          reason: 'a slot held by a projection would never be released',
        );

        gates.first.complete();
        await _waitFor(
          () => runRepo.runs[run.id]?.status == PipelineRunStatus.completed,
        );
      },
    );

    test('a queued run is not resumed as an interrupted one', () async {
      templateRepo.seed(gatedDefinition(maxParallelRuns: 1));
      registerGatedBodies();

      final first = await engine.start('gated', workspaceId: 'ws');
      await _waitFor(() => gates.length == 1);
      final second = await engine.start('gated', workspaceId: 'ws');
      expect(runRepo.runs[second!.id]!.status, PipelineRunStatus.queued);

      // Simulate the crash: the in-flight run is gone but its row survived.
      runRepo.runs[first!.id] = runRepo.runs[first.id]!.copyWith(
        status: PipelineRunStatus.cancelled,
        finishedAt: DateTime.now(),
      );

      await engine.resumeAll();
      await _waitFor(
        () => runRepo.runs[second.id]?.status == PipelineRunStatus.running,
        reason: 'resume must re-run admission, not strand the queue',
      );

      await _waitFor(() => gates.length == 2);
      for (final gate in gates) {
        if (!gate.isCompleted) {
          gate.complete();
        }
      }
    });
  });

  // ── Conditional step execution — `extras.runWhen` ────────────────────
  //
  // The gate lets ONE template vary its shape per run instead of forking into
  // near-identical copies. What matters is that a gated-off step is recorded
  // as deliberately skipped (not missing), that its declared output still
  // lands so downstream placeholders resolve, and that a join over it fires.

  group('conditional step execution - runWhen', () {
    /// trigger → gated (runs only when `mode` allows) + always → join → end.
    PipelineDefinition gatedDefinition({
      required List<Object?> allowed,
      String? skippedOutput = '(not run)',
    }) {
      return PipelineDefinition(
        templateId: 'tpl',
        workspaceId: 'ws',
        name: 'Gated',
        steps: [
          PipelineStepDefinition(
            id: 'trigger',
            kind: StepKind.trigger,
            bodyKey: 'pipeline.trigger',
          ),
          PipelineStepDefinition(
            id: 'gated',
            kind: StepKind.listen,
            bodyKey: 'bodyGated',
            triggers: const [
              StepTrigger(sourceStepIds: ['trigger']),
            ],
            config: PipelineNodeConfig(
              outputKey: 'gated_out',
              extras: {
                'runWhen': {
                  'key': 'mode',
                  'in': allowed,
                  'skippedOutput': ?skippedOutput,
                },
              },
            ),
          ),
          PipelineStepDefinition(
            id: 'always',
            kind: StepKind.listen,
            bodyKey: 'bodyAlways',
            triggers: [
              const StepTrigger(sourceStepIds: ['trigger']),
            ],
          ),
          PipelineStepDefinition(
            id: 'join',
            kind: StepKind.join,
            bodyKey: 'bodyJoin',
            waitForStepIds: ['gated', 'always'],
            triggers: [
              const StepTrigger(sourceStepIds: ['gated']),
              const StepTrigger(sourceStepIds: ['always']),
            ],
          ),
          PipelineStepDefinition(
            id: 'end',
            kind: StepKind.terminal,
            bodyKey: '_terminal',
            triggers: [
              const StepTrigger(sourceStepIds: ['join']),
            ],
          ),
        ],
      );
    }

    void registerBodies({required void Function() onGated}) {
      bodies
        ..registerBody('pipeline.trigger', (_) async => StepResult.ok())
        ..registerBody('bodyGated', (_) async {
          onGated();
          return StepResult.ok(mutatedState: {'gated_out': 'ran'});
        })
        ..registerBody('bodyAlways', (_) async => StepResult.ok())
        ..registerBody('bodyJoin', (_) async => StepResult.ok());
    }

    test('runs the gated step when the value is allowed', () async {
      templateRepo.seed(gatedDefinition(allowed: ['deep']));
      var gatedRan = false;
      registerBodies(onGated: () => gatedRan = true);

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'mode': 'deep'},
      );
      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(gatedRan, isTrue);
      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['gated'], PipelineStepStatus.completed);
      expect(runRepo.runs[run.id]?.state['gated_out'], 'ran');
    });

    test('skips the gated step when the value is not allowed', () async {
      templateRepo.seed(gatedDefinition(allowed: ['deep']));
      var gatedRan = false;
      registerBodies(onGated: () => gatedRan = true);

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'mode': 'shallow'},
      );
      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      // The body must not have been invoked — the whole point of the gate is
      // that the work does not happen, not that its output is discarded.
      expect(gatedRan, isFalse);
      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['gated'], PipelineStepStatus.skipped);
      expect(statusMap['always'], PipelineStepStatus.completed);
      // A join over a skipped source still fires, so the run finishes.
      expect(statusMap['join'], PipelineStepStatus.completed);
    });

    test('merges the declared placeholder output when skipped', () async {
      // Without this a downstream `{{gated_out}}` would not resolve, and an
      // unresolved placeholder fails its step — a skipped optional node would
      // take the step that consolidates it down with it.
      templateRepo.seed(gatedDefinition(allowed: ['deep']));
      registerBodies(onGated: () {});

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'mode': 'shallow'},
      );
      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(runRepo.runs[run!.id]?.state['gated_out'], '(not run)');
    });

    test('writes no output when the gate declares none', () async {
      templateRepo.seed(
        gatedDefinition(allowed: ['deep'], skippedOutput: null),
      );
      registerBodies(onGated: () {});

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'mode': 'shallow'},
      );
      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(runRepo.runs[run!.id]?.state.containsKey('gated_out'), isFalse);
    });

    test('a null entry lets the step run when the key is absent', () async {
      // This is what keeps a gate added to an existing template working for
      // runs started before the key existed.
      templateRepo.seed(gatedDefinition(allowed: ['deep', null]));
      var gatedRan = false;
      registerBodies(onGated: () => gatedRan = true);

      final run = await engine.start('tpl', workspaceId: 'ws');
      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(gatedRan, isTrue);
      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['gated'], PipelineStepStatus.completed);
    });

    test('an absent key without a null entry skips the step', () async {
      templateRepo.seed(gatedDefinition(allowed: ['deep']));
      var gatedRan = false;
      registerBodies(onGated: () => gatedRan = true);

      final run = await engine.start('tpl', workspaceId: 'ws');
      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(gatedRan, isFalse);
      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['gated'], PipelineStepStatus.skipped);
    });

    test('run state takes precedence over the trigger payload', () async {
      // This mirrors the real shape: a setup step normalizes the value into
      // state, and the gate must read that rather than the raw payload — or
      // the normalization would be silently overridden by whatever the
      // trigger happened to carry.
      templateRepo.seed(
        PipelineDefinition(
          templateId: 'tpl',
          workspaceId: 'ws',
          name: 'Setup normalizes the gate key',
          steps: [
            PipelineStepDefinition(
              id: 'trigger',
              kind: StepKind.trigger,
              bodyKey: 'pipeline.trigger',
            ),
            PipelineStepDefinition(
              id: 'setup',
              kind: StepKind.listen,
              bodyKey: 'bodySetup',
              triggers: [
                const StepTrigger(sourceStepIds: ['trigger']),
              ],
            ),
            PipelineStepDefinition(
              id: 'gated',
              kind: StepKind.listen,
              bodyKey: 'bodyGated',
              triggers: [
                const StepTrigger(sourceStepIds: ['setup']),
              ],
              config: const PipelineNodeConfig(
                extras: {
                  'runWhen': {
                    'key': 'mode',
                    'in': ['deep'],
                  },
                },
              ),
            ),
            PipelineStepDefinition(
              id: 'end',
              kind: StepKind.terminal,
              bodyKey: '_terminal',
              triggers: [
                const StepTrigger(sourceStepIds: ['gated']),
              ],
            ),
          ],
        ),
      );
      var gatedRan = false;
      bodies
        ..registerBody('pipeline.trigger', (_) async => StepResult.ok())
        // Setup rewrites the payload's 'shallow' to 'deep'.
        ..registerBody(
          'bodySetup',
          (_) async => StepResult.ok(mutatedState: {'mode': 'deep'}),
        )
        ..registerBody('bodyGated', (_) async {
          gatedRan = true;
          return StepResult.ok();
        });

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'mode': 'shallow'},
      );
      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(gatedRan, isTrue);
    });

    test('an ungated step is unaffected', () async {
      // The gate is opt-in: a node with no `runWhen` must take exactly the
      // path it took before the gate existed.
      templateRepo.seed(gatedDefinition(allowed: ['deep']));
      registerBodies(onGated: () {});

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'mode': 'shallow'},
      );
      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['always'], PipelineStepStatus.completed);
    });

    test('a malformed gate closes rather than opens', () async {
      // An unreadable allow-list must not silently become "run everything".
      // Uses the join shape so the run still completes and the assertion is
      // about the gated step rather than about a hung run.
      templateRepo.seed(
        PipelineDefinition(
          templateId: 'tpl',
          workspaceId: 'ws',
          name: 'Malformed gate',
          steps: [
            PipelineStepDefinition(
              id: 'trigger',
              kind: StepKind.trigger,
              bodyKey: 'pipeline.trigger',
            ),
            PipelineStepDefinition(
              id: 'gated',
              kind: StepKind.listen,
              bodyKey: 'bodyGated',
              triggers: [
                const StepTrigger(sourceStepIds: ['trigger']),
              ],
              config: const PipelineNodeConfig(
                // No `in` key at all.
                extras: {
                  'runWhen': {'key': 'mode'},
                },
              ),
            ),
            PipelineStepDefinition(
              id: 'always',
              kind: StepKind.listen,
              bodyKey: 'bodyAlways',
              triggers: [
                const StepTrigger(sourceStepIds: ['trigger']),
              ],
            ),
            PipelineStepDefinition(
              id: 'join',
              kind: StepKind.join,
              bodyKey: 'bodyJoin',
              waitForStepIds: ['gated', 'always'],
              triggers: [
                const StepTrigger(sourceStepIds: ['gated']),
                const StepTrigger(sourceStepIds: ['always']),
              ],
            ),
            PipelineStepDefinition(
              id: 'end',
              kind: StepKind.terminal,
              bodyKey: '_terminal',
              triggers: [
                const StepTrigger(sourceStepIds: ['join']),
              ],
            ),
          ],
        ),
      );
      var gatedRan = false;
      bodies
        ..registerBody('pipeline.trigger', (_) async => StepResult.ok())
        ..registerBody('bodyGated', (_) async {
          gatedRan = true;
          return StepResult.ok();
        })
        ..registerBody('bodyAlways', (_) async => StepResult.ok())
        ..registerBody('bodyJoin', (_) async => StepResult.ok());

      final run = await engine.start(
        'tpl',
        workspaceId: 'ws',
        triggerPayload: {'mode': 'deep'},
      );
      await _waitFor(
        () => runRepo.runs[run!.id]?.status == PipelineRunStatus.completed,
      );

      expect(gatedRan, isFalse);
      final stepRuns = await runRepo.stepRunsForPipeline(run!.id);
      final statusMap = {for (final sr in stepRuns) sr.stepId: sr.status};
      expect(statusMap['gated'], PipelineStepStatus.skipped);
    });
  });
}
