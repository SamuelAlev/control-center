import 'dart:io';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
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

/// Pins the steering delivery gate on [DispatchSession.steer]: a message is
/// only accepted while a built-in harness loop is actually driving the
/// session. The regression this guards: `steerDispatch` used to return true
/// for ANY live session, so steering a `claude -p` run showed a "delivered"
/// toast while the text sat in a queue no one-shot process would ever read.
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
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _KeylessStore implements ProviderCredentialStore {
  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      ProviderCredential(
        providerId: providerId,
        method: HarnessAuthMethod.none,
        baseUrl: 'http://127.0.0.1:1',
      );

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async => [
    (await activeCredential(providerId))!,
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ScriptedLoop implements AgentLoop {
  _ScriptedLoop(this.script);

  final List<AgentLoopEvent> script;

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
  }) => Stream.fromIterable(script);
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cc_steer_gate_');
    addTearDown(() => deleteDirBestEffort(tempDir));
  });

  DispatchSession buildSession({void Function()? onHarnessStarted}) {
    final deps = SandboxDispatchDeps(
      sandbox: _NoopSandbox(),
      broker: _NoopBroker(),
      agentRepo: _UnusedAgentRepo(),
      runLogRepo: _UnusedRunLogRepo(),
      defaultCaps: AgentCapabilities.safeDefault,
      eventBus: null,
      backendRegistry: BackendRegistry({'cc-harness': const HarnessBackend()}),
      harnessCredentialStore: _KeylessStore(),
      harnessProviderFactory: const HarnessProviderFactory(),
      agentLoop: _ScriptedLoop(const [LoopDone(LoopDoneReason.completed)]),
    );
    final session = DispatchSession(
      deps: deps,
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
      prompt: 'do the thing',
      agentDirHostPath: tempDir.path,
      modelId: 'openai/test-model',
      callerEnv: const {},
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      conversationId: 'conv-1',
      spaceId: 'space-1',
      runLogId: 'run-1',
      mode: Mode.chat,
    );
    session.onHarnessStarted = onHarnessStarted;
    return session;
  }

  test(
    'steer is refused (and enqueues nothing) before the harness runs',
    () async {
      final session = buildSession();
      // The exact shape of the regression: the session EXISTS (a live dispatch,
      // as far as the adapter's map is concerned) but no harness loop is
      // driving it — the external-CLI transport state.
      final accepted = session.steer('nudge');
      expect(accepted, isFalse);
      expect(session.steeringQueue.isEmpty, isTrue);
    },
  );

  test('steer is refused for blank content even mid-harness', () async {
    var midRunAccepted = true;
    final session = buildSession();
    session.onHarnessStarted = () {
      midRunAccepted = session.steer('   ');
    };
    await session.run();
    expect(midRunAccepted, isFalse);
    expect(session.steeringQueue.isEmpty, isTrue);
  });

  test('steer is accepted while a harness loop drives the session', () async {
    var midRunAccepted = false;
    var midRunHarnessActive = false;
    final session = buildSession();
    session.onHarnessStarted = () {
      midRunHarnessActive = session.isHarnessActive;
      midRunAccepted = session.steer('nudge');
    };
    await session.run();
    expect(midRunHarnessActive, isTrue);
    expect(midRunAccepted, isTrue);
    // The queue is drained by the loop at its next turn boundary; this
    // scripted loop completes without one, so the message stays queued —
    // that is the queue's contract, not a leak.
    expect(session.isHarnessActive, isFalse, reason: 'run finished');
  });
}
