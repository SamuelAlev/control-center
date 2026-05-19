import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pipeline_events.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../fakes/fake_agent_run_log_repository.dart';

/// In-memory run store covering only the reads/writes [PipelineEngine.cancel]
/// performs. Everything else routes through [noSuchMethod] and throws if hit.
class _FakeRunRepo implements PipelineRunRepository {
  final Map<String, PipelineRun> runs = {};
  final Map<String, PipelineStepRun> steps = {};

  @override
  Future<PipelineRun?> getRun(String id) async => runs[id];

  @override
  Future<void> updateRun(PipelineRun run) async => runs[run.id] = run;

  @override
  Future<List<PipelineStepRun>> stepRunsForPipeline(
    String pipelineRunId,
  ) async =>
      steps.values.where((s) => s.pipelineRunId == pipelineRunId).toList();

  @override
  Future<PipelineStepRun?> getStepRunById(
    String workspaceId,
    String stepRunId,
  ) async => steps[stepRunId];

  @override
  Future<void> updateStepRun(
    String workspaceId,
    String stepRunId, {
    PipelineStepStatus? status,
    String? inputJson,
    String? outputJson,
    String? channelId,
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
      inputJson: current.inputJson,
      outputJson: current.outputJson,
      errorMessage: errorMessage ?? current.errorMessage,
      branchIndex: current.branchIndex,
      attemptCount: current.attemptCount,
      startedAt: current.startedAt,
      finishedAt: finishedAt ?? current.finishedAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTemplateRepo implements PipelineTemplateRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRunRepo runRepo;
  late StepProcessRegistry registry;
  late PipelineEngine engine;

  setUp(() {
    runRepo = _FakeRunRepo();
    registry = StepProcessRegistry();
    engine = PipelineEngine(
      bodies: PipelineBodyRegistry(),
      templates: _FakeTemplateRepo(),
      repository: runRepo,
      agentRunLogRepository: FakeAgentRunLogRepository(),
      stepProcessRegistry: registry,
      eventBus: DomainEventBus(),
    );
  });

  test('cancel() invokes each in-flight step\'s kill callback (cancel ticket / '
      'stop agent) and flips the run + step rows to cancelled', () async {
    runRepo.runs['run-1'] = PipelineRun(
      id: 'run-1',
      templateId: 'tpl',
      workspaceId: 'w',
      status: PipelineRunStatus.running,
      startedAt: DateTime(2026),
    );
    runRepo.steps['sr-1'] = PipelineStepRun(
      id: 'sr-1',
      pipelineRunId: 'run-1',
      stepId: 'step-1',
      status: PipelineStepStatus.running,
      startedAt: DateTime(2026),
    );

    // The promptAgent body registers a cleanup like this while its work is
    // live; cancel() must run it so the dispatched/dispatching agent is stopped.
    var killed = false;
    registry.register('sr-1', () => killed = true);

    await engine.cancel('w', 'run-1');

    expect(killed, isTrue, reason: 'cancel must interrupt live step work');
    expect(runRepo.runs['run-1']!.status, PipelineRunStatus.cancelled);
    expect(runRepo.steps['sr-1']!.status, PipelineStepStatus.cancelled);
    expect(registry.isLive('sr-1'), isFalse, reason: 'callback consumed');
  });

  test('cancel() is a no-op when there is no registered callback', () async {
    runRepo.runs['run-1'] = PipelineRun(
      id: 'run-1',
      templateId: 'tpl',
      workspaceId: 'w',
      status: PipelineRunStatus.running,
      startedAt: DateTime(2026),
    );
    runRepo.steps['sr-1'] = PipelineStepRun(
      id: 'sr-1',
      pipelineRunId: 'run-1',
      stepId: 'step-1',
      status: PipelineStepStatus.pending,
      startedAt: DateTime(2026),
    );

    // No callback registered (the step had not started its real work yet).
    await engine.cancel('w', 'run-1');

    expect(runRepo.runs['run-1']!.status, PipelineRunStatus.cancelled);
    expect(runRepo.steps['sr-1']!.status, PipelineStepStatus.cancelled);
  });

  test(
    'cancel() emits PipelineRunCancelled so listeners can finalize in-session',
    () async {
      final bus = DomainEventBus();
      final engineWithBus = PipelineEngine(
        bodies: PipelineBodyRegistry(),
        templates: _FakeTemplateRepo(),
        repository: runRepo,
        agentRunLogRepository: FakeAgentRunLogRepository(),
        stepProcessRegistry: registry,
        eventBus: bus,
      );
      final events = <PipelineRunCancelled>[];
      final sub = bus.on<PipelineRunCancelled>().listen(events.add);

      runRepo.runs['run-1'] = PipelineRun(
        id: 'run-1',
        templateId: 'meeting_summary',
        workspaceId: 'w',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2026),
      );

      await engineWithBus.cancel('w', 'run-1');
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.pipelineRunId, 'run-1');
      expect(events.single.templateId, 'meeting_summary');

      await sub.cancel();
    },
  );

