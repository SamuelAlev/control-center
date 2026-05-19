import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_engine.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_step_resume_listener.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRunLogRepo implements AgentRunLogRepository {
  AgentRunLog? byIdReturn;
  List<AgentRunLog> forStepReturn = const [];

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async =>
      byIdReturn;

  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => forStepReturn;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _RecordingEngine implements PipelineEngine {
  final List<({String runId, String stepId})> resumes = [];

  @override
  Future<void> resumeStep({
    required String pipelineRunId,
    required String stepId,
  }) async {
    resumes.add((runId: pipelineRunId, stepId: stepId));
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

AgentRunLog _run({
  RunStatus status = RunStatus.completed,
  String id = 'run-1',
}) => AgentRunLog(
  id: id,
  agentId: 'agent-1',
  workspaceId: 'ws-1',
  conversationId: 'chan-1',
  pipelineRunId: 'pr-1',
  pipelineStepId: 'step-1',
  startedAt: DateTime(2026, 1, 1),
  status: status,
);

void main() {
  late DomainEventBus bus;
  late _FakeRunLogRepo runLogs;
  late _RecordingEngine engine;
  late PipelineStepResumeListener listener;

  setUp(() {
    bus = DomainEventBus();
    runLogs = _FakeRunLogRepo();
    engine = _RecordingEngine();
    listener = PipelineStepResumeListener(
      eventBus: bus,
      runLogRepository: runLogs,
      engine: engine,
    )..start();
  });

  tearDown(() => listener.dispose());

  Future<void> complete(String? runId, {String? workspaceId = 'ws-1'}) async {
    bus.publish(
      AgentRunCompleted(
        agentId: 'agent-1',
        workspaceId: workspaceId,
        conversationId: 'chan-1',
        runId: runId,
        occurredAt: DateTime.now(),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await Future.microtask(() {});
    }
  }

  test('no runId → ignored', () async {
    await complete(null);
    expect(engine.resumes, isEmpty);
  });

  test('run not found → ignored', () async {
    runLogs.byIdReturn = null;
    await complete('run-1');
    expect(engine.resumes, isEmpty);
  });

  test('non-pipeline run → ignored', () async {
    runLogs.byIdReturn = AgentRunLog(
      id: 'run-1',
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      conversationId: 'chan-1',
      startedAt: DateTime(2026, 1, 1),
      status: RunStatus.completed,
    );
    await complete('run-1');
    expect(engine.resumes, isEmpty);
  });

  test('not all runs terminal → does NOT resume', () async {
    runLogs.byIdReturn = _run(id: 'run-1');
    // A genuinely-still-running SIBLING (distinct id) must keep the step
    // suspended — the event's run being terminal is not enough on its own.
    runLogs.forStepReturn = [
      _run(id: 'run-1', status: RunStatus.completed),
      _run(id: 'run-2', status: RunStatus.running),
    ];
    await complete('run-1');
    expect(engine.resumes, isEmpty);
  });

  test('all runs terminal → resumes the step', () async {
    runLogs.byIdReturn = _run();
    runLogs.forStepReturn = [
      _run(id: 'run-1', status: RunStatus.completed),
      _run(id: 'run-2', status: RunStatus.error),
    ];
    await complete('run-1');
    expect(engine.resumes, hasLength(1));
    expect(engine.resumes.single.runId, 'pr-1');
    expect(engine.resumes.single.stepId, 'step-1');
  });

  test("event's own run still reads `running` (status write races the event) "
      '→ resumes anyway', () async {
    // The DB row for the just-completed run has NOT yet been flipped to
    // `completed` (agent_stream_processor._onDone writes it after the event
    // fires). The listener must trust the event and resume, or a lone-agent
    // step is stranded `running` forever.
    runLogs.byIdReturn = _run(id: 'run-1', status: RunStatus.running);
    runLogs.forStepReturn = [_run(id: 'run-1', status: RunStatus.running)];
    await complete('run-1');
    expect(engine.resumes, hasLength(1));
    expect(engine.resumes.single.stepId, 'step-1');
  });
}
