import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_policy_use_case.dart';

/// MCP tool that retires a memory policy (marks it inactive) when it no longer
/// reflects the current state of the workspace.
class SupersedePolicyTool extends McpTool {
  /// Creates a [SupersedePolicyTool].
  SupersedePolicyTool({required SupersedePolicyUseCase useCase})
      : _useCase = useCase;

  final SupersedePolicyUseCase _useCase;

  @override
  String get name => 'supersede_policy';

  @override
  String get description =>
      'Retires a memory policy that is no longer accurate — marks it inactive '
      'so it stops applying, while keeping it for audit. Use this (rather than '
      'leaving stale rules in place) when re-reviewing a codebase whose '
      'conventions have changed. If a corrected rule still applies, call '
      'propose_policy with the new rule afterwards.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace that owns the policy.',
      },
      'policy_id': {
        'type': 'string',
        'description': 'ID of the policy to retire (from list_policies / '
            'search_memory).',
      },
    },
    'required': ['workspace_id', 'policy_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final policyId = arguments['policy_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (policyId is! String) {
      return CallResult.error('Missing policy_id');
    }

    try {
      final retired = await _useCase.execute(
        workspaceId: workspaceId,
        policyId: policyId,
      );

      return CallResult.success(jsonEncode({
        'policy_id': retired.id,
        'domain': retired.domain,
        'status': 'superseded',
      }));
    } on ArgumentError catch (e) {
      return CallResult.error(e.message);
    }
  }
}