  test(
    'cancel() on an already-terminal run does nothing and emits nothing',
    () async {
      final bus = DomainEventBus();
      final engineWithBus = PipelineEngine(
        bodies: PipelineBodyRegistry(),
        templates: _FakeTemplateRepo(),
        repository: runRepo,
        agentRunLogRepository: FakeAgentRunLogRepository(),
        stepProcessRegistry: registry,
        eventBus: bus,
      );
      final events = <PipelineRunCancelled>[];
      final sub = bus.on<PipelineRunCancelled>().listen(events.add);

      runRepo.runs['run-1'] = PipelineRun(
        id: 'run-1',
        templateId: 'meeting_summary',
        workspaceId: 'w',
        status: PipelineRunStatus.completed,
        startedAt: DateTime(2026),
      );

      await engineWithBus.cancel('w', 'run-1');
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty, reason: 'terminal runs are not re-cancelled');
      expect(runRepo.runs['run-1']!.status, PipelineRunStatus.completed);

      await sub.cancel();
    },
  );

  group('killStep()', () {
    /// A fan-out: two sibling step rows running in parallel off the same source.
    void seedParallelRun() {
      runRepo.runs['run-1'] = PipelineRun(
        id: 'run-1',
        templateId: 'tpl',
        workspaceId: 'w',
        status: PipelineRunStatus.running,
        startedAt: DateTime(2026),
      );
      for (final id in ['sr-a', 'sr-b']) {
        runRepo.steps[id] = PipelineStepRun(
          id: id,
          pipelineRunId: 'run-1',
          stepId: 'step-$id',
          status: PipelineStepStatus.running,
          startedAt: DateTime(2026),
        );
      }
    }

    test('stopping one branch closes out its parallel siblings instead of '
        'leaving them stuck on Running', () async {
      seedParallelRun();
      var killedB = false;
      registry.register('sr-a', () {});
      registry.register('sr-b', () => killedB = true);

      await engine.killStep('w', 'sr-a');

      expect(runRepo.runs['run-1']!.status, PipelineRunStatus.failed);
      expect(runRepo.steps['sr-a']!.status, PipelineStepStatus.failed);
      expect(runRepo.steps['sr-a']!.errorMessage, 'Killed by user');
      // The sibling is orphaned by the run going terminal: nothing would ever
      // finish its row, so the engine has to close it out here.
      expect(runRepo.steps['sr-b']!.status, PipelineStepStatus.cancelled);
      expect(
        runRepo.steps['sr-b']!.finishedAt,
        isNotNull,
        reason: 'a finishedAt-less row makes the duration timer tick forever',
      );
      expect(
        killedB,
        isTrue,
        reason: 'the sibling\'s live work must be stopped',
      );
      expect(registry.isLive('sr-b'), isFalse, reason: 'callback consumed');
    });

    test('leaves already-terminal siblings alone', () async {
      seedParallelRun();
      runRepo.steps['sr-b'] = PipelineStepRun(
        id: 'sr-b',
        pipelineRunId: 'run-1',
        stepId: 'step-b',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026, 1, 1, 0, 1),
      );

      await engine.killStep('w', 'sr-a');

      expect(runRepo.steps['sr-b']!.status, PipelineStepStatus.completed);
    });

    test('still stops and closes the step when the run is already terminal — '
        'Stop must never look like a no-op on an open row', () async {
      seedParallelRun();
      runRepo.runs['run-1'] = runRepo.runs['run-1']!.copyWith(
        status: PipelineRunStatus.failed,
        finishedAt: DateTime(2026, 1, 1, 0, 5),
      );
      var killed = false;
      registry.register('sr-a', () => killed = true);

      await engine.killStep('w', 'sr-a');

      expect(killed, isTrue);
      expect(runRepo.steps['sr-a']!.status, PipelineStepStatus.failed);
      expect(runRepo.steps['sr-a']!.finishedAt, isNotNull);
      // The run's own terminal state (and its finishedAt) is not rewritten.
      expect(runRepo.runs['run-1']!.finishedAt, DateTime(2026, 1, 1, 0, 5));
    });

    test('is a no-op on a step row that already finished', () async {
      seedParallelRun();
      runRepo.steps['sr-a'] = PipelineStepRun(
        id: 'sr-a',
        pipelineRunId: 'run-1',
        stepId: 'step-a',
        status: PipelineStepStatus.completed,
        startedAt: DateTime(2026),
        finishedAt: DateTime(2026, 1, 1, 0, 1),
      );

      await engine.killStep('w', 'sr-a');

      expect(runRepo.steps['sr-a']!.status, PipelineStepStatus.completed);
      expect(
        runRepo.runs['run-1']!.status,
        PipelineRunStatus.running,
        reason: 'a finished step must not fail the run',
      );
    });
  });
}
