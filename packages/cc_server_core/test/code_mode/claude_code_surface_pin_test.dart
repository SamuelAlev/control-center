import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/core/domain/ports/mode_resolver.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/cc_infra.dart' show ClaudeCliBackend;
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp/src/mcp_server_instructions.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart'
    show BridgedMcpTool, McpRemoteTool;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/server_mcp_registry_fixture.dart';
import '../helpers/test_database.dart';
import 'script_callable_pin_test.dart' show mcpScriptCallable;

/// What a Claude Code run gets from the server's real registry on the MCP
/// endpoint, in every mode: the tools it is asked to load upfront fit what
/// Claude Code keeps of an upfront description, its `initialize`
/// instructions fit what Claude Code keeps of them (and today's index is
/// whole), an external server cannot mark its own tools upfront, and every
/// tool the appended Claude Code prompt names is a real tool.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late _Modes modes;
  late McpToolRegistry registry;
  late McpToolDispatcher dispatcher;

  setUp(() {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    modes = _Modes();
    final repl = ReplMcpTool(
      executions: _NoScripts(),
      limitsFor: (_) async => CodeModeLimits.defaults,
      records: _NoRecords(),
      past: null,
    );
    registry = buildTestServerMcpRegistry(global: global, dbs: dbs, repl: repl);
    dispatcher = McpToolDispatcher(
      registry: registry,
      modeGuard: ModeToolGuard(modes),
    );
    repl.bind(dispatcher);
  });
  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  const run = McpCallScope(
    workspaceId: 'ws-1',
    agentId: 'agent-1',
    conversationId: 'conv-1',
    spaceId: 'space-1',
    attested: true,
    runId: 'dispatch-1',
    runLogId: 'log-1',
  );

  Future<List<Map<String, dynamic>>> listed([McpCallScope scope = run]) async {
    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(method: 'tools/list', params: const {}, id: 1),
      scope: scope,
    );
    return ((response['result'] as Map)['tools'] as List)
        .cast<Map<String, dynamic>>();
  }

  Future<String> instructions() async {
    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(method: 'initialize', params: const {}, id: 0),
      scope: run,
    );
    return (response['result'] as Map)['instructions'] as String;
  }

  for (final mode in Mode.values) {
    test('${mode.name}: every upfront description and the instructions fit '
        '${McpServerInstructions.maxChars} characters, and the index is '
        'whole', () async {
      modes.mode = mode;
      final upfront = [
        for (final t in await listed())
          if (t['_meta'] != null) t,
      ];
      expect(
        upfront.map((t) => t['name']),
        contains(ReplToolDescription.toolName),
      );
      final rows = <String>[];
      for (final t in upfront) {
        expect(t['_meta'], McpRunToolSurface.upfrontMeta);
        final description = t['description'] as String;
        expect(
          description.length,
          lessThanOrEqualTo(McpServerInstructions.maxChars),
          reason: '${t['name']}',
        );
        rows.add(
          '${t['name']} ${utf8.encode(jsonEncode(t)).length} B, '
          'description ${description.length} chars',
        );
      }
      final text = await instructions();
      expect(text, startsWith('Control Center tools for this run.'));
      expect(text.length, lessThanOrEqualTo(McpServerInstructions.maxChars));
      // The day the index starts cutting is noticed here.
      expect(text, isNot(contains('more, found with `searchTools`')));
      // ignore: avoid_print
      print(
        '${mode.name}: ${upfront.length} upfront\n  ${rows.join('\n  ')}\n'
        'instructions: ${text.length} chars\n$text\n',
      );
    });
  }

  test('an external server\'s _meta never reaches the listing', () async {
    final tool = BridgedMcpTool(
      serverName: 'tracker',
      remoteTool: McpRemoteTool.fromJson(const {
        'name': 'ask_user',
        'description': 'Asks.',
        'inputSchema': {'type': 'object'},
        '_meta': {'anthropic/alwaysLoad': true},
      }),
      invoker: (_, _, _) async => const {},
    );
    expect(tool.definition.toJson().containsKey('_meta'), isFalse);
    registry.setWorkspaceTools('ws-1', [tool]);
    // A run without scripts lists its external tools (one with scripts
    // reaches them from a script and does not list them).
    const noScripts = McpCallScope(
      workspaceId: 'ws-1',
      agentId: 'agent-1',
      conversationId: 'conv-1',
      spaceId: 'space-1',
      attested: true,
      runId: 'dispatch-1',
    );
    final entries = [
      for (final t in await listed(noScripts))
        if (t['name'] == tool.name) t,
    ];
    expect(entries, hasLength(1));
    expect(entries.single.containsKey('_meta'), isFalse);
    expect([
      for (final t in await listed()) t['name'],
    ], isNot(contains(tool.name)));
  });

  // The fixture registry holds only the tools that need no live services
  // (`open_pull_request` and `todo_read` are registered by the runtime), so
  // a name is checked against every MCP tool class's name as
  // `script_callable_pin_test.dart` reads it off its source.
  test('every tool the Claude Code prompt names is a real tool', () {
    final prompt = ClaudeCliBackend.appendedSystemPrompt(
      hasControlCenterMcp: true,
    );
    for (final name in ClaudeCliBackend.controlCenterToolNames) {
      expect(prompt, contains(name));
      expect(mcpScriptCallable, contains(name), reason: name);
    }
  });

  // The fixture holds a part of the tools. A real server's index is measured
  // here on every first-party tool a script may call, which is at least what
  // any one run is told.
  for (final mode in Mode.values) {
    test('${mode.name}: the index of every script-callable tool fits '
        '${McpServerInstructions.maxChars} characters and is whole', () {
      final direct = McpRunToolSurface.directNames(mode);
      final text = McpServerInstructions.forScripts([
        for (final MapEntry(key: name, value: callable)
            in mcpScriptCallable.entries)
          if (callable &&
              !direct.contains(name) &&
              ModeToolPolicy.isAllowed(name, mode))
            name,
      ]);
      expect(text.length, lessThanOrEqualTo(McpServerInstructions.maxChars));
      expect(text, isNot(contains('more, found with `searchTools`')));
    });
  }
}

/// Resolves every conversation to [mode].
class _Modes implements ModeResolver {
  Mode mode = Mode.chat;

  @override
  Future<Mode> resolveForConversation(
    String workspaceId,
    String? conversationId,
  ) async => mode;
}

class _NoScripts implements CodeExecutionPort {
  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.available();

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) => throw StateError('no scripts in this test');
}

class _NoRecords implements CodeExecutionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no scripts in this test');
}
