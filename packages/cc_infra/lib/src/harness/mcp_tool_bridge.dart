import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_harness/tools.dart';

/// Adapts a Control Center [McpTool] into a [HarnessTool] so the built-in agent
/// loop can call CC's orchestration tools (hire_agent, recall_facts,
/// create_ticket, send_message, list_prs, …) natively, alongside the built-in
/// filesystem tools.
///
/// Workspace scoping: when the tool's schema declares `workspace_id`,
/// `agent_id`, or `conversation_id` and the model omitted it, the bridge injects
/// the value from the [HarnessToolContext], so the loop never escapes its
/// workspace and the model is not burdened with repeating ids it already
/// operates under (e.g. `todo_write` gets its conversation for free).
class McpToolBridge extends HarnessTool {
  /// Creates an [McpToolBridge] wrapping [mcpTool].
  McpToolBridge(this.mcpTool);

  /// The wrapped Control Center MCP tool.
  final McpTool mcpTool;

  @override
  String get name => mcpTool.name;

  @override
  String get description => mcpTool.description;

  @override
  Map<String, dynamic> get inputSchema => mcpTool.inputSchema;

  @override
  ToolApprovalTier get approvalTier {
    // Use the args-independent default tier as the registry-time classification.
    return _mapTier(mcpTool.toolApproval(const {}).tier);
  }

  @override
  Set<ActionClass> get actionClasses => mcpTool.actionClasses;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final scoped = _withScope(args, context);
    final result = await mcpTool.call(scoped);
    final text = result.content
        .where((c) => c.text.isNotEmpty)
        .map((c) => c.text)
        .join('\n');
    return HarnessToolResult(content: text, isError: result.isError);
  }

  Map<String, dynamic> _withScope(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) {
    final props = mcpTool.inputSchema['properties'];
    if (props is! Map<String, dynamic>) {
      return args;
    }
    final scoped = Map<String, dynamic>.from(args);
    final wsId = context.workspaceId;
    // workspace_id is the isolation boundary: FORCE it to the run's workspace,
    // overriding any value the model supplied. A harness agent must never be
    // able to name a different workspace than the one it runs in (a
    // model-supplied foreign id would otherwise be an isolation escape).
    if (wsId != null && wsId.isNotEmpty && props.containsKey('workspace_id')) {
      scoped['workspace_id'] = wsId;
    }
    final agentId = context.agentId;
    if (agentId != null &&
        agentId.isNotEmpty &&
        props.containsKey('agent_id') &&
        (scoped['agent_id'] == null || scoped['agent_id'] == '')) {
      scoped['agent_id'] = agentId;
    }
    final convId = context.conversationId;
    if (convId != null &&
        convId.isNotEmpty &&
        props.containsKey('conversation_id') &&
        (scoped['conversation_id'] == null ||
            scoped['conversation_id'] == '')) {
      scoped['conversation_id'] = convId;
    }
    return scoped;
  }

  static ToolApprovalTier _mapTier(CapabilityTier tier) {
    switch (tier) {
      case CapabilityTier.read:
        return ToolApprovalTier.read;
      case CapabilityTier.write:
        return ToolApprovalTier.write;
      case CapabilityTier.exec:
        return ToolApprovalTier.exec;
    }
  }
}
