import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/backends/acp_backend.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/person_removal_service.dart'
    show kRunStoppedPersonRemovedSummary;
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// How a run ends: one terminal sequence however it got there, a stop that
/// cannot be swallowed by a failing teardown step, and an explicit key that a
/// stored pool cannot demote.

class _NoopSandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedRunLogRepo implements AgentRunLogRepository {
  @override
  Future<void> upsert(AgentRunLog log) async {}

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async => null;

  @override
  Future<bool> updateRuntime(
    String workspaceId,
    String runId, {
    int? pid,
    bool markRunning = false,
    String? logPath,
    String? contextSnapshotJson,
    DateTime? lastOutputAt,
    RunLiveness? liveness,
    RunErrorFamily? errorFamily,
    String? summary,
    String? modelId,
    String? effort,
    String? taskFamily,
  }) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A store holding one running row, recorded at dispatch with its requester,
/// that takes the terminal write.
class _RowRunLogRepo extends _UnusedRunLogRepo {
  _RowRunLogRepo(this.row);

  AgentRunLog row;

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async =>
      workspaceId == row.workspaceId && id == row.id ? row : null;

  @override
  Future<bool> updateRuntime(
    String workspaceId,
    String runId, {
    int? pid,
    bool markRunning = false,
    String? logPath,
    String? contextSnapshotJson,
    DateTime? lastOutputAt,
    RunLiveness? liveness,
    RunErrorFamily? errorFamily,
    String? summary,
    String? modelId,
    String? effort,
    String? taskFamily,
  }) async => runId == row.id && row.completedAt == null;

  /// How long a cost write takes to land (a real store's write).
  Duration costWriteDelay = Duration.zero;

  @override
  Future<void> updateCost(String workspaceId, String runId, RunCost cost) async {
    await Future<void>.delayed(costWriteDelay);
    if (runId == row.id) {
      row = row.copyWith(cost: cost);
    }
  }

  @override
  Future<bool> completeIfActive(
    AgentRunLog completed, {
    bool writeCost = true,
  }) async {
    if (completed.id != row.id || row.completedAt != null) {
      return false;
    }
    // Like the real store: the terminal write never touches the requester.
    row = row.copyWith(
      status: completed.status,
      completedAt: completed.completedAt,
      summary: completed.summary,
      endReason: completed.endReason,
      cost: writeCost ? completed.cost : row.cost,
    );
    return true;
  }
}

/// One model call that reports its usage, the way a real provider streams.
class _UsageProvider extends LlmProviderPort {
  @override
  String get displayName => 'Usage';

  @override
  String get defaultModel => 'test-model';

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    yield const LlmTextDelta('thinking it over');
    yield const LlmDone(
      stopReason: LlmStopReason.endTurn,
      usage: LlmUsage(inputTokens: 200000, outputTokens: 10000),
    );
  }

  @override
  Future<List<ProviderModel>> listModels() async => const [];
}

class _UsageFactory extends HarnessProviderFactory {
  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) => _UsageProvider();
}

/// Makes one model call, then parks until the run is cancelled.
class _CallingLoop extends _Loop {
  _CallingLoop() : super(waitForCancel: true);

  @override
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    List<HarnessTool> deferredTools = const [],
    List<HarnessTool> scriptTools = const [],
    required LlmProviderPort provider,
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
    List<HarnessImageBlock> userImages = const [],
  }) async* {
    await provider.complete(messages: const []).drain<void>();
    if (!started.isCompleted) {
      started.complete();
    }
    await cancel?.whenCancelled;
    yield const LoopDone(LoopDoneReason.cancelled);
  }
}

const _price = ModelCost(input: 3, output: 15);

class _Store implements ProviderCredentialStore {
  static const stored = ProviderCredential(
    providerId: 'openai',
    method: HarnessAuthMethod.apiKey,
    apiKey: 'sk-stored',
    accountLabel: 'stored',
    baseUrl: 'http://127.0.0.1:1',
  );

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      stored;

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async => [
    stored,
  ];

  @override
  Future<void> save(ProviderCredential credential) async {}

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {}
}

class _Factory extends HarnessProviderFactory {
  final created = <ProviderCredential?>[];

  @override
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) {
    created.add(credential);
    return super.create(
      providerId: providerId,
      model: model,
      credential: credential,
      tokenResolver: tokenResolver,
    );
  }
}

/// Finishes at once, or — with [waitForCancel] — only when the run is
/// cancelled, the way a real loop parks on a model call.
class _Loop implements AgentLoop {
  _Loop({this.waitForCancel = false});

