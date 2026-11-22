import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/server_mcp_registry_fixture.dart';
import '../helpers/test_database.dart';

/// `search_tool_bm25` on the MCP endpoint tells the truth to its caller: a
/// run with scripts learns which hits it calls from a script, and every
/// other caller may call every hit directly.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late ReplMcpTool repl;
  late McpToolDispatcher dispatcher;

  setUp(() {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    repl = ReplMcpTool(
      executions: _NoScripts(),
      limitsFor: (_) async => CodeModeLimits.defaults,
      records: _NoRecords(),
      past: null,
    );
    dispatcher = McpToolDispatcher(
      registry: buildTestServerMcpRegistry(
        global: global,
        dbs: dbs,
        repl: repl,
      ),
    );
    repl.bind(dispatcher);
  });
  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  McpCallScope run(String runLogId) => McpCallScope(
    workspaceId: 'ws-1',
    agentId: 'agent-1',
    conversationId: 'conv-1',
    spaceId: 'space-1',
    attested: true,
    runId: 'dispatch-1',
    runLogId: runLogId,
  );

  /// The text of [result]'s first content piece.
  String textOf(Map<String, dynamic> result) =>
      ((result['content'] as List).first as Map)['text'] as String;

  Future<Map<String, dynamic>> call(
    McpCallScope scope,
    String name, [
    Map<String, dynamic> arguments = const {},
  ]) async {
    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(
        method: 'tools/call',
        params: {'name': name, 'arguments': arguments},
        id: 2,
      ),
      scope: scope,
    );
    return response['result'] as Map<String, dynamic>;
  }

  Future<Set<String>> listed(McpCallScope scope) async {
    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(method: 'tools/list', params: const {}, id: 1),
      scope: scope,
    );
    return {
      for (final t in (response['result'] as Map)['tools'] as List)
        (t as Map)['name'] as String,
    };
  }

  Future<Map<String, dynamic>> search(McpCallScope scope) async {
    final result = await call(scope, 'search_tool_bm25', {
      'query': 'list agents tickets memory repos skills messages',
      'limit': 60,
    });
    expect(result['isError'], isFalse);
    return jsonDecode(textOf(result)) as Map<String, dynamic>;
  }

  test('a run with scripts: a hit not marked script_only is in its list, '
      'and a script_only hit is redirected when called directly', () async {
    final scope = run('log-1');
    final tools = await listed(scope);
    expect(tools, contains('repl'));
    final answer = await search(scope);
    final hits = (answer['tools'] as List).cast<Map<String, dynamic>>();
    final scriptOnly = [
      for (final h in hits)
        if (h['script_only'] == true) h['name'] as String,
    ];
    final direct = [
      for (final h in hits)
        if (h['script_only'] == false) h['name'] as String,
    ];
    // Every hit says which it is, and both kinds occur.
    expect(scriptOnly.length + direct.length, hits.length);
    expect(scriptOnly, isNotEmpty);
    for (final name in direct) {
      expect(tools, contains(name), reason: name);
    }
    for (final name in scriptOnly) {
      expect(tools, isNot(contains(name)), reason: name);
      final called = await call(scope, name);
      expect(called['isError'], isTrue, reason: name);
      expect(
        textOf(called),
        contains('is callable only from a script'),
        reason: name,
      );
    }
    expect(answer['note'], contains('`repl`'));
    expect(answer['note'], isNot(contains('Every hit is directly callable')));
    // Nothing it is not listed: no catalogue search among the hits.
    expect(answer['matches'], isNot(contains('list_my_tools')));
    expect(answer['matches'], isNot(contains('search_tool_bm25')));
  });

  test(
    'a run whose scripts were withdrawn may call every hit directly',
    () async {
      final scope = run('log-w');
      repl.withdrawn.add('log-w');
      final tools = await listed(scope);
      expect(tools, isNot(contains('repl')));
      final answer = await search(scope);
      final hits = (answer['tools'] as List).cast<Map<String, dynamic>>();
      expect(hits, isNotEmpty);
      for (final hit in hits) {
        expect(hit.containsKey('script_only'), isFalse);
        expect(tools, contains(hit['name']), reason: '${hit['name']}');
      }
      expect(answer['note'], 'Every hit is directly callable by its `name`.');
      // A hit a run with scripts would reach from a script runs directly.
      final called = await call(scope, 'list_agents', {'workspace_id': 'ws-1'});
      expect(
        '${called['content']}',
        isNot(contains('is callable only from a script')),
      );
    },
  );
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
