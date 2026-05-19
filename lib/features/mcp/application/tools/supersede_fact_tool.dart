import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/memory/domain/usecases/supersede_fact_use_case.dart';

/// MCP tool that marks a memory fact as superseded by another fact.
class SupersedeFactTool extends McpTool {

  /// Creates a [SupersedeFactTool].
  SupersedeFactTool({required SupersedeFactUseCase useCase}) : _useCase = useCase;

  final SupersedeFactUseCase _useCase;

  @override
  String get name => 'supersede_fact';

  @override
  String get description =>
      'Marks a memory fact as superseded by another fact.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace that owns the fact.',
      },
      'fact_id': {'type': 'string', 'description': 'ID of the fact to supersede.'},
      'superseding_fact_id': {
        'type': 'string',
        'description': 'ID of the fact that replaces it.',
      },
    },
    'required': ['workspace_id', 'fact_id', 'superseding_fact_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    final factId = arguments['fact_id'];
    final supersedingFactId = arguments['superseding_fact_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing workspace_id');
    }
    if (factId is! String) {
      return CallResult.error('Missing fact_id');
    }
    if (supersedingFactId is! String) {
      return CallResult.error('Missing superseding_fact_id');
    }

    try {
      final superseded = await _useCase.execute(
        workspaceId: workspaceId,
        factId: factId,
        supersedingFactId: supersedingFactId,
      );

      return CallResult.success(jsonEncode({
        'fact_id': superseded.id,
        'superseded_by': superseded.supersededBy,
        'status': 'superseded',
      }));
    } on ArgumentError catch (e) {
      return CallResult.error(e.message);
    }
  }
}
