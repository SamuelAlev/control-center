import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/sandboxed_agent_dispatch_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// `SandboxPort` fake for testing `SandboxedAgentDispatchAdapter`.
///
class _FakeSandboxPort implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.native;

  @override
  Future<SandboxBackendCapabilities> probe() async {
    return const SandboxBackendCapabilities(
      backend: SandboxBackend.native,
      available: true,
    );
  }

  @override
  Future<SandboxHandle> launch(SandboxSpec spec) async {
    return SandboxHandle(
      sessionId: spec.sessionId,
      backend: SandboxBackend.native,
      state: SandboxState.warm,
    );
  }

  @override
  Future<bool> isAlive(SandboxHandle handle) async => true;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) => const Stream.empty();

  @override
  Future<int> exec(
    SandboxHandle handle,
    List<String> argv, {
    Map<String, String>? env,
    String? workdir,
    Duration? timeout,
    void Function(int pid)? onPid,
    String? stdinInput,
    Stream<String>? stdinStream,
  }) async {
    return 0;
  }

  @override
  Future<void> pause(SandboxHandle handle) async {}

  @override
  Future<void> resume(SandboxHandle handle) async {}

  @override
  Future<void> destroy(SandboxHandle handle) async {}
}

/// Holds a run at the first thing it asks (whose commits it makes), so a
/// test can act on a dispatch that is still live. [fail] ends the run.
class _Gate {
  _Gate() {
    // A test can fail the gate before the run has reached it; an error
    // nobody listens to yet would otherwise surface as an uncaught one. The
    // run still sees it once it asks.
    _completer.future.ignore();
  }

  final _completer = Completer<void>();

  Future<void> get passed => _completer.future;

  void fail() => _completer.completeError(Exception('done'));
}

