import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
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
  }) {
    final tempDir = Directory.systemTemp.createTempSync('cc_session_end_');
    addTearDown(() => deleteDirBestEffort(tempDir));
    return DispatchSession(
      deps: SandboxDispatchDeps(
        hostExecution: const HostExecutionGate(
          posture: HostExecutionPosture.offByOwner,
        ),
        sandbox: _NoopSandbox(),
        agentRepo: _UnusedAgentRepo(),
        runLogRepo: _UnusedRunLogRepo(),
        eventBus: null,
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
        harnessProviderFactory: factory ?? _Factory(),
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
    final errors = events.whereType<ErrorEvent>().map((e) => e.content);
    expect(errors, contains(kRunStoppedByUserSummary));
    // A second stop changes nothing.
    await s.terminate();
    expect(events.whereType<DoneEvent>(), hasLength(1));
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
