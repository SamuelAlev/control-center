import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
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
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// Pins that the built-in harness honours the SAME account-pool verdict the
/// Claude Code lane does: a pool naming only removed keys holds the run on the
/// credential gate instead of running on whatever key the store has left.

class _NoopSandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopBroker implements CredentialBrokerPort {
  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
  }) async => const ScopedCredentials(handle: 'h', environment: {});

  @override
  Future<void> revoke(String handle) async {}
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One stored API key, `key-left`.
class _OneKeyStore implements ProviderCredentialStore {
  static const _cred = ProviderCredential(
    providerId: 'openai',
    method: HarnessAuthMethod.apiKey,
    apiKey: 'sk-test',
    accountLabel: 'key-left',
    baseUrl: 'http://127.0.0.1:1',
  );

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      _cred;

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async => [
    _cred,
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

class _Loop implements AgentLoop {
  int runs = 0;

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
  }) {
    runs++;
    return Stream.fromIterable(const [
      LoopTextDelta('done'),
      LoopDone(LoopDoneReason.completed),
    ]);
  }
}

/// A gate that records the block, lets the test "fix" the pool, and then
/// reports whether the recheck saw the fix.
class _Gate implements RunCredentialGatePort {
  _Gate({this.fix});

  final void Function()? fix;
  final List<RunCredentialBlockRequest> requests = [];

  @override
  Future<RunCredentialOutcome> awaitCredentials(
    RunCredentialBlockRequest request, {
    required Future<bool> Function() recheck,
  }) async {
    requests.add(request);
    final apply = fix;
    if (apply == null) {
      return RunCredentialOutcome.timedOut;
    }
    apply();
    return await recheck()
        ? RunCredentialOutcome.resolved
        : RunCredentialOutcome.timedOut;
  }
}

void main() {
  late bool poolFixed;
  late List<List<String>> asked;

  setUp(() {
    poolFixed = false;
    asked = [];
  });

  Future<AccountPoolOrder> pool({
    String? workspaceId,
    String? agentId,
    required String providerId,
    required List<String> credentialIds,
  }) async {
    asked.add(credentialIds);
    if (poolFixed) {
      return (order: credentialIds, refusal: null);
    }
    return (
      order: null,
      refusal: (
        reason: RunCredentialReason.accountsRemoved,
        accountIds: const ['gone'],
        earliestReset: null,
      ),
    );
  }

  Future<({List<AgentProcessEvent> events, _Loop loop})> run(_Gate gate) async {
    final tempDir = Directory.systemTemp.createTempSync('cc_harness_pool_');
    addTearDown(() => deleteDirBestEffort(tempDir));
    final loop = _Loop();
    final session = DispatchSession(
      deps: SandboxDispatchDeps(
        sandbox: _NoopSandbox(),
        broker: _NoopBroker(),
        agentRepo: _UnusedAgentRepo(),
        runLogRepo: _UnusedRunLogRepo(),
        eventBus: null,
        backendRegistry: BackendRegistry({
          'cc-harness': const HarnessBackend(),
        }),
        harnessCredentialStore: _OneKeyStore(),
        harnessProviderFactory: const HarnessProviderFactory(),
        agentLoop: loop,
        credentialGate: gate,
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
      cliName: 'cc-harness',
      prompt: 'hello',
      agentDirHostPath: tempDir.path,
      modelId: 'openai/test-model',
      callerEnv: const {},
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      conversationId: 'conv-1',
      runLogId: 'run-1',
      mode: Mode.chat,
      onResolveHarnessRotation: pool,
    );
    final events = <AgentProcessEvent>[];
    final sub = session.controller.stream.listen(events.add);
    await session.run();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();
    return (events: events, loop: loop);
  }

  test('a pool of removed keys holds the run, never the key left', () async {
    final gate = _Gate();
    final result = await run(gate);

    // Even with ONE key stored the pool is asked, and its refusal stands.
    expect(asked, isNotEmpty);
    expect(asked.first, hasLength(1));
    expect(gate.requests.single.lane, RunCredentialLane.harness);
    expect(gate.requests.single.reason, RunCredentialReason.accountsRemoved);
    expect(gate.requests.single.providerId, 'openai');
    expect(result.loop.runs, 0, reason: 'nothing ran on the leftover key');
    final error = _harnessErrors(result.events).single;
    expect(error.content, contains('has been removed from the server'));
  });

  test('fixing the pool while held resumes the same run', () async {
    final gate = _Gate(fix: () => poolFixed = true);
    final result = await run(gate);

    expect(gate.requests, hasLength(1));
    expect(result.loop.runs, 1);
    expect(_harnessErrors(result.events), isEmpty);
  });
}

/// The run's own failures, without the run-log bookkeeping this harness's
/// stub repository provokes.
Iterable<ErrorEvent> _harnessErrors(List<AgentProcessEvent> events) =>
    events.whereType<ErrorEvent>().where((e) => e.source == 'harness');