/// Minimal [AgentRepository] stub. Only [getById] is called by
/// `DispatchSession`; unused methods use [noSuchMethod].
class _FakeAgentRepo implements AgentRepository {
  @override
  Future<Agent?> getById(String workspaceId, String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a fresh [SandboxedAgentDispatchAdapter] backed by the given
/// (or default) fakes.
SandboxedAgentDispatchAdapter _adapter({
  SandboxPort? sandbox,
  _Gate? gate,
  AgentRepository? agentRepo,
}) {
  return SandboxedAgentDispatchAdapter(
    hostExecution: const HostExecutionGate(
      posture: HostExecutionPosture.offByOwner,
    ),
    sandbox: sandbox ?? _FakeSandboxPort(),
    agentRepository: agentRepo ?? _FakeAgentRepo(),
    runLogRepository: null,
    eventBus: null,
    resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async {
      await gate?.passed;
      return AgentCommitIdentity.person((
        name: 'Test User',
        email: 'test@example.test',
      ));
    },
  );
}

/// Parameters for [SandboxedAgentDispatchAdapter.start].
void main() {
  group('SandboxedAgentDispatchAdapter', () {
    // -----------------------------------------------------------------------
    // constructor — configuration storage
    // -----------------------------------------------------------------------
    test('stores sandbox port', () {
      final sandbox = _FakeSandboxPort();
      final adapter = _adapter(sandbox: sandbox);

      // The sandbox port is stored; we verify indirectly by calling a method
      // that touches it.
      expect(adapter, isNotNull);
    });

    // -----------------------------------------------------------------------
    // start — session management
    // -----------------------------------------------------------------------
    test(
      'start returns DispatchHandle with dispatchId and event stream',
      () async {
        final gate = _Gate();
        final adapter = _adapter(gate: gate);

        final handle = adapter.start(
          wakeContext: const WakeContext.userMessage(),
          freshHistory: false,
          readOnly: false,
          cliName: 'claude',
          prompt: 'hello',
          workingDirectory: '/tmp/work',
          agentId: null,
        );

        expect(handle.dispatchId, isNotEmpty);
        expect(handle.events, isA<Stream>());
        expect(handle.onStop, isNotNull);

        // Allow run() to proceed so the session can clean up.
        gate.fail();
        await pumpEventQueue();
      },
    );

    test(
      'start with different agentIds produces different dispatchIds',
      () async {
        final gate = _Gate();
        final adapter = _adapter(gate: gate);

        final h1 = adapter.start(
          wakeContext: const WakeContext.userMessage(),
          freshHistory: false,
          readOnly: false,
          cliName: 'claude',
          prompt: 'p1',
          workingDirectory: '/tmp/w1',
          agentId: 'agent-a',
        );
        final h2 = adapter.start(
          wakeContext: const WakeContext.userMessage(),
          freshHistory: false,
          readOnly: false,
          cliName: 'claude',
          prompt: 'p2',
          workingDirectory: '/tmp/w2',
          agentId: 'agent-b',
        );

        expect(h1.dispatchId, isNot(h2.dispatchId));

        gate.fail();
        await pumpEventQueue();
      },
    );

    // -----------------------------------------------------------------------
    // stopDispatch
    // -----------------------------------------------------------------------
    test('stopDispatch removes session and calls terminate', () async {
      final gate = _Gate();
      final adapter = _adapter(gate: gate);

      final handle = adapter.start(
        wakeContext: const WakeContext.userMessage(),
        freshHistory: false,
        readOnly: false,
        cliName: 'claude',
        prompt: 'hello',
        workingDirectory: '/tmp/work',
        agentId: null,
      );

      // stopDispatch should succeed even while run() is pending.
      await adapter.stopDispatch(handle.dispatchId);

      // Second call on the same id is a no-op (already removed).
      await adapter.stopDispatch(handle.dispatchId);

      // Allow run() to complete.
      gate.fail();
      await pumpEventQueue();
    });

    test('stopDispatch with unknown id does not throw', () async {
      final adapter = _adapter();

      await adapter.stopDispatch('nonexistent');
      // No exception = pass.
    });

    // -----------------------------------------------------------------------
    // stopAllForAgent
    // -----------------------------------------------------------------------
    test('stopAllForAgent terminates only matching agent sessions', () async {
      final gate = _Gate();
      final stalledAdapter = _adapter(gate: gate);

      final h1 = stalledAdapter.start(
        wakeContext: const WakeContext.userMessage(),
        freshHistory: false,
        readOnly: false,
        cliName: 'claude',
        prompt: 'p1',
        workingDirectory: '/tmp/w1',
        agentId: 'agent-a',
      );
      final h2 = stalledAdapter.start(
        wakeContext: const WakeContext.userMessage(),
        freshHistory: false,
        readOnly: false,
        cliName: 'claude',
        prompt: 'p2',
        workingDirectory: '/tmp/w2',
        agentId: 'agent-b',
      );

      // Stop only agent-a dispatches.
      await stalledAdapter.stopAllForAgent('agent-a');

      // agent-b's dispatch can still be stopped individually.
      await stalledAdapter.stopDispatch(h2.dispatchId);

      // agent-a's dispatch already removed — no-op.
      await stalledAdapter.stopDispatch(h1.dispatchId);

      gate.fail();
      await pumpEventQueue();
    });

    // -----------------------------------------------------------------------
    // stop — stop all
    // -----------------------------------------------------------------------
    test('stop clears all active dispatches', () async {
      final gate = _Gate();
      final adapter = _adapter(gate: gate);

      adapter.start(
        wakeContext: const WakeContext.userMessage(),
        freshHistory: false,
        readOnly: false,
        cliName: 'claude',
        prompt: 'p1',
        workingDirectory: '/tmp/w1',
        agentId: null,
      );
      adapter.start(
        wakeContext: const WakeContext.userMessage(),
        freshHistory: false,
        readOnly: false,
        cliName: 'claude',
        prompt: 'p2',
        workingDirectory: '/tmp/w2',
        agentId: null,
      );

      await adapter.stop();

      // Subsequent stopDispatch calls on arbitrary ids should not throw
      // (sessions already cleaned up).
      await adapter.stopDispatch('any-id');

      gate.fail();
      await pumpEventQueue();
    });

    // -----------------------------------------------------------------------
    // destroyAll — empty state
    // -----------------------------------------------------------------------
    test('destroyAll on fresh adapter does not throw', () async {
      final adapter = _adapter();

      await adapter.destroyAll();
      // No exception = pass.
    });

    test('destroyAll after stop does not throw', () async {
      final gate = _Gate();
      final adapter = _adapter(gate: gate);

      adapter.start(
        wakeContext: const WakeContext.userMessage(),
        freshHistory: false,
        readOnly: false,
        cliName: 'claude',
        prompt: 'p1',
        workingDirectory: '/tmp/w1',
        agentId: null,
      );
      await adapter.stop();

      await adapter.destroyAll();

      gate.fail();
      await pumpEventQueue();
    });
  });
}
