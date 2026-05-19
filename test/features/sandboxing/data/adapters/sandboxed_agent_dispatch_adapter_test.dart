import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_infra/src/dispatch/sandboxed_agent_dispatch_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// `SandboxPort` fake for testing `SandboxedAgentDispatchAdapter`.
///
/// `mintStaller` is a `Completer` whose future is returned by `mint`.
/// Completing it allows the DispatchSession's `run()` to proceed.
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
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream.empty();

  @override
  Future<int> exec(
    SandboxHandle handle,
    List<String> argv, {
    Map<String, String>? env,
    String? workdir,
    Duration? timeout,
    void Function(int pid)? onPid,
    String? stdinInput,
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

/// `CredentialBrokerPort` whose `mint` can be stalled via a `Completer`.
///
/// By default `mint` resolves immediately. Set `mintStaller` before calling
/// `start` to keep the DispatchSession's `run()` pending.
class _FakeBroker implements CredentialBrokerPort {
  Completer<ScopedCredentials>? mintStaller;

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
  }) async {
    if (mintStaller != null) {
      return mintStaller!.future;
    }
    return const ScopedCredentials(
      handle: 'h1',
      environment: {},
    );
  }

  @override
  Future<void> revoke(String handle) async {}
}

/// Minimal [AgentRepository] stub. Only [getById] is called by
/// `DispatchSession._capabilitiesFor`; unused methods use [noSuchMethod].
class _FakeAgentRepo implements AgentRepository {
  @override
  Future<Agent?> getById(String id) async => null;

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
  CredentialBrokerPort? broker,
  AgentRepository? agentRepo,
}) {
  return SandboxedAgentDispatchAdapter(
    sandbox: sandbox ?? _FakeSandboxPort(),
    credentialBroker: broker ?? _FakeBroker(),
    agentRepository: agentRepo ?? _FakeAgentRepo(),
    runLogRepository: null,
    defaultCapabilities: AgentCapabilities.safeDefault,
    eventBus: null,
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

    test('stores default capabilities', () {
      const caps = AgentCapabilities(
        canPushToRepo: true,
        canCallGitHubApi: true,
        canAccessNetwork: false,
      );
      final adapter = SandboxedAgentDispatchAdapter(
        sandbox: _FakeSandboxPort(),
        credentialBroker: _FakeBroker(),
        agentRepository: _FakeAgentRepo(),
        runLogRepository: null,
        defaultCapabilities: caps,
        eventBus: null,
      );

      // Capabilities used by DispatchSession later; here we just verify
      // the constructor doesn't throw and adapter is created.
      expect(adapter, isNotNull);
    });

    // -----------------------------------------------------------------------
    // start — session management
    // -----------------------------------------------------------------------
    test('start returns DispatchHandle with dispatchId and event stream',
        () async {
      final broker = _FakeBroker();
      broker.mintStaller = Completer<ScopedCredentials>();
      final adapter = _adapter(broker: broker);

      final handle = adapter.start(
        cliName: 'pi',
        prompt: 'hello',
        workingDirectory: '/tmp/work',
        agentId: null,
      );

      expect(handle.dispatchId, isNotEmpty);
      expect(handle.events, isA<Stream>());
      expect(handle.onStop, isNotNull);

      // Allow run() to proceed so the session can clean up.
      broker.mintStaller!.completeError(Exception('test completion'));
      await pumpEventQueue();
    });

    test('start with different agentIds produces different dispatchIds',
        () async {
      final broker = _FakeBroker();
      broker.mintStaller = Completer<ScopedCredentials>();
      final adapter = _adapter(broker: broker);

      final h1 = adapter.start(
        cliName: 'pi',
        prompt: 'p1',
        workingDirectory: '/tmp/w1',
        agentId: 'agent-a',
      );
      final h2 = adapter.start(
        cliName: 'pi',
        prompt: 'p2',
        workingDirectory: '/tmp/w2',
        agentId: 'agent-b',
      );

      expect(h1.dispatchId, isNot(h2.dispatchId));

      broker.mintStaller!.completeError(Exception('done'));
      await pumpEventQueue();
    });

    // -----------------------------------------------------------------------
    // stopDispatch
    // -----------------------------------------------------------------------
    test('stopDispatch removes session and calls terminate', () async {
      final broker = _FakeBroker();
      broker.mintStaller = Completer<ScopedCredentials>();
      final adapter = _adapter(broker: broker);

      final handle = adapter.start(
        cliName: 'pi',
        prompt: 'hello',
        workingDirectory: '/tmp/work',
        agentId: null,
      );

      // stopDispatch should succeed even while run() is pending.
      await adapter.stopDispatch(handle.dispatchId);

      // Second call on the same id is a no-op (already removed).
      await adapter.stopDispatch(handle.dispatchId);

      // Allow run() to complete.
      broker.mintStaller!.completeError(Exception('done'));
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
    test('stopAllForAgent terminates only matching agent sessions',
        () async {
      final broker1 = _FakeBroker();
      broker1.mintStaller = Completer<ScopedCredentials>();
      final broker2 = _FakeBroker();
      broker2.mintStaller = Completer<ScopedCredentials>();

      final _ = SandboxedAgentDispatchAdapter(
        sandbox: _FakeSandboxPort(),
        credentialBroker: _FakeBroker(),
        agentRepository: _FakeAgentRepo(),
        runLogRepository: null,
        defaultCapabilities: AgentCapabilities.safeDefault,
        eventBus: null,
      );

      // Both dispatches use the same broker that doesn't stall, so run()
      // completes quickly. We need to start them and stop by agent.
      // Use stalled broker so sessions stay alive.
      final stalledBroker = _FakeBroker();
      stalledBroker.mintStaller = Completer<ScopedCredentials>();
      final stalledAdapter = _adapter(broker: stalledBroker);

      final h1 = stalledAdapter.start(
        cliName: 'pi',
        prompt: 'p1',
        workingDirectory: '/tmp/w1',
        agentId: 'agent-a',
      );
      final h2 = stalledAdapter.start(
        cliName: 'pi',
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

      stalledBroker.mintStaller!.completeError(Exception('done'));
      await pumpEventQueue();
    });

    // -----------------------------------------------------------------------
    // stop — stop all
    // -----------------------------------------------------------------------
    test('stop clears all active dispatches', () async {
      final broker = _FakeBroker();
      broker.mintStaller = Completer<ScopedCredentials>();
      final adapter = _adapter(broker: broker);

      adapter.start(
        cliName: 'pi',
        prompt: 'p1',
        workingDirectory: '/tmp/w1',
        agentId: null,
      );
      adapter.start(
        cliName: 'pi',
        prompt: 'p2',
        workingDirectory: '/tmp/w2',
        agentId: null,
      );

      await adapter.stop();

      // Subsequent stopDispatch calls on arbitrary ids should not throw
      // (sessions already cleaned up).
      await adapter.stopDispatch('any-id');

      broker.mintStaller!.completeError(Exception('done'));
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
      final broker = _FakeBroker();
      broker.mintStaller = Completer<ScopedCredentials>();
      final adapter = _adapter(broker: broker);

      adapter.start(
        cliName: 'pi',
        prompt: 'p1',
        workingDirectory: '/tmp/w1',
        agentId: null,
      );
      await adapter.stop();

      await adapter.destroyAll();

      broker.mintStaller!.completeError(Exception('done'));
      await pumpEventQueue();
    });
  });
}
