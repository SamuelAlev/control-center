import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/backend_registry.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// Which runs the agent run gateway lets prove themselves on the MCP
/// endpoint (`AgentRunGrant.mcpEndpoint`) and on Claude Code's hook route
/// (`AgentRunGrant.claudeHook`), as the dispatch session decides it when it
/// opens the run's lease, asked of the real gateway with the run's secret.
///
/// Only a run whose tools are served in process (the built-in harness) is
/// refused `/mcp`: its secret opening it would let a command it runs call
/// tools outside the harness gate. Every other backend is an agent CLI handed
/// the endpoint, and a wrong answer there silently takes every MCP tool from
/// its runs. Only Claude Code installs the hook, so only its runs are
/// answered on the hook route. The backends are the ones the server's
/// registry builds, not a list written here, so a backend added later is
/// covered or fails.
void main() {
  /// What the real gateway answers the secret of a run of [cliName] on each
  /// route, with the grant the session opened the run's lease with.
  Future<({bool mcp, bool hook})> answersFor(
    BackendRegistry registry,
    String cliName,
  ) async {
    final gateway = _OpeningGateway();
    final dir = Directory.systemTemp.createTempSync('cc_mcp_endpoint_');
    addTearDown(() => deleteDirBestEffort(dir));
    final session = DispatchSession(
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
        backendRegistry: registry,
        agentRunGateway: gateway,
      ),
      onResolveHandle:
          ({required String sessionId, required spec, required emit}) async =>
              SandboxHandle(
                sessionId: sessionId,
                backend: SandboxBackend.none,
                state: SandboxState.warm,
              ),
      onScheduleCooldown: (_) {},
      dispatchId: 'd1',
      cliName: cliName,
      prompt: 'do the thing',
      agentDirHostPath: dir.path,
      modelId: null,
      callerEnv: const {},
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      conversationId: 'conv-1',
      runLogId: 'run-1',
      mode: Mode.chat,
    );
    await session.run();
    final answers = gateway.answers.single;
    expect(answers.mcp, gateway.grants.single.mcpEndpoint);
    expect(answers.hook, gateway.grants.single.claudeHook);
    return answers;
  }

  test('every backend the server registers: only a run whose tools are '
      'served in process is refused the MCP endpoint, and only a Claude Code '
      'run is answered on the hook route', () async {
    final registry = buildBackendRegistry();
    final cliNames = {for (final a in predefinedAdapters) a.cliName};
    expect(cliNames, isNotEmpty);
    final inProcess = <String>{};
    final endpoint = <String>{};
    final hooked = <String>{};
    for (final cliName in cliNames) {
      final backend = registry.backendFor(cliName);
      expect(backend, isNotNull, reason: cliName);
      final answers = await answersFor(registry, cliName);
      expect(
        answers.mcp,
        backend is! HarnessBackend,
        reason: '$cliName (${backend!.transport.name})',
      );
      expect(
        answers.hook,
        backend.transport == AdapterTransport.claudeCli,
        reason: '$cliName (${backend.transport.name})',
      );
      (answers.mcp ? endpoint : inProcess).add(cliName);
      if (answers.hook) {
        hooked.add(cliName);
      }
    }
    // Both kinds ship: the harness, and at least the Claude CLI.
    expect(inProcess, contains('cc-harness'));
    expect(endpoint, contains('claude'));
    expect(hooked, {'claude'});
  });

  test('every transport decides, a new one included', () async {
    // A transport added later has no entry here and fails until someone
    // decides whether its agent is handed the endpoint.
    const handedTheEndpoint = {
      AdapterTransport.acp: (mcp: true, hook: false),
      AdapterTransport.claudeCli: (mcp: true, hook: true),
      AdapterTransport.harness: (mcp: false, hook: false),
    };
    for (final transport in AdapterTransport.values) {
      expect(handedTheEndpoint, contains(transport), reason: transport.name);
      final registry = buildBackendRegistry(
        adapters: [
          Adapter(
            id: 'x',
            name: 'X',
            description: '',
            cliName: 'x-cli',
            transport: transport,
            acpArgs: transport == AdapterTransport.acp ? 'acp' : null,
          ),
        ],
      );
      expect(
        await answersFor(registry, 'x-cli'),
        handedTheEndpoint[transport],
        reason: transport.name,
      );
    }
  });

  test('a run of a backend nobody registered proves nothing', () async {
    expect(await answersFor(BackendRegistry(const {}), 'unknown-cli'), (
      mcp: false,
      hook: false,
    ));
  });
}

/// Records the grant a session opens its lease with, opens it for real and
/// asks itself with the new secret on both routes, then stops the run there:
/// nothing past the lease (a CLI, a sandbox) is started.
class _OpeningGateway extends AgentRunGateway {
  _OpeningGateway()
    : super(
        guard: ActionGuardService(
          repository: _NoRules(),
          confirmationPort: _NoApprover(),
        ),
        broker: _NoBroker(),
        loopbackBase: () async => Uri.parse('http://127.0.0.1:9'),
      );

  final List<AgentRunGrant> grants = [];
  final List<({bool mcp, bool hook})> answers = [];

  @override
  Future<AgentRunLease?> open(AgentRunGrant grant) async {
    grants.add(grant);
    final lease = (await super.open(grant))!;
    try {
      answers.add((
        mcp: mcpScopeFor(lease.secret) != null,
        hook: await _hookAnswers(lease.secret),
      ));
    } finally {
      await close(lease);
    }
    throw StateError('stopped at the lease');
  }

  /// Whether the hook route answers [secret] at all: a refused run gets 401
  /// as a secret that names no run; an answered one gets the hook's verdict
  /// (here a denial of a request that is not a Bash call).
  Future<bool> _hookAnswers(String secret) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(handle);
    final client = HttpClient();
    try {
      final request = await client.post(
        InternetAddress.loopbackIPv4.address,
        server.port,
        AgentRunGateway.hookPath,
      );
      request.headers.set(AgentRunLease.tokenHeader, secret);
      request.write(jsonEncode({'tool_name': 'none'}));
      final response = await request.close();
      await response.drain<void>();
      expect(
        response.statusCode,
        anyOf(HttpStatus.ok, HttpStatus.unauthorized),
      );
      return response.statusCode == HttpStatus.ok;
    } finally {
      client.close(force: true);
      await server.close(force: true);
    }
  }
}

class _NoopSandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoBroker implements CredentialBrokerPort {
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

class _NoRules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoApprover implements ConfirmationPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
