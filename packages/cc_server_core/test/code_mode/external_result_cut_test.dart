import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// An external MCP server's result past `BridgedMcpTool.maxResultChars`
/// reaches a script cut, as the `repl` description says: the real bridge
/// cuts it, the real dispatcher hands it over, and in the real runner the
/// script gets a string that ends in the marker and does not parse. The call
/// itself succeeded, and its record says so. Structured content within the
/// cap reaches the script whole, ahead of the text.
///
/// Runs the real runner (`CC_CODEMODE_RUNNER`, an absolute path to a built
/// `cc_codemode`).
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoCodeExecutionRepository executions;
  late CodeSandboxProcess sandbox;

  const workspaceId = 'ws-cut';
  const cap = BridgedMcpTool.maxResultChars;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, workspaceId);
    final db = dbs.of(workspaceId);
    await db.customStatement(
      'INSERT INTO agents '
      '(id, name, title, agent_md_path, workspace_id, skills) '
      "VALUES ('agent-1', 'agent-1', 'Agent', '', ?, '')",
      [workspaceId],
    );
    await db.customStatement(
      'INSERT INTO agent_run_logs (id, agent_id, workspace_id) '
      "VALUES ('run-1', 'agent-1', ?)",
      [workspaceId],
    );
    executions = DaoCodeExecutionRepository(dbs);
    final runner = BundledCodeRunner.locate(
      appSupportRoot: Directory.systemTemp.path,
    );
    sandbox = CodeSandboxProcess(executable: runner.executable);
    expect((await sandbox.selfTest()).isAvailable, isTrue);
  });

  tearDown(() async {
    await sandbox.dispose();
    await dbs.closeAll();
    await global.close();
  });

  test('the description states the cut at the bridge\'s own cap', () {
    final grouped = cap.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+$)'),
      (_) => ',',
    );
    expect(
      ReplToolDescription.externalToolsLine,
      contains('result text is cut at $grouped characters'),
    );
  });

  /// Runs [body] as a script on the MCP surface of a run whose workspace
  /// server's one tool, `make_json`, answers [reply] (a `tools/call` result).
  /// The tool's script name is `mcp__srv__make_json`, and the result `r`.
  Future<CodeExecutionResult> scriptOver(
    Map<String, dynamic> reply,
    String body,
  ) async {
    final tool = BridgedMcpTool(
      serverName: 'srv',
      remoteTool: const McpRemoteTool(
        name: 'make_json',
        description: 'Makes JSON.',
        inputSchema: {'type': 'object'},
      ),
      invoker: (server, name, args) async => reply,
    );
    final dispatcher = McpToolDispatcher(
      // A workspace's own server, as the owner added it.
      registry: McpToolRegistry(const [])
        ..setWorkspaceTools(workspaceId, [tool]),
      // The owner lets external tools run without a card.
      approvalMode: ApprovalMode.yolo,
    );
    const scope = McpCallScope(
      workspaceId: workspaceId,
      agentId: 'agent-1',
      conversationId: 'conv-1',
      spaceId: 'space-1',
      attested: true,
      runId: 'dispatch-1',
      runLogId: 'run-1',
    );
    final service = CodeExecutionService(
      sandbox: sandbox,
      executions: executions,
      store: DaoCodeModeStoreRepository(dbs),
      serverProcessCap: 2,
    );
    addTearDown(service.dispose);
    final result = await service.execute(
      CodeExecutionRequest(
        readOnly: false,
        past: null,
        workspaceId: workspaceId,
        runId: 'run-1',
        parentToolCallId: 'call_1',
        surface: CodeExecutionSurface.mcp,
        code: 'const r = await tools.${tool.name}({});\n$body',
        description: 'cut result',
        limits: CodeModeLimits.defaults,
        tools: [
          ScriptToolDescriptor(
            name: tool.name,
            namespace: 'srv',
            description: 'Makes JSON.',
            inputSchema: const {'type': 'object'},
          ),
        ],
        agentId: 'agent-1',
      ),
      callNested: (r) =>
          dispatcher.callNested(scope, r, approvals: ScriptApprovalBudget()),
    );
    expect(
      result.execution.status,
      CodeExecutionStatus.completed,
      reason: '${result.execution.errorKind}: ${result.result.text}',
    );
    return result;
  }

  // 300 KiB of `[0,0,…]`: valid JSON, and longer than the cap.
  final json = '[${List.filled(150 * 1024, '0').join(',')}]';

  test('300 KiB of JSON from an external tool reaches the script as a '
      'string ending in the marker; JSON.parse throws inside the script, and '
      'the call is recorded as completed', () async {
    expect(json.length, greaterThan(cap));
    final result = await scriptOver(
      {
        'content': [
          {'type': 'text', 'text': json},
        ],
      },
      '''
let parsed;
try { JSON.parse(r); parsed = 'parsed'; } catch (e) { parsed = e.name; }
return { type: typeof r, length: r.length, tail: r.slice(-48), parsed };
''',
    );

    final text = result.result.text;
    expect(text, contains('"type": "string"'));
    expect(text, contains('"parsed": "SyntaxError"'));
    expect(text, contains('[external output truncated at $cap chars]'));
    const marker = '\n…[external output truncated at $cap chars]';
    expect(text, contains('"length": ${cap + marker.length}'));
    final detail = (await executions.get(workspaceId, result.execution.id))!;
    final call = detail.calls.single;
    expect(call.toolName, 'mcp__srv__make_json');
    expect(call.status, NestedCallStatus.completed);
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('structured content within the cap is what the script gets, whole, '
      'though the text beside it is over the cap', () async {
    final values = List.generate(1000, (i) => i);
    final result = await scriptOver(
      {
        'content': [
          {'type': 'text', 'text': json},
        ],
        'structuredContent': {'values': values},
      },
      'return { type: typeof r, count: r.values.length, last: r.values[999] };',
    );

    final text = result.result.text;
    expect(text, contains('"type": "object"'));
    expect(text, contains('"count": 1000'));
    expect(text, contains('"last": 999'));
  }, timeout: const Timeout(Duration(seconds: 60)));
}
