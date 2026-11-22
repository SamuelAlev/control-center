import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:test/test.dart';

import 'code_mode_fakes.dart';

/// An external MCP server's tool on the MCP surface: a script's call takes
/// the gate the model's own call takes and gets its verdict. The owner's
/// approval mode (`mcp.client.setApprovalMode`) decides both.
void main() {
  late _External tool;
  late Approver approver;
  late McpToolDispatcher dispatcher;

  void build(ApprovalMode mode) {
    tool = _External();
    approver = Approver();
    dispatcher = McpToolDispatcher(
      registry: McpToolRegistry(const [])..setWorkspaceTools('ws-own', [tool]),
      confirmationPort: approver,
      actionGuard: ActionGuardService(repository: _NoRules()),
      approvalMode: mode,
    );
  }

  /// The model's own call, then a script's; the cards each raised.
  Future<({int direct, int nested})> both() async {
    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(
        method: 'tools/call',
        params: {'name': tool.name, 'arguments': <String, dynamic>{}},
        id: 1,
      ),
      scope: runScope(),
    );
    expect(response['result'], isNotNull, reason: '$response');
    final direct = approver.requests.length;
    final outcome = await dispatcher.callNested(
      runScope(),
      nestedRequest(tool.name),
      approvals: ScriptApprovalBudget(),
    );
    expect(outcome.status, NestedCallStatus.completed);
    expect(tool.runs, 2);
    return (direct: direct, nested: approver.requests.length - direct);
  }

  test('asking for every tool above read: both ask', () async {
    build(ApprovalMode.alwaysAsk);
    expect(await both(), (direct: 1, nested: 1));
  });

  test('auto-approving everything: neither asks', () async {
    build(ApprovalMode.yolo);
    expect(await both(), (direct: 0, nested: 0));
  });
}

/// A tool as `BridgedMcpTool` declares one: no effect class, the exec tier,
/// and a card of its own.
class _External extends McpTool {
  int runs = 0;

  @override
  String get name => 'mcp__srv__ping';

  @override
  String get description => '[srv] Answers pong.';

  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  ToolApproval toolApproval(Map<String, dynamic> arguments) =>
      ToolApproval.exec;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) =>
      const ApprovalPayload(title: 'Ping?', detail: 'It pings.');

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    runs++;
    return CallResult.success('pong');
  }
}

class _NoRules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
