import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        AgentRunGateway,
        AgentRunGrant,
        AgentRunLease,
        CcInfraLog,
        CcInfraLogLevel;
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_server_core/src/server_mcp_control.dart';
import 'package:test/test.dart';

/// A run's secret on the server's MCP endpoint, wired the way the runtime
/// wires it (`ServerMcpControl.attestRun = AgentRunGateway.mcpScopeFor`):
/// an agent CLI's run connects with the server map it is handed and gets its
/// scope and its tools; a run whose tools are served in process (the built-in
/// harness) gets nothing for its secret, and the refusal is in the server log
/// with the run named, once per run. The same for Claude Code's hook route on
/// the same listener: only a run whose Claude Code has the hook installed is
/// answered there.
void main() {
  late Directory tmp;
  late _Tool tool;
  late ServerMcpControl control;
  late AgentRunGateway gateway;
  late List<String> warnings;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('cc_run_mcp_endpoint_');
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();
    tool = _Tool();
    control = ServerMcpControl(
      dispatcher: McpToolDispatcher(registry: McpToolRegistry([tool])),
      dataDir: tmp.path,
      companionPort: port,
    );
    gateway = AgentRunGateway(
      guard: ActionGuardService(
        repository: _NoRules(),
        confirmationPort: _NoApprover(),
      ),
      broker: _NoBroker(),
      loopbackBase: () async => Uri.parse('http://127.0.0.1:$port'),
    );
    control
      ..agentRoutes = gateway.handle
      ..attestRun = gateway.mcpScopeFor;
    warnings = [];
    final previous = CcInfraLog.sink;
    CcInfraLog.sink = (level, message, [error, stackTrace]) {
      if (level == CcInfraLogLevel.warning) {
        warnings.add(message);
      }
    };
    addTearDown(() => CcInfraLog.sink = previous);
  });

  tearDown(() async {
    await control.dispose();
    tmp.deleteSync(recursive: true);
  });

  Future<AgentRunLease> open({
    required bool mcpEndpoint,
    bool claudeHook = false,
    String? runId,
  }) async {
    final lease = (await gateway.open(
      AgentRunGrant(
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
        runId: runId,
        mcpEndpoint: mcpEndpoint,
        claudeHook: claudeHook,
        readOnly: false,
      ),
    ))!;
    addTearDown(() => gateway.close(lease));
    return lease;
  }

  /// Sends [method] with the server map a run of [lease] is handed, as an
  /// agent CLI would: the JSON-RPC result, or the HTTP status of a refusal.
  Future<Object> send(
    AgentRunLease lease,
    String method, [
    Map<String, Object?> params = const {},
  ]) async {
    final server =
        (await control.agentMcpServersForDispatch(
              runToken: lease.secret,
            ))!['control-center']!
            as Map<String, dynamic>;
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(server['url'] as String));
      request.headers.contentType = ContentType.json;
      (server['headers'] as Map).cast<String, String>().forEach(
        request.headers.set,
      );
      request.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': method,
          'params': params,
        }),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        return response.statusCode;
      }
      return (jsonDecode(body) as Map<String, dynamic>)['result'] as Object;
    } finally {
      client.close();
    }
  }

  /// Posts a PreToolUse request with [lease]'s secret to the hook route on
  /// the listener the run dials: the HTTP status.
  Future<int> hook(AgentRunLease lease) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        lease.base.replace(path: AgentRunGateway.hookPath),
      );
      request.headers.set(AgentRunLease.tokenHeader, lease.secret);
      request.write(jsonEncode({'tool_name': 'none'}));
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode;
    } finally {
      client.close();
    }
  }

  test("an agent CLI's run gets its scope and its tools", () async {
    final cli = await open(
      mcpEndpoint: true,
      claudeHook: true,
      runId: 'dispatch-cli',
    );

    final listed = await send(cli, 'tools/list') as Map<String, dynamic>;
    final names = [for (final t in listed['tools'] as List) (t as Map)['name']];
    expect(names, contains('probe'));

    final called =
        await send(cli, 'tools/call', {'name': 'probe', 'arguments': {}})
            as Map<String, dynamic>;
    expect(called['isError'], isNot(isTrue));
    // The scope the secret proves, not anything the call said.
    expect(tool.calls.single['workspace_id'], 'ws-1');
    // Claude Code's hook is answered (a denial of a request that is no Bash
    // call), not refused as an unknown run.
    expect(await hook(cli), HttpStatus.ok);
    expect(warnings, isEmpty);
  });

  test('an agent CLI without the hook gets its tools but not the hook '
      'route', () async {
    final acp = await open(mcpEndpoint: true, runId: 'dispatch-acp');

    final listed = await send(acp, 'tools/list') as Map<String, dynamic>;
    expect(
      [for (final t in listed['tools'] as List) (t as Map)['name']],
      ['probe'],
    );
    expect(await hook(acp), HttpStatus.unauthorized);
    expect(await hook(acp), HttpStatus.unauthorized);
    expect(warnings, hasLength(1));
    expect(warnings.single, contains(AgentRunGateway.hookPath));
  });

  test("a harness run's secret gets nothing, and the server log says "
      'which run and why', () async {
    final harness = await open(mcpEndpoint: false, runId: 'dispatch-harness');

    expect(await send(harness, 'tools/list'), HttpStatus.unauthorized);
    expect(
      await send(harness, 'tools/call', {'name': 'probe', 'arguments': {}}),
      HttpStatus.unauthorized,
    );
    expect(await hook(harness), HttpStatus.unauthorized);
    expect(await hook(harness), HttpStatus.unauthorized);
    expect(tool.calls, isEmpty);
    // Once per run and route, not per request.
    expect(warnings, hasLength(2));
    expect(
      warnings,
      everyElement(
        allOf(
          contains('dispatch-harness'),
          contains('ws-1'),
          contains('its agent does not use that route'),
        ),
      ),
    );
    expect(warnings.first, contains('/mcp'));
    expect(warnings.last, contains(AgentRunGateway.hookPath));
  });
}

/// Records the arguments it ran with.
class _Tool extends McpTool {
  final List<Map<String, dynamic>> calls = [];

  @override
  String get name => 'probe';

  @override
  String get description => 'Probe.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    calls.add(arguments);
    return CallResult.success('ok');
  }
}

class _NoBroker implements CredentialBrokerPort {
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
