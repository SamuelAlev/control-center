import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:test/test.dart';

import 'code_mode_fakes.dart';

/// A read-only run (a goal's review) on the MCP surface: its attested scope
/// says so, and the dispatcher lists and runs only what the read-only
/// profile admits, for a direct call and for a script's nested call alike.
void main() {
  late ProbeTool messages;
  late ProbeTool checklist;
  late ProbeTool send;
  late ProbeTool output;
  late ProbeTool mutate;
  late ProbeTool undecided;
  late McpToolDispatcher dispatcher;

  McpCallScope scope({required bool readOnly}) => McpCallScope(
    workspaceId: 'ws-own',
    agentId: 'agent-1',
    conversationId: 'conv-1',
    spaceId: 'sp-1',
    attested: true,
    runId: 'dispatch-1',
    runLogId: 'log-1',
    readOnly: readOnly,
  );

  setUp(() {
    messages = ProbeTool('get_messages');
    checklist = ProbeTool('todo_write');
    send = ProbeTool('send_message');
    output = ProbeTool('submit_output');
    mutate = ProbeTool(
      'get_thing_and_write',
      actionClasses: {ActionClass.workspaceMutation},
    );
    undecided = ProbeTool('brand_new_tool');
    dispatcher = McpToolDispatcher(
      registry: McpToolRegistry([
        messages,
        checklist,
        send,
        output,
        mutate,
        undecided,
      ]),
      modeGuard: ModeToolGuard(FixedModeResolver(Mode.review)),
    );
  });

  Future<List<String>> listed(McpCallScope scope) async {
    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(method: 'tools/list', params: {}, id: 1),
      scope: scope,
    );
    final tools = (response['result'] as Map)['tools'] as List;
    return [for (final t in tools) (t as Map)['name'] as String]..sort();
  }

  Future<Map<String, dynamic>> call(McpCallScope scope, String name) =>
      dispatcher.handleScopedRequest(
        JsonRpcRequest(
          method: 'tools/call',
          params: {
            'name': name,
            'arguments': {'workspace_id': 'ws-own'},
          },
          id: 2,
        ),
        scope: scope,
      );

  test(
    'tools/list shows a read-only run only reads and its output verb',
    () async {
      expect(await listed(scope(readOnly: true)), [
        'get_messages',
        'submit_output',
      ]);
      // The same run, not read-only, sees the state changes its mode allows.
      expect(await listed(scope(readOnly: false)), contains('todo_write'));
    },
  );

  test('a direct call of anything else is refused and never runs', () async {
    for (final tool in [checklist, send, mutate, undecided]) {
      final response = await call(scope(readOnly: true), tool.name);
      expect(
        jsonEncode(response),
        contains('read-only run'),
        reason: tool.name,
      );
      expect(tool.runs, 0, reason: tool.name);
    }
    await call(scope(readOnly: true), 'get_messages');
    expect(messages.runs, 1);
    await call(scope(readOnly: true), 'submit_output');
    expect(output.runs, 1);
  });

  test("a script's nested call meets the same profile", () async {
    for (final (i, tool) in [checklist, send, mutate, undecided].indexed) {
      final outcome = await dispatcher.callNested(
        scope(readOnly: true),
        nestedRequest(tool.name, sequence: i + 1),
        approvals: ScriptApprovalBudget(),
      );
      expect(
        outcome.status,
        isNot(NestedCallStatus.completed),
        reason: tool.name,
      );
      expect(tool.runs, 0, reason: tool.name);
    }
    final read = await dispatcher.callNested(
      scope(readOnly: true),
      nestedRequest('get_messages', sequence: 9),
      approvals: ScriptApprovalBudget(),
    );
    expect(read.status, NestedCallStatus.completed);
    expect(messages.runs, 1);
  });

  test('only an attested scope can be read-only', () {
    expect(
      () => McpCallScope(workspaceId: 'ws-own', readOnly: true),
      throwsA(isA<AssertionError>()),
    );
  });
}
