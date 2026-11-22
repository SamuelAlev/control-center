import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/server_mcp_registry_fixture.dart';
import 'helpers/test_database.dart';

/// Proves the headless `cc_server` now serves a REAL MCP tool surface over
/// `tools/list` — it used to mount `NoToolsRpcDispatcher` (method-not-found for
/// every tool call). The same `cc_mcp` tool classes the desktop registers are
/// constructed server-side from the server's own Drift-backed repositories.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
  });
  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test('server MCP dispatcher lists the data-backed tools', () async {
    McpToolRegistry build(ReplMcpTool? repl) =>
        buildTestServerMcpRegistry(global: global, dbs: dbs, repl: repl);
    final registry = build(null);
    final dispatcher = McpToolDispatcher(registry: registry);

    final response = await dispatcher.handleRequest(
      JsonRpcRequest(method: 'tools/list', params: const {}, id: 1),
    );

    final tools = (response['result'] as Map<String, dynamic>)['tools'] as List;
    final names = {for (final t in tools) (t as Map<String, dynamic>)['name']};

    // `tools/list` advertises the FULL catalogue. Discovery gating (essential
    // subset + hidden-but-callable lookup) was removed: external MCP clients
    // (Claude Code) validate calls against their cached
    // tools/list CLIENT-side, so every hidden tool — all agent writes included
    // (`todo_write`, `ticket_cli`, `propose_fact`, …) — was unreachable in
    // practice. The BM25 search tool remains as a catalogue navigation aid.
    expect(tools.length, greaterThanOrEqualTo(40));
    expect(names, contains('search_tool_bm25'));
    expect(
      names,
      containsAll(<String>[
        'list_workspaces',
        'render_media',
        'list_agents',
        'list_spaces',
        'get_messages',
        // Long instructed by prompts/mode-guard but historically never
        // registered server-side — now real.
        'send_message',
        // Claude addresses this as mcp__control-center__ask_user. Absent
        // from tools/list, ToolSearch reports it missing and the run guesses.
        'ask_user',
        'list_tickets',
        'get_ticket',
        // The per-conversation checklist agents plan with.
        'todo_write',
        // The pipeline output contract: server-run agents can now write their
        // structured output so the step resume listener can harvest + advance.
        'submit_output',
        // The write surface the old gating hid from every external client —
        // memory, governance, work products.
        'propose_fact',
        'propose_policy',
        'record_observation',
        'create_goal',
        'create_approval',
        'create_work_product',
        'list_repos',
        'list_articles',
        'list_goals',
        'agent_heartbeat',
        'get_org_chart',
      ]),
    );

    // The advertised list and the callable set are the SAME set: everything
    // listed resolves and the catalogue view matches the list.
    for (final name in names) {
      expect(
        registry.lookup(name as String, view: McpToolView.shared),
        isNotNull,
        reason: '$name listed but not resolvable',
      );
    }
    expect(
      registry.allToolDefinitions().map((d) => d.name).toSet(),
      names,
      reason: 'BM25 catalogue must mirror tools/list exactly',
    );

    // Code mode's `repl`, registered the way the runtime does it. It is a
    // tool only an attested agent run can see or call: a paired phone or a
    // person's token (no scope, or a scope that is not a run's) never gets
    // it.
    final withRepl = build(
      ReplMcpTool(
        executions: _NeverRuns(),
        limitsFor: (_) async => CodeModeLimits.defaults,
        records: _NoRecords(),
        past: null,
      ),
    );
    final replDispatcher = McpToolDispatcher(registry: withRepl);
    (withRepl.lookup('repl', view: McpToolView.shared)! as ReplMcpTool).bind(
      replDispatcher,
    );
    Future<Set<String>> listed(McpCallScope? scope) async {
      final response = await replDispatcher.handleScopedRequest(
        JsonRpcRequest(method: 'tools/list', params: const {}, id: 2),
        scope: scope,
      );
      return {
        for (final t
            in (response['result'] as Map<String, dynamic>)['tools'] as List)
          (t as Map<String, dynamic>)['name'] as String,
      };
    }

    McpCallScope scope({required bool attested}) => McpCallScope(
      workspaceId: 'ws-1',
      agentId: 'agent-1',
      conversationId: 'conv-1',
      spaceId: 'space-1',
      attested: attested,
      runId: 'dispatch-1',
      runLogId: 'log-1',
    );

    expect(await listed(null), names, reason: 'not a run: no repl');
    expect(
      await listed(scope(attested: false)),
      names,
      reason: 'a scope nobody attested is not a run',
    );
    // An attested run sees repl, the direct set and what a script may not
    // call; everything else is reached from a script.
    final run = await listed(scope(attested: true));
    expect(
      run,
      containsAll(['repl', 'ask_user', 'todo_write', 'send_message']),
    );
    expect(run, isNot(contains('list_tickets')));
    expect(run, isNot(contains('list_my_tools')));
    // Not callable either: a caller that is not a run is refused before the
    // tool runs (the fake executor would throw).
    for (final callerScope in [null, scope(attested: false)]) {
      final response = await replDispatcher.handleScopedRequest(
        JsonRpcRequest(
          method: 'tools/call',
          params: {
            'name': 'repl',
            'arguments': {'code': 'return 1;', 'description': 'one'},
          },
          id: 3,
        ),
        scope: callerScope,
      );
      final error = response['error'];
      final result = response['result'] as Map<String, dynamic>?;
      expect(
        error != null || result?['isError'] == true,
        isTrue,
        reason: 'repl ran for a caller that is not a run: $response',
      );
    }

    // What a script may call on this lane: never `repl` itself and never
    // the discovery tools (the script catalog is the discovery).
    final scriptable = {
      for (final d in await replDispatcher.scriptToolsFor(
        scope(attested: true),
      ))
        d.name,
    };
    expect(scriptable, isNotEmpty);
    // Nothing is lost: what the run does not list, a script reaches.
    expect(
      names
          .difference(run)
          .difference({'list_my_tools', 'search_tool_bm25'})
          .difference(scriptable),
      isEmpty,
    );
    expect(
      scriptable.intersection({'repl', 'search_tool_bm25', 'list_my_tools'}),
      isEmpty,
    );
  });
}

/// An executor a test must never reach.
class _NeverRuns implements CodeExecutionPort {
  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.available();

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) => throw StateError('repl ran for a caller that is not a run');
}

class _NoRecords implements CodeExecutionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('repl ran for a caller that is not a run');
}
