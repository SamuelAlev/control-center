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
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:clock/clock.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// The silence watchdog and a parked harness loop: a loop waiting on its own
/// background command makes no model call and prints nothing, by design, so
/// no silence stop fires however long the park lasts, and the silence window
/// starts again when the park ends. Time is `clock` (package:clock) moved by
/// the test; the watchdog checks every few milliseconds.

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

/// Keyless credential so the harness path clears its auth gate without a secret.
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
  Future<void> save(ProviderCredential credential) async {}

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {}
}

/// A loop whose events [body] produces, with the run's cancel token.
class _Loop implements AgentLoop {
  _Loop(this.body);

  final Stream<AgentLoopEvent> Function(CancellationToken cancel) body;

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
  }) => body(cancel ?? CancellationToken.none);
}

DispatchSession _session(_Loop loop) {
  final tempDir = Directory.systemTemp.createTempSync('cc_park_watchdog_');
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
      runLogRepo: _UnusedRunLogRepo(),
      eventBus: null,
      resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
          AgentCommitIdentity.person((
            name: 'Test User',
            email: 'test@example.test',
          )),
      backendRegistry: BackendRegistry({'cc-harness': const HarnessBackend()}),
      harnessCredentialStore: _KeylessStore(),
      harnessProviderFactory: const HarnessProviderFactory(),
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
    cliName: 'cc-harness',
    prompt: 'run the tests in the background',
    agentDirHostPath: tempDir.path,
    modelId: 'openai/test-model',
    callerEnv: const {},
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    runLogId: 'run-1',
    mode: Mode.chat,
    // A one-minute threshold: the park below lasts an hour.
    silenceTimeoutMinutes: 1,
  )..silenceCheckEvery = const Duration(milliseconds: 5);
}

/// Lets the watchdog tick a few times in real time.
Future<void> _ticks() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  test('no silence stop during an hour-long park; the window restarts when '
      'the park ends', () async {
    var now = DateTime(2026, 11, 19, 9);
    late DispatchSession session;
    bool? parkedSeen;
    bool? heldThroughPark;
    bool? heldJustAfter;
    bool? firedAfterWindow;
    final events = <AgentProcessEvent>[];
    session = _session(
      _Loop((cancel) async* {
        // As the CLI lanes do once their process is up.
        session.startSilenceWatchdog();
        yield const LoopPark(parked: true, reason: 'background command b1');
        parkedSeen = session.parked;
        // An hour (the longest a background command may run) of nothing.
        for (var minute = 0; minute < 60; minute++) {
          now = now.add(const Duration(minutes: 1));
          await _ticks();
        }
        heldThroughPark = !cancel.isCancelled;
        yield const LoopPark(parked: false, reason: 'background command b1');
        // 40 s after the park ended: inside the one-minute window, which
        // counts from the park's end, not from the run's start.
        now = now.add(const Duration(seconds: 40));
        await _ticks();
        heldJustAfter = !cancel.isCancelled;
        // 70 s after: the window is up and the watchdog stops the run.
        now = now.add(const Duration(seconds: 30));
        for (var i = 0; i < 100 && !cancel.isCancelled; i++) {
          await _ticks();
        }
        firedAfterWindow = cancel.isCancelled;
        yield const LoopDone(LoopDoneReason.cancelled);
      }),
    );
    final sub = session.controller.stream.listen(events.add);
    await withClock(
      Clock(() => now),
      () => session.run(),
    ).timeout(const Duration(seconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();

    expect(parkedSeen, isTrue);
    expect(heldThroughPark, isTrue, reason: 'no silence stop while parked');
    expect(heldJustAfter, isTrue, reason: 'the window restarts at park end');
    expect(firedAfterWindow, isTrue, reason: 'silence after the park counts');
    expect(session.parked, isFalse);
    expect(
      events.whereType<DebugEvent>().map((e) => e.content),
      contains(
        '[harness] waiting for background command b1 to finish before the '
        'turn ends (no model call meanwhile).',
      ),
    );
  });

  test('the built-in harness lane starts no silence watchdog at all', () async {
    late DispatchSession session;
    bool? noTimer;
    session = _session(
      _Loop((cancel) async* {
        yield const LoopPark(parked: true, reason: 'background command b1');
        noTimer = session.silenceTimer == null && session.parked;
        yield const LoopPark(parked: false, reason: 'background command b1');
        yield const LoopDone(LoopDoneReason.completed);
      }),
    );
    final sub = session.controller.stream.listen((_) {});
    await session.run().timeout(const Duration(seconds: 30));
    await sub.cancel();
    expect(noTimer, isTrue);
  });
}