  final bool waitForCancel;
  final started = Completer<void>();

  @override
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    List<HarnessTool> deferredTools = const [],
    List<HarnessTool> scriptTools = const [],
    required LlmProviderPort provider,
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
    List<HarnessImageBlock> userImages = const [],
  }) async* {
    if (!started.isCompleted) {
      started.complete();
    }
    if (waitForCancel) {
      await cancel?.whenCancelled;
      yield const LoopDone(LoopDoneReason.cancelled);
      return;
    }
    yield const LoopTextDelta('done');
    yield const LoopDone(LoopDoneReason.completed);
  }
}

void main() {
  DispatchSession session({
    required _Loop loop,
    _Factory? factory,
    String cliName = 'cc-harness',
    Map<String, String> callerEnv = const {},
    AgentRunLogRepository? runLogRepo,
    DomainEventBus? eventBus,
    HarnessProviderFactory? providerFactory,
  }) {
    final tempDir = Directory.systemTemp.createTempSync('cc_session_end_');
    addTearDown(() => deleteDirBestEffort(tempDir));
    return DispatchSession(
      freshHistory: false,
      readOnly: false,
      deps: SandboxDispatchDeps(
        hostExecution: const HostExecutionGate(
          posture: HostExecutionPosture.offByOwner,
        ),
        sandbox: _NoopSandbox(),
        agentRepo: _UnusedAgentRepo(),
        runLogRepo: runLogRepo ?? _UnusedRunLogRepo(),
        eventBus: eventBus,
        resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
            AgentCommitIdentity.person((
              name: 'Test User',
              email: 'test@example.test',
            )),
        backendRegistry: BackendRegistry({
          'cc-harness': const HarnessBackend(),
          'some-acp': const AcpBackend(cliName: 'some-acp'),
        }),
        harnessCredentialStore: _Store(),
        harnessProviderFactory: providerFactory ?? factory ?? _Factory(),
        // Priced only for the run that makes a model call.
        modelResolver: providerFactory == null
            ? null
            : (id) => ModelInfo(
                id: id,
                providerId: 'openai',
                name: id,
                supportsTools: true,
                cost: _price,
              ),
        agentLoop: loop,
      ),
      onResolveHandle:
          ({
            required String sessionId,
            required SandboxSpec spec,
            required void Function(AgentProcessEvent) emit,
          }) async => SandboxHandle(
            sessionId: sessionId,
            backend: SandboxBackend.none,
            state: SandboxState.warm,
          ),
      onScheduleCooldown: (_) {},
      dispatchId: 'd1',
      cliName: cliName,
      prompt: 'hello',
      agentDirHostPath: tempDir.path,
      modelId: 'openai/test-model',
      callerEnv: callerEnv,
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      conversationId: 'conv-1',
      runLogId: 'run-1',
      mode: Mode.chat,
    );
  }

  test('a stop ends the run exactly once', () async {
    final loop = _Loop(waitForCancel: true);
    final s = session(loop: loop);
    final events = <AgentProcessEvent>[];
    final closed = Completer<void>();
    s.controller.stream.listen(events.add, onDone: closed.complete);
    final running = s.run();
    await loop.started.future;

    await s.terminate();
    await running;
    await closed.future.timeout(const Duration(seconds: 5));

    expect(events.whereType<DoneEvent>(), hasLength(1));
    expect(
      events.whereType<DoneEvent>().single.endReason,
      RunEndReason.stoppedByUser,
    );
    final errors = events.whereType<ErrorEvent>().map((e) => e.content);
    expect(errors, contains(kRunStoppedByUserSummary));
    // A second stop changes nothing.
    await s.terminate();
    expect(events.whereType<DoneEvent>(), hasLength(1));
  });

  test('a server stop ends the run as serverStopped', () async {
    final loop = _Loop(waitForCancel: true);
    final s = session(loop: loop);
    final events = <AgentProcessEvent>[];
    final closed = Completer<void>();
    s.controller.stream.listen(events.add, onDone: closed.complete);
    final running = s.run();
    await loop.started.future;

    await s.stop(summary: kRunStoppedByShutdownSummary);
    await running;
    await closed.future.timeout(const Duration(seconds: 5));

    final done = events.whereType<DoneEvent>();
    expect(done, hasLength(1));
    expect(done.single.endReason, RunEndReason.serverStopped);
  });

  test("a server stop settles once, naming the requester the run's row "
      'recorded', () async {
    final bus = DomainEventBus();
    addTearDown(bus.dispose);
    final settled = <AgentRunSettled>[];
    bus.on<AgentRunSettled>().listen(settled.add);
    final repo = _RowRunLogRepo(
      AgentRunLog(
        id: 'run-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        spaceId: 'space-1',
        startedAt: DateTime.utc(2026, 7, 1),
        status: RunStatus.running,
        requestedByUserId: 'olga',
      ),
    );
    final loop = _Loop(waitForCancel: true);
    // The session itself is told no requester: the event's comes from the row.
    final s = session(loop: loop, runLogRepo: repo, eventBus: bus);
    final closed = Completer<void>();
    s.controller.stream.listen((_) {}, onDone: closed.complete);
    final running = s.run();
    await loop.started.future;

    await s.stop(summary: kRunStoppedByShutdownSummary);
    await running;
    await closed.future.timeout(const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);

    expect(settled, hasLength(1));
    expect(settled.single.endReason, RunEndReason.serverStopped);
    expect(settled.single.requestedByUserId, 'olga');
    expect(repo.row.requestedByUserId, 'olga');
  });

  test("a person's removal stops the run as the server, with its own "
      'summary: serverStopped, never a person\'s stop or a failure', () async {
    final bus = DomainEventBus();
    addTearDown(bus.dispose);
    final settled = <AgentRunSettled>[];
    bus.on<AgentRunSettled>().listen(settled.add);
    final repo = _RowRunLogRepo(
      AgentRunLog(
        id: 'run-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        spaceId: 'space-1',
        startedAt: DateTime.utc(2026, 7, 1),
        status: RunStatus.running,
        requestedByUserId: 'olga',
      ),
    );
    final loop = _Loop(waitForCancel: true);
    final s = session(loop: loop, runLogRepo: repo, eventBus: bus);
    final closed = Completer<void>();
    s.controller.stream.listen((_) {}, onDone: closed.complete);
    final running = s.run();
    await loop.started.future;

    await s.stop(summary: kRunStoppedPersonRemovedSummary);
    await running;
    await closed.future.timeout(const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);

    expect(settled.single.endReason, RunEndReason.serverStopped);
    expect(repo.row.summary, kRunStoppedPersonRemovedSummary);
  });

  test('a stop right after a model call settles with that call\'s cost, '
      'once its accounting write has landed', () async {
    final bus = DomainEventBus();
    addTearDown(bus.dispose);
    final settled = <AgentRunSettled>[];
    bus.on<AgentRunSettled>().listen(settled.add);
    final repo = _RowRunLogRepo(
      AgentRunLog(
        id: 'run-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        spaceId: 'space-1',
        startedAt: DateTime.utc(2026, 7, 1),
        status: RunStatus.running,
      ),
    )..costWriteDelay = const Duration(milliseconds: 50);
    final loop = _CallingLoop();
    final s = session(
      loop: loop,
      runLogRepo: repo,
      eventBus: bus,
      providerFactory: _UsageFactory(),
    );
    final closed = Completer<void>();
    s.controller.stream.listen((_) {}, onDone: closed.complete);
    final running = s.run();
    await loop.started.future;

    await s.terminate();
    await running;
    await closed.future.timeout(const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final expected = _price.estimateMicros(
      inputTokens: 200000,
      outputTokens: 10000,
    );
    expect(expected, greaterThan(0));
    expect(settled.single.endReason, RunEndReason.stoppedByUser);
    expect(settled.single.costMicros, expected);
    expect(repo.row.cost.costMicros, expected);
  });

  test('an explicit caller key keeps leading over the stored pool', () async {
    final factory = _Factory();
    final s = session(
      loop: _Loop(),
      factory: factory,
      callerEnv: const {'OPENAI_API_KEY': 'sk-caller'},
    );
    s.controller.stream.listen((_) {});
    await s.run();
    expect(factory.created, isNotEmpty);
    expect(factory.created.first?.apiKey, 'sk-caller');
  });

  test('without the OS sandbox an ACP agent is refused, not run', () async {
    final s = session(loop: _Loop(), cliName: 'some-acp');
    final events = <AgentProcessEvent>[];
    final closed = Completer<void>();
    s.controller.stream.listen(events.add, onDone: closed.complete);
    await s.run();
    await closed.future.timeout(const Duration(seconds: 5));
    final errors = events.whereType<ErrorEvent>().map((e) => e.content);
    expect(errors, anyElement(contains('does not run ACP agents unsandboxed')));
    expect(events.whereType<DoneEvent>(), hasLength(1));
  });
}
