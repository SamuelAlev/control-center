import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/sandboxed_agent_dispatch_adapter.dart';
import 'package:test/test.dart';

/// A warm sandbox keeps the posture it launched with, so it is reused only
/// for the same spec; and a shut-down adapter keeps nothing alive.
class _Sandbox implements SandboxPort {
  final launched = <SandboxSpec>[];
  final destroyed = <String>[];
  var _n = 0;

  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Future<SandboxHandle> launch(SandboxSpec spec) async {
    launched.add(spec);
    return SandboxHandle(
      sessionId: '${spec.sessionId}#${_n++}',
      backend: SandboxBackend.none,
      state: SandboxState.warm,
    );
  }

  @override
  Future<bool> isAlive(SandboxHandle handle) async =>
      !destroyed.contains(handle.sessionId);

  @override
  Future<void> destroy(SandboxHandle handle) async =>
      destroyed.add(handle.sessionId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Unused implements CredentialBrokerPort, AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Sandbox sandbox;
  late SandboxedAgentDispatchAdapter adapter;

  setUp(() {
    sandbox = _Sandbox();
    adapter = SandboxedAgentDispatchAdapter(
      hostExecution: const HostExecutionGate(
        posture: HostExecutionPosture.offByOwner,
      ),
      sandbox: sandbox,
      agentRepository: _Unused(),
    );
  });

  SandboxSpec spec({bool network = true}) => SandboxSpec(
    sessionId: 'agent-1::c1::chat',
    workspaceId: 'ws',
    agentId: 'agent-1',
    bindMounts: const [],
    networkEnabled: network,
  );

  Future<SandboxHandle> resolve(SandboxSpec s) => adapter
      .resolveHandleForTesting(sessionId: s.sessionId, spec: s, emit: (_) {});

  test('the same spec reuses the warm handle', () async {
    final a = await resolve(spec());
    final b = await resolve(spec());
    expect(b, same(a));
    expect(sandbox.launched, hasLength(1));
  });

  test(
    'a changed posture tears the old sandbox down and starts fresh',
    () async {
      final open = await resolve(spec());
      final closed = await resolve(spec(network: false));
      expect(closed.sessionId, isNot(open.sessionId));
      expect(sandbox.destroyed, [open.sessionId]);
      expect(sandbox.launched.last.networkEnabled, isFalse);
    },
  );

  test('shutdown destroys warm sandboxes and refuses new ones', () async {
    final warm = await resolve(spec());
    await adapter.shutdown();
    expect(sandbox.destroyed, [warm.sessionId]);
    await expectLater(resolve(spec()), throwsStateError);
    expect(
      () => adapter.start(
        wakeContext: const WakeContext.userMessage(),
        freshHistory: false,
        readOnly: false,
        cliName: 'cc-harness',
        prompt: 'p',
        workingDirectory: '/tmp',
      ),
      throwsStateError,
    );
  });
}
